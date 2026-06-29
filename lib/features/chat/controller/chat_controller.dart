// lib/features/chat/controller/chat_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/chat_message_model.dart';
import '../data/models/chat_model.dart';
import '../data/repositories/chat_repository.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    required this.myUid,
    required this.chat,
    this.fromDetail = false,
  });

  final String myUid;
  final ChatModel chat;
  /// true quando aberto a partir de DreamDetailPage / DonationDetailPage
  final bool fromDetail;
  final _repo = ChatRepository.instance;

  List<ChatMessage> _messages           = [];
  bool _chatExistsInDb                  = false;
  bool _loading                         = true;
  bool _sending                         = false;
  String? _error;

  // Presença do outro usuário
  bool _otherOnline                     = false;
  int? _otherLastSeen;

  // Estado de conclusão da doação
  bool _completed                       = false;
  bool _showCompletionEffect            = false;

  // Controle de request pendente (impede o outro lado de mandar um também)
  bool _hasPendingRequest               = false;
  // true quando FUI EU quem enviou um request ainda sem resposta
  bool _iSentPendingRequest             = false;

  // true quando fromDetail e o itemId atual difere do gravado no Firebase
  bool _isContextSwitch             = false;

  List<ChatMessage> get messages        => _messages;
  bool get chatExistsInDb               => _chatExistsInDb;
  bool get loading                      => _loading;
  bool get sending                      => _sending;
  String? get error                     => _error;
  bool get otherOnline                  => _otherOnline;
  int? get otherLastSeen                => _otherLastSeen;
  bool get completed                    => _completed;
  bool get showCompletionEffect         => _showCompletionEffect;
  bool get hasPendingRequest            => _hasPendingRequest;
  bool get iSentPendingRequest          => _iSentPendingRequest;
  bool get isContextSwitch              => _isContextSwitch;

  /// A barra de entrega só aparece quando há pelo menos 1 mensagem de texto
  /// de cada lado — evita confirmar entrega sem ter combinado com o outro.
  bool get canSendDelivery {
    int myTexts    = 0;
    int otherTexts = 0;
    for (final m in _messages) {
      if (m.type != ChatMessageType.text) continue;
      if (m.senderId == myUid) {
        myTexts++;
      } else {
        otherTexts++;
      }
    }
    return myTexts >= 1 && otherTexts >= 1;
  }

  StreamSubscription<List<ChatMessage>>?    _msgSub;
  StreamSubscription<Map<String, dynamic>>? _presenceSub;
  StreamSubscription<bool>?                 _completedSub;

  Future<void> init() async {
    await _repo.goOnline(myUid);

    _presenceSub = _repo.presenceStream(chat.otherUid).listen((p) {
      _otherOnline   = p['online'] == true;
      _otherLastSeen = p['last_seen'] as int?;
      notifyListeners();
    });

    // Escuta conclusão em tempo real, filtrando pelo item atual.
    // Se o chat já foi concluído para um item ANTERIOR, o stream emite
    // false — o novo sonho/doação começa com estado limpo.
    _completedSub = _repo
        .chatCompletedStream(chat.chatId, currentItemId: chat.itemId)
        .listen((done) {
      if (done && !_completed) {
        _completed            = true;
        _showCompletionEffect = true;
        notifyListeners();
      } else if (done) {
        _completed = true;
        notifyListeners();
      } else if (!done && _completed) {
        // O contexto mudou para um novo item — reseta o estado local
        _completed            = false;
        _showCompletionEffect = false;
        notifyListeners();
      }
    });

    try {
      _chatExistsInDb = await _repo.chatExists(chat.chatId, myUid);
      if (_chatExistsInDb) {
        _subscribeMessages();
        _hasPendingRequest =
            await _repo.hasPendingDeliveryRequest(chat.chatId);

        // Detecta se o usuário abriu pelo detail com um item diferente
        // do que está gravado no chat — sinaliza troca de contexto
        if (fromDetail && chat.itemId != null) {
          final storedItemId = await _repo.fetchChatItemId(chat.chatId);
          _isContextSwitch =
              storedItemId != null && storedItemId != chat.itemId;
          if (_isContextSwitch) notifyListeners();
        }
      } else {
        _loading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChatController] init error: $e');
      _chatExistsInDb = false;
      _loading        = false;
      notifyListeners();
    }
  }

  void _subscribeMessages() {
    _msgSub = _repo.messagesStream(chat.chatId).listen(
      (msgs) {
        _messages = msgs;
        _loading  = false;
        // Recalcula pending request a partir das mensagens
        _recalcPendingRequest(msgs);
        notifyListeners();
        _repo.markAsRead(chat.chatId, myUid);
      },
      onError: (e) {
        _error   = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  void _recalcPendingRequest(List<ChatMessage> msgs) {
    bool hasRequest   = false;
    bool hasResponse  = false;
    String? requestSender;

    for (final m in msgs) {
      if (m.type == ChatMessageType.deliveryRequest) {
        hasRequest    = true;
        hasResponse   = false;
        requestSender = m.senderId;
      } else if (m.type == ChatMessageType.deliveryConfirmed ||
                 m.type == ChatMessageType.deliveryDenied) {
        hasResponse = true;
      }
    }

    // Pending = tem request sem resposta E não fui EU quem enviou
    // (quem enviou o request não precisa bloquear — já está esperando)
    _hasPendingRequest =
        hasRequest && !hasResponse && requestSender != myUid;
    // Sent = fui EU quem enviou e ainda não há resposta → esconde os botões
    _iSentPendingRequest =
        hasRequest && !hasResponse && requestSender == myUid;
  }

  /// Dispensa o efeito visual de conclusão (usuário viu / trocou de contexto)
  void dismissCompletionEffect() {
    _showCompletionEffect = false;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════
  // ENVIAR MENSAGEM NORMAL
  // ════════════════════════════════════════════════════════════════

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _sending) return;
    _sending = true;
    _error   = null;
    notifyListeners();

    try {
      await _repo.sendMessage(
        chat:              chat,
        senderId:          myUid,
        text:              text.trim(),
        chatAlreadyExists: _chatExistsInDb,
      );
      if (!_chatExistsInDb) {
        _chatExistsInDb = true;
        _subscribeMessages();
      }
      // Após enviar, o contexto já foi atualizado no Firebase
      if (_isContextSwitch) {
        _isContextSwitch = false;
      }
    } catch (e) {
      _error = 'Falha ao enviar. Tente novamente.';
      debugPrint('[ChatController] sendMessage error: $e');
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════════════
  // EVENTOS DE ENTREGA
  // ════════════════════════════════════════════════════════════════

  /// Quem tem o item avisa que entregou / quem vai buscar avisa que buscou.
  Future<void> sendDeliveryRequest({
    required String itemTitle,
    required String itemType,
    required bool isDonor,
  }) async {
    if (_sending || _hasPendingRequest) return;
    _sending = true;
    _error   = null;
    notifyListeners();

    final emoji = isDonor ? '📦' : '🛍️';
    final acao  = isDonor ? 'Entrega realizada' : 'Retirada realizada';
    final text  =
        '$emoji $acao\n"$itemTitle"\nAguardando confirmação do outro participante.';

    try {
      final msg = ChatMessage(
        id:                '',
        senderId:          myUid,
        text:              text,
        timestamp:         DateTime.now().millisecondsSinceEpoch,
        type:              ChatMessageType.deliveryRequest,
        deliveryItemTitle: itemTitle,
        deliveryItemType:  itemType,
      );
      await _repo.sendDeliveryEvent(
          chat: chat, senderId: myUid, message: msg);
    } catch (e) {
      _error = 'Falha ao registrar entrega.';
      debugPrint('[ChatController] sendDeliveryRequest error: $e');
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  // Trava local para evitar duplo disparo de respondDelivery
  bool _respondingDelivery = false;

  /// O receptor responde ao delivery_request: confirma ou nega.
  Future<void> respondDelivery({
    required ChatMessage requestMsg,
    required bool confirmed,
  }) async {
    // Dupla trava: _sending E _respondingDelivery evitam race condition
    if (_sending || _respondingDelivery) return;
    _sending            = true;
    _respondingDelivery = true;
    _error              = null;
    notifyListeners();

    final itemTitle = requestMsg.deliveryItemTitle ?? 'Item';
    final itemType  = requestMsg.deliveryItemType  ?? 'donation';

    final text = confirmed
        ? '✅ Recebimento confirmado!\n"$itemTitle"\nDoação concluída com sucesso! 🎉'
        : '❌ Recebimento não confirmado.\n"$itemTitle"\nEntre em contato para alinhar os detalhes.';

    try {
      // Verificação server-side: já existe resposta para este request?
      // Protege contra dois taps / dois dispositivos simultâneos.
      final alreadyAnswered = await _repo.deliveryRequestAlreadyAnswered(
        chatId:    chat.chatId,
        requestId: requestMsg.id,
      );
      if (alreadyAnswered) {
        debugPrint(
            '[ChatController] respondDelivery: já respondido, ignorando');
        return;
      }

      final msg = ChatMessage(
        id:                '',
        senderId:          myUid,
        text:              text,
        timestamp:         DateTime.now().millisecondsSinceEpoch,
        type:              confirmed
            ? ChatMessageType.deliveryConfirmed
            : ChatMessageType.deliveryDenied,
        deliveryItemTitle: itemTitle,
        deliveryItemType:  itemType,
        deliveryRequestId: requestMsg.id,
      );
      await _repo.sendDeliveryEvent(
          chat: chat, senderId: myUid, message: msg);

      // Se confirmou, dispara a conclusão completa
      if (confirmed && chat.itemId != null) {
        final meta = await _repo.fetchItemMeta(chat.itemId!, itemType);

        // O doador é sempre derivado do dono do item no Firebase (campo userId),
        // independente de quem apertou qual botão na UI:
        //   • donation → userId = quem cadastrou a doação = quem TEM o item = doador
        //   • dream    → userId = quem cadastrou o sonho  = quem QUER receber
        //                portanto o doador é o OUTRO participante do chat
        final itemOwnerUid = meta['userId'];
        final otherUid     = chat.user1 == myUid ? chat.user2 : chat.user1;
        final donorUid     = itemType == 'donation'
            ? (itemOwnerUid ?? otherUid)   // dono da doação = quem doou
            : otherUid;                    // dono do sonho NÃO é o doador

        await _repo.completeDonation(
          chat:          chat,
          confirmingUid: myUid,
          donorUid:      donorUid,
          itemId:        chat.itemId!,
          itemType:      itemType,
          itemTitle:     itemTitle,
          itemPhotoUrl:  meta['photoUrl'],
          itemCategory:  meta['category'],
        );
      }
    } catch (e) {
      _error = 'Falha ao responder entrega.';
      debugPrint('[ChatController] respondDelivery error: $e');
    } finally {
      _sending            = false;
      _respondingDelivery = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _repo.goOffline(myUid);
    _msgSub?.cancel();
    _presenceSub?.cancel();
    _completedSub?.cancel();
    super.dispose();
  }
}
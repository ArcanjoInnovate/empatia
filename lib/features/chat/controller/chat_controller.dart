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

  // Quem tem direito de INICIAR a declaração de entrega/recebimento do
  // item atual: sempre o dono da publicação (quem cadastrou o sonho ou a
  // doação) — nunca escolhido pela UI.
  // • donation → dono = quem TEM o item → inicia declarando "Entreguei"
  // • dream    → dono = quem QUER o item → inicia declarando "Recebi"
  // O outro participante só pode CONFIRMAR, nunca iniciar.
  String? _publisherUid;
  String? _otherPartyUid;

  // Controle de request pendente (impede o outro lado de mandar um também)
  bool _hasPendingRequest               = false;
  // true quando FUI EU quem enviou um request ainda sem resposta
  bool _iSentPendingRequest             = false;

  // true quando fromDetail e o itemId atual difere do gravado no Firebase
  bool _isContextSwitch             = false;

  // true quando o item (sonho/doação) já está fulfilled/donated e essa
  // conclusão NÃO pertence a este chat (ou seja: um terceiro usuário está
  // tentando abrir/usar um chat sobre um item que outra pessoa já concluiu).
  // Fonte da verdade: o próprio nó do item (Dreams/{id} ou Donations/{id}),
  // não o campo `completed` do chat — esse só é true para o PAR que de fato
  // concluiu a troca; um chat novo com um terceiro nunca teria `completed`.
  bool _itemUnavailable             = false;

  // true apenas na primeira vez que este usuário vê cada diálogo — depois
  // de mostrado, fica persistido no RTDB e nunca mais volta a true para
  // esse par (chatId + itemId), mesmo reabrindo o chat depois.
  bool _showUnavailableDialog       = false;

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
  bool get itemUnavailable              => _itemUnavailable;
  bool get showUnavailableDialog        => _showUnavailableDialog;

  /// Chave única por chat + item, usada para persistir "já visto" no RTDB.
  String get _completionDialogKey  => '${chat.chatId}_${chat.itemId ?? "none"}_completed';
  String get _unavailableDialogKey => '${chat.chatId}_${chat.itemId ?? "none"}_unavailable';

  /// true quando EU sou o dono da publicação (sonho ou doação) — só eu
  /// posso iniciar a declaração de entrega/recebimento. Enquanto o item
  /// ainda não foi carregado, fica false (botão some até sabermos com
  /// certeza quem tem esse direito).
  bool get iAmPublisher                 => _publisherUid != null && _publisherUid == myUid;
  String? get publisherUid              => _publisherUid;

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
  StreamSubscription<String?>?              _itemStatusSub;

  Future<void> init() async {
    await _repo.goOnline(myUid);
    await _repo.setActiveChat(myUid, chat.chatId);

    await _loadReceiverInfo();

    // Escuta o status do item AO VIVO — cobre o caso de este chat já
    // estar aberto (ex: outra aba) quando o item é concluído em OUTRO
    // chat. Sem isso, só pegaríamos essa mudança reabrindo a tela.
    if (chat.itemId != null) {
      _itemStatusSub = _repo
          .itemStatusStream(chat.itemId!, chat.itemType ?? 'dream')
          .listen((status) => _handleItemStatus(status));
    }

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
        .listen((done) async {
      if (done && !_completed) {
        _completed = true;
        // Só mostra o efeito de celebração se este usuário ainda não viu
        // esse diálogo para este chat+item — persistido no RTDB.
        final seen = await _repo.hasSeenDialog(myUid, _completionDialogKey);
        if (!seen) {
          _showCompletionEffect = true;
          await _repo.markDialogSeen(myUid, _completionDialogKey);
        }
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
        // 🩹 Auto-repara chats afetados pelo bug antigo que podia resetar
        // o estado de conclusão ao enviar mensagem depois de concluído.
        // Idempotente — não faz nada se o chat já estiver correto.
        // O _completedSub já assinado acima capta a correção automaticamente
        // assim que ela é gravada (é um listener ao vivo em Chats/{chatId}).
        await _repo.repairCompletionIfNeeded(chat.chatId);

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

  /// Descobre, a partir do `userId` gravado no item (Dream/Donation), quem
  /// é o dono da publicação — ele sempre inicia a declaração de entrega/
  /// recebimento; o outro participante só pode confirmar.
  Future<void> _loadReceiverInfo() async {
    if (chat.itemId == null) return;
    final itemType = chat.itemType ?? 'dream';
    try {
      final meta = await _repo.fetchItemMeta(chat.itemId!, itemType);
      final itemOwnerUid = meta['userId'];

      // Disponibilidade real do item — checada sempre, mesmo se userId vier
      // nulo, pois é o que decide se o usuário pode conversar sobre ele.
      await _handleItemStatus(meta['status'] as String?);

      if (itemOwnerUid == null) return;

      _publisherUid  = itemOwnerUid;
      _otherPartyUid = chat.user1 == itemOwnerUid ? chat.user2 : chat.user1;
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatController] _loadReceiverInfo error: $e');
    }
  }

  /// Processa uma leitura (pontual ou ao vivo) do `status` do item e decide
  /// se o chat deve ser marcado como indisponível e/ou mostrar o diálogo
  /// de terceiro. Compartilhado entre a checagem inicial (_loadReceiverInfo)
  /// e o listener ao vivo (_itemStatusSub) — mesma lógica, duas origens.
  Future<void> _handleItemStatus(String? status) async {
    final itemType = chat.itemType ?? 'dream';
    final isFulfilled = itemType == 'donation'
        ? status == 'donated'
        : status == 'fulfilled';

    if (!isFulfilled) return;
    if (_itemUnavailable) return; // já processado, evita reprocessar à toa

    _itemUnavailable = true;

    // CRÍTICO: item fulfilled/donated não significa necessariamente que
    // este chat é de um TERCEIRO — pode ser exatamente o par que concluiu
    // a troca (participante legítimo). Sem essa checagem, até quem
    // participou da conclusão veria o diálogo de "terceiro" por engano.
    final belongsToThisChat =
        await _repo.isCompletedByThisChat(chat.chatId, chat.itemId);

    if (!belongsToThisChat) {
      final seen = await _repo.hasSeenDialog(myUid, _unavailableDialogKey);
      if (!seen) {
        _showUnavailableDialog = true;
        await _repo.markDialogSeen(myUid, _unavailableDialogKey);
      }
    }
    notifyListeners();
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
    // Trava também no controller (não só na UI): item já concluído por
    // outra pessoa nunca pode receber nova mensagem, mesmo que a tela
    // de alguma forma deixe o usuário chamar sendMessage.
    if (_itemUnavailable && !_completed) return;
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

  /// O dono da publicação (sonho ou doação) declara o lado dele da troca.
  /// Travado por `_publisherUid` (calculado a partir do userId real do
  /// item, não escolhido pela UI) — o outro participante só confirma.
  Future<void> sendDeliveryRequest({
    required String itemTitle,
    required String itemType,
  }) async {
    // Mesma trava do sendMessage: item já indisponível (concluído em
    // outro chat) nunca pode iniciar uma nova declaração de entrega,
    // mesmo que a UI de alguma forma deixe chamar isso.
    if (_itemUnavailable && !_completed) return;
    if (_sending || _hasPendingRequest) return;
    if (!iAmPublisher) {
      debugPrint('[ChatController] sendDeliveryRequest bloqueado: '
          '$myUid não é o publisherUid ($_publisherUid)');
      return;
    }
    _sending = true;
    _error   = null;
    notifyListeners();

    // donation → dono TEM o item → declara que entregou
    // dream    → dono QUER o item → declara que recebeu
    final isDonation = itemType == 'donation';
    final emoji = isDonation ? '📦' : '🛍️';
    final acao  = isDonation ? 'Entrega realizada' : 'Recebimento declarado';
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
    // Mesma trava — não deixa confirmar/negar entrega de um item que já
    // foi concluído em outro chat.
    if (_itemUnavailable && !_completed) return;
    // Dupla trava: _sending E _respondingDelivery evitam race condition
    if (_sending || _respondingDelivery) return;
    _sending            = true;
    _respondingDelivery = true;
    _error              = null;
    notifyListeners();

    final itemTitle = requestMsg.deliveryItemTitle ?? 'Item';
    final itemType  = requestMsg.deliveryItemType  ?? 'donation';
    final isDonation = itemType == 'donation';

    // donation → quem confirma é quem BUSCOU o item
    // dream    → quem confirma é quem ENTREGOU o item
    final confirmedText = isDonation
        ? '✅ Retirada confirmada!\n"$itemTitle"\nDoação concluída com sucesso! 🎉'
        : '✅ Entrega confirmada!\n"$itemTitle"\nSonho concluído com sucesso! 🎉';
    final text = confirmed
        ? confirmedText
        : '❌ Não confirmado.\n"$itemTitle"\nEntre em contato para alinhar os detalhes.';

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
        // independente de quem apertou qual botão na UI — mesmo cálculo já
        // usado para decidir quem é o `_publisherUid` (que inicia a
        // declaração):
        //   • donation → userId = quem cadastrou a doação = quem TEM o item = doador = publisher
        //   • dream    → userId = quem cadastrou o sonho  = quem QUER receber
        //                portanto o doador é o OUTRO participante do chat (otherParty)
        final donorUid = itemType == 'donation'
            ? (_publisherUid ?? meta['userId'] ?? myUid)
            : (_otherPartyUid ?? (chat.user1 == myUid ? chat.user2 : chat.user1));

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

        // Fecha o chat IMEDIATAMENTE no dispositivo de quem confirmou —
        // não espera o round-trip do chatCompletedStream (RTDB) voltar.
        // Isso garante que quem confirmou nunca fique com o campo de
        // mensagem liberado por causa de latência/race do listener em
        // tempo real. O stream, quando chegar, só vai confirmar o que já
        // setamos aqui (idempotente).
        _completed = true;
        notifyListeners();
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
    _repo.clearActiveChat(myUid);
    _msgSub?.cancel();
    _presenceSub?.cancel();
    _completedSub?.cancel();
    _itemStatusSub?.cancel();
    super.dispose();
  }
}
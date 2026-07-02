// lib/features/chat/data/repositories/chat_repository.dart

import 'dart:async';

import 'package:empatia/features/search/data/repositories/search_repository.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../models/chat_model.dart';

class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  final _db = FirebaseDatabase.instance.ref();

  // ── Referências ───────────────────────────────────────────────
  DatabaseReference _chats(String id)                  => _db.child('Chats').child(id);
  DatabaseReference _msgs(String id)                   => _db.child('ChatMessages').child(id);
  DatabaseReference _preview(String uid, String cid)   => _db.child('ChatPreviews').child(uid).child(cid);
  DatabaseReference _userChats(String uid, String cid) => _db.child('UserChats').child(uid).child(cid);
  DatabaseReference _usersPublic(String uid)           => _db.child('UsersPublic').child(uid);
  DatabaseReference _presence(String uid)              => _db.child('Presence').child(uid);

  // ════════════════════════════════════════════════════════════════
  // PRESENCE — online / offline
  // ════════════════════════════════════════════════════════════════

  Future<void> goOnline(String uid) async {
    final ref = _presence(uid);
    await ref.onDisconnect().update({
      'online':    false,
      'last_seen': ServerValue.timestamp,
    });
    await ref.update({
      'online':    true,
      'last_seen': ServerValue.timestamp,
    });
  }

  Future<void> goOffline(String uid) async {
    await _presence(uid).update({
      'online':    false,
      'last_seen': ServerValue.timestamp,
    });
  }

  Stream<Map<String, dynamic>> presenceStream(String uid) {
    return _presence(uid).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) {
        return {'online': false, 'last_seen': null};
      }
      return {
        'online':    data['online'] == true,
        'last_seen': (data['last_seen'] as num?)?.toInt(),
      };
    });
  }

  // ════════════════════════════════════════════════════════════════
  // CRIAR / GARANTIR CHAT
  // ════════════════════════════════════════════════════════════════

  Future<bool> chatExists(String chatId, String myUid) async {
    try {
      final snap = await _userChats(myUid, chatId).get();
      return snap.exists && snap.value == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> createChat(ChatModel chat) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updates = <String, dynamic>{};

    chat.toChatNode().forEach((k, v) {
      updates['Chats/${chat.chatId}/$k'] = v;
    });

    updates['UserChats/${chat.user1}/${chat.chatId}'] = true;
    updates['UserChats/${chat.user2}/${chat.chatId}'] = true;

    updates['ChatPreviews/${chat.user1}/${chat.chatId}'] = {
      'other_uid':      chat.user2,
      'last_message':   '',
      'last_sender':    '',
      'last_timestamp': now,
      'unread':         0,
      'block_dialog':   false,
    };
    updates['ChatPreviews/${chat.user2}/${chat.chatId}'] = {
      'other_uid':      chat.user1,
      'last_message':   '',
      'last_sender':    '',
      'last_timestamp': now,
      'unread':         0,
      'block_dialog':   false,
    };

    await _db.update(updates);
  }

  /// Atualiza o contexto do chat (item atual).
  ///
  /// Se o [chat.itemId] for REALMENTE diferente do item que foi concluído
  /// (ou do item gravado, se ainda não houve conclusão), os campos
  /// [completed], [completed_at] e [completed_item_id] são resetados para que
  /// a UI de AMBOS os usuários comece limpa. O histórico de mensagens e o
  /// [DonationHistory] são preservados intactos.
  ///
  /// Continuar conversando sobre o MESMO item — mesmo depois de concluído
  /// (ex: combinar detalhes, agradecer) — NUNCA deve resetar a conclusão.
  Future<void> updateContext(ChatModel chat) async {
    final updates = chat.toContextUpdate();

    try {
      final snap = await _chats(chat.chatId).get();
      final data = snap.value is Map ? snap.value as Map : const {};

      final savedItemId     = data['item_id']?.toString();
      final completedItemId = data['completed_item_id']?.toString();
      final wasCompleted    = data['completed'] == true;

      // Item "efetivo" para fins de comparação: o completed_item_id é a
      // fonte da verdade sobre QUAL item gerou a conclusão. Só cai no
      // fallback de item_id quando o chat nunca foi concluído ou é legado.
      final effectiveItemId = wasCompleted
          ? (completedItemId ?? savedItemId)
          : savedItemId;

      // Só é uma TROCA DE ITEM de verdade quando o item atual do chat
      // (chat.itemId) é diferente do item gravado/concluído. Tratamos
      // effectiveItemId == null (chat antigo sem esse campo) como
      // "item diferente" apenas quando chat.itemId não é nulo.
      final itemChanged =
          chat.itemId != null && effectiveItemId != chat.itemId;

      if (itemChanged) {
        // Novo item → reseta todos os campos de conclusão atomicamente.
        // Isso garante que o chatCompletedStream do OUTRO usuário também
        // enxergue false: completed=false derruba a comparação antes mesmo
        // de avaliar completed_item_id, eliminando a janela de race.
        updates['completed']          = false;
        updates['completed_at']       = null;
        updates['completed_item_id']  = null; // <── fix: limpa o campo que
        //     chatCompletedStream usa como referência do outro lado

        // Grava o timestamp da troca de contexto — usado pela Cloud Function
        // para saber que mensagens anteriores a este momento pertencem a outro
        // item e NÃO devem contar como "primeiro contato no contexto atual".
        updates['item_changed_at']    = ServerValue.timestamp;
      }
    } catch (e) {
      // 🔧 FIX: falha ao ler o estado atual do chat NÃO reseta mais a
      // conclusão. O comportamento anterior ("reseta por precaução")
      // fazia com que qualquer mensagem enviada depois de uma doação
      // concluída — inclusive sobre o MESMO item — apagasse o estado
      // de conclusão sempre que essa leitura falhasse (ex: hiccup de
      // rede). Um erro de leitura transitório nunca deve poder apagar
      // uma doação já concluída; na dúvida, preservamos o estado atual
      // e apenas atualizamos os campos de contexto (item_id, título etc).
      debugPrint(
          '[ChatRepository] updateContext: falha ao verificar item atual, '
          'mantendo estado de conclusão intacto: $e');
    }

    await _chats(chat.chatId).update(updates);
  }

  // ════════════════════════════════════════════════════════════════
  // ENVIAR MENSAGEM
  // ════════════════════════════════════════════════════════════════

  Future<void> sendMessage({
    required ChatModel chat,
    required String senderId,
    required String text,
    required bool chatAlreadyExists,
  }) async {
    if (!chatAlreadyExists) {
      await createChat(chat);
    } else {
      await updateContext(chat);
    }

    final now     = DateTime.now().millisecondsSinceEpoch;
    final msgRef  = _msgs(chat.chatId).push();
    final msg     = ChatMessage(
      id:        msgRef.key!,
      senderId:  senderId,
      text:      text.trim(),
      timestamp: now,
      readBy:    {senderId: true},
    );

    final otherId = chat.user1 == senderId ? chat.user2 : chat.user1;

    await msgRef.set(msg.toMap());

    await _db.update({
      'Chats/${chat.chatId}/metadata/last_message':   text.trim(),
      'Chats/${chat.chatId}/metadata/last_sender':    senderId,
      'Chats/${chat.chatId}/metadata/last_timestamp': now,

      'ChatPreviews/$senderId/${chat.chatId}/last_message':    text.trim(),
      'ChatPreviews/$senderId/${chat.chatId}/last_sender':     senderId,
      'ChatPreviews/$senderId/${chat.chatId}/last_timestamp':  now,
      'ChatPreviews/$senderId/${chat.chatId}/unread':          0,
      'ChatPreviews/$senderId/${chat.chatId}/last_read_by_me': true,

      'ChatPreviews/$otherId/${chat.chatId}/last_message':    text.trim(),
      'ChatPreviews/$otherId/${chat.chatId}/last_sender':     senderId,
      'ChatPreviews/$otherId/${chat.chatId}/last_timestamp':  now,
      'ChatPreviews/$otherId/${chat.chatId}/last_read_by_me': false,
    });

    await _db
        .child('ChatPreviews/$otherId/${chat.chatId}/unread')
        .set(ServerValue.increment(1));
  }

  // ════════════════════════════════════════════════════════════════
  // EVENTOS DE ENTREGA
  // ════════════════════════════════════════════════════════════════

  /// Envia uma mensagem de evento de entrega (request / confirmed / denied).
  /// Bloqueia o outro lado de enviar um request enquanto um já está pendente.
  Future<void> sendDeliveryEvent({
    required ChatModel chat,
    required String senderId,
    required ChatMessage message,
  }) async {
    final otherId = chat.user1 == senderId ? chat.user2 : chat.user1;
    final now     = DateTime.now().millisecondsSinceEpoch;
    final msgRef  = _msgs(chat.chatId).push();
    final msgData = message.toMap();

    await msgRef.set(msgData);

    final previewText = message.text;

    await _db.update({
      'Chats/${chat.chatId}/metadata/last_message':   previewText,
      'Chats/${chat.chatId}/metadata/last_sender':    senderId,
      'Chats/${chat.chatId}/metadata/last_timestamp': now,

      'ChatPreviews/$senderId/${chat.chatId}/last_message':    previewText,
      'ChatPreviews/$senderId/${chat.chatId}/last_sender':     senderId,
      'ChatPreviews/$senderId/${chat.chatId}/last_timestamp':  now,
      'ChatPreviews/$senderId/${chat.chatId}/unread':          0,
      'ChatPreviews/$senderId/${chat.chatId}/last_read_by_me': true,

      'ChatPreviews/$otherId/${chat.chatId}/last_message':    previewText,
      'ChatPreviews/$otherId/${chat.chatId}/last_sender':     senderId,
      'ChatPreviews/$otherId/${chat.chatId}/last_timestamp':  now,
      'ChatPreviews/$otherId/${chat.chatId}/last_read_by_me': false,
    });

    await _db
        .child('ChatPreviews/$otherId/${chat.chatId}/unread')
        .set(ServerValue.increment(1));
  }

  /// Verifica server-side se um delivery_request já foi respondido.
  /// Impede duplo confirm mesmo vindo de dois dispositivos ao mesmo tempo.
  Future<bool> deliveryRequestAlreadyAnswered({
    required String chatId,
    required String requestId,
  }) async {
    try {
      final snap = await _msgs(chatId)
          .orderByChild('timestamp')
          .limitToLast(50)
          .get();
      if (!snap.exists || snap.value is! Map) return false;
      for (final e in (snap.value as Map).entries) {
        final val = e.value;
        if (val is! Map) continue;
        final type    = val['type']?.toString() ?? '';
        final refId   = val['delivery_request_id']?.toString() ?? '';
        final isReply = type == 'delivery_confirmed' || type == 'delivery_denied';
        if (isReply && refId == requestId) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Verifica se já existe um delivery_request pendente (sem confirm/deny) no chat.
  Future<bool> hasPendingDeliveryRequest(String chatId) async {
    try {
      final snap = await _msgs(chatId)
          .orderByChild('timestamp')
          .limitToLast(50)
          .get();
      if (!snap.exists || snap.value is! Map) return false;

      bool hasRequest  = false;
      bool hasResponse = false;

      final entries = (snap.value as Map).entries.toList()
        ..sort((a, b) {
          final ta = (a.value as Map?)?['timestamp'] as num? ?? 0;
          final tb = (b.value as Map?)?['timestamp'] as num? ?? 0;
          return ta.compareTo(tb);
        });

      for (final e in entries) {
        final val  = e.value;
        if (val is! Map) continue;
        final type = val['type']?.toString();
        if (type == 'delivery_request') {
          hasRequest  = true;
          hasResponse = false;
        } else if (type == 'delivery_confirmed' || type == 'delivery_denied') {
          hasResponse = true;
        }
      }

      return hasRequest && !hasResponse;
    } catch (_) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // CONCLUSÃO DA DOAÇÃO — chamado quando delivery_confirmed
  // ════════════════════════════════════════════════════════════════

  /// Conclui a doação/sonho após confirmação de entrega.
  ///
  /// Os updates são separados em grupos por escopo de permissão,
  /// pois o Firebase valida cada path individualmente no update atômico.
  /// - confirmingUid = receptor (quem confirmou, está autenticado agora)
  /// - donorUid      = quem tinha o item (pode ser diferente do auth.uid)
  Future<void> completeDonation({
    required ChatModel chat,
    required String confirmingUid,
    required String donorUid,
    required String itemId,
    required String itemType,
    required String itemTitle,
    required String? itemPhotoUrl,
    required String? itemCategory,
  }) async {
    final now       = DateTime.now().millisecondsSinceEpoch;
    final weekKey   = _weekKey();
    final donorName = await _getUserName(donorUid);

    // ── GRUPO 1: paths que qualquer participante autenticado pode escrever ──
    // Chats, Donations, Dreams, Rankings, DonationHistory (via regra aberta)
    final updatesOpen = <String, dynamic>{};

    // Marca chat como concluído (regra do Chats permite participantes)
    updatesOpen['Chats/${chat.chatId}/completed']    = true;
    updatesOpen['Chats/${chat.chatId}/completed_at'] = now;

    // Grava também o item que foi concluído — usado pelo chatCompletedStream
    // para distinguir conclusões de itens diferentes no mesmo chat.
    updatesOpen['Chats/${chat.chatId}/completed_item_id'] = itemId;

    // Atualiza o item (Donations/.write = auth !== null)
    if (itemType == 'donation') {
      updatesOpen['Donations/$itemId/status']     = 'donated';
      updatesOpen['Donations/$itemId/updatedAt']  = now;
      updatesOpen['Donations/$itemId/receivedBy'] = confirmingUid;
      updatesOpen['Donations/$itemId/receivedAt'] = now;
    } else {
      // Dreams/.write = auth !== null (nó global)
      updatesOpen['Dreams/$itemId/progress']    = 1.0;
      updatesOpen['Dreams/$itemId/status']      = 'fulfilled';
      updatesOpen['Dreams/$itemId/updatedAt']   = now;
      updatesOpen['Dreams/$itemId/fulfilledBy'] = donorUid;
      updatesOpen['Dreams/$itemId/fulfilledAt'] = now;
      updatesOpen['Users/$confirmingUid/dreams/$itemId/progress']    = 1.0;
      updatesOpen['Users/$confirmingUid/dreams/$itemId/status']      = 'fulfilled';
      updatesOpen['Users/$confirmingUid/dreams/$itemId/updatedAt']   = now;
      updatesOpen['Users/$confirmingUid/dreams/$itemId/fulfilledBy'] = donorUid;
      updatesOpen['Users/$confirmingUid/dreams/$itemId/fulfilledAt'] = now;
    }

    // Rankings/.write = auth !== null
    updatesOpen['Rankings/weekly/$weekKey/$donorUid/score'] =
        ServerValue.increment(10);
    updatesOpen['Rankings/weekly/$weekKey/$donorUid/count'] =
        ServerValue.increment(1);
    updatesOpen['Rankings/weekly/$weekKey/$donorUid/name'] = donorName;

    // Histórico do RECEPTOR — confirmingUid == auth.uid, permitido
    final receiverHistoryKey =
        _db.child('DonationHistory/$confirmingUid').push().key!;
    updatesOpen['DonationHistory/$confirmingUid/$receiverHistoryKey'] = {
      'type':         'received',
      'itemId':       itemId,
      'itemType':     itemType,
      'itemTitle':    itemTitle,
      'itemPhotoUrl': itemPhotoUrl,
      'itemCategory': itemCategory,
      'otherUid':     donorUid,
      'chatId':       chat.chatId,
      'timestamp':    now,
    };

    // Histórico do DOADOR — qualquer auth pode escrever via regra $entryId
    final donorHistoryKey =
        _db.child('DonationHistory/$donorUid').push().key!;
    updatesOpen['DonationHistory/$donorUid/$donorHistoryKey'] = {
      'type':         'donated',
      'itemId':       itemId,
      'itemType':     itemType,
      'itemTitle':    itemTitle,
      'itemPhotoUrl': itemPhotoUrl,
      'itemCategory': itemCategory,
      'otherUid':     confirmingUid,
      'chatId':       chat.chatId,
      'timestamp':    now,
    };

    await _db.update(updatesOpen);
  }

  String _weekKey() {
    final now   = DateTime.now();
    final year  = now.year;
    final week  =
        ((now.difference(DateTime(year, 1, 1)).inDays) / 7).ceil();
    return '$year-W${week.toString().padLeft(2, '0')}';
  }

  Future<String> _getUserName(String uid) async {
    try {
      final snap = await _usersPublic(uid).child('name').get();
      return snap.value?.toString() ?? 'Usuário';
    } catch (_) {
      return 'Usuário';
    }
  }

  // ════════════════════════════════════════════════════════════════
  // STREAMS
  // ════════════════════════════════════════════════════════════════

  Stream<List<ChatMessage>> messagesStream(String chatId) {
    return _msgs(chatId).orderByChild('timestamp').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return <ChatMessage>[];
      final msgs = <ChatMessage>[];
      (data as Map).forEach((key, val) {
        if (key == '_placeholder') return;
        if (val is Map) msgs.add(ChatMessage.fromMap(val, key.toString()));
      });
      msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return msgs;
    });
  }

  /// Stream que emite [true] apenas se o chat está concluído E o item
  /// concluído corresponde ao [currentItemId] em tela.
  ///
  /// Isso garante que uma nova conversa sobre um item diferente no mesmo
  /// canal entre dois usuários não herde o status da doação anterior.
  /// O histórico de mensagens permanece intacto.
  Stream<bool> chatCompletedStream(String chatId, {String? currentItemId}) {
    return _chats(chatId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data is! Map) return false;

      final done = data['completed'] == true;
      if (!done) return false;

      // Se não há itemId atual para comparar (chat legado), confia no flag
      if (currentItemId == null) return true;

      // completed_item_id é gravado por completeDonation — identifica qual
      // item gerou a conclusão. Se bater com o item atual, mostra conclusão;
      // se não bater, o completed pertence a uma doação/sonho anterior.
      final completedItemId = data['completed_item_id']?.toString();

      // Fallback: chats antigos sem completed_item_id usam item_id do contexto
      final contextItemId = completedItemId ?? data['item_id']?.toString();

      return contextItemId == currentItemId;
    });
  }

  /// Stream reativo da caixa de entrada.
  ///
  /// Antes, este stream só reagia a mudanças em `ChatPreviews/{myUid}`.
  /// Isso deixava a lista desatualizada (exigindo refresh manual) sempre
  /// que algo mudava apenas em `Chats/{chatId}` sem tocar em ChatPreviews —
  /// por exemplo: `completeDonation` (marca `completed`) e `updateContext`
  /// quando chamado fora do fluxo de envio de mensagem.
  ///
  /// Agora, além de escutar `ChatPreviews/{myUid}`, mantemos um listener
  /// individual em `Chats/{chatId}` para cada conversa da lista — qualquer
  /// mudança em qualquer uma delas dispara um novo emit com a lista
  /// recalculada, sem precisar de pull-to-refresh.
  Stream<List<ChatModel>> inboxStream(String myUid) {
    late final StreamController<List<ChatModel>> controller;
    StreamSubscription<DatabaseEvent>? previewsSub;
    final chatSubs = <String, StreamSubscription<DatabaseEvent>>{};
    Map previewsData = {};

    // 🔧 FIX: serialização dos rebuilds.
    //
    // Antes, cada evento (`ChatPreviews` OU qualquer `Chats/{chatId}`)
    // disparava um `rebuild()` assíncrono independente. Como cada rebuild
    // faz várias chamadas de rede (.get() por chat), dois rebuilds podiam
    // rodar em paralelo — e o que TERMINASSE por último vencia, mesmo que
    // tivesse COMEÇADO com dados mais antigos. Era exatamente esse cenário:
    // Sarah manda mensagem → dispara rebuild A; um instante depois algo mais
    // dispara rebuild B; se A (mais antigo, sem ver a conclusão ainda
    // propagada) terminar DEPOIS de B, a lista do Mavey mostra "em
    // andamento" mesmo com o Firebase já 100% correto — só "acertava" ao
    // abrir o chat porque isso forçava mais uma leitura que, por sorte,
    // terminava por último.
    //
    // A fila abaixo garante no máximo 1 rebuild em execução por vez; se
    // eventos novos chegam enquanto um rebuild está rodando, apenas
    // marcamos "dirty" e rodamos mais UMA passada ao final (sempre lendo os
    // dados mais recentes) — nunca há sobreposição, então a última
    // passada sempre reflete o estado mais atual do Firebase.
    var rebuilding = false;
    var dirty      = false;

    Future<void> rebuild() async {
      if (previewsData.isEmpty) {
        if (!controller.isClosed) controller.add(<ChatModel>[]);
        return;
      }

      final chats = <ChatModel>[];

      for (final entry in previewsData.entries) {
        final chatId = entry.key.toString();
        final val    = entry.value;
        if (val is! Map) continue;

        final otherUid = val['other_uid']?.toString() ?? '';

        String? name, avatar, emoji;
        try {
          final snap = await _usersPublic(otherUid).get();
          if (snap.exists && snap.value is Map) {
            final u = snap.value as Map;
            name   = u['name']?.toString();
            avatar = u['profileImage']?.toString();
            emoji  = u['profileEmoji']?.toString();
          }
        } catch (_) {}

        String? itemId, itemTitle, itemType, itemPhotoUrl;
        bool completed     = false;
        bool otherHasRead  = false;
        try {
          final cSnap = await _chats(chatId).get();
          if (cSnap.exists && cSnap.value is Map) {
            final c      = cSnap.value as Map;
            itemId       = c['item_id']?.toString();
            itemTitle    = c['item_title']?.toString();
            itemType     = c['item_type']?.toString();
            itemPhotoUrl = c['item_photo_url']?.toString();

            final done             = c['completed'] == true;
            final completedItemId  = c['completed_item_id']?.toString();
            final effectiveItemId  = completedItemId ?? itemId;
            completed = done && (itemId == null || effectiveItemId == itemId);

            // "Visto" do outro lado — comparação feita no nó compartilhado
            // Chats/{chatId}/last_read, que ambos participantes podem ler.
            final lastRead      = c['last_read'];
            final lastTimestamp = (val['last_timestamp'] as num?)?.toInt() ?? 0;
            if (lastRead is Map) {
              final otherReadAt = (lastRead[otherUid] as num?)?.toInt();
              otherHasRead = otherReadAt != null && otherReadAt >= lastTimestamp;
            }
          }
        } catch (_) {}

        chats.add(ChatModel.fromPreviewMap(
          val, chatId, myUid,
          otherName:    name,
          otherAvatar:  avatar,
          otherEmoji:   emoji,
          itemId:       itemId,
          itemTitle:    itemTitle,
          itemType:     itemType,
          itemPhotoUrl: itemPhotoUrl,
          completed:    completed,
          otherHasRead: otherHasRead,
        ));
      }

      chats.sort((a, b) =>
          (b.lastTimestamp ?? 0).compareTo(a.lastTimestamp ?? 0));

      if (!controller.isClosed) controller.add(chats);
    }

    // Ponto de entrada para TODO evento — nunca chama rebuild() diretamente.
    Future<void> scheduleRebuild() async {
      if (rebuilding) {
        dirty = true;
        return;
      }
      rebuilding = true;
      try {
        do {
          dirty = false;
          await rebuild();
        } while (dirty);
      } finally {
        rebuilding = false;
      }
    }

    void syncChatSubs(Iterable<String> chatIds) {
      final idSet = chatIds.toSet();

      // Remove listeners de chats que saíram da lista (ex: dado apagado)
      final toRemove =
          chatSubs.keys.where((id) => !idSet.contains(id)).toList();
      for (final id in toRemove) {
        chatSubs.remove(id)?.cancel();
      }

      // Adiciona listeners para chats novos — cada um agenda um rebuild
      // (serializado) ao mudar (completed, item_id, last_read, etc.)
      for (final id in idSet) {
        if (chatSubs.containsKey(id)) continue;
        chatSubs[id] = _chats(id).onValue.listen((_) => scheduleRebuild());
      }
    }

    controller = StreamController<List<ChatModel>>.broadcast(
      onListen: () {
        previewsSub = _db
            .child('ChatPreviews')
            .child(myUid)
            .onValue
            .listen((event) async {
          final data   = event.snapshot.value;
          previewsData = (data is Map) ? data : {};
          syncChatSubs(previewsData.keys.map((k) => k.toString()));
          await scheduleRebuild();
        });
      },
      onCancel: () {
        previewsSub?.cancel();
        for (final s in chatSubs.values) {
          s.cancel();
        }
        chatSubs.clear();
      },
    );

    return controller.stream;
  }

  // ════════════════════════════════════════════════════════════════
  // MARCAR COMO LIDO
  // ════════════════════════════════════════════════════════════════

  Future<void> markAsRead(String chatId, String uid) async {
    await _preview(uid, chatId).update({
      'unread':          0,
      'last_read_by_me': true,
    });

    // Grava também no nó compartilhado Chats/{chatId} — é o único lugar
    // que AMBOS os participantes conseguem ler, então é dali que o outro
    // usuário descobre se EU já li a última mensagem dele (✓✓ azul).
    // ChatPreviews é por-usuário e não pode ser lido pelo outro lado.
    try {
      await _chats(chatId).child('last_read').update({
        uid: ServerValue.timestamp,
      });
    } catch (_) {}

    try {
      final snap = await _msgs(chatId)
          .orderByChild('timestamp')
          .limitToLast(50)
          .get();
      if (!snap.exists || snap.value is! Map) return;

      final updates = <String, dynamic>{};
      (snap.value as Map).forEach((msgId, val) {
        if (val is! Map) return;
        final senderId = val['sender_id']?.toString() ?? '';
        if (senderId == uid) return;
        final readBy      = val['read_by'];
        final alreadyRead = readBy is Map && readBy[uid] == true;
        if (!alreadyRead) {
          updates['ChatMessages/$chatId/$msgId/read_by/$uid'] = true;
        }
      });

      if (updates.isNotEmpty) await _db.update(updates);
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════════
  // UTILITÁRIOS
  // ════════════════════════════════════════════════════════════════

  Future<Map<String, String?>> fetchUserInfo(String uid) async {
    try {
      final snap = await _usersPublic(uid).get();
      if (!snap.exists || snap.value is! Map) return {};
      final u = snap.value as Map;
      return {
        'name':         u['name']?.toString(),
        'profileImage': u['profileImage']?.toString(),
        'profileEmoji': u['profileEmoji']?.toString(),
      };
    } catch (_) {
      return {};
    }
  }

  Stream<int> totalUnreadStream(String uid) {
    return _db.child('ChatPreviews').child(uid).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return 0;
      int total = 0;
      (data as Map).forEach((_, v) {
        if (v is Map) total += (v['unread'] as num?)?.toInt() ?? 0;
      });
      return total;
    });
  }

  // ════════════════════════════════════════════════════════════════
  // BUSCAR ITEM DO CONTEXTO (Dream ou Donation)
  // ════════════════════════════════════════════════════════════════

  Future<SearchResult?> fetchItemForContext(
      String itemId, String itemType) async {
    try {
      final node = itemType == 'donation' ? 'Donations' : 'Dreams';
      final snap = await _db.child(node).child(itemId).get();
      if (!snap.exists || snap.value is! Map) return null;
      final m = snap.value as Map;
      return SearchResult(
        id:          itemId,
        type:        itemType,
        title:       m['title']?.toString(),
        description: m['date']?.toString() ?? m['description']?.toString(),
        photoUrl:    (m['imageUrl'] ?? m['photoUrl'])?.toString(),
        city:        m['city']?.toString(),
        state:       m['state']?.toString(),
        status:      m['status']?.toString(),
        ownerId:     m['userId']?.toString(),
        childName:   m['childName']?.toString(),
        childEmoji:  m['childEmoji']?.toString(),
        dreamEmoji:  m['emoji']?.toString(),
        category:    m['category']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Busca um [ChatModel] completo pelo [chatId] e [myUid].
  /// Retorna null se o chat não existir ou o usuário não tiver acesso.
  Future<ChatModel?> fetchChatModel(String chatId, String myUid) async {
    try {
      // Verifica acesso
      final access = await _userChats(myUid, chatId).get();
      if (!access.exists) return null;

      // Dados do preview (last message, unread, other_uid...)
      final previewSnap = await _preview(myUid, chatId).get();
      if (!previewSnap.exists || previewSnap.value is! Map) return null;
      final preview = previewSnap.value as Map;

      final otherUid = preview['other_uid']?.toString() ?? '';

      // Info pública do outro usuário
      String? name, avatar, emoji;
      try {
        final uSnap = await _usersPublic(otherUid).get();
        if (uSnap.exists && uSnap.value is Map) {
          final u = uSnap.value as Map;
          name   = u['name']?.toString();
          avatar = u['profileImage']?.toString();
          emoji  = u['profileEmoji']?.toString();
        }
      } catch (_) {}

      // Contexto do chat principal
      String? itemId, itemTitle, itemType, itemPhotoUrl;
      bool completed    = false;
      bool otherHasRead = false;
      try {
        final cSnap = await _chats(chatId).get();
        if (cSnap.exists && cSnap.value is Map) {
          final c      = cSnap.value as Map;
          itemId       = c['item_id']?.toString();
          itemTitle    = c['item_title']?.toString();
          itemType     = c['item_type']?.toString();
          itemPhotoUrl = c['item_photo_url']?.toString();
          final done            = c['completed'] == true;
          final completedItemId = c['completed_item_id']?.toString();
          final effectiveItemId = completedItemId ?? itemId;
          completed = done && (itemId == null || effectiveItemId == itemId);

          final lastRead      = c['last_read'];
          final lastTimestamp = (preview['last_timestamp'] as num?)?.toInt() ?? 0;
          if (lastRead is Map) {
            final otherReadAt = (lastRead[otherUid] as num?)?.toInt();
            otherHasRead = otherReadAt != null && otherReadAt >= lastTimestamp;
          }
        }
      } catch (_) {}

      return ChatModel.fromPreviewMap(
        preview, chatId, myUid,
        otherName:    name,
        otherAvatar:  avatar,
        otherEmoji:   emoji,
        itemId:       itemId,
        itemTitle:    itemTitle,
        itemType:     itemType,
        itemPhotoUrl: itemPhotoUrl,
        completed:    completed,
        otherHasRead: otherHasRead,
      );
    } catch (_) {
      return null;
    }
  }

  /// Retorna o [item_id] atualmente gravado no nó do chat.
  /// Usado para detectar troca de contexto ao abrir pelo detail page.
  Future<String?> fetchChatItemId(String chatId) async {
    try {
      final snap = await _chats(chatId).child('item_id').get();
      return snap.value?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Busca metadados extras do item para usar na conclusão da doação.
  Future<Map<String, String?>> fetchItemMeta(
      String itemId, String itemType) async {
    try {
      final node = itemType == 'donation' ? 'Donations' : 'Dreams';
      final snap = await _db.child(node).child(itemId).get();
      if (!snap.exists || snap.value is! Map) return {};
      final m = snap.value as Map;
      return {
        'category': m['category']?.toString(),
        'photoUrl': (m['imageUrl'] ?? m['photoUrl'])?.toString(),
        'userId':   m['userId']?.toString(),
      };
    } catch (_) {
      return {};
    }
  }

  // ════════════════════════════════════════════════════════════════
  // REPARO — chats corrompidos pelo bug antigo de updateContext
  // ════════════════════════════════════════════════════════════════
  //
  // A versão anterior de updateContext() resetava `completed` e
  // `completed_item_id` sempre que a leitura do item_id falhava, mesmo
  // enviando mensagem sobre o MESMO item já concluído. Isso já corrigimos,
  // mas chats que sofreram esse reset ANTES da correção ficaram com dado
  // errado gravado no Firebase — o código novo não reescreve sozinho um
  // dado que já está lá.
  //
  // `item_id` nunca era apagado por aquele bug (só completed/completed_at/
  // completed_item_id), então dá pra reconstruir com segurança: se existe
  // uma mensagem `delivery_confirmed` no histórico do chat mas o nó
  // Chats/{chatId} não está marcado como concluído, restauramos.

  /// Repara UM chat, se necessário. Retorna `true` se algo foi corrigido.
  /// Seguro de chamar repetidamente — não faz nada se já estiver consistente.
  Future<bool> repairCompletionIfNeeded(String chatId) async {
    try {
      final chatSnap = await _chats(chatId).get();
      if (!chatSnap.exists || chatSnap.value is! Map) return false;
      final chatData = chatSnap.value as Map;

      final alreadyOk = chatData['completed'] == true &&
          chatData['completed_item_id'] != null;
      if (alreadyOk) return false;

      final itemId = chatData['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) return false;

      final msgSnap = await _msgs(chatId)
          .orderByChild('timestamp')
          .limitToLast(200)
          .get();
      if (!msgSnap.exists || msgSnap.value is! Map) return false;

      // Encontra a confirmação de entrega mais recente, se existir.
      Map? confirmedMsg;
      for (final entry in (msgSnap.value as Map).entries) {
        final val = entry.value;
        if (val is! Map) continue;
        if (val['type']?.toString() != 'delivery_confirmed') continue;
        final ts     = (val['timestamp'] as num?)?.toInt() ?? 0;
        final prevTs = (confirmedMsg?['timestamp'] as num?)?.toInt() ?? -1;
        if (ts >= prevTs) confirmedMsg = val;
      }
      if (confirmedMsg == null) return false; // nunca foi confirmado de fato

      final completedAt = (confirmedMsg['timestamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch;

      await _chats(chatId).update({
        'completed':         true,
        'completed_at':      completedAt,
        'completed_item_id': itemId,
      });

      debugPrint('[ChatRepository] repairCompletionIfNeeded: '
          'chat $chatId restaurado (item $itemId)');
      return true;
    } catch (e) {
      debugPrint('[ChatRepository] repairCompletionIfNeeded error: $e');
      return false;
    }
  }

  /// Roda o reparo em todos os chats de [myUid]. Chame uma vez ao abrir
  /// a lista de conversas (fire-and-forget) — a inboxStream já escuta
  /// Chats/{chatId} de cada conversa, então qualquer correção aplicada
  /// aqui aparece sozinha na tela, sem precisar de refresh manual.
  Future<int> repairAllChatsForUser(String myUid) async {
    var repaired = 0;
    try {
      final snap = await _db.child('UserChats').child(myUid).get();
      if (!snap.exists || snap.value is! Map) return 0;

      final chatIds = (snap.value as Map).keys.map((k) => k.toString());
      for (final chatId in chatIds) {
        final fixed = await repairCompletionIfNeeded(chatId);
        if (fixed) repaired++;
      }
    } catch (e) {
      debugPrint('[ChatRepository] repairAllChatsForUser error: $e');
    }
    return repaired;
  }
}
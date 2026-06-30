// lib/features/chat/data/repositories/chat_repository.dart

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
  /// Se o [chat.itemId] for diferente do item gravado no Firebase, os campos
  /// [completed], [completed_at] e [completed_item_id] são resetados para que
  /// a UI de AMBOS os usuários comece limpa. O histórico de mensagens e o
  /// [DonationHistory] são preservados intactos.
  Future<void> updateContext(ChatModel chat) async {
    final updates = chat.toContextUpdate();

    // Verifica se o item mudou em relação ao que está salvo no Firebase.
    // Tratamos savedItemId == null (campo ausente em chats antigos) como
    // "item diferente" sempre que chat.itemId não é nulo — o reset é seguro.
    try {
      final snap        = await _chats(chat.chatId).child('item_id').get();
      final savedItemId = snap.value?.toString();
      final itemChanged = chat.itemId != null && savedItemId != chat.itemId;

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
    } catch (_) {
      // Se falhar ao ler o item_id atual, reseta completed por precaução
      // para não deixar o outro usuário preso em estado concluído.
      if (chat.itemId != null) {
        updates['completed']         = false;
        updates['completed_at']      = null;
        updates['completed_item_id'] = null;
      }
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

  Stream<List<ChatModel>> inboxStream(String myUid) {
    return _db
        .child('ChatPreviews')
        .child(myUid)
        .onValue
        .asyncMap((event) async {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return <ChatModel>[];

      final chats = <ChatModel>[];

      for (final entry in (data as Map).entries) {
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
        bool completed = false;
        try {
          final cSnap = await _chats(chatId).get();
          if (cSnap.exists && cSnap.value is Map) {
            final c      = cSnap.value as Map;
            itemId       = c['item_id']?.toString();
            itemTitle    = c['item_title']?.toString();
            itemType     = c['item_type']?.toString();
            itemPhotoUrl = c['item_photo_url']?.toString();

            // Na inbox, completed só é verdadeiro se o item concluído
            // ainda é o mesmo item do contexto atual do chat.
            final done              = c['completed'] == true;
            final completedItemId   = c['completed_item_id']?.toString();
            final effectiveItemId   = completedItemId ?? itemId;
            completed = done && (itemId == null || effectiveItemId == itemId);
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
        ));
      }

      chats.sort((a, b) =>
          (b.lastTimestamp ?? 0).compareTo(a.lastTimestamp ?? 0));
      return chats;
    });
  }

  // ════════════════════════════════════════════════════════════════
  // MARCAR COMO LIDO
  // ════════════════════════════════════════════════════════════════

  Future<void> markAsRead(String chatId, String uid) async {
    await _preview(uid, chatId).update({
      'unread':          0,
      'last_read_by_me': true,
    });

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
      bool completed = false;
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
}
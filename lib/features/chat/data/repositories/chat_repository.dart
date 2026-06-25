// lib/features/chat/data/repositories/chat_repository.dart

import 'package:empatia/features/search/data/repositories/search_repository.dart';
import 'package:firebase_database/firebase_database.dart';
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

  /// Chama ao abrir o app / tela de chat.
  /// O Firebase seta offline automaticamente via onDisconnect quando
  /// a conexão cai — sem precisar de lógica manual.
  Future<void> goOnline(String uid) async {
    final ref = _presence(uid);
    // Quando desconectar, Firebase seta automaticamente
    await ref.onDisconnect().update({
      'online':    false,
      'last_seen': ServerValue.timestamp,
    });
    // Marca online agora
    await ref.update({
      'online':    true,
      'last_seen': ServerValue.timestamp,
    });
  }

  /// Chama ao fechar a tela de chat ou fazer logout explícito.
  Future<void> goOffline(String uid) async {
    await _presence(uid).update({
      'online':    false,
      'last_seen': ServerValue.timestamp,
    });
  }

  /// Stream de presença de outro usuário.
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

  Future<void> updateContext(ChatModel chat) async {
    await _chats(chat.chatId).update(chat.toContextUpdate());
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

    // 1 — grava mensagem
    await msgRef.set(msg.toMap());

    // 2 — metadata + previews de ambos
    await _db.update({
      'Chats/${chat.chatId}/metadata/last_message':   text.trim(),
      'Chats/${chat.chatId}/metadata/last_sender':    senderId,
      'Chats/${chat.chatId}/metadata/last_timestamp': now,

      'ChatPreviews/$senderId/${chat.chatId}/last_message':   text.trim(),
      'ChatPreviews/$senderId/${chat.chatId}/last_sender':    senderId,
      'ChatPreviews/$senderId/${chat.chatId}/last_timestamp': now,
      'ChatPreviews/$senderId/${chat.chatId}/unread':         0,
      'ChatPreviews/$senderId/${chat.chatId}/last_read_by_me': true,

      'ChatPreviews/$otherId/${chat.chatId}/last_message':    text.trim(),
      'ChatPreviews/$otherId/${chat.chatId}/last_sender':     senderId,
      'ChatPreviews/$otherId/${chat.chatId}/last_timestamp':  now,
      'ChatPreviews/$otherId/${chat.chatId}/last_read_by_me': false,
    });

    // 3 — incrementa unread do outro
    await _db
        .child('ChatPreviews/$otherId/${chat.chatId}/unread')
        .set(ServerValue.increment(1));
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

  Stream<List<ChatModel>> inboxStream(String myUid) {
    return _db.child('ChatPreviews').child(myUid).onValue.asyncMap((event) async {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return <ChatModel>[];

      final chats = <ChatModel>[];

      for (final entry in (data as Map).entries) {
        final chatId   = entry.key.toString();
        final val      = entry.value;
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
        try {
          final cSnap = await _chats(chatId).get();
          if (cSnap.exists && cSnap.value is Map) {
            final c      = cSnap.value as Map;
            itemId       = c['item_id']?.toString();
            itemTitle    = c['item_title']?.toString();
            itemType     = c['item_type']?.toString();
            itemPhotoUrl = c['item_photo_url']?.toString();
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

  /// Zera unread, marca last_read_by_me=true e atualiza read_by
  /// em todas as mensagens ainda não lidas pelo uid.
  Future<void> markAsRead(String chatId, String uid) async {
    // Zera preview
    await _preview(uid, chatId).update({
      'unread':         0,
      'last_read_by_me': true,
    });

    // Atualiza read_by nas mensagens não lidas (apenas as mais recentes
    // para não sobrecarregar — máx 50)
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
        if (senderId == uid) return; // própria mensagem, não precisa
        final readBy = val['read_by'];
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
}
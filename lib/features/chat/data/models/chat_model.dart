// lib/features/chat/data/models/chat_model.dart

enum ChatOrigin { dream, donation, direct }

extension ChatOriginExt on ChatOrigin {
  String get value {
    switch (this) {
      case ChatOrigin.dream:    return 'dream';
      case ChatOrigin.donation: return 'donation';
      case ChatOrigin.direct:   return 'direct';
    }
  }

  static ChatOrigin fromString(String? s) {
    switch (s) {
      case 'dream':    return ChatOrigin.dream;
      case 'donation': return ChatOrigin.donation;
      default:         return ChatOrigin.direct;
    }
  }
}

class ChatModel {
  final String chatId;
  final String user1;
  final String user2;
  final ChatOrigin origin;

  // Contexto atual — sobrescrito a cada nova interação
  final String? itemId;
  final String? itemTitle;
  final String? itemType;     // 'dream' | 'donation'
  final String? itemPhotoUrl; // para thumbnail no banner

  // Preview (last message)
  final String? lastMessage;
  final String? lastSenderId;
  final int? lastTimestamp;
  final int unread;
  /// true quando a última mensagem enviada por mim foi lida pelo outro
  final bool? lastReadByMe;

  /// true quando a doação foi concluída (delivery_confirmed)
  final bool completed;

  // Info do outro usuário
  final String otherUid;
  final String? otherName;
  final String? otherAvatar;
  final String? otherEmoji;

  const ChatModel({
    required this.chatId,
    required this.user1,
    required this.user2,
    required this.otherUid,
    this.origin = ChatOrigin.direct,
    this.itemId,
    this.itemTitle,
    this.itemType,
    this.itemPhotoUrl,
    this.lastMessage,
    this.lastSenderId,
    this.lastTimestamp,
    this.unread = 0,
    this.lastReadByMe,
    this.completed = false,
    this.otherName,
    this.otherAvatar,
    this.otherEmoji,
  });

  /// chatId canônico: menor UID _ maior UID
  static String buildId(String uid1, String uid2) {
    final s = [uid1, uid2]..sort();
    return '${s[0]}_${s[1]}';
  }

  /// Constrói a partir do nó Chats/{chatId} do Firebase
  factory ChatModel.fromChatNode(Map map, String chatId, String myUid) {
    final u1 = map['user1']?.toString() ?? '';
    final u2 = map['user2']?.toString() ?? '';
    final otherUid = u1 == myUid ? u2 : u1;
    return ChatModel(
      chatId: chatId,
      user1: u1,
      user2: u2,
      otherUid: otherUid,
      origin: ChatOriginExt.fromString(map['item_type']?.toString()),
      itemId: map['item_id']?.toString(),
      itemTitle: map['item_title']?.toString(),
      itemType: map['item_type']?.toString(),
      itemPhotoUrl: map['item_photo_url']?.toString(),
    );
  }

  /// Constrói a partir do nó ChatPreviews/{uid}/{chatId}
  factory ChatModel.fromPreviewMap(
    Map map,
    String chatId,
    String myUid, {
    String? otherName,
    String? otherAvatar,
    String? otherEmoji,
    // contexto vindo de Chats/{chatId}
    String? itemId,
    String? itemTitle,
    String? itemType,
    String? itemPhotoUrl,
    bool completed = false,
  }) {
    final otherUid = map['other_uid']?.toString() ?? '';
    final parts = chatId.split('_');
    return ChatModel(
      chatId: chatId,
      user1: parts.isNotEmpty ? parts[0] : myUid,
      user2: parts.length > 1 ? parts[1] : otherUid,
      otherUid: otherUid,
      lastMessage: map['last_message']?.toString(),
      lastSenderId: map['last_sender']?.toString(),
      lastTimestamp: (map['last_timestamp'] as num?)?.toInt(),
      unread: (map['unread'] as num?)?.toInt() ?? 0,
      lastReadByMe: map['last_read_by_me'] as bool?,
      otherName: otherName,
      otherAvatar: otherAvatar,
      otherEmoji: otherEmoji,
      itemId: itemId,
      itemTitle: itemTitle,
      itemType: itemType,
      itemPhotoUrl: itemPhotoUrl,
      completed: completed,
    );
  }

  /// Nó principal Chats/{chatId} — criação inicial
  Map<String, dynamic> toChatNode() => {
    'user1': user1,
    'user2': user2,
    'participants': [user1, user2],
    'origin': origin.value,
    'item_id': itemId,
    'item_title': itemTitle,
    'item_type': itemType,
    'item_photo_url': itemPhotoUrl,
    'block_dialog': false,
    'unreadCount': {user1: 0, user2: 0},
    'metadata': {
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'last_message': '',
      'last_sender': '',
      'last_timestamp': DateTime.now().millisecondsSinceEpoch,
    },
  };

  /// Apenas os campos de contexto — usado para atualizar chat existente
  Map<String, dynamic> toContextUpdate() => {
    'item_id': itemId,
    'item_title': itemTitle,
    'item_type': itemType,
    'item_photo_url': itemPhotoUrl,
    'origin': origin.value,
  };

  /// Preview por usuário
  Map<String, dynamic> toPreviewNode(String myUid) => {
    'other_uid': otherUid,
    'last_message': lastMessage ?? '',
    'last_sender': lastSenderId ?? '',
    'last_timestamp': lastTimestamp ?? DateTime.now().millisecondsSinceEpoch,
    'unread': unread,
    'block_dialog': false,
  };
}
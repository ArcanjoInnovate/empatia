// lib/features/notifications/data/models/notification_model.dart

enum NotificationType {
  firstMessage,   // primeira mensagem de interesse numa doação/sonho
  message,        // mensagem normal de chat
  donationDone,   // doação concluída (donor + receiver)
  rankingReset,   // reset semanal do ranking (broadcast)
}

extension NotificationTypeExt on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.firstMessage:  return 'first_message';
      case NotificationType.message:       return 'message';
      case NotificationType.donationDone:  return 'donation_done';
      case NotificationType.rankingReset:  return 'ranking_reset';
    }
  }

  static NotificationType fromString(String? s) {
    switch (s) {
      case 'first_message':  return NotificationType.firstMessage;
      case 'donation_done':  return NotificationType.donationDone;
      case 'ranking_reset':  return NotificationType.rankingReset;
      default:               return NotificationType.message;
    }
  }

  String get emoji {
    switch (this) {
      case NotificationType.firstMessage: return '🎁';
      case NotificationType.message:      return '💬';
      case NotificationType.donationDone: return '🎉';
      case NotificationType.rankingReset: return '🏆';
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final int timestamp;
  final bool read;

  // Contexto opcional — para navegar direto ao chat ao tocar
  final String? chatId;
  final String? senderUid;
  final String? senderName;
  final String? itemTitle;
  final String? itemType;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.read = false,
    this.chatId,
    this.senderUid,
    this.senderName,
    this.itemTitle,
    this.itemType,
  });

  factory AppNotification.fromMap(Map map, String id) {
    return AppNotification(
      id:         id,
      type:       NotificationTypeExt.fromString(map['type']?.toString()),
      title:      map['title']?.toString() ?? '',
      body:       map['body']?.toString() ?? '',
      timestamp:  (map['timestamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      read:       map['read'] == true,
      chatId:     map['chatId']?.toString(),
      senderUid:  map['senderUid']?.toString(),
      senderName: map['senderName']?.toString(),
      itemTitle:  map['itemTitle']?.toString(),
      itemType:   map['itemType']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'type':       type.value,
    'title':      title,
    'body':       body,
    'timestamp':  timestamp,
    'read':       read,
    if (chatId     != null) 'chatId':     chatId,
    if (senderUid  != null) 'senderUid':  senderUid,
    if (senderName != null) 'senderName': senderName,
    if (itemTitle  != null) 'itemTitle':  itemTitle,
    if (itemType   != null) 'itemType':   itemType,
  };

  AppNotification copyWith({bool? read}) => AppNotification(
    id:         id,
    type:       type,
    title:      title,
    body:       body,
    timestamp:  timestamp,
    read:       read ?? this.read,
    chatId:     chatId,
    senderUid:  senderUid,
    senderName: senderName,
    itemTitle:  itemTitle,
    itemType:   itemType,
  );

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// Agrupa notificações próximas do mesmo remetente (ex: mensagens em sequência)
  bool isSameContextAs(AppNotification other) =>
      type == other.type &&
      chatId != null &&
      chatId == other.chatId;
}
// lib/features/notifications/data/models/notification_model.dart

enum NotificationType {
  firstMessage,     // primeira mensagem de interesse numa doação/sonho
  message,          // mensagem normal de chat
  donationDone,     // doação concluída (donor + receiver)
  rankingReset,     // reset semanal do ranking (broadcast)
  deliveryRequest,  // confirmação de entrega pendente (um lado confirmou)
  deliveryConfirmed,// entrega confirmada por ambos
  deliveryDenied,   // entrega negada (item ainda não chegou)
}

extension NotificationTypeExt on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.firstMessage:      return 'first_message';
      case NotificationType.message:           return 'message';
      case NotificationType.donationDone:      return 'donation_done';
      case NotificationType.rankingReset:      return 'ranking_reset';
      case NotificationType.deliveryRequest:   return 'delivery_request';
      case NotificationType.deliveryConfirmed: return 'delivery_confirmed';
      case NotificationType.deliveryDenied:    return 'delivery_denied';
    }
  }

  static NotificationType fromString(String? s) {
    switch (s) {
      case 'first_message':      return NotificationType.firstMessage;
      case 'donation_done':      return NotificationType.donationDone;
      case 'ranking_reset':      return NotificationType.rankingReset;
      case 'delivery_request':   return NotificationType.deliveryRequest;
      case 'delivery_confirmed': return NotificationType.deliveryConfirmed;
      case 'delivery_denied':    return NotificationType.deliveryDenied;
      default:                   return NotificationType.message;
    }
  }

  String get emoji {
    switch (this) {
      case NotificationType.firstMessage:      return '🎁';
      case NotificationType.message:           return '💬';
      case NotificationType.donationDone:      return '🎉';
      case NotificationType.rankingReset:      return '🏆';
      case NotificationType.deliveryRequest:   return '📦';
      case NotificationType.deliveryConfirmed: return '✅';
      case NotificationType.deliveryDenied:    return '❌';
    }
  }

  /// Notificações de chat puro — não aparecem na tela de notificações,
  /// pois o usuário já vê essas mensagens dentro do próprio chat.
  ///
  /// IMPORTANTE: firstMessage NÃO entra aqui — é o aviso de "alguém tem
  /// interesse na sua doação/sonho", que é uma notificação relevante por
  /// si só (não é só "mais uma mensagem de chat"), então precisa aparecer
  /// na aba de notificações e contar no badge, igual delivery_request/
  /// delivery_confirmed/donation_done. Só a 2ª mensagem em diante
  /// (message) é chat puro de verdade.
  bool get isChatOnly {
    switch (this) {
      case NotificationType.message:
        return true;
      default:
        return false;
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

  /// 'action' = pendência que bloqueia algo até o usuário responder
  /// (ex: delivery_request). 'info' = tudo mais. Usado pra ordenar a
  /// lista (pendências primeiro) e pro canal/som do push.
  final String priority;

  /// Quantos eventos se acumularam nessa célula (agrupada por chat)
  /// desde a última leitura — ex: "3 mensagens novas".
  final int unreadCount;

  // Contexto opcional — para navegar direto ao chat ao tocar
  final String? chatId;
  final String? senderUid;
  final String? senderName;
  final String? senderImageUrl;
  final String? itemTitle;
  final String? itemType;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.read = false,
    this.priority = 'info',
    this.unreadCount = 1,
    this.chatId,
    this.senderUid,
    this.senderName,
    this.senderImageUrl,
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
      priority:   map['priority']?.toString() ?? 'info',
      unreadCount: (map['unreadCount'] as num?)?.toInt() ?? 1,
      chatId:     map['chatId']?.toString(),
      senderUid:  map['senderUid']?.toString(),
      senderName: map['senderName']?.toString(),
      senderImageUrl: map['senderImageUrl']?.toString(),
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
    'priority':   priority,
    'unreadCount': unreadCount,
    if (chatId     != null) 'chatId':     chatId,
    if (senderUid  != null) 'senderUid':  senderUid,
    if (senderName != null) 'senderName': senderName,
    if (senderImageUrl != null) 'senderImageUrl': senderImageUrl,
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
    priority:   priority,
    unreadCount: unreadCount,
    chatId:     chatId,
    senderUid:  senderUid,
    senderName: senderName,
    senderImageUrl: senderImageUrl,
    itemTitle:  itemTitle,
    itemType:   itemType,
  );

  bool get isActionRequired => priority == 'action';

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// Agrupa notificações próximas do mesmo remetente (ex: mensagens em sequência)
  bool isSameContextAs(AppNotification other) =>
      type == other.type &&
      chatId != null &&
      chatId == other.chatId;
}
// lib/features/chat/data/models/chat_message_model.dart

enum ChatMessageType {
  text,
  deliveryRequest,   // remetente diz que entregou/buscou
  deliveryConfirmed, // receptor confirma recebimento
  deliveryDenied,    // receptor nega recebimento
}

extension ChatMessageTypeExt on ChatMessageType {
  String get value {
    switch (this) {
      case ChatMessageType.text:              return 'text';
      case ChatMessageType.deliveryRequest:   return 'delivery_request';
      case ChatMessageType.deliveryConfirmed: return 'delivery_confirmed';
      case ChatMessageType.deliveryDenied:    return 'delivery_denied';
    }
  }

  static ChatMessageType fromString(String? s) {
    switch (s) {
      case 'delivery_request':   return ChatMessageType.deliveryRequest;
      case 'delivery_confirmed': return ChatMessageType.deliveryConfirmed;
      case 'delivery_denied':    return ChatMessageType.deliveryDenied;
      default:                   return ChatMessageType.text;
    }
  }

  bool get isDeliveryEvent =>
      this == ChatMessageType.deliveryRequest ||
      this == ChatMessageType.deliveryConfirmed ||
      this == ChatMessageType.deliveryDenied;
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final int timestamp;
  final Map<String, bool> readBy;
  final ChatMessageType type;

  // Metadados para eventos de entrega
  final String? deliveryItemTitle;
  final String? deliveryItemType; // 'dream' | 'donation'
  // ID da mensagem de request que este confirm/deny responde
  final String? deliveryRequestId;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.readBy = const {},
    this.type = ChatMessageType.text,
    this.deliveryItemTitle,
    this.deliveryItemType,
    this.deliveryRequestId,
  });

  factory ChatMessage.fromMap(Map map, String id) {
    final rb     = map['read_by'];
    final readBy = <String, bool>{};
    if (rb is Map) {
      rb.forEach((k, v) => readBy[k.toString()] = v == true);
    }
    return ChatMessage(
      id:                 id,
      senderId:           map['sender_id']?.toString() ?? '',
      text:               map['text']?.toString() ?? '',
      timestamp:          (map['timestamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      readBy:             readBy,
      type:               ChatMessageTypeExt.fromString(map['type']?.toString()),
      deliveryItemTitle:  map['delivery_item_title']?.toString(),
      deliveryItemType:   map['delivery_item_type']?.toString(),
      deliveryRequestId:  map['delivery_request_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'sender_id': senderId,
      'text':      text,
      'timestamp': timestamp,
      'read_by':   {senderId: true},
      'type':      type.value,
    };
    if (deliveryItemTitle != null)  m['delivery_item_title']  = deliveryItemTitle;
    if (deliveryItemType != null)   m['delivery_item_type']   = deliveryItemType;
    if (deliveryRequestId != null)  m['delivery_request_id']  = deliveryRequestId;
    return m;
  }

  bool isReadBy(String uid) => readBy[uid] == true;

  bool get isReadByRecipient {
    for (final entry in readBy.entries) {
      if (entry.key != senderId && entry.value == true) return true;
    }
    return false;
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}
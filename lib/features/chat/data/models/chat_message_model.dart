// lib/features/chat/data/models/chat_message_model.dart

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final int timestamp;
  final Map<String, bool> readBy;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.readBy = const {},
  });

  factory ChatMessage.fromMap(Map map, String id) {
    final rb     = map['read_by'];
    final readBy = <String, bool>{};
    if (rb is Map) {
      rb.forEach((k, v) => readBy[k.toString()] = v == true);
    }
    return ChatMessage(
      id:        id,
      senderId:  map['sender_id']?.toString() ?? '',
      text:      map['text']?.toString() ?? '',
      timestamp: (map['timestamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      readBy:    readBy,
    );
  }

  Map<String, dynamic> toMap() => {
    'sender_id': senderId,
    'text':      text,
    'timestamp': timestamp,
    'read_by':   {senderId: true},
  };

  bool isReadBy(String uid) => readBy[uid] == true;

  /// true se pelo menos um participante diferente do remetente já leu
  bool get isReadByRecipient {
    for (final entry in readBy.entries) {
      if (entry.key != senderId && entry.value == true) return true;
    }
    return false;
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}
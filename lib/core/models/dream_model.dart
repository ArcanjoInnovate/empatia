class DreamModel {
  final String? id;
  final String? title;
  final String? emoji;
  final String? date;
  final double? progress;

  const DreamModel({this.id, this.title, this.emoji, this.date, this.progress});

  factory DreamModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return DreamModel(
      id: id,
      title: map['title']?.toString(),
      emoji: map['emoji']?.toString(),
      date: map['date']?.toString(),
      progress: map['progress'] != null
          ? double.tryParse(map['progress'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (title != null) 'title': title,
      if (emoji != null) 'emoji': emoji,
      if (date != null) 'date': date,
      if (progress != null) 'progress': progress,
    };
  }
}
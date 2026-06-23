/// 💭 DREAM MODEL
///
/// Representa um sonho/objetivo atrelado a um filho do usuário.
/// Fica em /Users/{uid}/dreams/{id} no Firebase.
class DreamModel {
  final String? id;
  final String? title;
  final String? emoji;

  /// Data meta — texto livre, ex: "Dez 2025"
  final String? date;

  /// Progresso de 0.0 a 1.0
  final double? progress;

  /// URL da imagem de inspiração no Cloudinary (opcional)
  final String? imageUrl;

  // ── Filho vinculado ──────────────────────────────────────────────────────
  final String? childId;
  final String? childName;
  final String? childEmoji;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DreamModel({
    this.id,
    this.title,
    this.emoji,
    this.date,
    this.progress,
    this.imageUrl,
    this.childId,
    this.childName,
    this.childEmoji,
    this.createdAt,
    this.updatedAt,
  });

  factory DreamModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return DreamModel(
      id: id,
      title: map['title']?.toString(),
      emoji: map['emoji']?.toString(),
      date: map['date']?.toString(),
      progress: map['progress'] != null
          ? double.tryParse(map['progress'].toString())
          : null,
      imageUrl: map['imageUrl']?.toString(),
      childId: map['childId']?.toString(),
      childName: map['childName']?.toString(),
      childEmoji: map['childEmoji']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.parse(map['createdAt'].toString()))
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.parse(map['updatedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (title != null) 'title': title,
      if (emoji != null) 'emoji': emoji,
      if (date != null) 'date': date,
      if (progress != null) 'progress': progress,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (childId != null) 'childId': childId,
      if (childName != null) 'childName': childName,
      if (childEmoji != null) 'childEmoji': childEmoji,
      'createdAt': createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  DreamModel copyWith({
    String? id,
    String? title,
    String? emoji,
    String? date,
    double? progress,
    String? imageUrl,
    String? childId,
    String? childName,
    String? childEmoji,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DreamModel(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      date: date ?? this.date,
      progress: progress ?? this.progress,
      imageUrl: imageUrl ?? this.imageUrl,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      childEmoji: childEmoji ?? this.childEmoji,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
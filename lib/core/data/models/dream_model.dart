/// 💭 DREAM MODEL
///
/// Representa um sonho vinculado ao perfil do usuário (Users/{uid}/dreams).
/// Diferente de [DreamFeedItem], este modelo é usado nas telas de criação,
/// edição e exibição privada (perfil do dono).
class DreamModel {
  final String? id;
  final String? title;
  final String? date;

  /// Categoria do sonho — mesmo padrão de Donations (inglês minúsculo):
  ///   'clothes' | 'toys' | 'books' | 'food' | 'furniture' | 'others'
  final String? category;

  /// Emoji derivado automaticamente da categoria pelo [DreamService].
  /// Mantido no banco para compatibilidade com cards e feed existentes.
  final String? emoji;

  final String? imageUrl;
  final double? progress;
  final String? status; // null | 'fulfilled'
  final DateTime? createdAt;

  // ── Filho vinculado ────────────────────────────────────────────────────────
  final String? childId;
  final String? childName;
  final String? childEmoji;

  const DreamModel({
    this.id,
    this.title,
    this.date,
    this.category,
    this.emoji,
    this.imageUrl,
    this.progress,
    this.status,
    this.createdAt,
    this.childId,
    this.childName,
    this.childEmoji,
  });

  factory DreamModel.fromMap(Map<dynamic, dynamic> map, String id) {
    DateTime? createdAt;
    final raw = map['createdAt'];
    if (raw != null) {
      if (raw is int || raw is double) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      } else {
        createdAt = DateTime.tryParse(raw.toString());
      }
    }

    return DreamModel(
      id: id,
      title: map['title'] as String?,
      date: map['date'] as String?,
      category: map['category'] as String?,
      emoji: map['emoji'] as String?,
      imageUrl: map['imageUrl'] as String?,
      progress: (map['progress'] as num?)?.toDouble(),
      status:   map['status'] as String?,
      createdAt: createdAt,
      childId: map['childId'] as String?,
      childName: map['childName'] as String?,
      childEmoji: map['childEmoji'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (category != null) 'category': category,
      if (emoji != null) 'emoji': emoji,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (progress != null) 'progress': progress,
      if (createdAt != null)
        'createdAt': createdAt!.millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      if (childId != null) 'childId': childId,
      if (childName != null) 'childName': childName,
      if (childEmoji != null) 'childEmoji': childEmoji,
    };
  }

  DreamModel copyWith({
    String? id,
    String? title,
    String? date,
    String? category,
    String? emoji,
    String? imageUrl,
    double? progress,
    String? status,
    DateTime? createdAt,
    String? childId,
    String? childName,
    String? childEmoji,
  }) {
    return DreamModel(
      id:         id         ?? this.id,
      title:      title      ?? this.title,
      date:       date       ?? this.date,
      category:   category   ?? this.category,
      emoji:      emoji      ?? this.emoji,
      imageUrl:   imageUrl   ?? this.imageUrl,
      progress:   progress   ?? this.progress,
      status:     status     ?? this.status,
      createdAt:  createdAt  ?? this.createdAt,
      childId:    childId    ?? this.childId,
      childName:  childName  ?? this.childName,
      childEmoji: childEmoji ?? this.childEmoji,
    );
  }
}
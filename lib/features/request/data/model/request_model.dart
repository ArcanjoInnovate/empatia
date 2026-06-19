/// 🙏 REQUEST MODEL
///
/// Representa um pedido de doação feito pelo usuário.
/// Fica na coleção raiz /Requests/{id} no Firebase,
/// facilitando queries globais por cidade/estado no feed.
///
/// Firebase structure:
/// /Requests/{pushId}
///   userId, childId?, title, emoji, category, status,
///   city, state, latitude, longitude, createdAt, updatedAt
class RequestModel {
  final String? id;
  final String? userId;

  /// ID do filho para quem é o pedido (opcional)
  final String? childId;

  /// Título curto — ex: "Preciso de livros para o Scott"
  final String? title;

  /// Descrição opcional com mais detalhes
  final String? description;

  /// Emoji representativo do item
  final String? emoji;

  /// Categoria para filtros no feed
  /// Valores: 'clothes' | 'toys' | 'books' | 'food' | 'furniture' | 'other'
  final String? category;

  /// Status atual do pedido
  /// Valores: 'open' | 'fulfilled' | 'cancelled'
  final String status;

  // Localização (copiada do usuário no momento da criação)
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RequestModel({
    this.id,
    this.userId,
    this.childId,
    this.title,
    this.description,
    this.emoji,
    this.category,
    this.status = 'open',
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  factory RequestModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return RequestModel(
      id: id,
      userId: map['userId']?.toString(),
      childId: map['childId']?.toString(),
      title: map['title']?.toString(),
      description: map['description']?.toString(),
      emoji: map['emoji']?.toString(),
      category: map['category']?.toString(),
      status: map['status']?.toString() ?? 'open',
      city: map['city']?.toString(),
      state: map['state']?.toString(),
      latitude: map['latitude'] != null
          ? double.tryParse(map['latitude'].toString())
          : null,
      longitude: map['longitude'] != null
          ? double.tryParse(map['longitude'].toString())
          : null,
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
      if (userId != null) 'userId': userId,
      if (childId != null) 'childId': childId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (emoji != null) 'emoji': emoji,
      if (category != null) 'category': category,
      'status': status,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'createdAt': createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  RequestModel copyWith({
    String? id,
    String? userId,
    String? childId,
    String? title,
    String? description,
    String? emoji,
    String? category,
    String? status,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      childId: childId ?? this.childId,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      status: status ?? this.status,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Labels de categoria (igual ao DonationModel) ──────────────────────────

  static String categoryLabel(String? category) {
    switch (category) {
      case 'clothes':   return 'Roupas';
      case 'toys':      return 'Brinquedos';
      case 'books':     return 'Livros';
      case 'food':      return 'Alimentos';
      case 'furniture': return 'Móveis / Utensílios';
      default:          return 'Outros';
    }
  }

  static String categoryEmoji(String? category) {
    switch (category) {
      case 'clothes':   return '👕';
      case 'toys':      return '🧸';
      case 'books':     return '📚';
      case 'food':      return '🥫';
      case 'furniture': return '🪑';
      default:          return '📦';
    }
  }

  // ── Label de status ───────────────────────────────────────────────────────

  static String statusLabel(String status) {
    switch (status) {
      case 'fulfilled':  return 'Atendido';
      case 'cancelled':  return 'Cancelado';
      default:           return 'Aberto';
    }
  }
}
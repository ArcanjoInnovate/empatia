/// ðŸŽ DONATION MODEL
///
/// Representa um item que o usuÃ¡rio estÃ¡ OFERECENDO para doaÃ§Ã£o.
/// Fica na coleÃ§Ã£o raiz /Donations/{id} no Firebase.
///
/// Firebase structure:
/// /Donations/{pushId}
///   userId, title, description, photoUrl, emoji, category, status,
///   city, state, latitude, longitude, ownerName, ownerPhotoUrl,
///   createdAt, updatedAt
class DonationModel {
  final String? id;
  final String? userId;

  /// TÃ­tulo curto â€” ex: "Roupas 4â€“6 anos"
  final String? title;

  /// DescriÃ§Ã£o detalhada do item (obrigatÃ³ria)
  final String? description;

  /// URL da foto do item no Firebase Storage (obrigatÃ³ria)
  final String? photoUrl;

  /// Emoji representativo do item
  final String? emoji;

  /// Categoria do item
  /// Valores: 'clothes' | 'toys' | 'books' | 'food' | 'furniture' | 'other'
  final String? category;

  /// Status atual da oferta
  /// Valores: 'available' | 'reserved' | 'donated'
  final String status;

  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;

  /// Nome do doador no momento da criaÃ§Ã£o â€” snapshot, nÃ£o atualiza
  /// retroativamente se o usuÃ¡rio mudar o nome depois.
  final String? ownerName;

  /// Foto de perfil do doador no momento da criaÃ§Ã£o â€” mesmo raciocÃ­nio
  /// do [ownerName].
  final String? ownerPhotoUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DonationModel({
    this.id,
    this.userId,
    this.title,
    this.description,
    this.photoUrl,
    this.emoji,
    this.category,
    this.status = 'available',
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.ownerName,
    this.ownerPhotoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory DonationModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return DonationModel(
      id: id,
      userId: map['userId']?.toString(),
      title: map['title']?.toString(),
      description: map['description']?.toString(),
      photoUrl: map['photoUrl']?.toString(),
      emoji: map['emoji']?.toString(),
      category: map['category']?.toString(),
      status: map['status']?.toString() ?? 'available',
      city: map['city']?.toString(),
      state: map['state']?.toString(),
      latitude: map['latitude'] != null
          ? double.tryParse(map['latitude'].toString())
          : null,
      longitude: map['longitude'] != null
          ? double.tryParse(map['longitude'].toString())
          : null,
      ownerName: map['ownerName']?.toString(),
      ownerPhotoUrl: map['ownerPhotoUrl']?.toString(),
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
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (emoji != null) 'emoji': emoji,
      if (category != null) 'category': category,
      'status': status,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (ownerName != null) 'ownerName': ownerName,
      if (ownerPhotoUrl != null) 'ownerPhotoUrl': ownerPhotoUrl,
      'createdAt': createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  DonationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? photoUrl,
    String? emoji,
    String? category,
    String? status,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    String? ownerName,
    String? ownerPhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DonationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      status: status ?? this.status,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ownerName: ownerName ?? this.ownerName,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String categoryLabel(String? category) {
    switch (category) {
      case 'clothes':   return 'Roupas';
      case 'toys':      return 'Brinquedos';
      case 'books':     return 'Livros';
      case 'food':      return 'Alimentos';
      case 'furniture': return 'MÃ³veis / UtensÃ­lios';
      default:          return 'Outros';
    }
  }

  static String categoryEmoji(String? category) {
    switch (category) {
      case 'clothes':   return 'ðŸ‘•';
      case 'toys':      return 'ðŸ§¸';
      case 'books':     return 'ðŸ“š';
      case 'food':      return 'ðŸ¥«';
      case 'furniture': return 'ðŸª‘';
      default:          return 'ðŸ“¦';
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'reserved': return 'Reservado';
      case 'donated':  return 'Doado';
      default:         return 'DisponÃ­vel';
    }
  }
}
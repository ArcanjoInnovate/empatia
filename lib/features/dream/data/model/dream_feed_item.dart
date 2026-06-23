/// Representa um sonho no feed da home, vindo do nó global `Dreams`.
///
/// Diferente do sonho aninhado em `Users/{uid}/dreams`, este já vem com
/// os dados do autor (nome, foto, emoji) copiados pra dentro do próprio
/// registro — assim a home não precisa de uma leitura extra por usuário
/// pra montar cada card do feed.
class DreamFeedItem {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final String? userProfileEmoji;
  final String title;
  final String? date;
  final String emoji;
  final String? imageUrl;
  final double progress;
  final int createdAt;
  final int updatedAt;
  final int likesCount;
  final int commentsCount;

  /// Localização do autor no momento da criação (copiada do perfil).
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;

  /// Se o usuário atual já curtiu esse sonho. Calculado localmente a
  /// partir do mapa `likes` que já vem dentro do próprio nó do sonho —
  /// não exige nenhuma leitura adicional no Firebase.
  final bool likedByMe;

  const DreamFeedItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    this.userProfileEmoji,
    required this.title,
    this.date,
    required this.emoji,
    this.imageUrl,
    this.progress = 0.0,
    this.createdAt = 0,
    this.updatedAt = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.likedByMe = false,
  });

  /// [currentUserId] é opcional: se informado, [likedByMe] é calculado
  /// olhando o mapa `likes` que já está dentro do próprio map do sonho.
  factory DreamFeedItem.fromMap(
    String id,
    Map<dynamic, dynamic> map, {
    String? currentUserId,
  }) {
    bool liked = false;
    final likes = map['likes'];
    if (currentUserId != null && likes is Map) {
      liked = likes[currentUserId] == true;
    }

    return DreamFeedItem(
      id: id,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Amigo(a)',
      userProfileImage: map['userProfileImage'] as String?,
      userProfileEmoji: map['userProfileEmoji'] as String?,
      title: map['title'] as String? ?? 'Sem título',
      date: map['date'] as String?,
      emoji: map['emoji'] as String? ?? '💭',
      imageUrl: map['imageUrl'] as String?,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (map['updatedAt'] as num?)?.toInt() ?? 0,
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (map['commentsCount'] as num?)?.toInt() ?? 0,
      city: map['city'] as String?,
      state: map['state'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      likedByMe: liked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'userProfileEmoji': userProfileEmoji,
      'title': title,
      'date': date,
      'emoji': emoji,
      'imageUrl': imageUrl,
      'progress': progress,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  /// Usado pro update otimista de curtida na UI (sem esperar o Firebase
  /// confirmar antes de refletir o toque do usuário na tela).
  DreamFeedItem copyWith({
    bool? likedByMe,
    int? likesCount,
  }) {
    return DreamFeedItem(
      id: id,
      userId: userId,
      userName: userName,
      userProfileImage: userProfileImage,
      userProfileEmoji: userProfileEmoji,
      title: title,
      date: date,
      emoji: emoji,
      imageUrl: imageUrl,
      progress: progress,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      city: city,
      state: state,
      latitude: latitude,
      longitude: longitude,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}
import 'package:empatia/features/search/data/repositories/search_repository.dart';

/// Item unificado do feed — pode ser um sonho ou uma doação.
///
/// Carrega apenas os campos necessários para renderizar o card no feed.
/// Filtros disponíveis: estado, cidade, tipo (dream | donation).
enum FeedItemType { dream, donation }

class FeedItem {
  final String id;
  final FeedItemType type;
  final int createdAt;

  // ── Campos comuns ──────────────────────────────────────────────────
  final String title;
  final String emoji;
  final String? imageUrl;
  final String? city;
  final String? state;

  // ── Campos de sonho ───────────────────────────────────────────────
  final String? userId;
  final String? userName;
  final String? userProfileEmoji;
  final String? userProfileImage;
  final double? progress;
  final String? date;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;
  final String? childName;
  final String? childEmoji;

  // ── Campos de doação ──────────────────────────────────────────────
  final String? description;
  final String? category;
  final String? status;

  const FeedItem({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.title,
    required this.emoji,
    this.imageUrl,
    this.city,
    this.state,
    this.userId,
    this.userName,
    this.userProfileEmoji,
    this.userProfileImage,
    this.progress,
    this.date,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedByMe = false,
    this.childName,
    this.childEmoji,
    this.description,
    this.category,
    this.status,
  });

  static FeedItem fromDream(
    String id,
    Map<dynamic, dynamic> map, {
    String? currentUserId,
  }) {
    bool liked = false;
    final likes = map['likes'];
    if (currentUserId != null && likes is Map) {
      liked = likes[currentUserId] == true;
    }
    return FeedItem(
      id: id,
      type: FeedItemType.dream,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      title: map['title']?.toString() ?? 'Sem título',
      emoji: map['emoji']?.toString() ?? '💭',
      imageUrl: map['imageUrl']?.toString(),
      city: map['city']?.toString(),
      state: map['state']?.toString(),
      userId: map['userId']?.toString(),
      userName: map['userName']?.toString() ?? 'Alguém',
      userProfileEmoji: map['userProfileEmoji']?.toString(),
      userProfileImage: map['userProfileImage']?.toString(),
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      date: map['date']?.toString(),
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (map['commentsCount'] as num?)?.toInt() ?? 0,
      likedByMe: liked,
      childName: map['childName']?.toString(),
      childEmoji: map['childEmoji']?.toString(),
    );
  }

  static FeedItem fromDonation(String id, Map<dynamic, dynamic> map) {
    return FeedItem(
      id: id,
      type: FeedItemType.donation,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      title: map['title']?.toString() ?? 'Sem título',
      emoji: map['emoji']?.toString() ?? '📦',
      imageUrl: map['photoUrl']?.toString(),
      city: map['city']?.toString(),
      state: map['state']?.toString(),
      userId: map['userId']?.toString(),
      description: map['description']?.toString(),
      category: map['category']?.toString(),
      status: map['status']?.toString() ?? 'available',
    );
  }

  /// Converte este [FeedItem] em um [SearchResult] compatível com as páginas
  /// de detalhe [DreamDetailPage] e [DonationDetailPage].
  ///
  /// Reutiliza os dados já carregados no feed — sem nova chamada de rede.
  SearchResult toSearchResult() {
    return SearchResult(
      id: id,
      type: type == FeedItemType.dream ? 'dream' : 'donation',
      title: title,
      description: description,
      photoUrl: imageUrl,
      city: city,
      state: state,
      status: status,
      createdAt: createdAt > 0
          ? DateTime.fromMillisecondsSinceEpoch(createdAt)
          : null,
      childName: childName,
      childEmoji: childEmoji,
      dreamEmoji: type == FeedItemType.dream ? emoji : null,
      dreamDate: date,
      dreamProgress: progress,
      category: category,
    );
  }
}
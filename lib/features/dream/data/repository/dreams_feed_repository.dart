import 'package:empatia/features/dream/data/model/dream_feed_item.dart';
import 'package:firebase_database/firebase_database.dart';

class DreamFeedPage {
  final List<DreamFeedItem> items;
  final bool hasMore;

  const DreamFeedPage({required this.items, required this.hasMore});

  static const empty = DreamFeedPage(items: [], hasMore: false);
}

/// Acesso ao nó global `Dreams` no Firebase Realtime Database.
class DreamsFeedRepository {
  DreamsFeedRepository({DatabaseReference? dreamsRef})
      : _dreamsRef = dreamsRef ?? FirebaseDatabase.instance.ref('Dreams');

  final DatabaseReference _dreamsRef;

  Future<DreamFeedPage> fetchFeedPage({
    required String? currentUserId,
    int limit = 5,
    int? beforeTimestamp,
  }) async {
    Query query = _dreamsRef.orderByChild('createdAt');
    if (beforeTimestamp != null) {
      query = query.endBefore(beforeTimestamp);
    }
    query = query.limitToLast(limit);

    final snapshot = await query.get();
    if (!snapshot.exists || snapshot.value == null) {
      return DreamFeedPage.empty;
    }

    final items = <DreamFeedItem>[];
    for (final child in snapshot.children) {
      final value = child.value;
      if (value is Map) {
        items.add(DreamFeedItem.fromMap(
          child.key!,
          value,
          currentUserId: currentUserId,
        ));
      }
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final hasMore = items.length == limit;
    return DreamFeedPage(items: items, hasMore: hasMore);
  }

  Stream<List<DreamFeedItem>> watchUserDreams(String userId) {
    final query = _dreamsRef.orderByChild('userId').equalTo(userId);
    return query.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return <DreamFeedItem>[];
      final dreams = <DreamFeedItem>[];
      for (final child in snapshot.children) {
        final value = child.value;
        if (value is Map) {
          dreams.add(DreamFeedItem.fromMap(child.key!, value));
        }
      }
      dreams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return dreams;
    });
  }

  /// Cria um sonho no feed global com o mesmo [dreamId] gerado em
  /// Users/{uid}/dreams para manter os dois nós sincronizados.
  Future<void> createDreamWithId({
    required String dreamId,
    required String userId,
    required String userName,
    String? userProfileImage,
    String? userProfileEmoji,
    required String title,
    String? date,
    required String emoji,   // derivado da categoria pelo service
    required String category,
    String? imageUrl,
    double progress = 0.0,
    required String childId,
    required String childName,
    required String childEmoji,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _dreamsRef.child(dreamId).set({
      'userId':           userId,
      'userName':         userName,
      'userProfileImage': userProfileImage,
      'userProfileEmoji': userProfileEmoji,
      'title':            title,
      'date':             date,
      'emoji':            emoji,
      'category':         category,
      'imageUrl':         imageUrl,
      'progress':         progress,
      'childId':          childId,
      'childName':        childName,
      'childEmoji':       childEmoji,
      'createdAt':        now,
      'updatedAt':        now,
      'likesCount':       0,
      'commentsCount':    0,
      if (city != null)      'city':      city,
      if (state != null)     'state':     state,
      if (latitude != null)  'latitude':  latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  Future<void> deleteDream(String dreamId) =>
      _dreamsRef.child(dreamId).remove();

  /// Atualiza os campos editáveis de um sonho no feed global.
  Future<void> updateDream({
    required String dreamId,
    required String title,
    required String emoji,    // derivado da categoria pelo service
    required String category,
    String? date,
    String? imageUrl,
    double? progress,
    required String childId,
    required String childName,
    required String childEmoji,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
  }) {
    return _dreamsRef.child(dreamId).update({
      'title':    title,
      'emoji':    emoji,
      'category': category,
      'date':     date,
      'imageUrl': imageUrl,
      'progress': progress ?? 0.0,
      'childId':  childId,
      'childName': childName,
      'childEmoji': childEmoji,
      if (city != null)      'city':      city,
      if (state != null)     'state':     state,
      if (latitude != null)  'latitude':  latitude,
      if (longitude != null) 'longitude': longitude,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateProgress(String dreamId, double progress) {
    return _dreamsRef.child(dreamId).update({
      'progress':  progress,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> toggleLike(String dreamId, String userId) async {
    final likeRef  = _dreamsRef.child(dreamId).child('likes').child(userId);
    final dreamRef = _dreamsRef.child(dreamId);
    final likeSnapshot = await likeRef.get();
    if (likeSnapshot.exists) {
      await likeRef.remove();
      await dreamRef.update({'likesCount': ServerValue.increment(-1)});
    } else {
      await likeRef.set(true);
      await dreamRef.update({'likesCount': ServerValue.increment(1)});
    }
  }
}
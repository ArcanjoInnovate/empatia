import 'package:empatia/features/dream/data/model/dream_feed_item.dart';
import 'package:firebase_database/firebase_database.dart';

/// Resultado de uma página do feed: os itens e se ainda existe mais
/// conteúdo pra carregar depois (usado pra parar o scroll infinito).
class DreamFeedPage {
  final List<DreamFeedItem> items;
  final bool hasMore;

  const DreamFeedPage({required this.items, required this.hasMore});

  static const empty = DreamFeedPage(items: [], hasMore: false);
}

/// Acesso ao nó global `Dreams` no Firebase Realtime Database.
///
/// Esse nó é separado de `Users/{uid}/dreams` justamente pra permitir
/// montar um feed com sonhos de todos os usuários sem precisar baixar
/// o nó `Users` inteiro.
///
/// IMPORTANTE: o feed da home usa [fetchFeedPage] (busca pontual, sob
/// demanda) em vez de um listener contínuo. Isso é proposital — um
/// listener em tempo real escutando TODOS os sonhos cresce de leitura
/// pra sempre conforme a base de usuários cresce. Com paginação manual,
/// você só paga pelo que o usuário realmente rolou na tela.
class DreamsFeedRepository {
  DreamsFeedRepository({DatabaseReference? dreamsRef})
      : _dreamsRef = dreamsRef ?? FirebaseDatabase.instance.ref('Dreams');

  final DatabaseReference _dreamsRef;

  /// Busca uma página do feed, do mais recente pro mais antigo.
  ///
  /// Pra primeira página, não passe [beforeTimestamp]. Pra próxima
  /// página, passe o `createdAt` do último item já carregado — o
  /// Firebase devolve só os sonhos mais antigos que esse timestamp.
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

    // O Firebase devolve em ordem crescente de createdAt;
    // invertemos pra mostrar o sonho mais recente primeiro.
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Heurística simples: se voltou menos que o limite pedido, não tem
    // mais nada depois. Se voltou exatamente o limite, ASSUMIMOS que
    // pode ter mais — na pior das hipóteses a próxima página volta vazia
    // e paramos ali, custando 1 leitura vazia (insignificante).
    final hasMore = items.length == limit;

    return DreamFeedPage(items: items, hasMore: hasMore);
  }

  /// Sonhos de um único usuário (pra usar na tela de perfil, por exemplo).
  Stream<List<DreamFeedItem>> watchUserDreams(String userId) {
    final query = _dreamsRef.orderByChild('userId').equalTo(userId);

    return query.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return <DreamFeedItem>[];
      }

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

  /// Cria um novo sonho já no formato denormalizado do feed,
  /// usando o mesmo [dreamId] gerado em Users/{uid}/dreams para manter
  /// os dois nós sincronizados pela mesma chave.
  Future<void> createDreamWithId({
    required String dreamId,
    required String userId,
    required String userName,
    String? userProfileImage,
    String? userProfileEmoji,
    required String title,
    String? date,
    required String emoji,
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
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'userProfileEmoji': userProfileEmoji,
      'title': title,
      'date': date,
      'emoji': emoji,
      'imageUrl': imageUrl,
      'progress': progress,
      'childId': childId,
      'childName': childName,
      'childEmoji': childEmoji,
      'createdAt': now,
      'updatedAt': now,
      'likesCount': 0,
      'commentsCount': 0,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  /// Remove um sonho do feed global.
  Future<void> deleteDream(String dreamId) {
    return _dreamsRef.child(dreamId).remove();
  }

  /// Cria um novo sonho já no formato denormalizado do feed.
  /// Use isso no lugar de escrever em `Users/{uid}/dreams`.
  Future<void> createDream({
    required String userId,
    required String userName,
    String? userProfileImage,
    String? userProfileEmoji,
    required String title,
    String? date,
    required String emoji,
    String? imageUrl,
    double progress = 0.0,
  }) async {
    final newRef = _dreamsRef.push();
    final now = DateTime.now().millisecondsSinceEpoch;

    await newRef.set({
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'userProfileEmoji': userProfileEmoji,
      'title': title,
      'date': date,
      'emoji': emoji,
      'imageUrl': imageUrl,
      'progress': progress,
      'createdAt': now,
      'updatedAt': now,
      'likesCount': 0,
      'commentsCount': 0,
    });
  }

  /// Atualiza os dados editáveis de um sonho no feed global.
  Future<void> updateDream({
    required String dreamId,
    required String title,
    required String emoji,
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
      'title': title,
      'emoji': emoji,
      'date': date,
      'imageUrl': imageUrl,
      'progress': progress ?? 0.0,
      'childId': childId,
      'childName': childName,
      'childEmoji': childEmoji,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Atualiza o progresso de um sonho existente.
  Future<void> updateProgress(String dreamId, double progress) {
    return _dreamsRef.child(dreamId).update({
      'progress': progress,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Curte ou descurte um sonho. Guarda quem curtiu em
  /// `Dreams/{dreamId}/likes/{userId}` (pra saber se ESSE usuário já
  /// curtiu, sem precisar de leitura extra — isso já vem junto quando o
  /// sonho é carregado) e mantém `likesCount` consistente via
  /// `ServerValue.increment`, que é atômico no servidor (não tem corrida
  /// entre dois usuários curtindo ao mesmo tempo).
  Future<void> toggleLike(String dreamId, String userId) async {
    final likeRef = _dreamsRef.child(dreamId).child('likes').child(userId);
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
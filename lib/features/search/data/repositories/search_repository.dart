import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:firebase_database/firebase_database.dart';

/// Resultado unificado de busca (donation ou dream).
class SearchResult {
  final String id;
  final String type;
  final String? title;
  final String? description;
  final String? photoUrl;
  final String? city;
  final String? state;
  final String? status;
  final DateTime? createdAt;
  final double? latitude;
  final double? longitude;

  // ── Campos exclusivos de Dream ──────────────────────────────────────────
  final String? childName;
  final String? childEmoji;
  final String? dreamEmoji;
  final String? dreamDate;
  final double? dreamProgress;

  // ── Campos compartilhados (Donation e Dream) ────────────────────────────
  /// Categoria do item / sonho (ex: "Roupas", "Brinquedos", "Livros").
  /// Presente tanto em Donations quanto em Dreams — permite filtrar
  /// os dois tipos com um único campo.
  final String? category;

  // ── Campos exclusivos de Donation ──────────────────────────────────────
  final String? ownerName;
  final String? ownerPhotoUrl;
  /// UID do dono do item (sonho ou doação). Usado para abrir o chat.
  final String? ownerId;

  const SearchResult({
    required this.id,
    required this.type,
    this.title,
    this.description,
    this.photoUrl,
    this.city,
    this.state,
    this.status,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.childName,
    this.childEmoji,
    this.dreamEmoji,
    this.dreamDate,
    this.dreamProgress,
    this.category,
    this.ownerName,
    this.ownerPhotoUrl,
    this.ownerId,
  });

  factory SearchResult.fromDonation(DonationModel d) => SearchResult(
        id: d.id ?? '',
        type: 'donation',
        title: d.title,
        description: d.description,
        photoUrl: d.photoUrl,
        city: d.city,
        state: d.state,
        status: d.status,
        createdAt: d.createdAt,
        ownerId: d.userId,
      );

  factory SearchResult.fromMap(Map map, String id, String type) {
    final photo = (map['photoUrl'] as String?)?.isNotEmpty == true
        ? map['photoUrl'] as String
        : (map['imageUrl'] as String?)?.isNotEmpty == true
            ? map['imageUrl'] as String
            : null;

    DateTime? createdAt;
    final raw = map['createdAt'];
    if (raw != null) {
      if (raw is int || raw is double) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      } else {
        createdAt = DateTime.tryParse(raw.toString());
      }
    }

    double? dreamProgress;
    final prog = map['progress'];
    if (prog != null) {
      dreamProgress = double.tryParse(prog.toString());
    }

    return SearchResult(
      id: id,
      type: type,
      title: map['title'] as String?,
      description: map['description'] as String?,
      photoUrl: photo,
      city: map['city'] as String?,
      state: map['state'] as String?,
      status: map['status'] as String?,
      createdAt: createdAt,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      childName: map['childName'] as String?,
      childEmoji: map['childEmoji'] as String?,
      dreamEmoji: map['emoji'] as String?,
      dreamDate: map['date'] as String?,
      dreamProgress: dreamProgress,
      // category é lido para ambos os tipos — se o nó Dreams tiver o campo
      // 'category' no Firebase, ele será filtrado normalmente.
      category: map['category'] as String?,
      ownerName: map['ownerName'] as String?,
      ownerPhotoUrl: map['ownerPhotoUrl'] as String?,
      ownerId: map['userId'] as String?,
    );
  }
}

/// 🔍 SEARCH REPOSITORY
///
/// Busca unificada em /Donations e /Dreams.
/// Filtros aplicados client-side após o fetch do Firebase:
///   - texto livre (título, descrição, nome da criança)
///   - estado (dupla verificação — Firebase + local)
///   - categoria (comparação case-insensitive no campo `category`)
///
/// O filtro de categoria NÃO adiciona consultas separadas ao Firebase.
/// Ele percorre os resultados já carregados e descarta os que não
/// correspondem, mantendo uma única requisição por nó.
class SearchRepository {
  SearchRepository({
    DatabaseReference? donationsRef,
    DatabaseReference? dreamsRef,
  })  : _donationsRef =
            donationsRef ?? FirebaseDatabase.instance.ref('Donations'),
        _dreamsRef = dreamsRef ?? FirebaseDatabase.instance.ref('Dreams');

  final DatabaseReference _donationsRef;
  final DatabaseReference _dreamsRef;

  Future<List<SearchResult>> search({
    String? query,
    String? city,
    String? state,
    String? type,
    String? category, // ← NOVO: filtro de categoria
    int limit = 60,
    double? userLat,
    double? userLng,
  }) async {
    final futures = <Future<List<SearchResult>>>[];

    if (type == null || type == 'donation') {
      futures.add(_searchNode(
        ref: _donationsRef,
        type: 'donation',
        query: query,
        city: city,
        state: state,
        category: category,
        limit: limit,
      ));
    }

    if (type == null || type == 'dream') {
      futures.add(_searchNode(
        ref: _dreamsRef,
        type: 'dream',
        query: query,
        city: city,
        state: state,
        category: category,
        limit: limit,
      ));
    }

    final lists = await Future.wait(futures);
    final results = lists.expand((l) => l).toList();

    results.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

    return results;
  }

  Future<List<SearchResult>> _searchNode({
    required DatabaseReference ref,
    required String type,
    String? query,
    String? city,
    String? state,
    String? category, // ← NOVO
    required int limit,
  }) async {
    // ── Consulta Firebase (não muda com categoria) ─────────────────────────
    Query dbQuery;
    if (city != null && city.isNotEmpty) {
      dbQuery = ref.orderByChild('city').equalTo(city);
    } else if (state != null && state.isNotEmpty) {
      dbQuery = ref.orderByChild('state').equalTo(state);
    } else {
      dbQuery = ref.orderByChild('createdAt').limitToLast(limit);
    }

    final snapshot = await dbQuery.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final results = <SearchResult>[];

    for (final child in snapshot.children) {
      final value = child.value;
      if (value is! Map) continue;

      final item = SearchResult.fromMap(
        Map<String, dynamic>.from(value),
        child.key!,
        type,
      );

      // ── Filtro de status — exclui itens já concluídos ─────────────────
      // Donations: status 'donated' ou 'reserved' ficam fora
      // Dreams: status 'fulfilled' fica fora
      final itemStatus = (item.status ?? '').toLowerCase();
      if (type == 'donation' && itemStatus != 'available') continue;
      if (type == 'dream'    && itemStatus == 'fulfilled') continue;

      // ── Filtro de estado (dupla verificação) ───────────────────────────
      if (state != null &&
          state.isNotEmpty &&
          (item.state ?? '').toLowerCase() != state.toLowerCase()) continue;

      // ── Filtro de texto livre ──────────────────────────────────────────
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final inTitle = item.title?.toLowerCase().contains(q) ?? false;
        final inDesc  = item.description?.toLowerCase().contains(q) ?? false;
        final inChild = item.childName?.toLowerCase().contains(q) ?? false;
        if (!inTitle && !inDesc && !inChild) continue;
      }

      // ── Filtro de categoria ────────────────────────────────────────────────
      //
      // Donations têm campo `category` gravado em inglês minúsculo:
      //   "clothes" | "toys" | "books" | "food" | "furniture" | "others"
      //
      // Dreams novos (após a atualização do DreamService) também têm
      // `category` gravado com o mesmo padrão — match direto funciona.
      //
      // Dreams antigos (antes da atualização) não têm `category` — só
      // têm `emoji`. Para esses, usamos fallback por emoji como abaixo.
      //
      // Fluxo:
      //   item.category preenchido → match direto (case-insensitive)
      //   item.category ausente    → fallback por emoji
      //   emoji também não bate   → excluído do resultado
      if (category != null && category.isNotEmpty) {
        final itemCat   = (item.category ?? '').toLowerCase().trim();
        final filterCat = category.toLowerCase().trim();

        if (itemCat.isNotEmpty) {
          // Donations: comparação direta no campo category
          if (itemCat != filterCat) continue;
        } else {
          // Dreams: fallback por emoji
          final emoji = item.dreamEmoji ?? '';
          if (!_categoryMatchesEmoji(filterCat, emoji)) continue;
        }
      }

      results.add(item);
    }

    return results;
  }

  /// Verifica se o [emoji] de um Dream corresponde à [category] filtrada.
  ///
  /// Usado como fallback quando o nó não tem campo `category` (Dreams).
  /// O conjunto de emojis reflete AppTheme.dreamEmojiOptions — adicione
  /// aqui se novas opções forem incluídas no formulário de sonhos.
  static bool _categoryMatchesEmoji(String category, String emoji) {
    const map = <String, List<String>>{
      'books':     ['📚', '📖', '📕', '📗', '📘', '📙'],
      'clothes':   ['👕', '👗', '🧥', '👟', '👠', '🎽', '🧣', '🧤', '🩳', '👒', '👚', '👔'],
      'toys':      ['🧸', '🚗', '🎮', '🎯', '🎲', '🪀', '🪁', '🎠', '🚀', '✈️', '⚽', '🏀', '⚾', '🎸', '🎨', '🪆'],
      'food':      ['🍎', '🍕', '🍔', '🥗', '🍱', '🥤', '🍰', '🍜', '🍦', '🍩', '🍫', '🧃', '🥛'],
      'furniture': ['🛋️', '🛏️', '🪑', '🚿', '🪞', '🖥️', '📺', '🖼️'],
      // 'others' sem emojis definidos — Dreams sem match ficam fora do filtro
    };
    return map[category]?.contains(emoji) ?? false;
  }
}
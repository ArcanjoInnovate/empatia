import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:firebase_database/firebase_database.dart';

/// Resultado unificado de busca (donation ou dream).
class SearchResult {
  final String id;
  final String type; // 'donation' | 'dream'
  final String? title;
  final String? description;
  final String? photoUrl;
  final String? city;
  final String? state;
  final String? status;
  final DateTime? createdAt;

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
      );

  factory SearchResult.fromMap(Map map, String id, String type) => SearchResult(
        id: id,
        type: type,
        title: map['title'] as String?,
        description: map['description'] as String?,
        photoUrl: map['photoUrl'] as String?,
        city: map['city'] as String?,
        state: map['state'] as String?,
        status: map['status'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'].toString())
            : null,
      );
}

/// 🔍 SEARCH REPOSITORY
///
/// Busca unificada em /Donations e /Dreams.
/// Filtros: texto livre, cidade, estado, tipo (donation | dream).
///
/// Índices recomendados no firebase.json:
///   "Donations": { ".indexOn": ["city", "state"] }
///   "Dreams":    { ".indexOn": ["city", "state"] }
class SearchRepository {
  SearchRepository({
    DatabaseReference? donationsRef,
    DatabaseReference? dreamsRef,
  })  : _donationsRef =
            donationsRef ?? FirebaseDatabase.instance.ref('Donations'),
        _dreamsRef = dreamsRef ?? FirebaseDatabase.instance.ref('Dreams');

  final DatabaseReference _donationsRef;
  final DatabaseReference _dreamsRef;

  /// Busca unificada.
  ///
  /// [query]  → texto livre em title + description
  /// [city]   → filtra por cidade exata
  /// [state]  → filtra por estado
  /// [type]   → 'donation' | 'dream' | null (ambos)
  Future<List<SearchResult>> search({
    String? query,
    String? city,
    String? state,
    String? type,
    int limit = 60,
  }) async {
    final futures = <Future<List<SearchResult>>>[];

    if (type == null || type == 'donation') {
      futures.add(_searchNode(
        ref: _donationsRef,
        type: 'donation',
        query: query,
        city: city,
        state: state,
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
    required int limit,
  }) async {
    // Prioridade de filtro no servidor: city > state > recentes
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

      // Filtro de estado no cliente (quando servidor filtrou por city)
      if (state != null &&
          state.isNotEmpty &&
          (item.state ?? '').toLowerCase() != state.toLowerCase()) continue;

      // Filtro de texto no cliente
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final inTitle = item.title?.toLowerCase().contains(q) ?? false;
        final inDesc = item.description?.toLowerCase().contains(q) ?? false;
        if (!inTitle && !inDesc) continue;
      }

      results.add(item);
    }

    return results;
  }
}
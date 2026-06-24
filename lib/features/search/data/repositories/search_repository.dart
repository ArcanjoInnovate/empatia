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

  // ── Campos exclusivos de Donation ──────────────────────────────────────
  /// Categoria do item (ex: "Roupas", "Brinquedos")
  final String? category;

  /// Nome do doador
  final String? ownerName;

  /// Foto do doador (avatar)
  final String? ownerPhotoUrl;

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
    // dream-only
    this.childName,
    this.childEmoji,
    this.dreamEmoji,
    this.dreamDate,
    this.dreamProgress,
    // donation-only
    this.category,
    this.ownerName,
    this.ownerPhotoUrl,
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
      // dream-only
      childName: map['childName'] as String?,
      childEmoji: map['childEmoji'] as String?,
      dreamEmoji: map['emoji'] as String?,
      dreamDate: map['date'] as String?,
      dreamProgress: dreamProgress,
      // donation-only
      category: map['category'] as String?,
      ownerName: map['ownerName'] as String?,
      ownerPhotoUrl: map['ownerPhotoUrl'] as String?,
    );
  }
}

/// 🔍 SEARCH REPOSITORY
///
/// Busca unificada em /Donations e /Dreams.
/// Filtros: texto livre, cidade, estado, tipo.
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

      if (state != null &&
          state.isNotEmpty &&
          (item.state ?? '').toLowerCase() != state.toLowerCase()) continue;

      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final inTitle = item.title?.toLowerCase().contains(q) ?? false;
        final inDesc = item.description?.toLowerCase().contains(q) ?? false;
        final inChild = item.childName?.toLowerCase().contains(q) ?? false;
        if (!inTitle && !inDesc && !inChild) continue;
      }

      results.add(item);
    }

    return results;
  }
}
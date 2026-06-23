import 'dart:math';
import 'package:empatia/features/home/data/models/feed_filter.dart';
import 'package:empatia/features/home/data/models/feed_item_.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Resultado de uma página do feed mesclado.
class FeedPage {
  final List<FeedItem> items;
  final bool hasMore;

  const FeedPage({required this.items, required this.hasMore});
  static const empty = FeedPage(items: [], hasMore: false);
}

/// Busca sonhos (Dreams/) e doações disponíveis (Donations/) do Firebase,
/// mescla de forma pseudo-aleatória e retorna em páginas de [pageSize] itens.
///
/// Estratégia de paginação:
///   — Busca um lote de [pageSize * 3] candidatos de cada fonte para ter
///     margem suficiente após filtros e para montar a mistura.
///   — Usa [beforeTimestamp] como cursor: só retorna itens mais antigos
///     que o timestamp do último item já carregado.
///   — A mistura embaralha os dois lotes e corta em [pageSize].
class FeedRepository {
  FeedRepository({DatabaseReference? db})
      : _db = db ?? FirebaseDatabase.instance.ref();

  final DatabaseReference _db;

  static const int pageSize = 5;
  // Quantos candidatos buscar por fonte para ter margem de mistura
  static const int _fetchSize = 20;

  final _rng = Random();

  Future<FeedPage> fetchPage({
    required String? currentUserId,
    FeedFilter filter = const FeedFilter(),
    int? beforeTimestamp,
  }) async {
    // Busca Dreams e Donations em paralelo
    final results = await Future.wait([
      _fetchDreams(currentUserId: currentUserId, before: beforeTimestamp),
      if (filter.type == null || filter.type == FeedItemType.donation)
        _fetchDonations(before: beforeTimestamp)
      else
        Future.value(<FeedItem>[]),
    ]);

    var dreams = filter.type == FeedItemType.donation
        ? <FeedItem>[]
        : (results[0] as List<FeedItem>);
    var donations = results[1] as List<FeedItem>;

    // Aplica filtros de estado/cidade
    // stateCode = sigla do IBGE ex: "GO" — compara com o campo state do Firebase
    if (filter.stateCode != null) {
      dreams = dreams
          .where((d) =>
              d.state?.toUpperCase() == filter.stateCode!.toUpperCase())
          .toList();
      donations = donations
          .where((d) =>
              d.state?.toUpperCase() == filter.stateCode!.toUpperCase())
          .toList();
    }
    if (filter.city != null) {
      dreams = dreams
          .where((d) =>
              d.city?.toLowerCase() == filter.city!.toLowerCase())
          .toList();
      donations = donations
          .where((d) =>
              d.city?.toLowerCase() == filter.city!.toLowerCase())
          .toList();
    }

    // Mescla pseudo-aleatória: embaralha cada lista e intercala
    dreams.shuffle(_rng);
    donations.shuffle(_rng);

    final merged = _interleave(dreams, donations);

    // Pega a página
    final page = merged.take(pageSize).toList();
    final hasMore = merged.length > pageSize;

    return FeedPage(items: page, hasMore: hasMore);
  }

  /// Intercala duas listas alternando elementos de forma variada.
  /// Ex: 1 dream, 1 donation, 2 dreams, 1 donation, etc.
  List<FeedItem> _interleave(List<FeedItem> a, List<FeedItem> b) {
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;

    final result = <FeedItem>[];
    int ai = 0, bi = 0;

    while (ai < a.length || bi < b.length) {
      // Alterna aleatoriamente entre 1-2 elementos de cada lista
      final takeA = (ai < a.length) ? (_rng.nextInt(2) + 1) : 0;
      final takeB = (bi < b.length) ? (_rng.nextInt(2) + 1) : 0;

      for (int i = 0; i < takeA && ai < a.length; i++) {
        result.add(a[ai++]);
      }
      for (int i = 0; i < takeB && bi < b.length; i++) {
        result.add(b[bi++]);
      }
    }

    return result;
  }

  Future<List<FeedItem>> _fetchDreams({
    required String? currentUserId,
    int? before,
  }) async {
    Query query = _db.child('Dreams').orderByChild('createdAt');
    if (before != null) query = query.endBefore(before);
    query = query.limitToLast(_fetchSize);

    try {
      final snap = await query.get();
      if (!snap.exists || snap.value == null) return [];

      // Coleta os itens básicos do nó Dreams/
      final rawList = <MapEntry<String, Map>>[];
      for (final child in snap.children) {
        final value = child.value;
        if (value is Map) rawList.add(MapEntry(child.key!, value));
      }

      // Para cada sonho, tenta enriquecer com childName/childEmoji do nó
      // Users/{userId}/dreams/{dreamId} — busca em paralelo
      final enriched = await Future.wait(rawList.map((entry) async {
        final id = entry.key;
        final map = Map<dynamic, dynamic>.from(entry.value);
        final uid = map['userId']?.toString();

        if (uid != null) {
          try {
            final userDreamSnap =
                await _db.child('Users/$uid/dreams/$id').get();
            if (userDreamSnap.exists && userDreamSnap.value is Map) {
              final ud = userDreamSnap.value as Map;
              // Mescla campos extras que existem apenas no nó do usuário
              map['childName'] ??= ud['childName'];
              map['childEmoji'] ??= ud['childEmoji'];
              // Garante imageUrl atualizada (o Users/ pode ter versão mais recente)
              map['imageUrl'] ??= ud['imageUrl'];
            }
          } catch (_) {
            // Falhou ao buscar dados do usuário — continua sem enriquecimento
          }
        }

        return FeedItem.fromDream(id, map, currentUserId: currentUserId);
      }));

      enriched.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return enriched;
    } catch (e) {
      debugPrint('❌ _fetchDreams error: $e');
      return [];
    }
  }

  Future<List<FeedItem>> _fetchDonations({int? before}) async {
    Query query = _db.child('Donations').orderByChild('createdAt');
    if (before != null) query = query.endBefore(before);
    query = query.limitToLast(_fetchSize);

    try {
      final snap = await query.get();
      if (!snap.exists || snap.value == null) {
        debugPrint('⚠️ _fetchDonations: snapshot vazio');
        return [];
      }

      final items = <FeedItem>[];
      for (final child in snap.children) {
        final value = child.value;
        if (value is Map) {
          final status = value['status']?.toString();
          debugPrint('🎁 Donation ${child.key}: status=$status');
          if (status == 'available') {
            items.add(FeedItem.fromDonation(child.key!, value));
          }
        }
      }
      debugPrint('✅ _fetchDonations: ${items.length} itens disponíveis');
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e) {
      debugPrint('❌ _fetchDonations error: $e');
      return [];
    }
  }

  /// Lista de estados únicos presentes no feed (para o filtro).
  ///
  /// Donations não tem índice em `status`, então buscamos por `createdAt`
  /// e filtramos `status == 'available'` em memória para evitar erro do Firebase.
  Future<List<String>> fetchAvailableStates() async {
    final results = await Future.wait([
      _db.child('Dreams').orderByChild('createdAt').limitToLast(100).get(),
      _db.child('Donations').orderByChild('createdAt').limitToLast(100).get(),
    ]);

    final states = <String>{};
    final snaps = results;

    // Dreams: todos entram
    final dreamsSnap = snaps[0];
    if (dreamsSnap.exists && dreamsSnap.value != null) {
      for (final child in dreamsSnap.children) {
        final value = child.value;
        if (value is Map) {
          final s = value['state']?.toString();
          if (s != null && s.isNotEmpty) states.add(s);
        }
      }
    }

    // Donations: filtra status == 'available' em memória
    final donationsSnap = snaps[1];
    if (donationsSnap.exists && donationsSnap.value != null) {
      for (final child in donationsSnap.children) {
        final value = child.value;
        if (value is Map && value['status']?.toString() == 'available') {
          final s = value['state']?.toString();
          if (s != null && s.isNotEmpty) states.add(s);
        }
      }
    }

    return states.toList()..sort();
  }

  /// Lista de cidades de um estado (para o filtro de cidade).
  ///
  /// Dreams tem índice em `state`, então pode usar equalTo.
  /// Donations não tem índice em `state` — buscamos tudo e filtramos em memória.
  Future<List<String>> fetchCitiesByState(String stateCode) async {
    final results = await Future.wait([
      _db.child('Dreams').orderByChild('state').equalTo(stateCode).get(),
      _db.child('Donations').orderByChild('createdAt').limitToLast(200).get(),
    ]);

    final cities = <String>{};
    final stateLower = stateCode.toLowerCase();

    // Dreams: Firebase já filtrou por estado
    final dreamsSnap = results[0];
    if (dreamsSnap.exists && dreamsSnap.value != null) {
      for (final child in dreamsSnap.children) {
        final value = child.value;
        if (value is Map) {
          final c = value['city']?.toString();
          if (c != null && c.isNotEmpty) cities.add(c);
        }
      }
    }

    // Donations: filtra estado e status em memória
    final donationsSnap = results[1];
    if (donationsSnap.exists && donationsSnap.value != null) {
      for (final child in donationsSnap.children) {
        final value = child.value;
        if (value is Map &&
            value['status']?.toString() == 'available' &&
            value['state']?.toString().toLowerCase() == stateLower) {
          final c = value['city']?.toString();
          if (c != null && c.isNotEmpty) cities.add(c);
        }
      }
    }

    return cities.toList()..sort();
  }
}
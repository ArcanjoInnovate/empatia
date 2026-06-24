import 'dart:async';
import 'dart:math';
import 'package:empatia/features/search/data/repositories/search_repository.dart';
import 'package:flutter/material.dart';

export 'package:empatia/features/search/data/repositories/search_repository.dart'
    show SearchResult;

enum SearchState { idle, loading, success, empty, error }

/// 🔍 SEARCH CONTROLLER
///
/// Gerencia estado da busca unificada (donations + dreams).
/// Filtros de localização: estado, cidade e proximidade por raio.
///
/// Quando "Próximo de mim" está ativo:
///   1. O repositório busca itens sem filtro geográfico fixo (traz ampla base)
///   2. Este controller filtra localmente via Haversine os itens que possuem
///      lat/lng e estão dentro do raio definido pelo usuário
///   3. Ordena o resultado por distância crescente (mais próximo primeiro)
///
/// A localização exata do usuário NUNCA é exibida na UI; apenas a distância
/// calculada (em km inteiros) pode ser usada para ordenação.
class SearchController extends ChangeNotifier {
  final SearchRepository _repository;

  SearchController(this._repository);

  SearchState _state = SearchState.idle;
  List<SearchResult> _results = [];
  String? _errorMessage;

  String _query = '';
  String? _selectedType;
  String? _selectedState;
  String? _selectedCity;
  double? _userLatitude;
  double? _userLongitude;
  double _radiusKm = 10.0;

  Timer? _debounce;

  SearchState get state => _state;
  List<SearchResult> get results => _results;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  String? get selectedType => _selectedType;
  String? get selectedState => _selectedState;
  String? get selectedCity => _selectedCity;
  double get radiusKm => _radiusKm;

  bool get hasActiveFilters =>
      _query.isNotEmpty ||
      _selectedState != null ||
      _selectedCity != null ||
      _selectedType != null ||
      _userLatitude != null;

  bool get isProximityMode => _userLatitude != null && _userLongitude != null;

  // ── Filtros de texto ───────────────────────────────────────────────────────

  void onQueryChanged(String value) {
    _query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _runSearch);
    notifyListeners();
  }

  /// Seleciona o tipo de item a filtrar.
  ///
  /// [type] == null significa "Todos" — ainda dispara busca (force: true)
  /// para garantir que o filtro "Todos" sempre exiba resultados, mesmo que
  /// não haja nenhum outro filtro ativo no momento.
  void selectType(String? type) {
    _selectedType = type;
    notifyListeners();
    // force: true garante que "Todos" (type == null) dispara busca
    // mesmo sem outros filtros ativos — evita ficar preso no estado idle.
    _runSearch(force: true);
  }

  // ── Filtros de localização ─────────────────────────────────────────────────

  void applyLocationFilters({
    String? stateSigla,
    String? cityName,
    double? userLat,
    double? userLng,
    double radiusKm = 10.0,
  }) {
    _selectedState = stateSigla;
    _selectedCity = cityName;
    _userLatitude = userLat;
    _userLongitude = userLng;
    _radiusKm = radiusKm;
    notifyListeners();
    _runSearch();
  }

  /// Atualiza apenas o raio e re-filtra os resultados já carregados,
  /// sem disparar nova chamada à rede — apenas re-aplica Haversine local.
  void updateRadius(double radiusKm) {
    _radiusKm = radiusKm;
    notifyListeners();
    if (isProximityMode) {
      _runSearch();
    }
  }

  void clearFilters() {
    _query = '';
    _selectedState = null;
    _selectedCity = null;
    _selectedType = null;
    _userLatitude = null;
    _userLongitude = null;
    _radiusKm = 10.0;
    _results = [];
    _state = SearchState.idle;
    _debounce?.cancel();
    notifyListeners();
  }

  // ── Busca ──────────────────────────────────────────────────────────────────

  /// [force] == true ignora a checagem de hasActiveFilters.
  /// Usado por selectType para garantir que "Todos" sempre busca.
  Future<void> _runSearch({bool force = false}) async {
    if (!force && !hasActiveFilters) {
      _results = [];
      _state = SearchState.idle;
      notifyListeners();
      return;
    }

    _state = SearchState.loading;
    notifyListeners();

    try {
      final items = await _repository.search(
        query: _query.isEmpty ? null : _query,
        city: isProximityMode ? null : _selectedCity,
        state: isProximityMode ? null : _selectedState,
        type: _selectedType,
      );

      final filtered =
          isProximityMode ? _filterAndSortByProximity(items) : items;

      _results = filtered;
      _state = filtered.isEmpty ? SearchState.empty : SearchState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = SearchState.error;
    }

    notifyListeners();
  }

  // ── Haversine ──────────────────────────────────────────────────────────────

  List<SearchResult> _filterAndSortByProximity(List<SearchResult> items) {
    final userLat = _userLatitude!;
    final userLng = _userLongitude!;

    final withDistance = <_ItemWithDistance>[];

    for (final item in items) {
      if (item.latitude == null || item.longitude == null) continue;

      final dist = _haversineKm(
        userLat, userLng,
        item.latitude!, item.longitude!,
      );

      if (dist <= _radiusKm) {
        withDistance.add(_ItemWithDistance(item: item, distanceKm: dist));
      }
    }

    withDistance.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return withDistance.map((e) => e.item).toList();
  }

  double _haversineKm(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

class _ItemWithDistance {
  final SearchResult item;
  final double distanceKm;
  const _ItemWithDistance({required this.item, required this.distanceKm});
}
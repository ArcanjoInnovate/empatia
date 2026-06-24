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
///
/// Filtros disponíveis:
///   - Texto livre (query)
///   - Tipo (donation / dream / null = todos)
///   - Categoria (Roupas / Brinquedos / Livros / Alimentos / Móveis / Outros)
///   - Estado, Cidade, Proximidade (Haversine)
///
/// O filtro de categoria é passado ao repositório, que o aplica client-side
/// após o fetch do Firebase — sem consultas extras à rede.
class SearchController extends ChangeNotifier {
  final SearchRepository _repository;

  SearchController(this._repository);

  SearchState _state     = SearchState.idle;
  List<SearchResult> _results = [];
  String? _errorMessage;

  String  _query           = '';
  String? _selectedType;
  String? _selectedCategory; // ← NOVO
  String? _selectedState;
  String? _selectedCity;
  double? _userLatitude;
  double? _userLongitude;
  double  _radiusKm        = 10.0;

  bool _initialLoaded = false;

  Timer? _debounce;

  // ── Getters ────────────────────────────────────────────────────────────────

  SearchState        get state            => _state;
  List<SearchResult> get results          => _results;
  String?            get errorMessage     => _errorMessage;
  String             get query            => _query;
  String?            get selectedType     => _selectedType;
  String?            get selectedCategory => _selectedCategory; // ← NOVO
  String?            get selectedState    => _selectedState;
  String?            get selectedCity     => _selectedCity;
  double             get radiusKm         => _radiusKm;

  bool get hasActiveFilters =>
      _query.isNotEmpty      ||
      _selectedState    != null ||
      _selectedCity     != null ||
      _selectedType     != null ||
      _selectedCategory != null || // ← NOVO
      _userLatitude     != null;

  bool get isProximityMode => _userLatitude != null && _userLongitude != null;

  // ── Carga inicial ──────────────────────────────────────────────────────────

  Future<void> loadInitial() async {
    if (_initialLoaded) return;
    _initialLoaded = true;
    await _runSearch(force: true);
  }

  // ── Filtros de texto ───────────────────────────────────────────────────────

  void onQueryChanged(String value) {
    _query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _runSearch);
    notifyListeners();
  }

  // ── Filtro de tipo ─────────────────────────────────────────────────────────

  void selectType(String? type) {
    _selectedType = type;
    notifyListeners();
    _runSearch(force: true);
  }

  // ── Filtro de categoria ────────────────────────────────────────────────────

  /// Seleciona uma categoria para filtrar os resultados.
  ///
  /// [category] == null significa "Todos" — remove o filtro de categoria.
  /// Dispara nova busca imediatamente (force: true) para atualizar a lista.
  /// Funciona em conjunto com todos os outros filtros ativos.
  void selectCategory(String? category) {
    if (_selectedCategory == category) return; // sem mudança, sem busca extra
    _selectedCategory = category;
    notifyListeners();
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
    _selectedState  = stateSigla;
    _selectedCity   = cityName;
    _userLatitude   = userLat;
    _userLongitude  = userLng;
    _radiusKm       = radiusKm;
    notifyListeners();
    _runSearch(force: true);
  }

  void updateRadius(double radiusKm) {
    _radiusKm = radiusKm;
    notifyListeners();
    if (isProximityMode) _runSearch(force: true);
  }

  // ── Limpar filtros ─────────────────────────────────────────────────────────

  /// Limpa todos os filtros e recarrega a lista completa.
  /// Nunca retorna ao estado idle — o usuário sempre vê conteúdo.
  void clearFilters() {
    _query            = '';
    _selectedState    = null;
    _selectedCity     = null;
    _selectedType     = null;
    _selectedCategory = null; // ← NOVO
    _userLatitude     = null;
    _userLongitude    = null;
    _radiusKm         = 10.0;
    _debounce?.cancel();
    _initialLoaded    = false;
    loadInitial();
  }

  // ── Busca ──────────────────────────────────────────────────────────────────

  Future<void> _runSearch({bool force = false}) async {
    if (!force && !hasActiveFilters) return;

    _state        = SearchState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await _repository.search(
        query:    _query.isEmpty ? null : _query,
        city:     isProximityMode ? null : _selectedCity,
        state:    isProximityMode ? null : _selectedState,
        type:     _selectedType,
        category: _selectedCategory, // ← NOVO
      );

      final filtered =
          isProximityMode ? _filterAndSortByProximity(items) : items;

      _results = filtered;
      _state   = filtered.isEmpty ? SearchState.empty : SearchState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state        = SearchState.error;
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
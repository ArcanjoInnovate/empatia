import 'dart:async';
import 'package:empatia/features/search/data/repositories/search_repository.dart';
import 'package:flutter/material.dart';

export 'package:empatia/features/search/data/repositories/search_repository.dart'
    show SearchResult;

enum SearchState { idle, loading, success, empty, error }

/// 🔍 SEARCH CONTROLLER
///
/// Gerencia estado da busca unificada (donations + dreams) com debounce.
/// Filtros: texto livre, estado, cidade, tipo (donation | dream).
class SearchController extends ChangeNotifier {
  final SearchRepository _repository;

  SearchController(this._repository);

  // ── Estado ────────────────────────────────────────────────────────────

  SearchState _state = SearchState.idle;
  List<SearchResult> _results = [];
  String? _errorMessage;

  // Filtros
  String _query = '';
  String? _selectedState;
  String? _selectedCity;
  String? _selectedType; // null = todos | 'donation' | 'dream'

  Timer? _debounce;

  SearchState get state => _state;
  List<SearchResult> get results => _results;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  String? get selectedState => _selectedState;
  String? get selectedCity => _selectedCity;
  String? get selectedType => _selectedType;

  bool get hasActiveFilters =>
      _query.isNotEmpty ||
      _selectedState != null ||
      _selectedCity != null ||
      _selectedType != null;

  // ── Atualização de filtros ─────────────────────────────────────────────

  void onQueryChanged(String value) {
    _query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _runSearch);
    notifyListeners();
  }

  void selectState(String? state) {
    _selectedState = state;
    // Ao trocar estado, limpa cidade (pode não pertencer ao novo estado)
    _selectedCity = null;
    notifyListeners();
    _runSearch();
  }

  void selectCity(String? city) {
    _selectedCity = city;
    notifyListeners();
    _runSearch();
  }

  void selectType(String? type) {
    _selectedType = type;
    notifyListeners();
    _runSearch();
  }

  void clearFilters() {
    _query = '';
    _selectedState = null;
    _selectedCity = null;
    _selectedType = null;
    _results = [];
    _state = SearchState.idle;
    _debounce?.cancel();
    notifyListeners();
  }

  // ── Busca ─────────────────────────────────────────────────────────────

  Future<void> _runSearch() async {
    if (!hasActiveFilters) {
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
        city: _selectedCity,
        state: _selectedState,
        type: _selectedType,
      );

      _results = items;
      _state = items.isEmpty ? SearchState.empty : SearchState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = SearchState.error;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
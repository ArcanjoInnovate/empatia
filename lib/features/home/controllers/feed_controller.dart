// lib/features/home/controllers/feed_controller.dart

import 'package:empatia/features/home/data/models/feed_filter.dart';
import 'package:empatia/features/home/data/models/feed_item_.dart';
import 'package:empatia/features/home/data/repositories/feed_repository.dart';
import 'package:empatia/features/home/data/services/ibge_service.dart';
import 'package:flutter/foundation.dart';

enum FeedStatus { idle, loading, loaded, error }

class FeedController extends ChangeNotifier {
  FeedController(
    this._repo, {
    required this.currentUserId,
  });

  final FeedRepository _repo;
  final String currentUserId;
  final IbgeService _ibge = IbgeService.instance;

  // ── Estado do feed ──────────────────────────────────────────────────────────
  List<FeedItem> _items = [];
  FeedStatus _status = FeedStatus.idle;
  FeedFilter _filter = const FeedFilter();
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _error;

  List<FeedItem> get items => _items;
  FeedStatus get status => _status;
  FeedFilter get filter => _filter;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;

  // ── Estado do IBGE ──────────────────────────────────────────────────────────
  List<IbgeEstado> _estados = [];
  List<String> _cidades = [];
  bool _loadingEstados = false;
  bool _loadingCidades = false;
  String? _ibgeError;

  List<IbgeEstado> get estados => _estados;
  List<String> get cidades => _cidades;
  bool get loadingEstados => _loadingEstados;
  bool get loadingCidades => _loadingCidades;
  String? get ibgeError => _ibgeError;

  // ── Inicialização ───────────────────────────────────────────────────────────

  Future<void> init() async {
    await Future.wait([
      _loadFeed(),
      _loadEstados(),
    ]);
  }

  // ── IBGE ────────────────────────────────────────────────────────────────────

  Future<void> _loadEstados() async {
    _loadingEstados = true;
    _ibgeError = null;
    notifyListeners();

    try {
      _estados = await _ibge.fetchEstados();
    } catch (e) {
      _ibgeError = 'Não foi possível carregar os estados.';
      debugPrint('[IbgeService] _loadEstados error: $e');
    } finally {
      _loadingEstados = false;
      notifyListeners();
    }
  }

  Future<void> fetchCidadesByEstado(String estadoSigla) async {
    _cidades = [];
    _loadingCidades = true;
    _ibgeError = null;
    notifyListeners();

    try {
      _cidades = await _ibge.fetchCidades(estadoSigla);
    } catch (e) {
      _ibgeError = 'Não foi possível carregar as cidades.';
      debugPrint('[IbgeService] fetchCidadesByEstado($estadoSigla) error: $e');
    } finally {
      _loadingCidades = false;
      notifyListeners();
    }
  }

  void clearCidades() {
    _cidades = [];
    notifyListeners();
  }

  // ── Filtros ─────────────────────────────────────────────────────────────────

  Future<void> applyFilter(FeedFilter newFilter) async {
    _filter = newFilter;
    // Se mudou o estado, limpa as cidades do filtro
    await _loadFeed();
  }

  Future<void> clearFilters() async {
    _filter = const FeedFilter();
    _cidades = [];
    await _loadFeed();
  }

  // ── Feed ────────────────────────────────────────────────────────────────────

  Future<void> _loadFeed() async {
    _status = FeedStatus.loading;
    _items = [];
    _hasMore = true;
    notifyListeners();

    try {
      final result = await _repo.fetchPage(
        filter: _filter,
        currentUserId: currentUserId,
      );
      _items = result.items;
      _hasMore = result.hasMore;
      _status = FeedStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = FeedStatus.error;
      debugPrint('[FeedController] _loadFeed error: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _loadFeed();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _items.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Usa o createdAt do último item como cursor de paginação
      final result = await _repo.fetchPage(
        filter: _filter,
        currentUserId: currentUserId,
        beforeTimestamp: _items.last.createdAt,
      );
      _items = [..._items, ...result.items];
      _hasMore = result.hasMore;
    } catch (e) {
      debugPrint('[FeedController] loadMore error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
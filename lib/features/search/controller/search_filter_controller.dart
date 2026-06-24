import 'dart:async';

import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/features/profile/data/models/city_model.dart';
import 'package:empatia/features/profile/data/models/state_model.dart';
import 'package:empatia/features/search/data/models/user_location_model.dart';
import 'package:empatia/features/search/data/repositories/search_location_repository.dart';
import 'package:flutter/foundation.dart';

export 'package:empatia/features/search/data/services/search_location_service.dart'
    show LocationException;

enum FilterLoadState { idle, loading, success, error }

enum ProximityState { inactive, loading, active, error }

/// 🎛️ SEARCH FILTER CONTROLLER
///
/// Gerencia filtros de localização da tela de busca:
///   - Dropdown de Estado (IBGE)
///   - Dropdown de Cidade (dependente do Estado)
///   - Toggle "Próximo de mim" — usa lat/lng do PERFIL do usuário,
///     não GPS físico. Isso garante que itens cadastrados na cidade
///     do usuário apareçam mesmo que o dispositivo esteja em outra cidade.
class SearchFilterController extends ChangeNotifier {
  final SearchLocationRepository _repository;

  SearchFilterController(this._repository);

  // ── Dropdowns ─────────────────────────────────────────────────────────────

  FilterLoadState _estadosState = FilterLoadState.idle;
  FilterLoadState _cidadesState = FilterLoadState.idle;

  List<EstadoModel> _estados = [];
  List<CityModel> _cidades = [];

  EstadoModel? _selectedEstado;
  CityModel? _selectedCidade;

  FilterLoadState get estadosState => _estadosState;
  FilterLoadState get cidadesState => _cidadesState;

  List<EstadoModel> get estados => _estados;
  List<CityModel> get cidades => _cidades;

  EstadoModel? get selectedEstado => _selectedEstado;
  CityModel? get selectedCidade => _selectedCidade;

  bool get cidadeEnabled =>
      _selectedEstado != null && _cidadesState != FilterLoadState.loading;

  // ── Erros ─────────────────────────────────────────────────────────────────

  String? _estadosError;
  String? _cidadesError;

  String? get estadosError => _estadosError;
  String? get cidadesError => _cidadesError;

  // ── Proximidade ───────────────────────────────────────────────────────────

  ProximityState _proximityState = ProximityState.inactive;

  /// Localização sintética montada a partir do perfil do usuário.
  /// Nunca vem do GPS físico — usa lat/lng cadastrado no UserModel.
  UserLocationModel? _userLocation;
  String? _proximityErrorMessage;

  /// Raio de busca em km — slider de 1 a 100, incremento de 1 km.
  double _radiusKm = 10.0;

  ProximityState get proximityState => _proximityState;
  UserLocationModel? get userLocation => _userLocation;
  String? get proximityErrorMessage => _proximityErrorMessage;
  bool get isProximityActive => _proximityState == ProximityState.active;

  /// Raio atual em km (1–100)
  double get radiusKm => _radiusKm;

  // ── Filtros ativos ────────────────────────────────────────────────────────

  bool get hasAnyLocationFilter =>
      _selectedEstado != null || _selectedCidade != null || isProximityActive;

  // ══════════════════════════════════════════════════════════════════════════
  // ESTADOS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> loadEstados() async {
    if (_estadosState == FilterLoadState.loading || _estados.isNotEmpty) return;

    _estadosState = FilterLoadState.loading;
    _estadosError = null;
    notifyListeners();

    try {
      _estados = await _repository.getEstados();
      _estadosState = FilterLoadState.success;
    } catch (e) {
      _estadosError = 'Erro ao carregar estados. Verifique sua conexão.';
      _estadosState = FilterLoadState.error;
      debugPrint('❌ SearchFilterController.loadEstados: $e');
    }

    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SELEÇÃO DE ESTADO
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> selectEstado(EstadoModel? estado) async {
    if (_selectedEstado?.sigla == estado?.sigla) return;

    _selectedEstado = estado;
    _selectedCidade = null;
    _cidades = [];
    _cidadesError = null;

    notifyListeners();

    if (estado == null) return;
    await _loadCidades(estado.sigla);
  }

  Future<void> selectEstadoBySigla(String? sigla) async {
    if (sigla == null) return;
    await loadEstados();
    final estado = _estados.where((e) => e.sigla == sigla).firstOrNull;
    if (estado != null) await selectEstado(estado);
  }

  Future<void> _loadCidades(String sigla) async {
    _cidadesState = FilterLoadState.loading;
    notifyListeners();

    try {
      _cidades = await _repository.getCidades(sigla);
      _cidadesState = FilterLoadState.success;
    } catch (e) {
      _cidadesError = 'Erro ao carregar cidades. Verifique sua conexão.';
      _cidadesState = FilterLoadState.error;
      debugPrint('❌ SearchFilterController._loadCidades: $e');
    }

    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SELEÇÃO DE CIDADE
  // ══════════════════════════════════════════════════════════════════════════

  void selectCidade(CityModel? cidade) {
    if (_selectedCidade?.id == cidade?.id) return;
    _selectedCidade = cidade;
    notifyListeners();
  }

  void selectCidadeByNome(String? nome) {
    if (nome == null) return;
    final cidade = _cidades
        .where((c) => c.nome.toLowerCase() == nome.toLowerCase())
        .firstOrNull;
    if (cidade != null) selectCidade(cidade);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROXIMIDADE + RAIO
  // ══════════════════════════════════════════════════════════════════════════

  /// Ativa/desativa o modo "Próximo de mim".
  ///
  /// [user] — UserModel com lat/lng cadastrado no perfil.
  /// Se o perfil não tiver coordenadas, exibe erro amigável.
  Future<void> toggleProximity({UserModel? user}) async {
    if (isProximityActive) {
      _deactivateProximity();
    } else {
      _activateProximityFromProfile(user);
    }
  }

  /// Usa lat/lng do PERFIL do usuário — sem chamar GPS.
  void _activateProximityFromProfile(UserModel? user) {
    _proximityState = ProximityState.loading;
    _proximityErrorMessage = null;
    notifyListeners();

    final lat = user?.latitude;
    final lng = user?.longitude;

    if (lat == null || lng == null) {
      _proximityErrorMessage =
          'Sua localização não está cadastrada no perfil. '
          'Atualize seu endereço em Configurações para usar este filtro.';
      _proximityState = ProximityState.error;
      _userLocation = null;
      notifyListeners();
      return;
    }

    _userLocation = UserLocationModel(
      latitude: lat,
      longitude: lng,
      obtainedAt: DateTime.now(),
      detectedCity: user?.city,
      detectedState: user?.state,
    );
    _proximityState = ProximityState.active;
    notifyListeners();
  }

  void _deactivateProximity() {
    _proximityState = ProximityState.inactive;
    _userLocation = null;
    _proximityErrorMessage = null;
    _radiusKm = 10.0;
    notifyListeners();
  }

  void dismissProximityError() {
    if (_proximityState == ProximityState.error) {
      _proximityState = ProximityState.inactive;
      _proximityErrorMessage = null;
      notifyListeners();
    }
  }

  /// Atualiza o raio de busca em km (chamado pelo slider).
  /// O valor é arredondado para inteiro (1 km a 100 km).
  void setRadiusKm(double value) {
    final rounded = value.roundToDouble().clamp(1.0, 100.0);
    if (rounded == _radiusKm) return;
    _radiusKm = rounded;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIMPEZA
  // ══════════════════════════════════════════════════════════════════════════

  void clearAll() {
    _selectedEstado = null;
    _selectedCidade = null;
    _cidades = [];
    _cidadesError = null;
    _deactivateProximity();
    notifyListeners();
  }

  Future<void> prefillFromUser({
    String? stateSigla,
    String? cityName,
  }) async {
    if (_selectedEstado != null || stateSigla == null) return;

    await loadEstados();
    await selectEstadoBySigla(stateSigla);

    if (cityName != null && _selectedCidade == null) {
      if (_cidadesState == FilterLoadState.loading) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      selectCidadeByNome(cityName);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
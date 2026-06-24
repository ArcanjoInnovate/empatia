import 'package:empatia/features/profile/data/models/city_model.dart';
import 'package:empatia/features/profile/data/models/state_model.dart';
import 'package:empatia/features/search/data/models/bairro_model.dart';
import 'package:empatia/features/search/data/models/user_location_model.dart';
import 'package:empatia/features/search/data/services/search_location_service.dart';

/// 🗺️ SEARCH LOCATION REPOSITORY
///
/// Camada de acesso a dados de localização para a feature de busca.
/// Encapsula o [SearchLocationService] e expõe uma API limpa para o
/// [SearchFilterController].
///
/// Responsabilidades:
/// - Delegar chamadas ao serviço e tratar erros
/// - Ser o ponto único de acesso a dados de localização na feature search
///
/// Na Fase 2, este repositório pode ser estendido para:
/// - Persistência de localização em SharedPreferences
/// - Geocodificação reversa (lat/lng → endereço)
/// - Cálculo de distância entre pontos
class SearchLocationRepository {
  final SearchLocationService _service;

  SearchLocationRepository({SearchLocationService? service})
      : _service = service ?? SearchLocationService.instance;

  // ── Estados ──────────────────────────────────────────────────────────────

  /// Retorna todos os estados brasileiros (com cache em memória).
  Future<List<EstadoModel>> getEstados() => _service.fetchEstados();

  // ── Cidades ───────────────────────────────────────────────────────────────

  /// Retorna as cidades de um estado dado sua sigla (ex: "GO").
  /// Cache automático por estado.
  Future<List<CityModel>> getCidades(String siglaEstado) =>
      _service.fetchCidades(siglaEstado);

  // ── Bairros ───────────────────────────────────────────────────────────────

  /// Busca bairros pelo nome dentro de uma cidade+estado.
  /// Cache por par cidade+estado.
  Future<List<BairroModel>> searchBairros({
    required String query,
    required String city,
    required String stateCode,
  }) =>
      _service.searchBairros(
        query: query,
        city: city,
        stateCode: stateCode,
      );

  // ── Geolocalização ────────────────────────────────────────────────────────

  /// Solicita permissão e retorna a localização GPS atual.
  /// Lança [LocationException] em caso de erro.
  Future<UserLocationModel> getCurrentLocation() =>
      _service.getCurrentLocation();

  /// Retorna o status atual de permissão sem solicitar.
  Future<LocationPermissionStatus> checkPermission() =>
      _service.checkPermission();

  /// Verifica se o serviço de localização (GPS) está ativo.
  Future<bool> isLocationServiceEnabled() =>
      _service.isLocationServiceEnabled();

  // ── Cache ─────────────────────────────────────────────────────────────────

  /// Limpa o cache de localização GPS (chamado ao desativar "Próximo de mim")
  void clearLocationCache() => _service.clearLocationCache();
}
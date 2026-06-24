import 'dart:convert';

import 'package:empatia/features/profile/data/models/city_model.dart';
import 'package:empatia/features/profile/data/models/state_model.dart';
import 'package:empatia/features/search/data/models/bairro_model.dart';
import 'package:empatia/features/search/data/models/user_location_model.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// 🗺️ SEARCH LOCATION SERVICE
///
/// Serviço centralizado para todas as operações de localização
/// da tela de busca. Responsável por:
///
/// 1. Buscar estados via IBGE (com cache em memória)
/// 2. Buscar cidades por estado via IBGE (com cache em memória)
/// 3. Buscar bairros via Cloud Function existente (LocationRepository)
/// 4. Obter localização GPS do usuário
///
/// CACHE STRATEGY:
/// - Estados: carregados uma vez e mantidos em memória para toda a sessão
///   (27 estados do Brasil nunca mudam)
/// - Cidades: carregadas por estado na primeira consulta e mantidas em memória
///   (os municípios raramente mudam)
/// - Bairros: cache por chave "cidade|estado" para evitar chamadas repetidas
///   dentro da mesma sessão
/// - Localização do usuário: válida por 5 minutos (ver UserLocationModel)
///
/// FONTE DE BAIRROS:
/// O IBGE não fornece bairros de forma estruturada (apenas distritos
/// e subdivisões administrativas). Por isso, os bairros são obtidos
/// via Cloud Function já existente no projeto que usa Google Places API
/// (endpoint searchNeighborhoods). Cache local evita chamadas excessivas.
///
/// Preparatório para Fase 2:
/// - Os modelos BairroModel e UserLocationModel já contêm campos
///   de coordenadas para ranking por proximidade
/// - O método getNearbyLocation() retorna UserLocationModel pronto
///   para ser persistido e enviado ao backend na Fase 2
class SearchLocationService {
  SearchLocationService._();
  static final SearchLocationService instance = SearchLocationService._();

  // ── Constantes ────────────────────────────────────────────────────────────

  static const _ibgeBase =
      'https://servicodados.ibge.gov.br/api/v1/localidades';
  static const _cloudFunctionsBase =
      'https://southamerica-east1-empatia-34400.cloudfunctions.net';
  static const _httpTimeout = Duration(seconds: 10);

  // ── Cache em memória ──────────────────────────────────────────────────────

  /// Cache de estados: carregado uma vez por sessão
  List<EstadoModel>? _estadosCache;

  /// Cache de cidades: chave = sigla do estado (ex: "GO")
  final Map<String, List<CityModel>> _cidadesCache = {};

  /// Cache de bairros: chave = "cidade|estado" (ex: "Aparecida de Goiânia|GO")
  final Map<String, List<BairroModel>> _bairrosCache = {};

  /// Localização GPS atual do usuário (válida por 5 minutos)
  UserLocationModel? _currentLocation;

  // ══════════════════════════════════════════════════════════════════════════
  // ESTADOS
  // ══════════════════════════════════════════════════════════════════════════

  /// Retorna a lista de todos os estados brasileiros.
  ///
  /// Prioriza a lista embutida [estadosBrasileiros] que já existe no projeto,
  /// evitando uma chamada de rede desnecessária para dados estáticos.
  /// Se por algum motivo a lista embutida estiver vazia, faz fallback para IBGE.
  Future<List<EstadoModel>> fetchEstados() async {
    if (_estadosCache != null) return _estadosCache!;

    // Usa a lista estática já embutida no projeto (27 estados, nunca muda)
    if (estadosBrasileiros.isNotEmpty) {
      final estados = estadosBrasileiros
          .map((e) => EstadoModel(
                sigla: e['sigla']!,
                nome: e['nome']!,
              ))
          .toList();
      _estadosCache = estados;
      return estados;
    }

    // Fallback: busca na API do IBGE
    return _fetchEstadosFromIbge();
  }

  Future<List<EstadoModel>> _fetchEstadosFromIbge() async {
    final uri = Uri.parse('$_ibgeBase/estados?orderBy=nome');
    final res = await http.get(uri).timeout(_httpTimeout);

    if (res.statusCode != 200) {
      throw Exception('Erro ao buscar estados (HTTP ${res.statusCode})');
    }

    final list = (jsonDecode(res.body) as List)
        .map((e) => EstadoModel.fromJson(e as Map<String, dynamic>))
        .toList();

    _estadosCache = list;
    return list;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CIDADES
  // ══════════════════════════════════════════════════════════════════════════

  /// Retorna os municípios de um estado, ordenados por nome.
  ///
  /// [sigla] — sigla do estado (ex: "GO")
  ///
  /// O resultado é armazenado em cache em memória. A segunda chamada
  /// para o mesmo estado é instantânea.
  Future<List<CityModel>> fetchCidades(String sigla) async {
    final key = sigla.toUpperCase();

    if (_cidadesCache.containsKey(key)) {
      return _cidadesCache[key]!;
    }

    final uri = Uri.parse(
      '$_ibgeBase/estados/$key/municipios?orderBy=nome',
    );

    final res = await http.get(uri).timeout(_httpTimeout);

    if (res.statusCode != 200) {
      throw Exception(
          'Erro ao buscar cidades de $sigla (HTTP ${res.statusCode})');
    }

    final list = (jsonDecode(res.body) as List)
        .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
        .toList();

    _cidadesCache[key] = list;
    return list;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BAIRROS
  // ══════════════════════════════════════════════════════════════════════════

  /// Busca sugestões de bairros para uma cidade+estado dado um termo.
  ///
  /// Usa a Cloud Function `searchNeighborhoods` já existente no projeto
  /// (que internamente usa Google Places API).
  ///
  /// O cache é por chave "cidade|estado" e o conteúdo armazenado é a
  /// lista completa de sugestões para esse par, evitando chamadas repetidas
  /// quando o usuário muda o campo de texto mas mantém cidade/estado.
  ///
  /// LIMITAÇÃO CONHECIDA: O IBGE não disponibiliza bairros de forma
  /// estruturada — apenas divisões administrativas (distritos, subdistritos).
  /// A fonte oficial mais adequada seria o CNEFE/IBGE ou APIs municipais,
  /// mas elas não têm cobertura nacional uniforme. Google Places via
  /// Cloud Function é a alternativa mais confiável e já está integrada.
  Future<List<BairroModel>> searchBairros({
    required String query,
    required String city,
    required String stateCode,
  }) async {
    if (query.length < 2) return [];

    final cacheKey = '${city.toLowerCase()}|${stateCode.toLowerCase()}';

    // Verifica cache: se já temos sugestões para essa cidade, filtra localmente
    if (_bairrosCache.containsKey(cacheKey)) {
      final cached = _bairrosCache[cacheKey]!;
      if (cached.isNotEmpty) {
        final q = query.toLowerCase();
        return cached
            .where((b) => b.nome.toLowerCase().contains(q))
            .toList();
      }
    }

    try {
      final uri = Uri.parse('$_cloudFunctionsBase/searchNeighborhoods');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': query,
              'city': city,
              'state': stateCode,
            }),
          )
          .timeout(_httpTimeout);

      if (res.statusCode != 200) {
        debugPrint('⚠️ searchNeighborhoods HTTP ${res.statusCode}');
        return [];
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>?;
      if (decoded == null || decoded['status'] != 'OK') return [];

      final predictions = decoded['predictions'] as List? ?? [];
      final bairros = predictions
          .map((e) =>
              BairroModel.fromCloudFunction(Map<String, dynamic>.from(e as Map)))
          .where((b) => b.nome.isNotEmpty)
          .toList();

      // Armazena no cache
      _bairrosCache[cacheKey] = bairros;
      return bairros;
    } catch (e) {
      debugPrint('❌ Erro ao buscar bairros: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GEOLOCALIZAÇÃO
  // ══════════════════════════════════════════════════════════════════════════

  /// Verifica se o GPS está disponível sem solicitar permissão.
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  /// Retorna o status atual de permissão de localização.
  Future<LocationPermissionStatus> checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;

    final perm = await Geolocator.checkPermission();
    return _mapPermission(perm);
  }

  /// Solicita permissão de localização e obtém a posição atual.
  ///
  /// Retorna [UserLocationModel] pronto para uso nos filtros de busca.
  /// Preparado para Fase 2: o modelo inclui campos de geocodificação
  /// reversa que serão preenchidos pelo backend (cidade, estado, bairro).
  ///
  /// Lança [LocationException] com mensagem amigável em caso de erro.
  Future<UserLocationModel> getCurrentLocation() async {
    // Verifica cache válido (menos de 5 minutos)
    if (_currentLocation != null && _currentLocation!.isValid) {
      return _currentLocation!;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        LocationPermissionStatus.serviceDisabled,
        'O GPS está desativado. Ative a localização nas configurações do dispositivo.',
      );
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.denied) {
      throw LocationException(
        LocationPermissionStatus.denied,
        'Permissão de localização negada. Toque em "Próximo de mim" novamente para tentar.',
      );
    }

    if (perm == LocationPermission.deniedForever) {
      throw LocationException(
        LocationPermissionStatus.deniedForever,
        'Permissão de localização bloqueada. Vá em Configurações > Aplicativos > Empatia para ativar.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );

    final location = UserLocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      obtainedAt: DateTime.now(),
    );

    _currentLocation = location;
    return location;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CACHE MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════

  /// Limpa o cache de localização do usuário (ex: ao sair da tela)
  void clearLocationCache() {
    _currentLocation = null;
  }

  /// Limpa todo o cache (útil em logout ou testes)
  void clearAllCache() {
    _estadosCache = null;
    _cidadesCache.clear();
    _bairrosCache.clear();
    _currentLocation = null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  LocationPermissionStatus _mapPermission(LocationPermission p) {
    switch (p) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.unknown;
    }
  }
}

/// Exceção específica para erros de geolocalização.
/// Carrega o status de permissão para a UI exibir a mensagem correta.
class LocationException implements Exception {
  final LocationPermissionStatus status;
  final String message;

  const LocationException(this.status, this.message);

  @override
  String toString() => message;
}
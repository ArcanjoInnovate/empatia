import 'package:empatia/features/profile/data/models/city_model.dart';
import 'package:geolocator/geolocator.dart';
import '../repository/location_repository.dart';

/// 🗺️ LOCATION SERVICE
/// 
/// É o GERENTE de localização.
/// Ele pega dados do Repository e adiciona regras.
/// 
/// RESPONSABILIDADES:
/// - Validar permissões de GPS
/// - Organizar busca de cidades
/// - Gerenciar busca de bairros
class LocationService {
  final LocationRepository _repository;

  LocationService(this._repository);

  /// Pede permissão e pega localização do GPS
  Future<Position> getCurrentLocation() async {
    // Verifica se o GPS está ligado
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('❌ GPS desativado');
    }

    // Pede permissão
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('❌ Permissão de localização negada');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('❌ Permissão negada permanentemente');
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Busca cidades de um estado
  Future<List<CityModel>> getCidades(String sigla) async {
    return await _repository.fetchCidades(sigla);
  }

  /// Busca coordenadas de uma cidade
  Future<Map<String, double>?> getCityCoordinates({
    required String city,
    required String state,
  }) async {
    return await _repository.getCityCoordinates(
      city: city,
      state: state,
    );
  }

  /// Busca bairros
  Future<List<Map<String, dynamic>>> searchNeighborhoods({
    required String query,
    required String city,
    required String state,
    double? lat,
    double? lng,
  }) async {
    // Valida entrada mínima
    if (query.length < 3) {
      return [];
    }

    return await _repository.searchNeighborhoods(
      query: query,
      city: city,
      state: state,
      lat: lat,
      lng: lng,
    );
  }
}
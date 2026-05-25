import 'dart:convert';
import 'package:empatia/features/profile/data/models/city_model.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class LocationRepository {
  static const _functionsBaseUrl =
      'https://southamerica-east1-empatia-34400.cloudfunctions.net';

  /// Chama uma Cloud Function do Firebase
  /// É como fazer uma ligação para um ajudante especial
  Future<Map<String, dynamic>?> _callFunction(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/$name'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded == null) return null;
        return decoded as Map<String, dynamic>;
      } else {
        debugPrint('❌ Erro HTTP $name: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erro ao chamar $name: $e');
      return null;
    }
  }

  /// Busca lista de cidades de um estado no IBGE
  /// 
  /// Exemplo: sigla = "GO" → retorna ["Goiânia", "Anápolis", ...]
  Future<List<CityModel>> fetchCidades(String sigla) async {
    try {
      final url = Uri.parse(
        'https://servicodados.ibge.gov.br/api/v1/localidades/estados/$sigla/municipios?orderBy=nome',
      );
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json
            .map((item) => CityModel.fromJson(item))
            .toList();
      } else {
        debugPrint('❌ Erro ao buscar cidades: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar cidades: $e');
      return [];
    }
  }

  /// Busca coordenadas (latitude/longitude) de uma cidade
  /// 
  /// Retorna: {'lat': -16.686, 'lng': -49.264}
  Future<Map<String, double>?> getCityCoordinates({
    required String city,
    required String state,
  }) async {
    try {
      final data = await _callFunction('getCityCoordinates', {
        'city': city,
        'state': state,
      });

      if (data != null) {
        return {
          'lat': (data['lat'] as num).toDouble(),
          'lng': (data['lng'] as num).toDouble(),
        };
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erro ao buscar coordenadas: $e');
      return null;
    }
  }

  /// Busca sugestões de bairros no Google Places
  /// 
  /// Retorna lista de bairros que combinam com a busca
  Future<List<Map<String, dynamic>>> searchNeighborhoods({
    required String query,
    required String city,
    required String state,
    double? lat,
    double? lng,
  }) async {
    try {
      final data = await _callFunction('searchNeighborhoods', {
        'query': query,
        'city': city,
        'state': state,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });

      if (data != null && data['status'] == 'OK') {
        return List<Map<String, dynamic>>.from(
          (data['predictions'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
      return [];
    } catch (e) {
      debugPrint('❌ Erro ao buscar bairros: $e');
      return [];
    }
  }
}
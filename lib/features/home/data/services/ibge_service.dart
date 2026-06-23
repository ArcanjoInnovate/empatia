// lib/core/services/ibge_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class IbgeEstado {
  final int id;
  final String sigla;
  final String nome;

  const IbgeEstado({
    required this.id,
    required this.sigla,
    required this.nome,
  });

  factory IbgeEstado.fromJson(Map<String, dynamic> json) => IbgeEstado(
        id: json['id'] as int,
        sigla: json['sigla'] as String,
        nome: json['nome'] as String,
      );
}

class IbgeService {
  IbgeService._();
  static final IbgeService instance = IbgeService._();

  static const _base = 'https://servicodados.ibge.gov.br/api/v1/localidades';

  // Cache em memória para evitar chamadas repetidas
  List<IbgeEstado>? _estadosCache;
  final Map<String, List<String>> _cidadesCache = {};

  // ── Estados ─────────────────────────────────────────────────────────────────

  /// Retorna todos os estados ordenados por nome.
  Future<List<IbgeEstado>> fetchEstados() async {
    if (_estadosCache != null) return _estadosCache!;

    final uri = Uri.parse('$_base/estados?orderBy=nome');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('IBGE estados: HTTP ${res.statusCode}');
    }

    final list = (jsonDecode(res.body) as List)
        .map((e) => IbgeEstado.fromJson(e as Map<String, dynamic>))
        .toList();

    _estadosCache = list;
    return list;
  }

  // ── Municípios ───────────────────────────────────────────────────────────────

  /// Retorna os nomes dos municípios do estado (sigla ex: "GO") ordenados.
  Future<List<String>> fetchCidades(String estadoSigla) async {
    final key = estadoSigla.toUpperCase();
    if (_cidadesCache.containsKey(key)) return _cidadesCache[key]!;

    final uri = Uri.parse(
      '$_base/estados/$key/municipios?orderBy=nome',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('IBGE cidades ($key): HTTP ${res.statusCode}');
    }

    final list = (jsonDecode(res.body) as List)
        .map((e) => (e as Map<String, dynamic>)['nome'] as String)
        .toList();

    _cidadesCache[key] = list;
    return list;
  }

  void clearCache() {
    _estadosCache = null;
    _cidadesCache.clear();
  }
}
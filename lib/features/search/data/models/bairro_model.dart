/// 🏘️ BAIRRO MODEL
///
/// Representa um bairro retornado pela busca de bairros.
/// Como o IBGE não fornece bairros de forma estruturada, os bairros
/// são obtidos via Cloud Function (Google Places API) já existente
/// no projeto (LocationRepository.searchNeighborhoods).
///
/// Para a Fase 2, este modelo pode ser estendido com coordenadas
/// para cálculo de distância e ranking de proximidade.
class BairroModel {
  /// Nome do bairro (ex: "Jardim Tiradentes")
  final String nome;

  /// Descrição completa (ex: "Jardim Tiradentes, Aparecida de Goiânia - GO")
  final String? descricao;

  /// Latitude do centróide do bairro (preparatório Fase 2)
  final double? latitude;

  /// Longitude do centróide do bairro (preparatório Fase 2)
  final double? longitude;

  /// Identificador único usado pela fonte de dados (Google Place ID etc.)
  final String? sourceId;

  const BairroModel({
    required this.nome,
    this.descricao,
    this.latitude,
    this.longitude,
    this.sourceId,
  });

  /// Constrói a partir do Map retornado pela Cloud Function searchNeighborhoods.
  factory BairroModel.fromCloudFunction(Map<String, dynamic> map) {
    return BairroModel(
      nome: (map['neighborhood'] as String? ?? '').trim(),
      descricao: map['description'] as String?,
      latitude: (map['lat'] as num?)?.toDouble(),
      longitude: (map['lng'] as num?)?.toDouble(),
      sourceId: map['placeId'] as String?,
    );
  }

  /// Serialização para cache local (SharedPreferences futuro / Fase 2).
  Map<String, dynamic> toJson() => {
        'nome': nome,
        if (descricao != null) 'descricao': descricao,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (sourceId != null) 'sourceId': sourceId,
      };

  factory BairroModel.fromJson(Map<String, dynamic> json) => BairroModel(
        nome: json['nome'] as String,
        descricao: json['descricao'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        sourceId: json['sourceId'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is BairroModel && other.nome == nome;

  @override
  int get hashCode => nome.hashCode;

  @override
  String toString() => 'BairroModel($nome)';
}
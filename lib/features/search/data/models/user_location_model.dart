/// 📍 USER LOCATION MODEL
///
/// Armazena a localização geográfica atual do usuário obtida via GPS.
/// Utilizado para filtros de proximidade ("Próximo de mim").
///
/// Preparatório para Fase 2:
/// - Ranking de resultados por distância
/// - Sugestões baseadas em localização
/// - Raio de busca configurável
class UserLocationModel {
  /// Latitude obtida pelo GPS
  final double latitude;

  /// Longitude obtida pelo GPS
  final double longitude;

  /// Precisão em metros reportada pelo dispositivo
  final double? accuracyMeters;

  /// Momento em que a localização foi obtida (para expiração de cache)
  final DateTime obtainedAt;

  /// Nome da cidade detectada via geocodificação reversa (Fase 2)
  final String? detectedCity;

  /// Nome do estado detectado via geocodificação reversa (Fase 2)
  final String? detectedState;

  /// Sigla do estado detectado (Fase 2)
  final String? detectedStateCode;

  /// Nome do bairro detectado (Fase 2)
  final String? detectedNeighborhood;

  const UserLocationModel({
    required this.latitude,
    required this.longitude,
    required this.obtainedAt,
    this.accuracyMeters,
    this.detectedCity,
    this.detectedState,
    this.detectedStateCode,
    this.detectedNeighborhood,
  });

  /// Verifica se a localização ainda é válida (menos de 5 minutos)
  bool get isValid {
    final age = DateTime.now().difference(obtainedAt);
    return age.inMinutes < 5;
  }

  /// Cria uma cópia com campos opcionais atualizados (geocodificação reversa Fase 2)
  UserLocationModel copyWith({
    String? detectedCity,
    String? detectedState,
    String? detectedStateCode,
    String? detectedNeighborhood,
  }) {
    return UserLocationModel(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      obtainedAt: obtainedAt,
      detectedCity: detectedCity ?? this.detectedCity,
      detectedState: detectedState ?? this.detectedState,
      detectedStateCode: detectedStateCode ?? this.detectedStateCode,
      detectedNeighborhood: detectedNeighborhood ?? this.detectedNeighborhood,
    );
  }

  /// Serialização para persistência (Fase 2)
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'obtainedAt': obtainedAt.toIso8601String(),
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
        if (detectedCity != null) 'detectedCity': detectedCity,
        if (detectedState != null) 'detectedState': detectedState,
        if (detectedStateCode != null) 'detectedStateCode': detectedStateCode,
        if (detectedNeighborhood != null)
          'detectedNeighborhood': detectedNeighborhood,
      };

  factory UserLocationModel.fromJson(Map<String, dynamic> json) =>
      UserLocationModel(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        obtainedAt: DateTime.parse(json['obtainedAt'] as String),
        accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
        detectedCity: json['detectedCity'] as String?,
        detectedState: json['detectedState'] as String?,
        detectedStateCode: json['detectedStateCode'] as String?,
        detectedNeighborhood: json['detectedNeighborhood'] as String?,
      );

  @override
  String toString() =>
      'UserLocationModel(lat=$latitude, lng=$longitude, city=$detectedCity)';
}

/// Enum com o status de permissão de localização
enum LocationPermissionStatus {
  /// Permissão ainda não solicitada
  unknown,

  /// Permissão concedida
  granted,

  /// Permissão negada pelo usuário (pode ser solicitada novamente)
  denied,

  /// Permissão negada permanentemente (redirecionar para configurações)
  deniedForever,

  /// GPS/serviço de localização desativado no dispositivo
  serviceDisabled,
}
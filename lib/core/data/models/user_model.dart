import 'package:empatia/core/data/models/child_model.dart';
import 'package:empatia/core/data/models/dream_model.dart';

/// 👤 USER MODEL
///
/// activeMode removido — o usuário pode doar E receber ao mesmo tempo.
/// totalDonated e totalReceived são calculados a partir das coleções
/// Donations e Requests no Firebase (não ficam no documento do usuário).
class UserModel {
  final String? id;
  final String? name;
  final int? age;
  final String? status;
  final String? state;
  final String? city;
  final String? neighborhood;
  final double? latitude;
  final double? longitude;
  final String? profileEmoji;
  final String? activeMode;
  final String? profileImage;
  final String? sexo;
  final bool? isVerified;

  // ── Verificações individuais ──────────────────────────────
  final bool? phoneVerified;       // telefone confirmado via SMS
  final bool? emailVerified;       // e-mail confirmado
  final bool? birthDateVerified;   // data de nascimento confirmada
  final int?  birthDateVerifiedAt; // timestamp da verificação de idade
  final bool? profileCompleted;    // todos os campos obrigatórios preenchidos
  final int?  profileCompletedAt;  // timestamp de quando o perfil foi completado

  final List<ChildModel>? children;
  final List<DreamModel>? dreams;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    this.id,
    this.name,
    this.age,
    this.status,
    this.state,
    this.city,
    this.neighborhood,
    this.latitude,
    this.longitude,
    this.profileEmoji,
    this.profileImage,
    this.sexo,
    this.isVerified,
    this.activeMode,
    this.phoneVerified,
    this.emailVerified,
    this.birthDateVerified,
    this.birthDateVerifiedAt,
    this.profileCompleted,
    this.profileCompletedAt,
    this.children,
    this.dreams,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel.fromMap(json, json['id']?.toString() ?? '');
  }

  factory UserModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name']?.toString(),
      activeMode: map['activeMode']?.toString(),
      age: map['age'] != null ? int.tryParse(map['age'].toString()) : null,
      status: map['status']?.toString(),
      state: map['state']?.toString(),
      city: map['city']?.toString(),
      neighborhood: map['neighborhood']?.toString(),
      latitude: map['latitude'] != null
          ? double.tryParse(map['latitude'].toString())
          : null,
      longitude: map['longitude'] != null
          ? double.tryParse(map['longitude'].toString())
          : null,
      profileEmoji: map['profileEmoji']?.toString(),
      profileImage: map['profileImage']?.toString(),
      sexo: map['sexo']?.toString(),
      isVerified: map['isVerified'] == true,
      phoneVerified:       map['phoneVerified'] == true,
      emailVerified:       map['emailVerified'] == true,
      birthDateVerified:   map['birthDateVerified'] == true,
      birthDateVerifiedAt: map['birthDateVerifiedAt'] != null
          ? int.tryParse(map['birthDateVerifiedAt'].toString())
          : null,
      profileCompleted:   map['profileCompleted'] == true,
      profileCompletedAt: map['profileCompletedAt'] != null
          ? int.tryParse(map['profileCompletedAt'].toString())
          : null,
      children: map['children'] != null
          ? (map['children'] as Map<dynamic, dynamic>)
              .entries
              .map((e) => ChildModel.fromMap(
                    Map<dynamic, dynamic>.from(e.value),
                    e.key.toString(),
                  ))
              .toList()
          : [],
      dreams: map['dreams'] != null
          ? (map['dreams'] as Map<dynamic, dynamic>)
              .entries
              .map((e) => DreamModel.fromMap(
                    Map<dynamic, dynamic>.from(e.value),
                    e.key.toString(),
                  ))
              .toList()
          : [],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.parse(map['createdAt'].toString()))
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.parse(map['updatedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (name != null) 'name': name,
      if (age != null) 'age': age,
      'status': status,
      'state': state,
      'city': city,
      'neighborhood': neighborhood,
      'latitude': latitude,
      'longitude': longitude,
      if (profileEmoji != null) 'profileEmoji': profileEmoji,
      if (profileImage != null) 'profileImage': profileImage,
      if (sexo != null) 'sexo': sexo,
      if (isVerified != null) 'isVerified': isVerified,
      // Não escrevemos os campos de verificação aqui — eles são gravados
      // por métodos dedicados no Repository (markProfileCompleted, etc.)
      // para evitar sobrescrever acidentalmente com null num update de perfil.
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    int? age,
    String? status,
    String? state,
    String? city,
    String? neighborhood,
    double? latitude,
    double? longitude,
    String? profileEmoji,
    String? profileImage,
    String? activeMode,
    String? sexo,
    bool? isVerified,
    bool? phoneVerified,
    bool? emailVerified,
    bool? birthDateVerified,
    int?  birthDateVerifiedAt,
    bool? profileCompleted,
    int?  profileCompletedAt,
    List<ChildModel>? children,
    List<DreamModel>? dreams,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      status: status ?? this.status,
      state: state ?? this.state,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      profileEmoji: profileEmoji ?? this.profileEmoji,
      profileImage: profileImage ?? this.profileImage,
      sexo: sexo ?? this.sexo,
      activeMode: activeMode ?? this.activeMode,
      isVerified: isVerified ?? this.isVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      birthDateVerified: birthDateVerified ?? this.birthDateVerified,
      birthDateVerifiedAt: birthDateVerifiedAt ?? this.birthDateVerifiedAt,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      profileCompletedAt: profileCompletedAt ?? this.profileCompletedAt,
      children: children ?? this.children,
      dreams: dreams ?? this.dreams,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
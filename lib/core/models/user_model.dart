import 'package:empatia/core/models/child_model.dart';
import 'package:empatia/core/models/dream_model.dart';

class UserModel {
  final String? id;
  final String? name;
  final int? age;
  final String? status;
  final String? state;
  final String? city;
  final String? neighborhood;
  final double? latitude;      // ← NOVO
  final double? longitude;     // ← NOVO
  final String? profileEmoji;
  final String? profileImage;
  final String? sexo;
  final bool? isVerified;
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
    this.latitude,      // ← NOVO
    this.longitude,     // ← NOVO
    this.profileEmoji,
    this.profileImage,
    this.sexo,
    this.isVerified,
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
      age: map['age'] != null ? int.tryParse(map['age'].toString()) : null,
      status: map['status']?.toString(),
      state: map['state']?.toString(),
      city: map['city']?.toString(),
      neighborhood: map['neighborhood']?.toString(),
      latitude: map['latitude'] != null        // ← NOVO
          ? double.tryParse(map['latitude'].toString())
          : null,
      longitude: map['longitude'] != null      // ← NOVO
          ? double.tryParse(map['longitude'].toString())
          : null,
      profileEmoji: map['profileEmoji']?.toString(),
      profileImage: map['profileImage']?.toString(),
      sexo: map['sexo']?.toString(),
      isVerified: map['isVerified'] == true,
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
      'latitude': latitude,        // ← NOVO (null apaga no Firebase)
      'longitude': longitude,      // ← NOVO (null apaga no Firebase)
      if (profileEmoji != null) 'profileEmoji': profileEmoji,
      if (profileImage != null) 'profileImage': profileImage,
      if (sexo != null) 'sexo': sexo,
      if (isVerified != null) 'isVerified': isVerified,
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
    double? latitude,        // ← NOVO
    double? longitude,       // ← NOVO
    String? profileEmoji,
    String? profileImage,
    String? sexo,
    bool? isVerified,
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
      latitude: latitude ?? this.latitude,          // ← NOVO
      longitude: longitude ?? this.longitude,        // ← NOVO
      profileEmoji: profileEmoji ?? this.profileEmoji,
      profileImage: profileImage ?? this.profileImage,
      sexo: sexo ?? this.sexo,
      isVerified: isVerified ?? this.isVerified,
      children: children ?? this.children,
      dreams: dreams ?? this.dreams,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
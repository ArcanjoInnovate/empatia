class AccountInfoModel {
  final String  email;
  final bool    emailVerified;
  final DateTime? updatedAt;

  const AccountInfoModel({
    required this.email,
    this.emailVerified = false,
    this.updatedAt,
  });

  factory AccountInfoModel.fromMap(Map<dynamic, dynamic> map) {
    return AccountInfoModel(
      email:         map['email']         as String? ?? '',
      emailVerified: map['emailVerified'] as bool?   ?? false,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }

  AccountInfoModel copyWith({
    String? email,
    bool?   emailVerified,
  }) {
    return AccountInfoModel(
      email:         email         ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      updatedAt:     DateTime.now(),
    );
  }

  String get displayEmail => email.isNotEmpty ? email : '—';
}
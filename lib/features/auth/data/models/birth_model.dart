class BirthDateModel {
  final DateTime birthDate;
  final int age;
  final bool isVerified;
  final DateTime? verifiedAt;

  BirthDateModel({
    required this.birthDate,
    required this.age,
    this.isVerified = false,
    this.verifiedAt,
  });

  // Cria instância calculando a idade automaticamente
  factory BirthDateModel.fromBirthDate(DateTime birthDate) {
    final age = _calculateAge(birthDate);
    return BirthDateModel(
      birthDate: birthDate,
      age: age,
      isVerified: false,
    );
  }

  // Cria instância a partir do Firebase
  factory BirthDateModel.fromJson(Map<String, dynamic> json) {
    return BirthDateModel(
      birthDate: DateTime.fromMillisecondsSinceEpoch(json['birthDate'] as int),
      age: json['age'] as int,
      isVerified: json['isVerified'] as bool? ?? false,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['verifiedAt'] as int)
          : null,
    );
  }

  // Converte para Map para salvar no Firebase
  Map<String, dynamic> toJson() {
    return {
      'birthDate': birthDate.millisecondsSinceEpoch,
      'age': age,
      'isVerified': isVerified,
      'verifiedAt': verifiedAt?.millisecondsSinceEpoch,
    };
  }

  // Cria uma cópia marcada como verificada
  BirthDateModel copyWithVerified() {
    return BirthDateModel(
      birthDate: birthDate,
      age: age,
      isVerified: true,
      verifiedAt: DateTime.now(),
    );
  }

  // Valida se o usuário tem pelo menos 18 anos
  bool isAdult() => age >= 18;

  // Retorna a data formatada (DD/MM/YYYY)
  String get formattedDate {
    return '${birthDate.day.toString().padLeft(2, '0')}/'
        '${birthDate.month.toString().padLeft(2, '0')}/'
        '${birthDate.year}';
  }

  static int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  String toString() =>
      'BirthDateModel(birthDate: $formattedDate, age: $age, isVerified: $isVerified)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BirthDateModel &&
        other.birthDate == birthDate &&
        other.age == age &&
        other.isVerified == isVerified;
  }

  @override
  int get hashCode => Object.hash(birthDate, age, isVerified);
}
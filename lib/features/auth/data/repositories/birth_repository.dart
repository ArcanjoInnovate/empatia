import 'package:empatia/features/auth/data/models/birth_model.dart';
import 'package:empatia/features/auth/data/service/birth_service.dart';


class BirthDateRepository {
  final BirthDateService _service;

  BirthDateRepository({BirthDateService? service})
      : _service = service ?? BirthDateService();

  /// Valida e salva a data de nascimento
  /// 
  /// Retorna: Success(true) ou Failure com mensagem de erro
  Future<BirthDateResult> validateAndSaveBirthDate({
    required String userId,
    required DateTime birthDate,
  }) async {
    try {
      // Validação 1: Data não pode ser futura
      if (birthDate.isAfter(DateTime.now())) {
        return BirthDateResult.failure('A data não pode ser no futuro.');
      }

      // Validação 2: Calcula idade
      final age = _calculateAge(birthDate);

      // Validação 3: Idade mínima de 18 anos
      if (age < 18) {
        return BirthDateResult.failure(
          'Você precisa ter pelo menos 18 anos para usar o Empatia.',
        );
      }

      // Validação 4: Idade máxima razoável (120 anos)
      if (age > 120) {
        return BirthDateResult.failure(
          'Por favor, verifique a data inserida. A idade parece incorreta.',
        );
      }

      // Cria o model
      final birthDateModel = BirthDateModel(
        birthDate: birthDate,
        age: age,
        isVerified: true,
        verifiedAt: DateTime.now(),
      );

      // Salva no Firebase
      await _service.saveBirthDate(
        userId: userId,
        birthDateModel: birthDateModel,
      );

      return BirthDateResult.success(birthDateModel);
    } catch (e) {
      return BirthDateResult.failure(
        'Erro ao salvar data de nascimento: ${e.toString()}',
      );
    }
  }

  /// Busca a data de nascimento do usuário
  Future<BirthDateModel?> getBirthDate(String userId) async {
    try {
      return await _service.getBirthDate(userId);
    } catch (e) {
      return null;
    }
  }

  /// Verifica se o usuário já cadastrou a data de nascimento
  Future<bool> hasBirthDate(String userId) async {
    return await _service.hasBirthDate(userId);
  }

  /// Verifica se o usuário é maior de idade
  Future<bool> isAdult(String userId) async {
    final birthDateModel = await getBirthDate(userId);
    return birthDateModel?.isAdult() ?? false;
  }

  /// Valida uma data de nascimento sem salvar
  BirthDateValidation validateBirthDate(DateTime birthDate) {
    // Data não pode ser futura
    if (birthDate.isAfter(DateTime.now())) {
      return BirthDateValidation(
        isValid: false,
        errorMessage: 'A data não pode ser no futuro.',
      );
    }

    // Calcula idade
    final age = _calculateAge(birthDate);

    // Idade mínima
    if (age < 18) {
      return BirthDateValidation(
        isValid: false,
        errorMessage: 'Você precisa ter pelo menos 18 anos.',
        age: age,
      );
    }

    // Idade máxima
    if (age > 120) {
      return BirthDateValidation(
        isValid: false,
        errorMessage: 'Por favor, verifique a data inserida.',
        age: age,
      );
    }

    return BirthDateValidation(
      isValid: true,
      age: age,
    );
  }

  // Calcula a idade
  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}

/// Resultado da operação de salvar data de nascimento
class BirthDateResult {
  final bool success;
  final String? errorMessage;
  final BirthDateModel? data;

  BirthDateResult._({
    required this.success,
    this.errorMessage,
    this.data,
  });

  factory BirthDateResult.success(BirthDateModel data) {
    return BirthDateResult._(
      success: true,
      data: data,
    );
  }

  factory BirthDateResult.failure(String errorMessage) {
    return BirthDateResult._(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// Resultado da validação de data de nascimento
class BirthDateValidation {
  final bool isValid;
  final String? errorMessage;
  final int? age;

  BirthDateValidation({
    required this.isValid,
    this.errorMessage,
    this.age,
  });
}
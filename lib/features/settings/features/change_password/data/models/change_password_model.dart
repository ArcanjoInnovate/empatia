/// Resultado de uma operação de troca de senha.
class ChangePasswordResult {
  final bool    success;
  final String? errorMessage;

  const ChangePasswordResult._({
    required this.success,
    this.errorMessage,
  });

  factory ChangePasswordResult.success() =>
      const ChangePasswordResult._(success: true);

  factory ChangePasswordResult.failure(String message) =>
      ChangePasswordResult._(success: false, errorMessage: message);
}
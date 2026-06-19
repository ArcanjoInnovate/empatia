import 'package:empatia/features/settings/features/change_password/data/models/change_password_model.dart';
import 'package:empatia/features/settings/features/change_password/data/services/change_password_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Responsabilidade: orquestrar a troca de senha.
///
/// Fluxo:
///  1. Valida entradas (campos vazios, tamanho mínimo, senha igual à atual).
///  2. Reautentica o usuário com a senha atual (exigido pelo Firebase para
///     operações sensíveis).
///  3. Chama [updatePassword] no Firebase Auth.
///  4. Registra o timestamp de atualização no RTDB via [ChangePasswordService].
class ChangePasswordRepository {
  final ChangePasswordService _service;
  final FirebaseAuth          _auth;

  ChangePasswordRepository({
    ChangePasswordService? service,
    FirebaseAuth?           auth,
  })  : _service = service ?? ChangePasswordService(),
        _auth    = auth    ?? FirebaseAuth.instance;

  // ─── TROCAR SENHA ─────────────────────────────────────────────────────────

  Future<ChangePasswordResult> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return ChangePasswordResult.failure('Usuário não autenticado.');
    }

    // ── Validações básicas ────────────────────────────────────────────────
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      return ChangePasswordResult.failure('Preencha todos os campos.');
    }

    if (newPassword.length < 6) {
      return ChangePasswordResult.failure(
          'A nova senha precisa ter pelo menos 6 caracteres.');
    }

    if (currentPassword == newPassword) {
      return ChangePasswordResult.failure(
          'A nova senha deve ser diferente da atual.');
    }

    try {
      // ── Reautenticação ────────────────────────────────────────────────────
      // O Firebase exige reautenticação recente para operações sensíveis.
      final credential = EmailAuthProvider.credential(
        email:    user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // ── Atualiza a senha no Auth ───────────────────────────────────────────
      await user.updatePassword(newPassword);

      // ── Registra no RTDB ──────────────────────────────────────────────────
      await _service.recordPasswordUpdated(user.uid);

      return ChangePasswordResult.success();
    } on FirebaseAuthException catch (e) {
      return ChangePasswordResult.failure(_mapAuthError(e));
    } catch (_) {
      return ChangePasswordResult.failure(
          'Erro ao atualizar senha. Tente novamente.');
    }
  }

  // ─── MAPEAMENTO DE ERROS ──────────────────────────────────────────────────

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Senha atual incorreta. Tente novamente.';
      case 'weak-password':
        return 'Senha fraca! Use letras, números e símbolos.';
      case 'requires-recent-login':
        return 'Por segurança, faça login novamente e tente outra vez.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um momento e tente de novo.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'operation-not-allowed':
        return 'Operação não permitida. Verifique as configurações do app.';
      default:
        return e.message ?? 'Erro ao atualizar senha.';
    }
  }
}
import 'package:empatia/features/settings/features/change_password/data/repositories/change_password_repository.dart';
import 'package:flutter/foundation.dart';

enum ChangePasswordStatus { idle, loading, success, error }

/// Controller de troca de senha.
///
/// Expõe estado granular para a UI:
///  - [status]  → estado geral da operação
///  - [loading] → exibe indicador de progresso no botão
///  - [error]   → mensagem de erro a exibir na tela
///
/// A UI chama [updatePassword] e reage às notificações.
/// Chame [clearError] ao reabrir ou limpar o formulário.
class ChangePasswordController extends ChangeNotifier {
  final ChangePasswordRepository _repository;

  ChangePasswordController({ChangePasswordRepository? repository})
      : _repository = repository ?? ChangePasswordRepository();

  // ─── STATE ────────────────────────────────────────────────────────────────

  ChangePasswordStatus _status  = ChangePasswordStatus.idle;
  ChangePasswordStatus get status => _status;

  bool    _loading = false;
  bool    get loading => _loading;

  String? _error;
  String? get error => _error;

  // ─── TROCAR SENHA ─────────────────────────────────────────────────────────
  /// Retorna [true] se a senha foi trocada com sucesso.

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _loading = true;
    _error   = null;
    _status  = ChangePasswordStatus.loading;
    notifyListeners();

    final result = await _repository.updatePassword(
      currentPassword: currentPassword,
      newPassword:     newPassword,
    );

    _loading = false;

    if (result.success) {
      _status = ChangePasswordStatus.success;
    } else {
      _error  = result.errorMessage;
      _status = ChangePasswordStatus.error;
    }

    notifyListeners();
    return result.success;
  }

  // ─── LIMPAR ERRO ──────────────────────────────────────────────────────────

  void clearError() {
    _error  = null;
    _status = ChangePasswordStatus.idle;
    notifyListeners();
  }

  // ─── DISPOSE ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    super.dispose();
  }
}
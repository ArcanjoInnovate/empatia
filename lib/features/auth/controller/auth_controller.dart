import 'package:empatia/core/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/service/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<String?> loginUser(String email, String password) async {
    try {
      // login() já chama _syncEmailIfNeeded internamente
      await _authService.login(email, password);
      return 'success';
    } on FirebaseAuthException catch (e) {
      return _mapErrorLogin(e);
    } catch (_) {
      return 'Erro inesperado';
    }
  }

  Future<String?> registerUser(String email, String password) async {
    try {
      await _authService.register(email, password);
      return 'success';
    } on FirebaseAuthException catch (e) {
      return _mapErrorRegister(e);
    } catch (_) {
      return 'Erro inesperado';
    }
  }

  /// Cadastro completo: só cria a conta quando email + senha + data de
  /// nascimento já foram validados na UI. Nada vai pro Firebase antes disso.
  Future<String?> registerUserWithBirthDate({
    required String email,
    required String password,
    required DateTime birthDate,
  }) async {
    try {
      await _authService.registerWithBirthDate(
        email:     email,
        password:  password,
        birthDate: birthDate,
      );
      return 'success';
    } on FirebaseAuthException catch (e) {
      return _mapErrorRegister(e);
    } catch (_) {
      return 'Erro inesperado';
    }
  }

  Future<UserModel?> getUserData() async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) return null;
      return await _authService.getUserData(currentUser.uid);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) throw Exception('Usuário não autenticado');
    await _authService.updateUserData(currentUser.uid, data);
  }

  Future<void> logout() async => _authService.logout();

  String? getCurrentUid() => _authService.getCurrentUser()?.uid;

  // ─── MAPEAMENTO DE ERROS ──────────────────────────────────────────────────

  String _mapErrorLogin(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Ops! Não achamos essa conta 🔍✨';
      case 'wrong-password':
        return 'Senha errada! Tenta de novo 🔑💫';
      case 'invalid-email':
        return 'Email estranho! Confere aí 📧✨';
      case 'invalid-credential':
        return 'Email ou senha tá errado! 😅💫';
      case 'user-disabled':
        return 'Essa conta tá desativada 🚫✨';
      case 'too-many-requests':
        return 'Calma! Muitas tentativas 🕐💫';
      case 'network-request-failed':
        return 'Sem internet! Liga o Wi-Fi 📶✨';
      default:
        return 'Algo deu errado! 😅💫';
    }
  }

  Future<String?> sendResetEmail(String email) async {
    if (email.isEmpty) {
      return 'Cadê o email? 📧✨';
    }

    if (!email.contains('@') || !email.contains('.')) {
      return 'Email tá estranho! Confere aí 🤔💫';
    }

    try {
      await _authService.sendPasswordReset(email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (e) {
      // Captura erros genéricos (PlatformException, erros de rede não-Firebase)
      // e expõe a mensagem real em vez de engolir silenciosamente.
      debugPrint('[sendResetEmail] Erro inesperado: $e');
      return 'Algo deu errado! Tenta de novo 😅💫';
    }
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        // Com "Email Enumeration Protection" ativado no Firebase Console
        // esse código nunca é lançado — o Firebase retorna sucesso silencioso.
        // Mantido aqui para projetos com a proteção desativada.
        return 'Não achei nenhuma conta com esse email 👀';
      case 'invalid-email':
        return 'Email tá estranho! Confere aí 📧💫';
      case 'too-many-requests':
        return 'Calma! Muitas tentativas, tenta mais tarde 🕐💫';
      case 'network-request-failed':
        return 'Sem internet! Liga o Wi-Fi 📶✨';
      default:
        return 'Erro inesperado 😵';
    }
  }

  String _mapErrorRegister(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Ops! Email já cadastrado! 📧✨';
      case 'invalid-email':
        return 'Email tá estranho! Confere? 🤔💫';
      case 'weak-password':
        return 'Senha fraquinha! Capricha mais 💪🌟';
      case 'network-request-failed':
        return 'Sem internet! Liga o Wi-Fi 📶✨';
      default:
        return 'Algo deu errado! 😅💫';
    }
  }
}
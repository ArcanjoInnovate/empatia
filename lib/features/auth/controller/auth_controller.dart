import 'package:empatia/core/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<String?> loginUser(String email, String password) async {
    try {
      await _authService.login(email, password);
      return "success";
    } on FirebaseAuthException catch (e) {
      return _mapErrorLogin(e);
    } catch (e) {
      return "Erro inesperado";
    }
  }

  Future<String?> registerUser(String email, String password) async {
    try {
      await _authService.register(email, password);
      return "success";
    } on FirebaseAuthException catch (e) {
      return _mapErrorRegister(e);
    } catch (e) {
      return "Erro inesperado";
    }
  }

  Future<UserModel?> getUserData() async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) return null;
      
      final userData = await _authService.getUserData(currentUser.uid);
      return userData;
    } catch (e) {
      print('Erro ao buscar dados do usuário: $e');
      return null;
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) throw Exception('Usuário não autenticado');
      
      await _authService.updateUserData(currentUser.uid, data);
    } catch (e) {
      print('Erro ao atualizar dados do usuário: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

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
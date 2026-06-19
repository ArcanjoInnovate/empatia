import 'dart:convert';

import 'package:empatia/features/settings/features/account_information/data/models/account_info_model.dart';
import 'package:empatia/features/settings/features/account_information/data/service/account_info_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// ─── URLs das Cloud Functions ─────────────────────────────────────────────────
const _kSyncEmailUrl =
    'https://syncemailnow-ebyemfp7ta-rj.a.run.app';
const _kSendEmailChangeUrl =
    'https://southamerica-east1-empatia-34400.cloudfunctions.net/sendEmailChangeVerification';

class AccountInfoResult {
  final bool    success;
  final String? errorMessage;

  const AccountInfoResult._({required this.success, this.errorMessage});

  factory AccountInfoResult.success() =>
      const AccountInfoResult._(success: true);

  factory AccountInfoResult.failure(String message) =>
      AccountInfoResult._(success: false, errorMessage: message);
}

class AccountInfoRepository {
  final AccountInfoService _service;
  final FirebaseAuth        _auth;

  AccountInfoRepository({
    AccountInfoService? service,
    FirebaseAuth?        auth,
  })  : _service = service ?? AccountInfoService(),
        _auth    = auth    ?? FirebaseAuth.instance;

  // ─── BUSCAR ────────────────────────────────────────────────────────────────

  Future<AccountInfoModel?> getUserInfo() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      final model = await _service.getUserInfo(uid);
      if (model != null && model.email.isEmpty) {
        return model.copyWith(email: _auth.currentUser?.email ?? '');
      }
      return model;
    } catch (_) {
      return AccountInfoModel(
        email: _auth.currentUser?.email ?? '',
      );
    }
  }

  // ─── ALTERAR E-MAIL ────────────────────────────────────────────────────────

  Future<AccountInfoResult> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return AccountInfoResult.failure('Usuário não autenticado.');
    }

    if (!_isValidEmail(newEmail)) {
      return AccountInfoResult.failure('Formato de e-mail inválido.');
    }

    if (newEmail == user.email) {
      return AccountInfoResult.failure('O novo e-mail é igual ao atual.');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email:    user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      final sent = await _sendEmailChangeVerification(
        user:     user,
        newEmail: newEmail,
      );
      if (!sent) {
        return AccountInfoResult.failure('Erro ao enviar e-mail de verificação. Tente novamente.');
      }

      return AccountInfoResult.success();
    } on FirebaseAuthException catch (e) {
      return AccountInfoResult.failure(_authError(e));
    } catch (_) {
      return AccountInfoResult.failure('Erro ao atualizar e-mail. Tente novamente.');
    }
  }

  // ─── SINCRONIZAR E-MAIL VIA CLOUD FUNCTION ────────────────────────────────

  Future<void> syncEmailViaCloudFunction(User user) async {
    try {
      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse(_kSyncEmailUrl),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final synced = body['synced'] as bool? ?? false;
        assert(() {
          // ignore: avoid_print
          print('[syncEmailNow] synced=$synced email=${body['email']}');
          return true;
        }());
      }
    } catch (_) {
      // Silencia — a Cloud Function beforeUserSignedIn é o fallback principal
    }
  }

  // ─── ENVIAR E-MAIL DE TROCA ───────────────────────────────────────────────

  Future<bool> _sendEmailChangeVerification({
    required User   user,
    required String newEmail,
  }) async {
    try {
      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse(_kSendEmailChangeUrl),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'newEmail': newEmail}),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Senha incorreta. Tente novamente.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso por outra conta.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'requires-recent-login':
        return 'Por segurança, faça login novamente e tente outra vez.';
      case 'operation-not-allowed':
        return 'Operação não permitida. Verifique as configurações do app.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return e.message ?? 'Erro ao atualizar e-mail.';
    }
  }
}
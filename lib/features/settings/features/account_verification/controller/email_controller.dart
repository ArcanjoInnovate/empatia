import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Controller exclusivo da feature de verificação de e-mail nas configurações.
class EmailVerificationController {
  EmailVerificationController({
    FirebaseAuth? auth,
    FirebaseDatabase? database,
    http.Client? httpClient,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _database = database ?? FirebaseDatabase.instance,
        _httpClient = httpClient ?? http.Client();

  final FirebaseAuth _auth;
  final FirebaseDatabase _database;
  final http.Client _httpClient;

  // ─── CONFIGURAÇÃO ─────────────────────────────────────────────────────────────
  // Pegue a URL exata no Firebase Console → Functions → copie a URL da função.
  static const String _functionUrl =
      'https://southamerica-east1-empatia-34400.cloudfunctions.net/sendEmailVerification';

  // ─── GETTERS ──────────────────────────────────────────────────────────────────

  String? get currentEmail => _auth.currentUser?.email;

  // ─── VERIFICAÇÃO ──────────────────────────────────────────────────────────────

  Future<bool> checkEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      final verified = _auth.currentUser?.emailVerified ?? false;
      debugPrint('[EmailVerification] checkEmailVerified → $verified');

      // ── Espelha no RTDB assim que confirmado, igual ao phoneVerified ──────
      if (verified) {
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          await _database.ref('Users/$uid').update({
            'emailVerified':   true,
            'emailVerifiedAt': DateTime.now().millisecondsSinceEpoch,
            'updatedAt':       DateTime.now().millisecondsSinceEpoch,
          });
          debugPrint('[EmailVerification] emailVerified salvo no RTDB');

          // ── Cross-check: perfil também completo? → isVerified ──────────
          final profileSnap = await _database
              .ref('Users/$uid/profileCompleted')
              .get();
          if (profileSnap.value == true) {
            await _database.ref('Users/$uid').update({
              'isVerified':   true,
              'isVerifiedAt': DateTime.now().millisecondsSinceEpoch,
              'updatedAt':    DateTime.now().millisecondsSinceEpoch,
            });
            debugPrint('[EmailVerification] isVerified = true gravado no RTDB');
          }
          // ────────────────────────────────────────────────────────────────
        }
      }
      // ──────────────────────────────────────────────────────────────────────

      return verified;
    } on FirebaseAuthException catch (e) {
      debugPrint('[EmailVerification] checkEmailVerified FirebaseError: ${e.code}');
      throw EmailVerificationException(
        code: e.code,
        message: _mapFirebaseError(e.code),
      );
    } catch (e) {
      debugPrint('[EmailVerification] checkEmailVerified erro: $e');
      throw const EmailVerificationException(
        code: 'unknown',
        message: 'Erro ao verificar o status do e-mail. Tente novamente.',
      );
    }
  }

  // ─── ENVIO VIA CLOUD FUNCTION ────────────────────────────────────────────────

  Future<String?> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        debugPrint('[EmailVerification] sendVerificationEmail → usuário nulo');
        return 'Nenhum usuário autenticado encontrado.';
      }

      debugPrint('[EmailVerification] uid=${user.uid} email=${user.email} emailVerified=${user.emailVerified}');

      if (user.emailVerified) {
        debugPrint('[EmailVerification] e-mail já verificado, sincronizando RTDB');
        await _database.ref('Users/${user.uid}').update({
          'emailVerified':   true,
          'emailVerifiedAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt':       DateTime.now().millisecondsSinceEpoch,
        });
        debugPrint('[EmailVerification] emailVerified sincronizado no RTDB');

        // ── Cross-check: perfil também completo? → isVerified ────────────
        final profileSnap = await _database
            .ref('Users/${user.uid}/profileCompleted')
            .get();
        if (profileSnap.value == true) {
          await _database.ref('Users/${user.uid}').update({
            'isVerified':   true,
            'isVerifiedAt': DateTime.now().millisecondsSinceEpoch,
            'updatedAt':    DateTime.now().millisecondsSinceEpoch,
          });
          debugPrint('[EmailVerification] isVerified = true gravado no RTDB');
        }
        // ─────────────────────────────────────────────────────────────────

        return null;
      }

      // getIdToken() retorna String (não anulável) nas versões recentes do firebase_auth.
      // forceRefresh: true garante token atualizado.
      final String idToken = await user.getIdToken(true) ?? '';

      if (idToken.isEmpty) {
        debugPrint('[EmailVerification] ID token vazio');
        return 'Não foi possível obter o token de autenticação.';
      }

      debugPrint('[EmailVerification] chamando Cloud Function → $_functionUrl');

      final response = await _httpClient
          .post(
            Uri.parse(_functionUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({}),
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              debugPrint('[EmailVerification] timeout ao chamar a Cloud Function');
              throw const EmailVerificationException(
                code: 'timeout',
                message: 'O servidor demorou para responder. Tente novamente.',
              );
            },
          );

      debugPrint('[EmailVerification] statusCode=${response.statusCode}');
      debugPrint('[EmailVerification] body=${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final alreadyVerified = body['alreadyVerified'] as bool? ?? false;
        debugPrint('[EmailVerification] sucesso — alreadyVerified=$alreadyVerified');
        return null;
      }

      // Tenta extrair mensagem de erro da resposta
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final serverError = body['error'] as String?;
        debugPrint('[EmailVerification] erro do servidor: $serverError');
        return serverError ?? 'Erro ${response.statusCode} ao enviar o e-mail.';
      } catch (_) {
        return 'Erro ${response.statusCode} ao enviar o e-mail.';
      }
    } on EmailVerificationException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      debugPrint('[EmailVerification] FirebaseAuthException: ${e.code}');
      return _mapFirebaseError(e.code);
    } catch (e) {
      debugPrint('[EmailVerification] erro inesperado: $e');
      return 'Erro inesperado ao enviar o e-mail. Tente novamente.';
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────────

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      case 'user-not-found':
        return 'Usuário não encontrado. Faça login novamente.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede.';
      default:
        return 'Ocorreu um erro inesperado ($code). Tente novamente.';
    }
  }
}

// ─── EXCEPTION ───────────────────────────────────────────────────────────────

class EmailVerificationException implements Exception {
  const EmailVerificationException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => 'EmailVerificationException($code): $message';
}
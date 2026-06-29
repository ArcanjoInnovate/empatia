// lib/core/services/fcm_service.dart
//
// Responsabilidade única: obter o token FCM do dispositivo
// e mantê-lo sincronizado no RTDB em Users/{uid}/fcmToken.
//
// Por que no RTDB e não no Firestore?
//   O projeto usa Firebase RTDB como banco principal.
//   Gravar o token aqui evita dependência de outro SDK.
//
// Uso:
//   await FcmService.init(uid);  // chamado uma vez após login
// ─────────────────────────────────────────────────────────────

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  FcmService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _db        = FirebaseDatabase.instance.ref();

  // ══════════════════════════════════════════════════════════
  // INIT — chame uma vez logo após identificar o uid
  // ══════════════════════════════════════════════════════════

  static Future<void> init(String uid) async {
    if (uid.isEmpty) return;

    try {
      // Pede permissão (iOS/macOS — no Android é automático)
      await _messaging.requestPermission(
        alert:      true,
        badge:      true,
        sound:      true,
        provisional: false,
      );

      // Salva o token atual
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(uid, token);

      // Atualiza automaticamente quando o token é renovado
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _saveToken(uid, newToken).catchError(
          (e) => debugPrint('[FcmService] onTokenRefresh error: $e'),
        );
      });
    } catch (e) {
      // Não crítico — app funciona sem FCM
      debugPrint('[FcmService] init error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  // CLEAR — chame no logout para não entregar push para
  //         a sessão encerrada
  // ══════════════════════════════════════════════════════════

  static Future<void> clear(String uid) async {
    if (uid.isEmpty) return;
    try {
      await _db.child('Users/$uid/fcmToken').remove();
    } catch (e) {
      debugPrint('[FcmService] clear error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  // PRIVADO
  // ══════════════════════════════════════════════════════════

  static Future<void> _saveToken(String uid, String token) async {
    await _db.child('Users/$uid/fcmToken').set(token);
    debugPrint('[FcmService] token salvo → $uid');
  }
}
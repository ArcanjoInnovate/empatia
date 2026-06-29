// lib/features/notifications/data/repository/notification_repository.dart

import 'dart:async';
import 'package:empatia/features/notification/data/model/notification_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class NotificationRepository {
  NotificationRepository._();
  static final NotificationRepository instance = NotificationRepository._();

  final _db = FirebaseDatabase.instance.ref();

  // ── Referências ───────────────────────────────────────────────
  DatabaseReference _userNotifs(String uid) =>
      _db.child('Notifications').child(uid);

  DatabaseReference _broadcast() =>
      _db.child('Notifications').child('broadcast');

  // ════════════════════════════════════════════════════════════════
  // STREAMS
  // ════════════════════════════════════════════════════════════════

  /// Stream das notificações relevantes do usuário (últimas 50, recentes primeiro).
  /// Exclui notificações de chat puro (message / first_message) — essas o
  /// usuário já acompanha dentro do próprio chat.
  Stream<List<AppNotification>> userNotificationsStream(String uid) {
    return _userNotifs(uid)
        .orderByChild('timestamp')
        .limitToLast(50)
        .onValue
        .map((event) => _parseNotifications(event.snapshot));
  }

  /// Stream da notificação de broadcast (ranking reset).
  /// Emite null quando não há broadcast recente (< 7 dias).
  Stream<AppNotification?> broadcastStream() {
    return _broadcast().onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value is! Map) return null;
      final map = event.snapshot.value as Map;
      final n = AppNotification.fromMap(map, 'broadcast');
      // Ignora broadcasts com mais de 7 dias
      final age = DateTime.now().millisecondsSinceEpoch - n.timestamp;
      if (age > const Duration(days: 7).inMilliseconds) return null;
      return n;
    });
  }

  // ════════════════════════════════════════════════════════════════
  // CONTAGEM DE NÃO LIDAS
  // ════════════════════════════════════════════════════════════════

  Stream<int> unreadCountStream(String uid) {
    return userNotificationsStream(uid).map(
      (list) => list.where((n) => !n.read).length,
    );
  }

  // ════════════════════════════════════════════════════════════════
  // MARCAR COMO LIDA
  // ════════════════════════════════════════════════════════════════

  Future<void> markAsRead(String uid, String notifId) async {
    try {
      await _userNotifs(uid).child(notifId).update({'read': true});
    } catch (e) {
      debugPrint('[NotificationRepository] markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead(String uid) async {
    try {
      final snap = await _userNotifs(uid).get();
      if (!snap.exists || snap.value is! Map) return;
      final updates = <String, dynamic>{};
      (snap.value as Map).forEach((key, val) {
        if (val is Map && val['read'] != true) {
          updates['Notifications/$uid/$key/read'] = true;
        }
      });
      if (updates.isNotEmpty) await _db.update(updates);
    } catch (e) {
      debugPrint('[NotificationRepository] markAllAsRead error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════

  List<AppNotification> _parseNotifications(DataSnapshot snapshot) {
    if (!snapshot.exists || snapshot.value is! Map) return [];
    final list = <AppNotification>[];
    (snapshot.value as Map).forEach((key, val) {
      if (val is Map) {
        final n = AppNotification.fromMap(val, key.toString());
        // Filtra notificações de chat puro — não relevantes nesta tela
        if (!n.type.isChatOnly) {
          list.add(n);
        }
      }
    });
    // Mais recentes primeiro
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }
}
// lib/features/home/data/repositories/user_stats_repository.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════
// MODEL
// ══════════════════════════════════════════════════════════════

class UserStats {
  /// Quantas doações o usuário fez no mês corrente.
  /// Alimenta "Você ajudou X famílias este mês".
  final int donatedThisMonth;

  /// Quantos sonhos o usuário recebeu (como receptor) — all-time.
  /// Só exibido quando [donatedThisMonth] == 0.
  final int dreamsReceived;

  /// Posição no ranking semanal (1-indexed). Null = não ranqueado.
  final int? rankingPosition;

  const UserStats({
    this.donatedThisMonth = 0,
    this.dreamsReceived   = 0,
    this.rankingPosition,
  });

  /// Usuário nunca interagiu com nada ainda.
  bool get isEmpty => donatedThisMonth == 0 && dreamsReceived == 0;
}

// ══════════════════════════════════════════════════════════════
// REPOSITORY
// ══════════════════════════════════════════════════════════════

class UserStatsRepository {
  UserStatsRepository._();
  static final UserStatsRepository instance = UserStatsRepository._();

  final _db = FirebaseDatabase.instance.ref();

  // ── Chave da semana ISO — igual à usada em chat_repository ─────
  String _weekKey() {
    final now  = DateTime.now();
    final year = now.year;
    final week =
        ((now.difference(DateTime(year, 1, 1)).inDays) / 7).ceil();
    return '$year-W${week.toString().padLeft(2, '0')}';
  }

  // ── Início do mês corrente em ms ───────────────────────────────
  int get _monthStartMs {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
  }

  /// Busca as stats em paralelo e retorna um [UserStats] consolidado.
  Future<UserStats> fetchStats(String uid) async {
    try {
      final results = await Future.wait([
        _db.child('DonationHistory/$uid').get(),
        _db.child('Rankings/weekly/${_weekKey()}').get(),
      ]);

      // ── 1. Histórico de doações ──────────────────────────────
      int donatedThisMonth = 0;
      int dreamsReceived   = 0;

      final historySnap = results[0];
      if (historySnap.exists && historySnap.value is Map) {
        for (final child in historySnap.children) {
          final val = child.value;
          if (val is! Map) continue;

          final type      = val['type']?.toString();
          final itemType  = val['itemType']?.toString();
          final timestamp = (val['timestamp'] as num?)?.toInt() ?? 0;

          if (type == 'donated' && timestamp >= _monthStartMs) {
            donatedThisMonth++;
          }
          if (type == 'received' && itemType == 'dream') {
            dreamsReceived++;
          }
        }
      }

      // ── 2. Posição no ranking semanal ────────────────────────
      int? rankingPosition;

      final rankingSnap = results[1];
      if (rankingSnap.exists && rankingSnap.value is Map) {
        // Monta lista de (uid, score) e ordena por score desc
        final entries = <MapEntry<String, int>>[];
        (rankingSnap.value as Map).forEach((key, val) {
          if (val is Map) {
            final score = (val['score'] as num?)?.toInt() ?? 0;
            entries.add(MapEntry(key.toString(), score));
          }
        });
        entries.sort((a, b) => b.value.compareTo(a.value));

        final pos = entries.indexWhere((e) => e.key == uid);
        if (pos != -1) rankingPosition = pos + 1;
      }

      return UserStats(
        donatedThisMonth: donatedThisMonth,
        dreamsReceived:   dreamsReceived,
        rankingPosition:  rankingPosition,
      );
    } catch (e) {
      debugPrint('[UserStatsRepository] fetchStats error: $e');
      return const UserStats();
    }
  }
}
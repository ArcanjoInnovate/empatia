// lib/features/home/data/repositories/ranking_repository.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════
// MODEL
// ══════════════════════════════════════════════════════════════

class RankingEntry {
  final String uid;
  final String name;
  final int score;
  final int count;
  final int position;
  final String? profileImage;
  final String? profileEmoji;
  final String? city;
  final String? state;

  const RankingEntry({
    required this.uid,
    required this.name,
    required this.score,
    required this.count,
    required this.position,
    this.profileImage,
    this.profileEmoji,
    this.city,
    this.state,
  });

  /// Alias para [uid] — usado pela RankingPage para identificar
  /// o usuário logado na lista e destacar sua linha.
  String get id => uid;

  /// Nome abreviado — só o primeiro nome, para espaços compactos.
  String get firstName => name.split(' ').first;

  /// Emoji de avatar com fallback garantido.
  String get avatarEmoji => profileEmoji ?? '👤';

  /// Cidade formatada com estado.
  String get location {
    if (city != null && state != null) return '$city, $state';
    if (city != null) return city!;
    if (state != null) return state!;
    return '';
  }
}

// ══════════════════════════════════════════════════════════════
// REPOSITORY — sem mudanças de lógica
// ══════════════════════════════════════════════════════════════

class RankingRepository {
  RankingRepository._();
  static final RankingRepository instance = RankingRepository._();

  final _db = FirebaseDatabase.instance.ref();

  String _weekKey() {
    final now  = DateTime.now();
    final year = now.year;
    final week =
        ((now.difference(DateTime(year, 1, 1)).inDays) / 7).ceil();
    return '$year-W${week.toString().padLeft(2, '0')}';
  }

  Future<List<RankingEntry>> fetchTopDonors({int limit = 100}) async {
    try {
      final snap =
          await _db.child('Rankings/weekly/${_weekKey()}').get();

      if (!snap.exists || snap.value is! Map) return [];

      final raw = <MapEntry<String, Map>>[];
      (snap.value as Map).forEach((key, val) {
        if (val is Map) raw.add(MapEntry(key.toString(), val));
      });

      raw.sort((a, b) {
        final sa = (a.value['score'] as num?)?.toInt() ?? 0;
        final sb = (b.value['score'] as num?)?.toInt() ?? 0;
        return sb.compareTo(sa);
      });

      final top = raw.take(limit).toList();

      final entries = await Future.wait(
        top.asMap().entries.map((e) async {
          final position = e.key + 1;
          final uid      = e.value.key;
          final val      = e.value.value;

          String  name   = val['name']?.toString() ?? 'Usuário';
          final   score  = (val['score'] as num?)?.toInt() ?? 0;
          final   count  = (val['count'] as num?)?.toInt() ?? 0;

          String? profileImage, profileEmoji, city, state;

          try {
            final pub = await _db.child('UsersPublic/$uid').get();
            if (pub.exists && pub.value is Map) {
              final m      = pub.value as Map;
              name         = m['name']?.toString() ?? name;
              profileImage = m['profileImage']?.toString();
              profileEmoji = m['profileEmoji']?.toString();
              city         = m['city']?.toString();
              state        = m['state']?.toString();
            }
          } catch (_) {}

          return RankingEntry(
            uid:          uid,
            name:         name,
            score:        score,
            count:        count,
            position:     position,
            profileImage: profileImage,
            profileEmoji: profileEmoji,
            city:         city,
            state:        state,
          );
        }),
      );

      return entries;
    } catch (e) {
      debugPrint('[RankingRepository] fetchTopDonors error: $e');
      return [];
    }
  }
}
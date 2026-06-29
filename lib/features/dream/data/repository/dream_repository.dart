import 'package:empatia/core/data/models/dream_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// 💭 DREAM REPOSITORY
///
/// CRUD da subcoleção /Users/{uid}/dreams no Firebase.
///
/// Usa authStateChanges().asyncExpand para garantir que o listener
/// de sonhos só abre após o usuário estar autenticado — resolve o
/// problema de cold-start onde currentUser é null momentaneamente.
class DreamRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DatabaseReference _dreamsRef(String uid) => _db.ref('Users/$uid/dreams');

  /// Aguarda o usuário estar autenticado e retorna o UID
  Future<String> _ensureAuthenticated() async {
    final currentUid = _uid;
    if (currentUid != null) return currentUid;

    final user = await _auth.authStateChanges()
        .firstWhere((user) => user != null)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw Exception('❌ Tempo esgotado aguardando autenticação.'),
        );

    if (user == null) throw Exception('❌ Usuário não está logado.');
    return user.uid;
  }

  /// 📺 Stream dos sonhos — aguarda auth antes de abrir o listener.
  Stream<List<DreamModel>> watchDreams() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(<DreamModel>[]);

      return _dreamsRef(user.uid).onValue.map((event) {
        final snapshot = event.snapshot;
        if (!snapshot.exists || snapshot.value == null) return <DreamModel>[];

        final map = Map<dynamic, dynamic>.from(snapshot.value as Map);

        // Filtra entradas parciais antes de parsear: registros gravados
        // indevidamente no nó do DOADOR pelo completeDonation só possuem
        // campos de controle (status, progress, fulfilledAt, fulfilledBy,
        // updatedAt) e nunca têm 'title'. Ignorá-los aqui evita que
        // apareçam na tela de sonhos de quem doou.
        final validEntries = map.entries.where((e) {
          final value = e.value;
          if (value is! Map) return false;
          final hasTitle = value['title'] != null &&
              (value['title'] as String?)?.trim().isNotEmpty == true;
          return hasTitle;
        });

        final list = validEntries
            .map((e) => DreamModel.fromMap(
                  Map<dynamic, dynamic>.from(e.value),
                  e.key.toString(),
                ))
            .toList();

        list.sort((a, b) =>
            (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)));

        // Remove sonhos realizados:
        // • status == 'fulfilled'  → campo novo, gravado pelo completeDonation
        // • progress >= 1.0        → fallback para dados legados sem o campo status
        list.removeWhere((d) =>
            d.status == 'fulfilled' || (d.progress != null && d.progress! >= 1.0));

        return list;
      });
    });
  }

  /// ➕ Adiciona um sonho
  Future<String> addDream(DreamModel dream) async {
    final uid = await _ensureAuthenticated();
    final ref = _dreamsRef(uid).push();
    await ref.set(dream.toMap());
    debugPrint('✅ Sonho criado: ${ref.key}');
    return ref.key!;
  }

  /// ✏️ Atualiza um sonho existente
  Future<void> updateDream(DreamModel dream) async {
    final uid = await _ensureAuthenticated();
    if (dream.id == null) throw Exception('❌ Sonho sem ID.');
    await _dreamsRef(uid).child(dream.id!).update(dream.toMap());
  }

  /// 🔄 Atualiza apenas o progresso
  Future<void> updateProgress(String dreamId, double progress) async {
    final uid = await _ensureAuthenticated();
    await _dreamsRef(uid).child(dreamId).update({
      'progress': progress,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 🗑️ Remove um sonho
  Future<void> deleteDream(String dreamId) async {
    final uid = await _ensureAuthenticated();
    await _dreamsRef(uid).child(dreamId).remove();
  }
}
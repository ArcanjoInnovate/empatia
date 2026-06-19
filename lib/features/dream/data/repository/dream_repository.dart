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
  /// Resolve o problema de cold-start onde currentUser é null momentaneamente
  Future<String> _ensureAuthenticated() async {
    final currentUid = _uid;
    if (currentUid != null) return currentUid;

    // Aguarda o primeiro evento de auth não-null (timeout de 5s)
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
      // Não autenticado → lista vazia
      if (user == null) return Stream.value(<DreamModel>[]);

      // Autenticado → escuta o nó de sonhos em tempo real
      return _dreamsRef(user.uid).onValue.map((event) {
        final snapshot = event.snapshot;
        if (!snapshot.exists || snapshot.value == null) return <DreamModel>[];

        final map = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final list = map.entries
            .map((e) => DreamModel.fromMap(
                  Map<dynamic, dynamic>.from(e.value),
                  e.key.toString(),
                ))
            .toList();

        // Mais recentes primeiro; sonhos sem createdAt vão pro fim
        list.sort((a, b) =>
            (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)));

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
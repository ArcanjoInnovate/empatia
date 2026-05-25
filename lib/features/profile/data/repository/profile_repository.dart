import 'package:empatia/core/models/child_model.dart';
import 'package:empatia/core/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// 👤 PROFILE REPOSITORY
/// 
/// É o ESTOQUISTA de dados do usuário.
/// Ele conversa diretamente com o Firebase (o banco de dados).
/// 
/// RESPONSABILIDADES:
/// - Ler dados do usuário
/// - Salvar alterações no perfil
/// - Adicionar/editar/remover filhos
class ProfileRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ID do usuário logado
  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('❌ Usuário não está logado.');
    return uid;
  }

  /// Caminho no Firebase: /Users/{uid}
  DatabaseReference get _userRef => _db.ref('Users/$_uid');

  /// 📺 STREAM: Fica "assistindo" mudanças no Firebase
  /// 
  /// Como uma TV que atualiza automaticamente quando o canal muda
  Stream<UserModel?> watchUser() {
    return _userRef.onValue.map((event) {
      final snapshot = event.snapshot;

      if (!snapshot.exists || snapshot.value == null) return null;

      return UserModel.fromMap(
        Map<dynamic, dynamic>.from(snapshot.value as Map),
        _uid,
      );
    });
  }

  /// 💾 SALVAR PERFIL
  /// 
  /// update() = só muda os campos enviados (merge)
  /// set() = substitui tudo (apaga o resto)
  Future<void> updateProfile(UserModel user) async {
    final map = user.toMap();
    debugPrint('📦 Salvando perfil: $map');
    await _userRef.update(map);
  }

  /// ➕ ADICIONAR FILHO
  Future<String> addChild(ChildModel child) async {
    final ref = _userRef.child('children').push();
    await ref.set(child.toMap());
    return ref.key!;
  }

  /// ✏️ EDITAR FILHO
  Future<void> updateChild(ChildModel child) async {
    if (child.id == null) {
      throw Exception('❌ Filho sem ID não pode ser atualizado.');
    }
    await _userRef.child('children/${child.id}').update(child.toMap());
  }

  /// 🗑️ REMOVER FILHO
  Future<void> removeChild(String childId) async {
    await _userRef.child('children/$childId').remove();
  }
}
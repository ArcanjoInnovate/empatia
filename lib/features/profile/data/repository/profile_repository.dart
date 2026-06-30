import 'package:empatia/core/data/models/child_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// 👤 PROFILE REPOSITORY
///
/// Conversa diretamente com o Firebase.
class ProfileRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('❌ Usuário não está logado.');
    return uid;
  }

  DatabaseReference get _userRef => _db.ref('Users/$_uid');

  /// 📺 Stream do usuário — atualiza em tempo real
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

  /// 💾 Salva dados do perfil (merge) e espelha dados públicos em UsersPublic
  Future<void> updateProfile(UserModel user) async {
    final map = user.toMap();
    debugPrint('📦 Salvando perfil: $map');

    // Grava dados completos em Users (privado)
    await _userRef.update(map);

    // Espelha campos públicos em UsersPublic (legível por qualquer autenticado)
    final publicData = <String, dynamic>{
      'uid': _uid,
      if (user.name != null) 'name': user.name,
      if (user.profileEmoji != null) 'profileEmoji': user.profileEmoji,
      // Sempre incluído (mesmo null): mantém UsersPublic em sincronia
      // quando o usuário remove a foto e volta para o avatar.
      'profileImage': user.profileImage,
      if (user.city != null) 'city': user.city,
      if (user.state != null) 'state': user.state,
      if (user.sexo != null) 'sexo': user.sexo,
      if (user.age != null) 'age': user.age,
      // Status pode ser limpo (ficar null) — sempre incluído para refletir
      // a remoção no perfil público também.
      'status': user.status,
      // Sempre incluídos (mesmo null): permite remover um link salvo
      // também no perfil público.
      'socialFacebook': user.socialFacebook,
      'socialInstagram': user.socialInstagram,
      'socialX': user.socialX,
      // Verificação: espelha os dois booleans + o resultado calculado
      // (mais simples de ler direto no perfil público sem reimplementar
      // a regra de negócio lá).
      'emailVerified': user.emailVerified == true,
      'profileCompleted': user.profileCompleted == true,
      'fullyVerified':
          (user.emailVerified == true) && (user.profileCompleted == true),
    };
    await _db.ref('UsersPublic/$_uid').update(publicData);
  }

  /// 🔄 ALTERNA MODO: "donor" ↔ "receiver"
  Future<void> toggleMode(String newMode) async {
    assert(
      newMode == 'donor' || newMode == 'receiver',
      '❌ newMode deve ser "donor" ou "receiver"',
    );
    debugPrint('🔄 Alternando modo para: $newMode');
    await _userRef.update({
      'activeMode': newMode,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// ✅ Marca perfil como completo no banco de dados
  ///
  /// Chamado automaticamente pelo [ProfileService] quando todos os
  /// campos obrigatórios estão preenchidos ao salvar.
  Future<void> markProfileCompleted() async {
    debugPrint('✅ Marcando perfil como completo');
    await _userRef.update({
      'profileCompleted': true,
      'profileCompletedAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    // ── Cross-check: e-mail também verificado? → isVerified ─────────────
    final emailSnap = await _userRef.child('emailVerified').get();
    final emailVerified = emailSnap.value == true;
    if (emailVerified) {
      await _userRef.update({
        'isVerified':   true,
        'isVerifiedAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt':    DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('✅ isVerified = true gravado no Firebase');
    }
    // ─────────────────────────────────────────────────────────────────────

    // Mantém UsersPublic em sincronia — sem isso, o perfil público
    // continuaria mostrando "não verificado" até o próximo saveProfile().
    await _db.ref('UsersPublic/$_uid').update({
      'profileCompleted': true,
      'emailVerified': emailVerified,
      'fullyVerified': emailVerified, // profileCompleted já é true aqui
    });
  }

  /// ➕ Adiciona filho
  Future<String> addChild(ChildModel child) async {
    final ref = _userRef.child('children').push();
    await ref.set(child.toMap());
    return ref.key!;
  }

  /// ✏️ Edita filho
  ///
  /// Após salvar, sincroniza os campos denormalizados (childName/
  /// childEmoji/childAge) em todos os sonhos já cadastrados desse filho
  /// — eles vivem em `Dreams/{dreamId}` (nó público, separado de Users)
  /// e são usados pela vitrine pública (PublicProfilePage) sem precisar
  /// ler o nó privado do filho. Sem isso, editar nome/idade/avatar do
  /// filho deixaria os sonhos já criados com dados antigos.
  Future<void> updateChild(ChildModel child) async {
    if (child.id == null) {
      throw Exception('❌ Filho sem ID não pode ser atualizado.');
    }
    await _userRef.child('children/${child.id}').update(child.toMap());
    await _syncChildDreams(child);
  }

  /// 🔄 Atualiza childName/childEmoji/childAge em todos os sonhos
  /// vinculados a [child] (Dreams/{dreamId} com childId == child.id).
  ///
  /// Requer índice em `childId` no nó `Dreams` (regras do Realtime
  /// Database): "Dreams": { ".indexOn": ["userId", "childId"] }
  Future<void> _syncChildDreams(ChildModel child) async {
    if (child.id == null) return;

    try {
      final dreamsSnap = await _db
          .ref('Dreams')
          .orderByChild('childId')
          .equalTo(child.id)
          .get();

      if (!dreamsSnap.exists || dreamsSnap.value is! Map) return;

      final dreamsMap = Map<dynamic, dynamic>.from(dreamsSnap.value as Map);
      if (dreamsMap.isEmpty) return;

      // Multi-path update: grava em vários sonhos numa única chamada
      // atômica, em vez de um await por sonho.
      final updates = <String, dynamic>{};
      for (final dreamId in dreamsMap.keys) {
        updates['Dreams/$dreamId/childName']  = child.name;
        updates['Dreams/$dreamId/childEmoji'] = child.emoji;
        updates['Dreams/$dreamId/childAge']   = child.age;
      }

      await _db.ref().update(updates);
      debugPrint(
          '✅ ${dreamsMap.length} sonho(s) sincronizado(s) para o filho ${child.name}');
    } catch (e) {
      // Não falha a edição do filho se a sincronização dos sonhos der
      // erro — os dados do filho já foram salvos corretamente acima.
      debugPrint('⚠️ Erro ao sincronizar sonhos do filho (continuando): $e');
    }
  }

  /// 🗑️ Remove filho
  Future<void> removeChild(String childId) async {
    await _userRef.child('children/$childId').remove();
  }
}
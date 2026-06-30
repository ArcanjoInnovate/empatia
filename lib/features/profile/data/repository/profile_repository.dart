import 'package:empatia/core/data/models/child_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// ðŸ‘¤ PROFILE REPOSITORY
///
/// Conversa diretamente com o Firebase.
class ProfileRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('âŒ UsuÃ¡rio nÃ£o estÃ¡ logado.');
    return uid;
  }

  DatabaseReference get _userRef => _db.ref('Users/$_uid');

  /// ðŸ“º Stream do usuÃ¡rio â€” atualiza em tempo real
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

  /// ðŸ’¾ Salva dados do perfil (merge) e espelha dados pÃºblicos em UsersPublic
  Future<void> updateProfile(UserModel user) async {
    final map = user.toMap();
    debugPrint('ðŸ“¦ Salvando perfil: $map');

    // Grava dados completos em Users (privado)
    await _userRef.update(map);

    // Espelha campos pÃºblicos em UsersPublic (legÃ­vel por qualquer autenticado)
    final publicData = <String, dynamic>{
      'uid': _uid,
      if (user.name != null) 'name': user.name,
      if (user.profileEmoji != null) 'profileEmoji': user.profileEmoji,
      // Sempre incluÃ­do (mesmo null): mantÃ©m UsersPublic em sincronia
      // quando o usuÃ¡rio remove a foto e volta para o avatar.
      'profileImage': user.profileImage,
      if (user.city != null) 'city': user.city,
      if (user.state != null) 'state': user.state,
      if (user.sexo != null) 'sexo': user.sexo,
      if (user.age != null) 'age': user.age,
      // Status pode ser limpo (ficar null) â€” sempre incluÃ­do para refletir
      // a remoÃ§Ã£o no perfil pÃºblico tambÃ©m.
      'status': user.status,
      // Sempre incluÃ­dos (mesmo null): permite remover um link salvo
      // tambÃ©m no perfil pÃºblico.
      'socialFacebook': user.socialFacebook,
      'socialInstagram': user.socialInstagram,
      'socialX': user.socialX,
      // VerificaÃ§Ã£o: espelha os dois booleans + o resultado calculado
      // (mais simples de ler direto no perfil pÃºblico sem reimplementar
      // a regra de negÃ³cio lÃ¡).
      'emailVerified': user.emailVerified == true,
      'profileCompleted': user.profileCompleted == true,
      'fullyVerified':
          (user.emailVerified == true) && (user.profileCompleted == true),
    };
    await _db.ref('UsersPublic/$_uid').update(publicData);
  }

  /// ðŸ”„ ALTERNA MODO: "donor" â†” "receiver"
  Future<void> toggleMode(String newMode) async {
    assert(
      newMode == 'donor' || newMode == 'receiver',
      'âŒ newMode deve ser "donor" ou "receiver"',
    );
    debugPrint('ðŸ”„ Alternando modo para: $newMode');
    await _userRef.update({
      'activeMode': newMode,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// âœ… Marca perfil como completo no banco de dados
  ///
  /// Chamado automaticamente pelo [ProfileService] quando todos os
  /// campos obrigatÃ³rios estÃ£o preenchidos ao salvar.
  Future<void> markProfileCompleted() async {
    debugPrint('âœ… Marcando perfil como completo');
    await _userRef.update({
      'profileCompleted': true,
      'profileCompletedAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    // â”€â”€ Cross-check: e-mail tambÃ©m verificado? â†’ isVerified â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final emailSnap = await _userRef.child('emailVerified').get();
    final emailVerified = emailSnap.value == true;
    if (emailVerified) {
      await _userRef.update({
        'isVerified':   true,
        'isVerifiedAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt':    DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('âœ… isVerified = true gravado no Firebase');
    }
    // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    // MantÃ©m UsersPublic em sincronia â€” sem isso, o perfil pÃºblico
    // continuaria mostrando "nÃ£o verificado" atÃ© o prÃ³ximo saveProfile().
    await _db.ref('UsersPublic/$_uid').update({
      'profileCompleted': true,
      'emailVerified': emailVerified,
      'fullyVerified': emailVerified, // profileCompleted jÃ¡ Ã© true aqui
    });
  }

  /// âž• Adiciona filho
  Future<String> addChild(ChildModel child) async {
    final ref = _userRef.child('children').push();
    await ref.set(child.toMap());
    return ref.key!;
  }

  /// âœï¸ Edita filho
  ///
  /// ApÃ³s salvar, sincroniza os campos denormalizados (childName/
  /// childEmoji/childAge) em todos os sonhos jÃ¡ cadastrados desse filho
  /// â€” eles vivem em `Dreams/{dreamId}` (nÃ³ pÃºblico, separado de Users)
  /// e sÃ£o usados pela vitrine pÃºblica (PublicProfilePage) sem precisar
  /// ler o nÃ³ privado do filho. Sem isso, editar nome/idade/avatar do
  /// filho deixaria os sonhos jÃ¡ criados com dados antigos.
  Future<void> updateChild(ChildModel child) async {
    if (child.id == null) {
      throw Exception('âŒ Filho sem ID nÃ£o pode ser atualizado.');
    }
    await _userRef.child('children/${child.id}').update(child.toMap());
    await _syncChildDreams(child);
  }

  /// ðŸ”„ Atualiza childName/childEmoji/childAge em todos os sonhos
  /// vinculados a [child], nos DOIS nÃ³s onde eles vivem:
  ///
  ///   â€¢ Users/{uid}/dreams/{id} â€” nÃ³ PRIVADO, lido pela DreamPage
  ///     (tela "Meus Sonhos" do prÃ³prio usuÃ¡rio)
  ///   â€¢ Dreams/{id}             â€” nÃ³ PÃšBLICO/feed, lido pela vitrine
  ///     pÃºblica (PublicProfilePage) e pela busca
  ///
  /// IMPORTANTE: antes sÃ³ sincronizÃ¡vamos o nÃ³ pÃºblico `Dreams`. Isso
  /// fazia o feed pÃºblico refletir a ediÃ§Ã£o do filho, mas a prÃ³pria
  /// DreamPage do usuÃ¡rio continuava mostrando nome/idade/avatar antigos
  /// â€” porque ela lÃª de `Users/{uid}/dreams`, que nunca era tocado aqui.
  ///
  /// Requer Ã­ndice em `childId` em ambos os nÃ³s (regras do Realtime
  /// Database):
  ///   "Dreams": { ".indexOn": ["userId", "childId"] }
  ///   "Users/$uid/dreams": { ".indexOn": ["childId"] }  (ou ".indexOn": ["$uid"]... ajustar conforme regras)
  Future<void> _syncChildDreams(ChildModel child) async {
    if (child.id == null) return;

    final updates = <String, dynamic>{};

    // â”€â”€ 1) NÃ³ privado: Users/{uid}/dreams â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    try {
      final privateSnap = await _userRef
          .child('dreams')
          .orderByChild('childId')
          .equalTo(child.id)
          .get();

      if (privateSnap.exists && privateSnap.value is Map) {
        final privateMap = Map<dynamic, dynamic>.from(privateSnap.value as Map);
        for (final dreamId in privateMap.keys) {
          updates['Users/$_uid/dreams/$dreamId/childName']  = child.name;
          updates['Users/$_uid/dreams/$dreamId/childEmoji'] = child.emoji;
          updates['Users/$_uid/dreams/$dreamId/childAge']   = child.age;
        }
        debugPrint(
            'âœ… ${privateMap.length} sonho(s) privado(s) sincronizado(s) para o filho ${child.name}');
      }
    } catch (e) {
      debugPrint('âš ï¸ Erro ao sincronizar sonhos privados do filho (continuando): $e');
    }

    // â”€â”€ 2) NÃ³ pÃºblico: Dreams (feed) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    try {
      final dreamsSnap = await _db
          .ref('Dreams')
          .orderByChild('childId')
          .equalTo(child.id)
          .get();

      if (dreamsSnap.exists && dreamsSnap.value is Map) {
        final dreamsMap = Map<dynamic, dynamic>.from(dreamsSnap.value as Map);
        for (final dreamId in dreamsMap.keys) {
          updates['Dreams/$dreamId/childName']  = child.name;
          updates['Dreams/$dreamId/childEmoji'] = child.emoji;
          updates['Dreams/$dreamId/childAge']   = child.age;
        }
        debugPrint(
            'âœ… ${dreamsMap.length} sonho(s) pÃºblico(s) sincronizado(s) para o filho ${child.name}');
      }
    } catch (e) {
      debugPrint('âš ï¸ Erro ao sincronizar sonhos pÃºblicos do filho (continuando): $e');
    }

    if (updates.isEmpty) return;

    try {
      // Multi-path update: grava em ambos os nÃ³s numa Ãºnica chamada
      // atÃ´mica, em vez de um await por sonho.
      await _db.ref().update(updates);
    } catch (e) {
      // NÃ£o falha a ediÃ§Ã£o do filho se a sincronizaÃ§Ã£o dos sonhos der
      // erro â€” os dados do filho jÃ¡ foram salvos corretamente acima.
      debugPrint('âš ï¸ Erro ao gravar sincronizaÃ§Ã£o dos sonhos do filho (continuando): $e');
    }
  }

  /// ðŸ—‘ï¸ Remove filho
  Future<void> removeChild(String childId) async {
    await _userRef.child('children/$childId').remove();
  }
}
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

    // Mantém Dreams e Donations já publicados em sincronia com os dados
    // atuais do usuário (nome, avatar/foto, localização). Sem isso, um
    // sonho ou doação criado antes de uma edição de perfil continuaria
    // mostrando nome/foto/cidade antigos para sempre.
    await _syncUserOwnedItems(user);
  }

  /// 🔄 Atualiza os campos denormalizados do usuário (nome, avatar/foto,
  /// cidade, estado, latitude/longitude) em TODOS os itens que ele
  /// possui, nos nós onde essas cópias vivem:
  ///
  ///   • Dreams/{id}             — nó PÚBLICO (feed/vitrine), campos:
  ///       userName, userProfileEmoji, userProfileImage, city, state,
  ///       latitude, longitude
  ///   • Users/{uid}/dreams/{id} — nó PRIVADO (tela "Meus Sonhos"),
  ///       mesmos campos, para não ficar dessincronizado da vitrine
  ///   • Donations/{id}          — nó PÚBLICO (feed de doações), campos:
  ///       ownerName, ownerPhotoUrl, city, state, latitude, longitude
  ///
  /// Requer índice em `userId` nos três nós (regras do Realtime Database):
  ///   "Dreams":              { ".indexOn": ["userId", "childId"] }
  ///   "Donations":           { ".indexOn": ["userId"] }
  ///   "Users/$uid/dreams":   { ".indexOn": ["userId"] }
  ///
  /// Assim como em [_syncChildDreams], falhas aqui não derrubam o
  /// salvamento do perfil — os dados do usuário já foram gravados acima.
  Future<void> _syncUserOwnedItems(UserModel user) async {
    final updates = <String, dynamic>{};

    // ── 1) Nó privado: Users/{uid}/dreams ───────────────────────────────
    try {
      final privateSnap = await _userRef.child('dreams').get();
      if (privateSnap.exists && privateSnap.value is Map) {
        final privateMap =
            Map<dynamic, dynamic>.from(privateSnap.value as Map);
        for (final dreamId in privateMap.keys) {
          updates['Users/$_uid/dreams/$dreamId/userName'] = user.name;
          updates['Users/$_uid/dreams/$dreamId/userProfileEmoji'] =
              user.profileEmoji;
          updates['Users/$_uid/dreams/$dreamId/userProfileImage'] =
              user.profileImage;
          updates['Users/$_uid/dreams/$dreamId/city'] = user.city;
          updates['Users/$_uid/dreams/$dreamId/state'] = user.state;
          updates['Users/$_uid/dreams/$dreamId/latitude'] = user.latitude;
          updates['Users/$_uid/dreams/$dreamId/longitude'] = user.longitude;
        }
        debugPrint(
            '✅ ${privateMap.length} sonho(s) privado(s) sincronizado(s) com o perfil');
      }
    } catch (e) {
      debugPrint(
          '⚠️ Erro ao sincronizar sonhos privados com o perfil (continuando): $e');
    }

    // ── 2) Nó público: Dreams (feed) ─────────────────────────────────────
    try {
      final dreamsSnap = await _db
          .ref('Dreams')
          .orderByChild('userId')
          .equalTo(_uid)
          .get();

      if (dreamsSnap.exists && dreamsSnap.value is Map) {
        final dreamsMap = Map<dynamic, dynamic>.from(dreamsSnap.value as Map);
        for (final dreamId in dreamsMap.keys) {
          updates['Dreams/$dreamId/userName'] = user.name;
          updates['Dreams/$dreamId/userProfileEmoji'] = user.profileEmoji;
          updates['Dreams/$dreamId/userProfileImage'] = user.profileImage;
          updates['Dreams/$dreamId/city'] = user.city;
          updates['Dreams/$dreamId/state'] = user.state;
          updates['Dreams/$dreamId/latitude'] = user.latitude;
          updates['Dreams/$dreamId/longitude'] = user.longitude;
        }
        debugPrint(
            '✅ ${dreamsMap.length} sonho(s) público(s) sincronizado(s) com o perfil');
      }
    } catch (e) {
      debugPrint(
          '⚠️ Erro ao sincronizar sonhos públicos com o perfil (continuando): $e');
    }

    // ── 3) Nó público: Donations (feed) ──────────────────────────────────
    try {
      final donationsSnap = await _db
          .ref('Donations')
          .orderByChild('userId')
          .equalTo(_uid)
          .get();

      if (donationsSnap.exists && donationsSnap.value is Map) {
        final donationsMap =
            Map<dynamic, dynamic>.from(donationsSnap.value as Map);
        for (final donationId in donationsMap.keys) {
          updates['Donations/$donationId/ownerName'] = user.name;
          updates['Donations/$donationId/ownerPhotoUrl'] = user.profileImage;
          updates['Donations/$donationId/city'] = user.city;
          updates['Donations/$donationId/state'] = user.state;
          updates['Donations/$donationId/latitude'] = user.latitude;
          updates['Donations/$donationId/longitude'] = user.longitude;
        }
        debugPrint(
            '✅ ${donationsMap.length} doação(ões) sincronizada(s) com o perfil');
      }
    } catch (e) {
      debugPrint(
          '⚠️ Erro ao sincronizar doações com o perfil (continuando): $e');
    }

    if (updates.isEmpty) return;

    try {
      // Multi-path update: grava em todos os nós numa única chamada
      // atômica, em vez de um await por item.
      await _db.ref().update(updates);
    } catch (e) {
      // Não falha o salvamento do perfil se a sincronização dos itens
      // der erro — os dados do usuário já foram salvos corretamente acima.
      debugPrint(
          '⚠️ Erro ao gravar sincronização dos itens do usuário (continuando): $e');
    }
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
  /// vinculados a [child], nos DOIS nós onde eles vivem:
  ///
  ///   • Users/{uid}/dreams/{id} — nó PRIVADO, lido pela DreamPage
  ///     (tela "Meus Sonhos" do próprio usuário)
  ///   • Dreams/{id}             — nó PÚBLICO/feed, lido pela vitrine
  ///     pública (PublicProfilePage) e pela busca
  ///
  /// IMPORTANTE: antes só sincronizávamos o nó público `Dreams`. Isso
  /// fazia o feed público refletir a edição do filho, mas a própria
  /// DreamPage do usuário continuava mostrando nome/idade/avatar antigos
  /// — porque ela lê de `Users/{uid}/dreams`, que nunca era tocado aqui.
  ///
  /// Requer índice em `childId` em ambos os nós (regras do Realtime
  /// Database):
  ///   "Dreams": { ".indexOn": ["userId", "childId"] }
  ///   "Users/$uid/dreams": { ".indexOn": ["childId"] }  (ou ".indexOn": ["$uid"]... ajustar conforme regras)
  Future<void> _syncChildDreams(ChildModel child) async {
    if (child.id == null) return;

    final updates = <String, dynamic>{};

    // ── 1) Nó privado: Users/{uid}/dreams ───────────────────────────────────
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
            '✅ ${privateMap.length} sonho(s) privado(s) sincronizado(s) para o filho ${child.name}');
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao sincronizar sonhos privados do filho (continuando): $e');
    }

    // ── 2) Nó público: Dreams (feed) ─────────────────────────────────────────
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
            '✅ ${dreamsMap.length} sonho(s) público(s) sincronizado(s) para o filho ${child.name}');
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao sincronizar sonhos públicos do filho (continuando): $e');
    }

    if (updates.isEmpty) return;

    try {
      // Multi-path update: grava em ambos os nós numa única chamada
      // atômica, em vez de um await por sonho.
      await _db.ref().update(updates);
    } catch (e) {
      // Não falha a edição do filho se a sincronização dos sonhos der
      // erro — os dados do filho já foram salvos corretamente acima.
      debugPrint('⚠️ Erro ao gravar sincronização dos sonhos do filho (continuando): $e');
    }
  }

  /// 🗑️ Remove filho
  Future<void> removeChild(String childId) async {
    await _userRef.child('children/$childId').remove();
  }
}
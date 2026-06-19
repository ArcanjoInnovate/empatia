import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// 🎁 DONATION REPOSITORY
///
/// CRUD da coleção /Donations no Firebase.
/// As doações ficam em uma coleção RAIZ (não dentro de /Users)
/// para permitir queries globais no feed por cidade/estado.
class DonationRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DatabaseReference get _donationsRef => _db.ref('Donations');

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

  /// 📺 Stream das doações do usuário logado
  Stream<List<DonationModel>> watchMyDonations() {
    return _auth.authStateChanges().asyncExpand((user) {
      // Não autenticado → lista vazia
      if (user == null) return Stream.value(<DonationModel>[]);

      // Autenticado → escuta as doações do usuário
      return _donationsRef
          .orderByChild('userId')
          .equalTo(user.uid)
          .onValue
          .map((event) {
        final snapshot = event.snapshot;
        if (!snapshot.exists || snapshot.value == null) return <DonationModel>[];

        final map = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final list = map.entries
            .map((e) => DonationModel.fromMap(
                  Map<dynamic, dynamic>.from(e.value),
                  e.key.toString(),
                ))
            .toList();

        // Mais recentes primeiro
        list.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

        return list;
      });
    });
  }

  /// 📺 Stream das doações disponíveis em uma cidade (para o feed)
  Stream<List<DonationModel>> watchDonationsByCity(String city) {
    return _donationsRef
        .orderByChild('city')
        .equalTo(city)
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return [];

      final map = Map<dynamic, dynamic>.from(snapshot.value as Map);
      return map.entries
          .map((e) => DonationModel.fromMap(
                Map<dynamic, dynamic>.from(e.value),
                e.key.toString(),
              ))
          .where((d) => d.status == 'available')
          .toList();
    });
  }

  /// ➕ Cria uma nova oferta de doação
  Future<String> createDonation(DonationModel donation) async {
    final uid = await _ensureAuthenticated();
    final ref = _donationsRef.push();
    await ref.set(donation.copyWith(userId: uid).toMap());
    debugPrint('✅ Doação criada: ${ref.key}');
    return ref.key!;
  }

  /// ✏️ Atualiza uma doação existente
  Future<void> updateDonation(DonationModel donation) async {
    if (donation.id == null) throw Exception('❌ Doação sem ID.');
    await _donationsRef
        .child(donation.id!)
        .update(donation.toMap());
  }

  /// 🔄 Atualiza apenas o status
  Future<void> updateStatus(String donationId, String newStatus) async {
    await _donationsRef.child(donationId).update({
      'status': newStatus,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 🗑️ Remove uma doação
  Future<void> deleteDonation(String donationId) async {
    await _donationsRef.child(donationId).remove();
  }
}
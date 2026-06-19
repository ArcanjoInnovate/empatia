import 'package:empatia/features/request/data/model/request_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// 🙏 REQUEST REPOSITORY
///
/// CRUD da coleção /Requests no Firebase.
/// Assim como Donations, fica na raiz para queries globais no feed.
class RequestRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DatabaseReference get _requestsRef => _db.ref('Requests');

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

  /// 📺 Stream dos pedidos do usuário logado
  Stream<List<RequestModel>> watchMyRequests() {
    return _auth.authStateChanges().asyncExpand((user) {
      // Não autenticado → lista vazia
      if (user == null) return Stream.value(<RequestModel>[]);

      // Autenticado → escuta os pedidos do usuário
      return _requestsRef
          .orderByChild('userId')
          .equalTo(user.uid)
          .onValue
          .map((event) {
        final snapshot = event.snapshot;
        if (!snapshot.exists || snapshot.value == null) return <RequestModel>[];

        final map = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final list = map.entries
            .map((e) => RequestModel.fromMap(
                  Map<dynamic, dynamic>.from(e.value),
                  e.key.toString(),
                ))
            .toList();

        list.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

        return list;
      });
    });
  }

  /// 📺 Stream dos pedidos abertos em uma cidade (para o feed)
  Stream<List<RequestModel>> watchRequestsByCity(String city) {
    return _requestsRef
        .orderByChild('city')
        .equalTo(city)
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return [];

      final map = Map<dynamic, dynamic>.from(snapshot.value as Map);
      return map.entries
          .map((e) => RequestModel.fromMap(
                Map<dynamic, dynamic>.from(e.value),
                e.key.toString(),
              ))
          .where((r) => r.status == 'open')
          .toList();
    });
  }

  /// ➕ Cria um novo pedido de doação
  Future<String> createRequest(RequestModel request) async {
    final uid = await _ensureAuthenticated();
    final ref = _requestsRef.push();
    await ref.set(request.copyWith(userId: uid).toMap());
    debugPrint('✅ Pedido criado: ${ref.key}');
    return ref.key!;
  }

  /// ✏️ Atualiza um pedido existente
  Future<void> updateRequest(RequestModel request) async {
    if (request.id == null) throw Exception('❌ Pedido sem ID.');
    await _requestsRef
        .child(request.id!)
        .update(request.toMap());
  }

  /// 🔄 Atualiza apenas o status
  Future<void> updateStatus(String requestId, String newStatus) async {
    await _requestsRef.child(requestId).update({
      'status': newStatus,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 🗑️ Remove um pedido
  Future<void> deleteRequest(String requestId) async {
    await _requestsRef.child(requestId).remove();
  }
}
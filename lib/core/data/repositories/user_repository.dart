import 'package:empatia/core/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// 👤 USER REPOSITORY
///
/// Fornece um Stream do UserModel do usuário logado.
/// Escuta mudanças no perfil em tempo real.
class UserRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream que emite o UserModel sempre que:
  /// - O usuário faz login/logout
  /// - O perfil do usuário é atualizado no Firebase
  Stream<UserModel?> watchCurrentUser() {
    return _auth.authStateChanges().asyncExpand((user) {
      // Não autenticado → retorna null
      if (user == null) return Stream.value(null);

      // Autenticado → escuta o nó do perfil em tempo real
      return _db.ref('Users/${user.uid}').onValue.map((event) {
        final snapshot = event.snapshot;
        
        // Se não existe perfil ainda, retorna um UserModel básico
        if (!snapshot.exists || snapshot.value == null) {
          return UserModel(
            id: user.uid,
            name: user.displayName,
          );
        }

        // Converte os dados do Firebase para UserModel
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return UserModel.fromMap(data, user.uid);
      });
    });
  }
}
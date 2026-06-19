import 'package:firebase_database/firebase_database.dart';

/// Responsabilidade: operações no Realtime Database relacionadas à senha.
///
/// A troca em si (reautenticação + updatePassword) é feita no Firebase Auth
/// pelo [ChangePasswordRepository]. Este service só persiste o timestamp de
/// atualização no RTDB para fins de auditoria/exibição.
class ChangePasswordService {
  final FirebaseDatabase _db;

  ChangePasswordService({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  DatabaseReference _userRef(String uid) => _db.ref('Users/$uid');

  /// Registra no RTDB o momento em que a senha foi alterada.
  /// Não armazena a senha — apenas o timestamp de atualização.
  Future<void> recordPasswordUpdated(String uid) async {
    try {
      await _userRef(uid).update({
        'passwordUpdatedAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt':         DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Erro ao registrar atualização de senha: $e');
    }
  }
}
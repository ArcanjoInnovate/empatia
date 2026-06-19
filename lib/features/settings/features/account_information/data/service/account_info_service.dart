import 'package:empatia/features/settings/features/account_information/data/models/account_info_model.dart';
import 'package:firebase_database/firebase_database.dart';

class AccountInfoService {
  final FirebaseDatabase _db;

  AccountInfoService({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  DatabaseReference _userRef(String uid) => _db.ref('Users/$uid');

  /// Busca e-mail do usuário no Realtime Database
  Future<AccountInfoModel?> getUserInfo(String uid) async {
    try {
      final snap = await _userRef(uid).get();
      if (!snap.exists) return null;
      final data = snap.value as Map<dynamic, dynamic>;
      return AccountInfoModel.fromMap(data);
    } catch (e) {
      throw Exception('Erro ao buscar informações: $e');
    }
  }

  /// Marca emailVerified = false quando o link de troca é enviado.
  Future<void> markEmailUnverified(String uid) async {
    try {
      await _userRef(uid).update({
        'emailVerified': false,
        'updatedAt':     DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Erro ao marcar e-mail como não verificado: $e');
    }
  }

  /// Atualiza o e-mail no banco
  Future<void> updateEmail(String uid, String newEmail) async {
    try {
      await _userRef(uid).update({
        'email':         newEmail,
        'emailVerified': false,
        'updatedAt':     DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Erro ao atualizar e-mail no banco: $e');
    }
  }
}
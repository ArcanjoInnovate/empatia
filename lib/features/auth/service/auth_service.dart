import 'package:empatia/core/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<User?> login(String email, String password) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<User?> register(String email, String password) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = result.user;

    if (user != null) {
      await _database.child('Users').child(user.uid).set({
        'id': user.uid,
        'email': email,
        'isVerified': false,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });
    }
    return user;
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final snapshot = await _database.child('Users').child(uid).get();
      if (snapshot.exists) {
        return UserModel.fromMap(
          Map<dynamic, dynamic>.from(snapshot.value as Map),
          uid,
        );
      }
      return null;
    } catch (e) {
      print('Erro ao buscar dados do usuário: $e');
      return null;
    }
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = ServerValue.timestamp;
      await _database.child('Users').child(uid).update(data);
    } catch (e) {
      print('Erro ao atualizar dados do usuário: $e');
      rethrow;
    }
  }

  User? getCurrentUser() => _auth.currentUser;

  Future<void> logout() async => _auth.signOut();
}
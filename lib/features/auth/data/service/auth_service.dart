import 'dart:convert';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth      _auth     = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<User?> login(String email, String password) async {
    final UserCredential result = await _auth.signInWithEmailAndPassword(
      email:    email,
      password: password,
    );

    final user = result.user;

    // ── Sincronização de e-mail no login ─────────────────────────────────────
    // Se o usuário confirmou o link de troca de e-mail enquanto o app estava
    // fechado, o Firebase Auth já tem o novo e-mail, mas o RTDB ainda pode
    // ter o antigo. Corrigimos aqui de forma silenciosa.
    if (user != null) {
      await _syncEmailIfNeeded(user);
    }

    return user;
  }

  // Cadastro simples — mantido para uso interno se necessário
  Future<User?> register(String email, String password) async {
    final UserCredential result = await _auth.createUserWithEmailAndPassword(
      email:    email,
      password: password,
    );

    final user = result.user;

    if (user != null) {
      await _database.child('Users').child(user.uid).set({
        'id':         user.uid,
        'email':      email,
        'isVerified': false,
        'createdAt':  ServerValue.timestamp,
        'updatedAt':  ServerValue.timestamp,
      });
    }
    return user;
  }

  /// Cadastro completo — só cria a conta quando email + senha + idade
  /// já foram validados. Tudo vai pro Firebase de uma vez só.
  Future<User?> registerWithBirthDate({
    required String email,
    required String password,
    required DateTime birthDate,
  }) async {
    // Passo 1 — cria a conta no Firebase Auth
    final UserCredential result = await _auth.createUserWithEmailAndPassword(
      email:    email,
      password: password,
    );

    final user = result.user;

    if (user != null) {
      final age = _calculateAge(birthDate);

      // Passo 2 — salva tudo no RTDB numa única escrita
      await _database.child('Users').child(user.uid).set({
        'id':                   user.uid,
        'email':                email,
        'isVerified':           false,
        'birthDate':            birthDate.millisecondsSinceEpoch,
        'age':                  age,
        'birthDateVerified':    true,
        'birthDateVerifiedAt':  DateTime.now().millisecondsSinceEpoch,
        'createdAt':            ServerValue.timestamp,
        'updatedAt':            ServerValue.timestamp,
      });
    }

    return user;
  }

  static int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final snapshot =
          await _database.child('Users').child(uid).get();
      if (snapshot.exists) {
        return UserModel.fromMap(
          Map<dynamic, dynamic>.from(snapshot.value as Map),
          uid,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserData(
      String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = ServerValue.timestamp;
    await _database.child('Users').child(uid).update(data);
  }

  User? getCurrentUser() => _auth.currentUser;

  Future<void> logout() async => _auth.signOut();

  // URL da Cloud Function — mesma região das outras functions do projeto
  static const _resetFunctionUrl =
      'https://southamerica-east1-empatia-34400.cloudfunctions.net/sendPasswordResetEmail';

  Future<void> sendPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse(_resetFunctionUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final details = body['details'] != null ? ' (${body['details']})' : '';
      throw Exception('${body['error'] ?? 'Erro ao enviar email'}$details');
    }
  }
  
  // ─── SINCRONIZAÇÃO SILENCIOSA ─────────────────────────────────────────────
  // Compara o e-mail do Firebase Auth com o que está salvo no RTDB.
  // Se forem diferentes, atualiza o RTDB para refletir a troca confirmada.

  Future<void> _syncEmailIfNeeded(User user) async {
    try {
      // Garante que temos os dados mais recentes do Auth
      await user.reload();
      final authEmail = _auth.currentUser?.email;
      if (authEmail == null || authEmail.isEmpty) return;

      final snap = await _database
          .child('Users')
          .child(user.uid)
          .child('email')
          .get();

      final dbEmail = snap.value as String?;

      if (dbEmail != null && dbEmail != authEmail) {
        // E-mail divergente → atualiza e-mail e reseta verificação no RTDB,
        // pois o novo e-mail ainda não foi verificado.
        await _database.child('Users').child(user.uid).update({
          'email':         authEmail,
          'emailVerified': false,
          'updatedAt':     ServerValue.timestamp,
        });
      }
    } catch (_) {
      // Silencia — não bloqueia o login por falha na sincronização
    }
  }
}
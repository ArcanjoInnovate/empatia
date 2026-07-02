import 'dart:async';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<UserModel?> watchCurrentUser() {
    late final StreamController<UserModel?> controller;
    StreamSubscription<DatabaseEvent>? dataSub;
    StreamSubscription<User?>? authSub;

    void listenToUser(User? user) {
      // cancela o listener do perfil anterior ANTES de assinar o novo
      dataSub?.cancel();
      dataSub = null;

      if (user == null) {
        controller.add(null);
        return;
      }

      dataSub = _db.ref('Users/${user.uid}').onValue.listen((event) {
        final snapshot = event.snapshot;
        if (!snapshot.exists || snapshot.value == null) {
          controller.add(UserModel(id: user.uid, name: user.displayName));
          return;
        }
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        controller.add(UserModel.fromMap(data, user.uid));
      }, onError: controller.addError);
    }

    controller = StreamController<UserModel?>.broadcast(
      onListen: () {
        authSub = _auth.authStateChanges().listen(listenToUser);
      },
      onCancel: () {
        dataSub?.cancel();
        authSub?.cancel();
      },
    );

    return controller.stream;
  }
}
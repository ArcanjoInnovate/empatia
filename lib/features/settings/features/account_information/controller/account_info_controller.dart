import 'dart:async';

import 'package:empatia/features/settings/features/account_information/data/models/account_info_model.dart';
import 'package:empatia/features/settings/features/account_information/data/repositories/account_info_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum AccountInfoStatus { idle, loading, success, error }

class AccountInfoController extends ChangeNotifier {
  final AccountInfoRepository _repository;
  final FirebaseAuth           _auth;

  StreamSubscription<User?>? _authSubscription;

  AccountInfoController({
    AccountInfoRepository? repository,
    FirebaseAuth?           auth,
  })  : _repository = repository ?? AccountInfoRepository(),
        _auth       = auth       ?? FirebaseAuth.instance {
    _listenAuthChanges();
  }

  // ─── STATE ────────────────────────────────────────────────────────────────

  AccountInfoStatus _status    = AccountInfoStatus.idle;
  AccountInfoStatus get status => _status;

  AccountInfoModel? _model;
  AccountInfoModel? get model  => _model;

  bool    _loadingPage  = true;
  bool    get loadingPage => _loadingPage;

  bool    _updatingEmail = false;
  bool    get updatingEmail => _updatingEmail;

  String? _emailError;
  String? get emailError => _emailError;

  // ─── LISTENER DE AUTH ─────────────────────────────────────────────────────

  void _listenAuthChanges() {
    _authSubscription = _auth.idTokenChanges().listen((user) async {
      if (user == null) return;

      await user.reload();
      final refreshedUser = _auth.currentUser;

      final authEmail  = refreshedUser?.email;
      final modelEmail = _model?.email;

      if (authEmail != null &&
          authEmail.isNotEmpty &&
          authEmail != modelEmail) {
        await _repository.syncEmailViaCloudFunction(refreshedUser!);

        _model = _model?.copyWith(
          email:         authEmail,
          emailVerified: false,
        );
        notifyListeners();
      }
    });
  }

  // ─── CARREGAR ─────────────────────────────────────────────────────────────

  Future<void> loadUserInfo() async {
    _loadingPage = true;
    notifyListeners();

    try {
      _model = await _repository.getUserInfo();

      final authEmail = _auth.currentUser?.email;
      if (authEmail != null &&
          authEmail.isNotEmpty &&
          authEmail != _model?.email) {
        final currentUser = _auth.currentUser!;
        await _repository.syncEmailViaCloudFunction(currentUser);
        _model = _model?.copyWith(email: authEmail);
      }
    } catch (_) {
      _status = AccountInfoStatus.error;
    } finally {
      _loadingPage = false;
      notifyListeners();
    }
  }

  // ─── ALTERAR E-MAIL ───────────────────────────────────────────────────────

  Future<bool> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    _updatingEmail = true;
    _emailError    = null;
    notifyListeners();

    final result = await _repository.updateEmail(
      newEmail: newEmail,
      password: password,
    );

    _updatingEmail = false;

    if (result.success) {
      _model = _model?.copyWith(emailVerified: false);
      _status = AccountInfoStatus.success;
    } else {
      _emailError = result.errorMessage;
      _status     = AccountInfoStatus.error;
    }

    notifyListeners();
    return result.success;
  }

  // ─── LIMPAR ERROS ─────────────────────────────────────────────────────────

  void clearEmailError() {
    _emailError = null;
    notifyListeners();
  }

  // ─── DISPOSE ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
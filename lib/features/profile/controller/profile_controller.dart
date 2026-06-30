import 'package:empatia/features/profile/data/service/location_service.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:image_picker/image_picker.dart';

enum SaveState { idle, loading, success, error }

/// 🎮 PROFILE CONTROLLER
///
/// Gerencia estado da UI e chama os Services.
class ProfileController extends ChangeNotifier {
  final ProfileService _profileService;
  final LocationService _locationService;

  ProfileController(this._profileService, this._locationService);

  // ── Estado ───────────────────────────────────────────────
  SaveState _saveState = SaveState.idle;
  String? _errorMessage;
  bool _togglingMode = false;

  SaveState get saveState => _saveState;
  String? get errorMessage => _errorMessage;
  bool get togglingMode => _togglingMode;

  Stream<UserModel?> get userStream => _profileService.watchUser();

  void resetState() {
    _saveState = SaveState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  
  // ── Salvar perfil ────────────────────────────────────────
  Future<void> saveProfile({
    required String? name,
    required String? age,
    required String? status,
    required String? city,
    required String? state,
    required String? neighborhood,
    required String? profileEmoji,
    required String? sexo,
    required UserModel currentUser,
    String? socialFacebook,
    String? socialInstagram,
    String? socialX,
    double? latitude,
    double? longitude,
    XFile? profilePhoto,
    bool usePhoto = true,
  }) async {
    _saveState = SaveState.loading;
    notifyListeners();

    try {
      await _profileService.saveProfile(
        name: name,
        age: age,
        status: status,
        city: city,
        state: state,
        neighborhood: neighborhood,
        profileEmoji: profileEmoji,
        sexo: sexo,
        currentUser: currentUser,
        socialFacebook: socialFacebook,
        socialInstagram: socialInstagram,
        socialX: socialX,
        latitude: latitude,
        longitude: longitude,
        profilePhoto: profilePhoto,
        usePhoto: usePhoto,
      );
      _saveState = SaveState.success;
      notifyListeners();
    } catch (e) {
      _saveState = SaveState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // ── Alternar modo ────────────────────────────────────────

  /// 🔄 Alterna entre modo "donor" e "receiver".
  ///
  /// [currentMode] = modo atual do usuário (vem do UserModel.activeMode).
  /// Calcula o oposto e salva no Firebase.
  Future<void> toggleMode(String? currentMode) async {
    final newMode = (currentMode == 'donor') ? 'receiver' : 'donor';

    _togglingMode = true;
    notifyListeners();

    try {
      await _profileService.toggleMode(newMode);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    } finally {
      _togglingMode = false;
      notifyListeners();
    }
  }

  // ── Filhos ───────────────────────────────────────────────
  Future<bool> addChild({
    required String? name,
    required String? age,
    required String emoji,
  }) async {
    try {
      await _profileService.addChild(name: name, age: age, emoji: emoji);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  Future<bool> updateChild({
    required String childId,
    required String? name,
    required String? age,
    required String emoji,
  }) async {
    try {
      await _profileService.updateChild(
        childId: childId,
        name: name,
        age: age,
        emoji: emoji,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  Future<void> removeChild(String childId) async {
    await _profileService.removeChild(childId);
  }
}
import 'dart:io';
import 'package:empatia/features/profile/data/service/location_service.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:empatia/core/models/user_model.dart';

/// Estados possíveis da tela
enum SaveState { idle, loading, success, error }

/// 🎮 PROFILE CONTROLLER
/// 
/// É o CAIXA que atende os clientes.
/// Ele recebe pedidos da tela e chama os Services.
/// 
/// RESPONSABILIDADES:
/// - Gerenciar estado da UI (loading, sucesso, erro)
/// - Chamar Services quando botões são clicados
/// - Notificar a tela quando algo muda
class ProfileController extends ChangeNotifier {
  final ProfileService _profileService;
  final LocationService _locationService;

  ProfileController(this._profileService, this._locationService);

  // ── ESTADO ───────────────────────────────────────────
  SaveState _saveState = SaveState.idle;
  String? _errorMessage;

  SaveState get saveState => _saveState;
  String? get errorMessage => _errorMessage;

  // Stream do usuário (vem do service)
  Stream<UserModel?> get userStream => _profileService.watchUser();

  /// Reseta estado após mostrar mensagem
  void resetState() {
    _saveState = SaveState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  // ── SALVAR PERFIL ────────────────────────────────────
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
    double? latitude,   // ← NOVO
    double? longitude,  // ← NOVO
    File? profilePhoto, // ← NOVO: foto de perfil
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
        latitude: latitude,    // ← NOVO
        longitude: longitude,  // ← NOVO
        profilePhoto: profilePhoto, // ← NOVO
      );

      _saveState = SaveState.success;
      notifyListeners();
    } catch (e) {
      _saveState = SaveState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // ── FILHOS ───────────────────────────────────────────
  Future<bool> addChild({
    required String? name,
    required String? age,
    required String emoji,
  }) async {
    try {
      await _profileService.addChild(
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
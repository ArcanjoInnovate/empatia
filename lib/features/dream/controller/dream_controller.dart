import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/features/dream/data/service/dream_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum DreamSaveState { idle, loading, success, error }

/// 💭 DREAM CONTROLLER
///
/// Gerencia estado de UI para CRUD de sonhos.
class DreamController extends ChangeNotifier {
  final DreamService _service;

  DreamController(this._service);

  DreamSaveState _state = DreamSaveState.idle;
  String? _errorMessage;

  DreamSaveState get state => _state;
  String? get errorMessage => _errorMessage;

  void resetState() {
    _state = DreamSaveState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Stream dos sonhos do usuário
  Stream<List<DreamModel>> watchDreams() => _service.watchDreams();

  /// Adiciona um sonho
  Future<bool> addDream({
    required String? title,
    required String emoji,
    required UserModel currentUser,
    required String childId,
    required String childName,
    required String childEmoji,
    String? date,
    double? progress,
    XFile? photo,
  }) async {
    _state = DreamSaveState.loading;
    notifyListeners();

    try {
      await _service.addDream(
        title: title,
        emoji: emoji,
        currentUser: currentUser,
        childId: childId,
        childName: childName,
        childEmoji: childEmoji,
        date: date,
        progress: progress,
        photo: photo,
      );
      _state = DreamSaveState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = DreamSaveState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Edita um sonho
  /// Edita um sonho
  Future<bool> updateDream({
    required String dreamId,
    required String? title,
    required String emoji,
    required String childId,
    required String childName,
    required String childEmoji,
    required UserModel currentUser,
    String? date,
    double? progress,
    String? currentImageUrl,
    XFile? newPhoto,
    bool removeImage = false,
  }) async {
    _state = DreamSaveState.loading;
    notifyListeners();

    try {
      await _service.updateDream(
        dreamId: dreamId,
        title: title,
        emoji: emoji,
        childId: childId,
        childName: childName,
        childEmoji: childEmoji,
        currentUser: currentUser,
        date: date,
        progress: progress,
        currentImageUrl: currentImageUrl,
        newPhoto: newPhoto,
        removeImage: removeImage,
      );
      _state = DreamSaveState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = DreamSaveState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Atualiza só o progresso (chamado pelo slider no card)
  Future<void> updateProgress(String dreamId, double progress) async {
    try {
      await _service.updateProgress(dreamId, progress);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Remove um sonho (e sua imagem, se houver)
  Future<void> deleteDream(String dreamId, {String? imageUrl}) async {
    try {
      await _service.deleteDream(dreamId, imageUrl: imageUrl);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}
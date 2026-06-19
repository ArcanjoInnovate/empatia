import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/features/profile/data/service/cloudinary_service.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:image_picker/image_picker.dart';
import '../repository/dream_repository.dart';

/// 💭 DREAM SERVICE
///
/// Valida dados, faz upload opcional de imagem e orquestra operações de sonhos.
/// Usa [XFile] em vez de [File] para funcionar no web e no mobile.
class DreamService {
  final DreamRepository _repository;
  final CloudinaryService _cloudinaryService;

  DreamService(this._repository, this._cloudinaryService);

  Stream<List<DreamModel>> watchDreams() => _repository.watchDreams();

  /// Adiciona um sonho COM VALIDAÇÃO e upload opcional de imagem
  Future<String> addDream({
    required String? title,
    required String emoji,
    required UserModel currentUser,
    String? date,
    double? progress,
    XFile? photo,
  }) async {
    // ── Guarda: apenas usuários verificados podem criar sonhos ─────────────
    if (!ProfileService.isFullyVerified(currentUser)) {
      throw Exception(
        '❌ Verifique seu e-mail e complete seu perfil antes de criar um sonho.',
      );
    }
    // ────────────────────────────────────────────────────────────────────────

    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty) {
      throw Exception('❌ O título do sonho não pode ficar em branco.');
    }
    if (trimmed.length < 3) {
      throw Exception('❌ O título precisa ter pelo menos 3 caracteres.');
    }

    if (progress != null && (progress < 0 || progress > 1)) {
      throw Exception('❌ Progresso deve ser entre 0 e 100%.');
    }

    // Upload da imagem se fornecida
    String? imageUrl;
    if (photo != null) {
      imageUrl = await _cloudinaryService.uploadProfileImage(photo);
    }

    final dream = DreamModel(
      title: trimmed,
      emoji: emoji,
      date: date?.trim().isEmpty == true ? null : date?.trim(),
      progress: progress,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    return await _repository.addDream(dream);
  }

  /// Edita um sonho existente com suporte a troca/remoção de imagem
  Future<void> updateDream({
    required String dreamId,
    required String? title,
    required String emoji,
    String? date,
    double? progress,
    String? currentImageUrl,
    XFile? newPhoto,
    bool removeImage = false,
  }) async {
    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty) {
      throw Exception('❌ O título do sonho não pode ficar em branco.');
    }

    if (progress != null && (progress < 0 || progress > 1)) {
      throw Exception('❌ Progresso deve ser entre 0 e 100%.');
    }

    String? imageUrl = currentImageUrl;

    if (removeImage) {
      // Remove imagem do Cloudinary e limpa a URL
      if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
        await _cloudinaryService.deleteProfileImage(currentImageUrl);
      }
      imageUrl = null;
    } else if (newPhoto != null) {
      // Troca a imagem — faz upload da nova (apaga a antiga se existir)
      imageUrl = await _cloudinaryService.uploadProfileImage(
        newPhoto,
        oldImageUrl: currentImageUrl,
      );
    }

    final dream = DreamModel(
      id: dreamId,
      title: trimmed,
      emoji: emoji,
      date: date?.trim().isEmpty == true ? null : date?.trim(),
      progress: progress,
      imageUrl: imageUrl,
    );

    await _repository.updateDream(dream);
  }

  /// Atualiza só o progresso
  Future<void> updateProgress(String dreamId, double progress) async {
    if (progress < 0 || progress > 1) {
      throw Exception('❌ Progresso deve ser entre 0 e 100%.');
    }
    await _repository.updateProgress(dreamId, progress);
  }

  /// Remove um sonho e sua imagem associada
  Future<void> deleteDream(String dreamId, {String? imageUrl}) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await _cloudinaryService.deleteProfileImage(imageUrl);
    }
    await _repository.deleteDream(dreamId);
  }
}
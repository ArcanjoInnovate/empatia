import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/features/profile/data/service/cloudinary_service.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:image_picker/image_picker.dart';
import '../repository/dream_repository.dart';
import '../repository/dreams_feed_repository.dart';

/// 💭 DREAM SERVICE
///
/// Valida dados, faz upload opcional de imagem e orquestra operações de sonhos.
/// Usa [XFile] em vez de [File] para funcionar no web e no mobile.
///
/// Ao criar um sonho, escreve em dois nós simultaneamente:
///   • Users/{uid}/dreams/{id}  — sonhos do perfil do usuário
///   • Dreams/{id}              — feed global (denormalizado com dados do usuário)
class DreamService {
  final DreamRepository _repository;
  final CloudinaryService _cloudinaryService;
  final DreamsFeedRepository _feedRepository;

  DreamService(this._repository, this._cloudinaryService, this._feedRepository);

  Stream<List<DreamModel>> watchDreams() => _repository.watchDreams();

  /// Adiciona um sonho COM VALIDAÇÃO e upload opcional de imagem.
  /// Salva em Users/{uid}/dreams (perfil) e Dreams (feed global) ao mesmo tempo.
  /// O sonho é obrigatoriamente atrelado a um filho via [childId], [childName] e [childEmoji].
  Future<String> addDream({
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
      childId: childId,
      childName: childName,
      childEmoji: childEmoji,
      createdAt: DateTime.now(),
    );

    // Salva em Users/{uid}/dreams (perfil do usuário)
    final dreamId = await _repository.addDream(dream);

    // Salva em Dreams/{id} (feed global) com o mesmo ID gerado acima
    await _feedRepository.createDreamWithId(
      dreamId: dreamId,
      userId: currentUser.id ?? '',
      userName: currentUser.name ?? '',
      userProfileImage: currentUser.profileImage,
      userProfileEmoji: currentUser.profileEmoji,
      title: trimmed,
      date: date?.trim().isEmpty == true ? null : date?.trim(),
      emoji: emoji,
      imageUrl: imageUrl,
      progress: progress ?? 0.0,
      childId: childId,
      childName: childName,
      childEmoji: childEmoji,
      city: currentUser.city,
      state: currentUser.state,
      latitude: currentUser.latitude,
      longitude: currentUser.longitude,
    );

    return dreamId;
  }

  /// Edita um sonho existente com suporte a troca/remoção de imagem e filho.
  /// Atualiza Users/{uid}/dreams (perfil) e Dreams/{id} (feed global).
  Future<void> updateDream({
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
    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty) {
      throw Exception('❌ O título do sonho não pode ficar em branco.');
    }

    if (progress != null && (progress < 0 || progress > 1)) {
      throw Exception('❌ Progresso deve ser entre 0 e 100%.');
    }

    String? imageUrl = currentImageUrl;

    if (removeImage) {
      if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
        await _cloudinaryService.deleteProfileImage(currentImageUrl);
      }
      imageUrl = null;
    } else if (newPhoto != null) {
      imageUrl = await _cloudinaryService.uploadProfileImage(
        newPhoto,
        oldImageUrl: currentImageUrl,
      );
    }

    final cleanDate = date?.trim().isEmpty == true ? null : date?.trim();

    final dream = DreamModel(
      id: dreamId,
      title: trimmed,
      emoji: emoji,
      date: cleanDate,
      progress: progress,
      imageUrl: imageUrl,
      childId: childId,
      childName: childName,
      childEmoji: childEmoji,
    );

    await Future.wait([
      _repository.updateDream(dream),
      _feedRepository.updateDream(
        dreamId: dreamId,
        title: trimmed,
        emoji: emoji,
        date: cleanDate,
        imageUrl: imageUrl,
        progress: progress,
        childId: childId,
        childName: childName,
        childEmoji: childEmoji,
        city: currentUser.city,
        state: currentUser.state,
        latitude: currentUser.latitude,
        longitude: currentUser.longitude,
      ),
    ]);
  }

  /// Atualiza só o progresso
  Future<void> updateProgress(String dreamId, double progress) async {
    if (progress < 0 || progress > 1) {
      throw Exception('❌ Progresso deve ser entre 0 e 100%.');
    }
    await _repository.updateProgress(dreamId, progress);
  }

  /// Remove um sonho e sua imagem associada (perfil + feed global)
  Future<void> deleteDream(String dreamId, {String? imageUrl}) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await _cloudinaryService.deleteProfileImage(imageUrl);
    }
    await Future.wait([
      _repository.deleteDream(dreamId),
      _feedRepository.deleteDream(dreamId),
    ]);
  }
}
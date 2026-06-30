import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/features/profile/data/service/storage_service.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:image_picker/image_picker.dart';
import '../repository/dream_repository.dart';
import '../repository/dreams_feed_repository.dart';

/// ðŸ’­ DREAM SERVICE
///
/// Orquestra criaÃ§Ã£o e ediÃ§Ã£o de sonhos.
/// Ao receber uma [category], deriva automaticamente o [emoji] correspondente
/// â€” o usuÃ¡rio nunca seleciona emoji diretamente.
///
/// Grava em dois nÃ³s simultaneamente:
///   â€¢ Users/{uid}/dreams/{id}  â€” perfil do usuÃ¡rio
///   â€¢ Dreams/{id}              â€” feed global (denormalizado)
class DreamService {
  final DreamRepository _repository;
  final StorageService _storageService;
  final DreamsFeedRepository _feedRepository;

  DreamService(this._repository, this._storageService, this._feedRepository);

  Stream<List<DreamModel>> watchDreams() => _repository.watchDreams();

  // â”€â”€ Mapeamento categoria â†’ emoji â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //
  // Mantido centralizado aqui para que qualquer parte do app que precise
  // do emoji a partir da categoria use um Ãºnico ponto de verdade.
  // Deve estar em sincronia com _kDreamCategories em dream_form_sheet.dart
  // e com _categoryMatchesEmoji em search_repository.dart.

  static String emojiForCategory(String? category) {
    switch (category) {
      case 'clothes':   return 'ðŸ‘•';
      case 'toys':      return 'ðŸ§¸';
      case 'books':     return 'ðŸ“š';
      case 'food':      return 'ðŸŽ';
      case 'furniture': return 'ðŸ›‹ï¸';
      default:          return 'ðŸ“¦'; // 'others' e valores desconhecidos
    }
  }

  // â”€â”€ Adicionar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<String> addDream({
    required String? title,
    required String category,   // â† substituiu emoji
    required UserModel currentUser,
    required String childId,
    required String childName,
    required String childEmoji,
    int? childAge,
    String? date,
    double? progress,
    XFile? photo,
  }) async {
    if (!ProfileService.isFullyVerified(currentUser)) {
      throw Exception(
        'âŒ Verifique seu e-mail e complete seu perfil antes de criar um sonho.',
      );
    }

    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty) {
      throw Exception('âŒ O tÃ­tulo do sonho nÃ£o pode ficar em branco.');
    }
    if (trimmed.length < 3) {
      throw Exception('âŒ O tÃ­tulo precisa ter pelo menos 3 caracteres.');
    }
    if (progress != null && (progress < 0 || progress > 1)) {
      throw Exception('âŒ Progresso deve ser entre 0 e 100%.');
    }

    String? imageUrl;
    if (photo != null) {
      imageUrl = await _storageService.uploadProfileImage(photo);
    }

    // Deriva o emoji da categoria â€” o usuÃ¡rio nÃ£o escolhe mais o emoji
    final emoji = emojiForCategory(category);

    final dream = DreamModel(
      title:      trimmed,
      emoji:      emoji,
      category:   category,
      date:       date?.trim().isEmpty == true ? null : date?.trim(),
      progress:   progress,
      imageUrl:   imageUrl,
      childId:    childId,
      childName:  childName,
      childEmoji: childEmoji,
      childAge:   childAge,
      createdAt:  DateTime.now(),
    );

    final dreamId = await _repository.addDream(dream);

    await _feedRepository.createDreamWithId(
      dreamId:          dreamId,
      userId:           currentUser.id ?? '',
      userName:         currentUser.name ?? '',
      userProfileImage: currentUser.profileImage,
      userProfileEmoji: currentUser.profileEmoji,
      title:            trimmed,
      date:             date?.trim().isEmpty == true ? null : date?.trim(),
      emoji:            emoji,
      category:         category,
      imageUrl:         imageUrl,
      progress:         progress ?? 0.0,
      childId:          childId,
      childName:        childName,
      childEmoji:       childEmoji,
      childAge:         childAge,
      city:             currentUser.city,
      state:            currentUser.state,
      latitude:         currentUser.latitude,
      longitude:        currentUser.longitude,
    );

    return dreamId;
  }

  // â”€â”€ Editar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> updateDream({
    required String dreamId,
    required String? title,
    required String category,   // â† substituiu emoji
    required String childId,
    required String childName,
    required String childEmoji,
    required UserModel currentUser,
    int? childAge,
    String? date,
    double? progress,
    String? currentImageUrl,
    XFile? newPhoto,
    bool removeImage = false,
  }) async {
    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty) {
      throw Exception('âŒ O tÃ­tulo do sonho nÃ£o pode ficar em branco.');
    }
    if (progress != null && (progress < 0 || progress > 1)) {
      throw Exception('âŒ Progresso deve ser entre 0 e 100%.');
    }

    String? imageUrl = currentImageUrl;

    if (removeImage) {
      if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
        await _storageService.deleteProfileImage(currentImageUrl);
      }
      imageUrl = null;
    } else if (newPhoto != null) {
      imageUrl = await _storageService.uploadProfileImage(
        newPhoto,
        oldImageUrl: currentImageUrl,
      );
    }

    final cleanDate = date?.trim().isEmpty == true ? null : date?.trim();
    final emoji     = emojiForCategory(category);

    final dream = DreamModel(
      id:         dreamId,
      title:      trimmed,
      emoji:      emoji,
      category:   category,
      date:       cleanDate,
      progress:   progress,
      imageUrl:   imageUrl,
      childId:    childId,
      childName:  childName,
      childEmoji: childEmoji,
      childAge:   childAge,
    );

    await Future.wait([
      _repository.updateDream(dream),
      _feedRepository.updateDream(
        dreamId:    dreamId,
        title:      trimmed,
        emoji:      emoji,
        category:   category,
        date:       cleanDate,
        imageUrl:   imageUrl,
        progress:   progress,
        childId:    childId,
        childName:  childName,
        childEmoji: childEmoji,
        childAge:   childAge,
        city:       currentUser.city,
        state:      currentUser.state,
        latitude:   currentUser.latitude,
        longitude:  currentUser.longitude,
      ),
    ]);
  }

  Future<void> updateProgress(String dreamId, double progress) async {
    if (progress < 0 || progress > 1) {
      throw Exception('âŒ Progresso deve ser entre 0 e 100%.');
    }
    await _repository.updateProgress(dreamId, progress);
  }

  Future<void> deleteDream(String dreamId, {String? imageUrl}) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await _storageService.deleteProfileImage(imageUrl);
    }
    await Future.wait([
      _repository.deleteDream(dreamId),
      _feedRepository.deleteDream(dreamId),
    ]);
  }
}
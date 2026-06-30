import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/features/donation/data/repository/donation_repository.dart';
import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:empatia/features/profile/data/service/storage_service.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:image_picker/image_picker.dart'; // XFile

/// ðŸŽ DONATION SERVICE
///
/// Valida dados, faz upload da foto e salva no Firebase.
/// Usa [XFile] em vez de [File] para funcionar no web e no mobile.
class DonationService {
  final DonationRepository _repository;
  final StorageService _storageService;

  DonationService(this._repository, this._storageService);

  Stream<List<DonationModel>> watchMyDonations() =>
      _repository.watchMyDonations();

  Stream<List<DonationModel>> watchDonationsByCity(String city) =>
      _repository.watchDonationsByCity(city);

  Future<String> createDonation({
    required String? title,
    required String? category,
    required String? description,
    required XFile photo,
    required UserModel currentUser,
    String? emoji,
  }) async {
    // â”€â”€ Guarda: apenas usuÃ¡rios verificados podem criar ofertas â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (!ProfileService.isFullyVerified(currentUser)) {
      throw Exception(
        'âŒ Verifique seu e-mail e complete seu perfil antes de criar uma oferta.',
      );
    }
    // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    final trimmedTitle = title?.trim() ?? '';
    if (trimmedTitle.isEmpty) {
      throw Exception('âŒ O nome do item nÃ£o pode ficar em branco.');
    }
    if (trimmedTitle.length < 3) {
      throw Exception('âŒ O nome precisa ter pelo menos 3 caracteres.');
    }

    final trimmedDesc = description?.trim() ?? '';
    if (trimmedDesc.isEmpty) {
      throw Exception('âŒ A descriÃ§Ã£o nÃ£o pode ficar em branco.');
    }
    if (trimmedDesc.length < 10) {
      throw Exception('âŒ A descriÃ§Ã£o precisa ter pelo menos 10 caracteres.');
    }

    final validCategories = [
      'clothes', 'toys', 'books', 'food', 'furniture', 'other',
    ];
    if (category == null || !validCategories.contains(category)) {
      throw Exception('âŒ Selecione uma categoria.');
    }

    if (!ProfileService.isFullyVerified(currentUser)) {
      throw Exception(
        'âŒ Verifique seu e-mail e complete seu perfil antes de criar uma oferta.',
      );
    }
    if (currentUser.city == null || currentUser.state == null) {
      throw Exception(
          'âŒ Complete sua localizaÃ§Ã£o no perfil antes de criar uma oferta.');
    }

    final photoUrl = await _storageService.uploadProfileImage(photo);

    final donation = DonationModel(
      title: trimmedTitle,
      description: trimmedDesc,
      photoUrl: photoUrl,
      emoji: emoji ?? DonationModel.categoryEmoji(category),
      category: category,
      status: 'available',
      city: currentUser.city,
      state: currentUser.state,
      latitude: currentUser.latitude,
      longitude: currentUser.longitude,
      ownerName: currentUser.name,
      ownerPhotoUrl: currentUser.profileImage,
      createdAt: DateTime.now(),
    );

    return await _repository.createDonation(donation);
  }

  Future<void> updateDonation({
    required String donationId,
    required String? title,
    required String? category,
    required String? description,
    required String? currentPhotoUrl,
    XFile? newPhoto,
    String? emoji,
  }) async {
    final trimmedTitle = title?.trim() ?? '';
    if (trimmedTitle.isEmpty) {
      throw Exception('âŒ O nome do item nÃ£o pode ficar em branco.');
    }

    final trimmedDesc = description?.trim() ?? '';
    if (trimmedDesc.isEmpty) {
      throw Exception('âŒ A descriÃ§Ã£o nÃ£o pode ficar em branco.');
    }

    String? photoUrl = currentPhotoUrl;
    if (newPhoto != null) {
      photoUrl = await _storageService.uploadProfileImage(
        newPhoto,
        oldImageUrl: currentPhotoUrl,
      );
    }

    final donation = DonationModel(
      id: donationId,
      title: trimmedTitle,
      description: trimmedDesc,
      photoUrl: photoUrl,
      emoji: emoji ?? DonationModel.categoryEmoji(category),
      category: category,
    );

    await _repository.updateDonation(donation);
  }

  Future<void> updateStatus(String donationId, String newStatus) async {
    final valid = ['available', 'reserved', 'donated'];
    if (!valid.contains(newStatus)) {
      throw Exception('âŒ Status invÃ¡lido: $newStatus');
    }
    await _repository.updateStatus(donationId, newStatus);
  }

  Future<void> deleteDonation(String donationId, {String? photoUrl}) async {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      await _storageService.deleteProfileImage(photoUrl);
    }
    await _repository.deleteDonation(donationId);
  }
}
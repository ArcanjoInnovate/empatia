import 'package:empatia/core/data/models/child_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:image_picker/image_picker.dart'; // XFile
import '../repository/profile_repository.dart';
import 'cloudinary_service.dart';

/// 👤 PROFILE SERVICE
///
/// Valida dados e orquestra chamadas ao Repository.
/// Usa [XFile] em vez de [File] para funcionar no web e no mobile.
class ProfileService {
  final ProfileRepository _repository;
  final CloudinaryService _cloudinaryService;

  ProfileService(this._repository, this._cloudinaryService);

  Stream<UserModel?> watchUser() => _repository.watchUser();

  // ── Campos obrigatórios para o perfil ser considerado completo ──────────────
  //
  // Para [isProfileComplete] retornar true, o usuário precisa ter:
  //   • name        — nome preenchido
  //   • age         — idade válida
  //   • sexo        — sexo selecionado
  //   • city        — cidade preenchida
  //   • state       — estado preenchido
  //   • neighborhood — bairro preenchido
  //   • profileEmoji ou profileImage — avatar definido
  //
  static bool isProfileComplete(UserModel user) {
    final hasName  = (user.name?.trim().isNotEmpty ?? false);
    final hasAge   = user.age != null;
    final hasSexo  = (user.sexo?.trim().isNotEmpty ?? false);
    final hasCity  = (user.city?.trim().isNotEmpty ?? false);
    final hasState = (user.state?.trim().isNotEmpty ?? false);
    final hasNeighborhood = (user.neighborhood?.trim().isNotEmpty ?? false);
    final hasAvatar = (user.profileEmoji?.trim().isNotEmpty ?? false) ||
        (user.profileImage?.trim().isNotEmpty ?? false);

    return hasName &&
        hasAge &&
        hasSexo &&
        hasCity &&
        hasState &&
        hasNeighborhood &&
        hasAvatar;
  }

  /// Retorna true quando as duas verificações estão concluídas:
  ///   1. E-mail verificado     (emailVerified == true)
  ///   2. Perfil completo       (profileCompleted == true)
  static bool isFullyVerified(UserModel user) {
    return (user.emailVerified == true) &&
        (user.profileCompleted == true);
  }

  /// Salva perfil COM VALIDAÇÃO.
  ///
  /// Após salvar, verifica automaticamente se o perfil foi completado
  /// e, em caso positivo, escreve [profileCompleted = true] no banco.
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
    double? latitude,
    double? longitude,
    XFile? profilePhoto,
  }) async {
    final trimmedName = name?.trim() ?? '';
    if (trimmedName.isEmpty) {
      throw Exception('❌ O nome não pode ficar em branco.');
    }
    if (trimmedName.length < 2) {
      throw Exception('❌ O nome precisa ter pelo menos 2 letras.');
    }

    int? parsedAge;
    if (age != null && age.trim().isNotEmpty) {
      parsedAge = int.tryParse(age.trim());
      if (parsedAge == null) {
        throw Exception('❌ Idade inválida. Digite só números.');
      }
      if (parsedAge < 18 || parsedAge > 99) {
        throw Exception('❌ Idade deve ser entre 18 e 99 anos.');
      }
    }

    String? profileImageUrl = currentUser.profileImage;

    if (profilePhoto != null) {
      profileImageUrl = await _cloudinaryService.uploadProfileImage(
        profilePhoto,
        oldImageUrl: currentUser.profileImage,
      );
    }

    final updatedUser = currentUser.copyWith(
      name: trimmedName,
      age: parsedAge,
      status: status?.trim().isEmpty == true ? null : status?.trim(),
      city: city?.trim().isEmpty == true ? null : city?.trim(),
      state: state?.trim().isEmpty == true ? null : state?.trim(),
      neighborhood:
          neighborhood?.trim().isEmpty == true ? null : neighborhood?.trim(),
      profileEmoji: profileEmoji,
      sexo: sexo,
      latitude: latitude,
      longitude: longitude,
      profileImage: profileImageUrl,
    );

    await _repository.updateProfile(updatedUser);

    // ── Verifica automaticamente se o perfil foi completado ─────────────────
    // Só marca se ainda não estava marcado (evita writes desnecessários).
    if (updatedUser.profileCompleted != true && isProfileComplete(updatedUser)) {
      await _repository.markProfileCompleted();
    }
  }

  /// 🔄 ALTERNA MODO do usuário: "donor" ↔ "receiver"
  Future<void> toggleMode(String newMode) async {
    if (newMode != 'donor' && newMode != 'receiver') {
      throw Exception('❌ Modo inválido: $newMode');
    }
    await _repository.toggleMode(newMode);
  }

  /// Adiciona filho COM VALIDAÇÃO
  Future<void> addChild({
    required String? name,
    required String? age,
    required String emoji,
  }) async {
    final trimmedName = name?.trim() ?? '';
    if (trimmedName.isEmpty) {
      throw Exception('❌ O nome do filho não pode ficar em branco.');
    }

    int? parsedAge;
    if (age != null && age.trim().isNotEmpty) {
      parsedAge = int.tryParse(age.trim());
      if (parsedAge == null || parsedAge < 0 || parsedAge > 18) {
        throw Exception('❌ Idade do filho deve ser entre 0 e 18 anos.');
      }
    }

    final child = ChildModel(name: trimmedName, age: parsedAge, emoji: emoji);
    await _repository.addChild(child);
  }

  /// Atualiza filho
  Future<void> updateChild({
    required String childId,
    required String? name,
    required String? age,
    required String emoji,
  }) async {
    final trimmedName = name?.trim() ?? '';
    if (trimmedName.isEmpty) {
      throw Exception('❌ O nome do filho não pode ficar em branco.');
    }
    int? parsedAge;
    if (age != null && age.trim().isNotEmpty) {
      parsedAge = int.tryParse(age.trim());
    }
    final child = ChildModel(
      id: childId,
      name: trimmedName,
      age: parsedAge,
      emoji: emoji,
    );
    await _repository.updateChild(child);
  }

  /// Remove filho
  Future<void> removeChild(String childId) async {
    await _repository.removeChild(childId);
  }
}
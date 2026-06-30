import 'package:empatia/core/data/models/child_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:image_picker/image_picker.dart'; // XFile
import '../repository/profile_repository.dart';
import 'storage_service.dart';

/// ðŸ‘¤ PROFILE SERVICE
///
/// Valida dados e orquestra chamadas ao Repository.
/// Usa [XFile] em vez de [File] para funcionar no web e no mobile.
class ProfileService {
  final ProfileRepository _repository;
  final StorageService _storageService;

  ProfileService(this._repository, this._storageService);

  Stream<UserModel?> watchUser() => _repository.watchUser();

  /// ConstrÃ³i a URL completa de uma rede social a partir do que a pessoa
  /// digitou no campo (sÃ³ o "@usuario", sem domÃ­nio):
  ///   â€¢ vazio/em branco â†’ null (remove o link salvo)
  ///   â€¢ remove @ e barras que tenham sobrado
  ///   â€¢ monta "https://{domain}/{usuario}"
  ///
  /// O domÃ­nio NUNCA vem do usuÃ¡rio (evita link incorreto/malicioso) â€”
  /// Ã© sempre o fixo da prÃ³pria plataforma, escolhido por cÃ³digo.
  static String? _buildSocialUrl(String? rawUsername, String domain) {
    var v = rawUsername?.trim();
    if (v == null || v.isEmpty) return null;
    if (v.contains('/')) {
      final parts = v.split('/').where((p) => p.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) v = parts.last;
    }
    v = v.replaceAll('@', '').trim();
    if (v.isEmpty) return null;
    return 'https://$domain/$v';
  }

  // â”€â”€ Campos obrigatÃ³rios para o perfil ser considerado completo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //
  // Para [isProfileComplete] retornar true, o usuÃ¡rio precisa ter:
  //   â€¢ name        â€” nome preenchido
  //   â€¢ age         â€” idade vÃ¡lida
  //   â€¢ sexo        â€” sexo selecionado
  //   â€¢ city        â€” cidade preenchida
  //   â€¢ state       â€” estado preenchido
  //   â€¢ neighborhood â€” bairro preenchido
  //   â€¢ profileEmoji ou profileImage â€” avatar definido
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

  /// Retorna true quando as duas verificaÃ§Ãµes estÃ£o concluÃ­das:
  ///   1. E-mail verificado     (emailVerified == true)
  ///   2. Perfil completo       (profileCompleted == true)
  static bool isFullyVerified(UserModel user) {
    return (user.emailVerified == true) &&
        (user.profileCompleted == true);
  }

  /// Salva perfil COM VALIDAÃ‡ÃƒO.
  ///
  /// ApÃ³s salvar, verifica automaticamente se o perfil foi completado
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
    String? socialFacebook,
    String? socialInstagram,
    String? socialX,
    double? latitude,
    double? longitude,
    XFile? profilePhoto,
    bool usePhoto = true,
  }) async {
    final trimmedName = name?.trim() ?? '';
    if (trimmedName.isEmpty) {
      throw Exception('âŒ O nome nÃ£o pode ficar em branco.');
    }
    if (trimmedName.length < 2) {
      throw Exception('âŒ O nome precisa ter pelo menos 2 letras.');
    }

    int? parsedAge;
    if (age != null && age.trim().isNotEmpty) {
      parsedAge = int.tryParse(age.trim());
      if (parsedAge == null) {
        throw Exception('âŒ Idade invÃ¡lida. Digite sÃ³ nÃºmeros.');
      }
      if (parsedAge < 18 || parsedAge > 99) {
        throw Exception('âŒ Idade deve ser entre 18 e 99 anos.');
      }
    }

    String? profileImageUrl = currentUser.profileImage;
    bool clearPhoto = false;

    if (profilePhoto != null) {
      profileImageUrl = await _storageService.uploadProfileImage(
        profilePhoto,
        oldImageUrl: currentUser.profileImage,
      );
    } else if (!usePhoto) {
      // UsuÃ¡rio trocou explicitamente para o modo "Avatar" (sem foto nova
      // selecionada) â€” limpa a foto antiga para o avatar prevalecer.
      profileImageUrl = null;
      clearPhoto = true;
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
      // Facebook: sem campo de ediÃ§Ã£o ativo no momento â€” nÃ£o enviamos
      // socialFacebook aqui, entÃ£o o UserModel.copyWith preserva o que
      // jÃ¡ estava salvo (ver comentÃ¡rio no copyWith).
      socialInstagram: _buildSocialUrl(socialInstagram, 'instagram.com'),
      socialX: _buildSocialUrl(socialX, 'x.com'),
      latitude: latitude,
      longitude: longitude,
      profileImage: profileImageUrl,
      clearProfileImage: clearPhoto,
    );

    await _repository.updateProfile(updatedUser);

    // â”€â”€ Verifica automaticamente se o perfil foi completado â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // SÃ³ marca se ainda nÃ£o estava marcado (evita writes desnecessÃ¡rios).
    if (updatedUser.profileCompleted != true && isProfileComplete(updatedUser)) {
      await _repository.markProfileCompleted();
    }
  }

  /// ðŸ”„ ALTERNA MODO do usuÃ¡rio: "donor" â†” "receiver"
  Future<void> toggleMode(String newMode) async {
    if (newMode != 'donor' && newMode != 'receiver') {
      throw Exception('âŒ Modo invÃ¡lido: $newMode');
    }
    await _repository.toggleMode(newMode);
  }

  /// Adiciona filho COM VALIDAÃ‡ÃƒO
  Future<void> addChild({
    required String? name,
    required String? age,
    required String emoji,
  }) async {
    final trimmedName = name?.trim() ?? '';
    if (trimmedName.isEmpty) {
      throw Exception('âŒ O nome do filho nÃ£o pode ficar em branco.');
    }

    int? parsedAge;
    if (age != null && age.trim().isNotEmpty) {
      parsedAge = int.tryParse(age.trim());
      if (parsedAge == null || parsedAge < 0 || parsedAge > 18) {
        throw Exception('âŒ Idade do filho deve ser entre 0 e 18 anos.');
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
      throw Exception('âŒ O nome do filho nÃ£o pode ficar em branco.');
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
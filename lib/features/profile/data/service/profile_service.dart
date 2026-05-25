import 'dart:io';
import 'package:empatia/core/models/child_model.dart';
import 'package:empatia/core/models/user_model.dart';
import '../repository/profile_repository.dart';
import 'cloudinary_service.dart';

/// 👤 PROFILE SERVICE
/// 
/// É o GERENTE do perfil.
/// Ele valida tudo antes de salvar no banco.
/// 
/// RESPONSABILIDADES:
/// - Validar nome, idade, etc
/// - Garantir que dados estão corretos
/// - Chamar o Repository para salvar
/// - Gerenciar upload de fotos (e deletar antigas)
class ProfileService {
  final ProfileRepository _repository;
  final CloudinaryService _cloudinaryService;

  ProfileService(this._repository, this._cloudinaryService);

  Stream<UserModel?> watchUser() => _repository.watchUser();

  /// Salva perfil COM VALIDAÇÃO
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
    File? profilePhoto, // ← arquivo de foto nova
  }) async {
    // VALIDAÇÃO: Nome não pode estar vazio
    final trimmedName = name?.trim() ?? '';
    if (trimmedName.isEmpty) {
      throw Exception('❌ O nome não pode ficar em branco.');
    }
    if (trimmedName.length < 2) {
      throw Exception('❌ O nome precisa ter pelo menos 2 letras.');
    }

    // VALIDAÇÃO: Idade
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

    // UPLOAD DE FOTO (se fornecida)
    String? profileImageUrl = currentUser.profileImage;
    
    if (profilePhoto != null) {
      try {
        // 🔥 PASSA A URL ANTIGA para deletar antes do upload
        profileImageUrl = await _cloudinaryService.uploadProfileImage(
          profilePhoto,
          oldImageUrl: currentUser.profileImage, // ← URL antiga
        );
      } catch (e) {
        // Repassa o erro do upload
        rethrow;
      }
    }

    // Cria novo objeto com dados atualizados
    final updatedUser = currentUser.copyWith(
      name: trimmedName,
      age: parsedAge,
      status: status?.trim().isEmpty == true ? null : status?.trim(),
      city: city?.trim().isEmpty == true ? null : city?.trim(),
      state: state?.trim().isEmpty == true ? null : state?.trim(),
      neighborhood: neighborhood?.trim().isEmpty == true 
          ? null 
          : neighborhood?.trim(),
      profileEmoji: profileEmoji,
      sexo: sexo,
      latitude: latitude,
      longitude: longitude,
      profileImage: profileImageUrl, // ← URL da foto nova
    );

    // Salva no banco
    await _repository.updateProfile(updatedUser);
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

    final child = ChildModel(
      name: trimmedName,
      age: parsedAge,
      emoji: emoji,
    );

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
import 'dart:io';
import 'package:flutter/material.dart';
import '../repository/cloudinary_repository.dart';

/// 📸 CLOUDINARY SERVICE
/// 
/// É o GERENTE de fotos.
/// Valida imagens antes de enviar para o Cloudinary.
/// 
/// RESPONSABILIDADES:
/// - Validar tamanho e formato de imagens
/// - Chamar o Repository para upload
/// - Deletar imagens antigas antes de fazer novo upload
/// - Garantir que dados estão corretos
class CloudinaryService {
  final CloudinaryRepository _repository;

  CloudinaryService(this._repository);

  /// Tamanho máximo: 5MB
  static const int _maxSizeBytes = 5 * 1024 * 1024;

  /// Formatos aceitos
  static const List<String> _allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  /// Faz upload de uma imagem COM VALIDAÇÃO
  /// 
  /// [file] = arquivo de imagem
  /// [oldImageUrl] = URL da imagem antiga (será deletada se fornecida)
  /// 
  /// Retorna URL pública da nova imagem
  Future<String> uploadProfileImage(
    File file, {
    String? oldImageUrl,
  }) async {
    // VALIDAÇÃO: Arquivo existe
    if (!file.existsSync()) {
      throw Exception('❌ Arquivo de imagem não encontrado.');
    }

    // VALIDAÇÃO: Tamanho do arquivo
    final fileSize = await file.length();
    if (fileSize > _maxSizeBytes) {
      final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      throw Exception(
        '❌ Imagem muito grande ($sizeMB MB). Máximo permitido: 5 MB.',
      );
    }

    // VALIDAÇÃO: Extensão do arquivo
    final fileName = file.path.toLowerCase();
    final hasValidExtension = _allowedExtensions.any(
      (ext) => fileName.endsWith(ext),
    );

    if (!hasValidExtension) {
      throw Exception(
        '❌ Formato inválido. Use: ${_allowedExtensions.join(", ")}',
      );
    }

    debugPrint('📤 Enviando imagem (${(fileSize / 1024).toStringAsFixed(0)} KB)...');

    // 1️⃣ DELETA imagem antiga ANTES de fazer upload
    if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
      await _deleteOldImage(oldImageUrl);
    }

    // 2️⃣ Faz upload da nova imagem
    final imageUrl = await _repository.uploadImage(file);
    
    return imageUrl;
  }

  /// Deleta uma imagem antiga do Cloudinary
  /// 
  /// [imageUrl] = URL completa da imagem
  Future<void> _deleteOldImage(String imageUrl) async {
    try {
      debugPrint('🗑️ Tentando deletar imagem antiga...');
      
      // Extrai public_id da URL
      final publicId = _repository.extractPublicId(imageUrl);
      
      if (publicId == null) {
        debugPrint('⚠️ Não foi possível extrair public_id da URL');
        return;
      }

      // Deleta via Cloud Function
      await _repository.deleteImageViaFunction(publicId);
      
      debugPrint('✅ Imagem antiga removida: $publicId');
      
    } catch (e) {
      // Não falhar se deleção não funcionar
      debugPrint('⚠️ Erro ao deletar imagem antiga (continuando): $e');
    }
  }

  /// Remove uma imagem de perfil (quando o usuário remove a foto)
  /// 
  /// [imageUrl] = URL completa da imagem
  Future<void> deleteProfileImage(String imageUrl) async {
    await _deleteOldImage(imageUrl);
  }
}
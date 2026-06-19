import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // XFile
import '../repository/cloudinary_repository.dart';

/// 📸 CLOUDINARY SERVICE
///
/// É o GERENTE de fotos.
/// Valida imagens antes de enviar para o Cloudinary.
///
/// Usa [XFile] em vez de [File] para funcionar no web e no mobile.
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
  /// [file] = XFile (funciona no web e no mobile)
  /// [oldImageUrl] = URL da imagem antiga (será deletada se fornecida)
  ///
  /// Retorna URL pública da nova imagem
  Future<String> uploadProfileImage(
    XFile file, {
    String? oldImageUrl,
  }) async {
    // Lê os bytes uma vez — funciona no web (blob URL) e no mobile
    final bytes = await file.readAsBytes();

    // VALIDAÇÃO: Arquivo tem conteúdo
    if (bytes.isEmpty) {
      throw Exception('❌ Arquivo de imagem não encontrado ou vazio.');
    }

    // VALIDAÇÃO: Tamanho do arquivo
    final fileSize = bytes.length;
    if (fileSize > _maxSizeBytes) {
      final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      throw Exception(
        '❌ Imagem muito grande ($sizeMB MB). Máximo permitido: 5 MB.',
      );
    }

    // VALIDAÇÃO: Extensão do arquivo
    final fileName = file.name.toLowerCase();
    final hasValidExtension = _allowedExtensions.any(
      (ext) => fileName.endsWith(ext),
    );

    if (!hasValidExtension) {
      throw Exception(
        '❌ Formato inválido. Use: ${_allowedExtensions.join(", ")}',
      );
    }

    debugPrint(
        '📤 Enviando imagem (${(fileSize / 1024).toStringAsFixed(0)} KB)...');

    // 1️⃣ Deleta imagem antiga ANTES de fazer upload
    if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
      await _deleteOldImage(oldImageUrl);
    }

    // 2️⃣ Faz upload passando os bytes (web + mobile safe)
    final imageUrl = await _repository.uploadImage(bytes, fileName: fileName);

    return imageUrl;
  }

  /// Deleta uma imagem antiga do Cloudinary
  Future<void> _deleteOldImage(String imageUrl) async {
    try {
      debugPrint('🗑️ Tentando deletar imagem antiga...');

      final publicId = _repository.extractPublicId(imageUrl);

      if (publicId == null) {
        debugPrint('⚠️ Não foi possível extrair public_id da URL');
        return;
      }

      await _repository.deleteImageViaFunction(publicId);

      debugPrint('✅ Imagem antiga removida: $publicId');
    } catch (e) {
      // Não falha se deleção não funcionar
      debugPrint('⚠️ Erro ao deletar imagem antiga (continuando): $e');
    }
  }

  /// Remove uma imagem (quando o usuário remove a foto)
  Future<void> deleteProfileImage(String imageUrl) async {
    await _deleteOldImage(imageUrl);
  }
}
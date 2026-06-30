import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // XFile
import '../repository/storage_repository.dart';

/// ðŸ“¸ STORAGE SERVICE
///
/// Ã‰ o GERENTE de fotos.
/// Valida imagens antes de enviar para o Firebase Storage (substitui o
/// antigo CloudinaryService).
///
/// Usa [XFile] em vez de [File] para funcionar no web e no mobile.
///
/// RESPONSABILIDADES:
/// - Validar tamanho e formato de imagens
/// - Chamar o Repository para upload
/// - Deletar imagens antigas antes de fazer novo upload
/// - Garantir que dados estÃ£o corretos
///
/// MantÃ©m os mesmos nomes de mÃ©todo do antigo CloudinaryService
/// (uploadProfileImage / deleteProfileImage) para que ProfileService,
/// DonationService e DreamService nÃ£o precisem mudar nada alÃ©m do
/// import e do tipo da dependÃªncia injetada.
class StorageService {
  final StorageRepository _repository;

  StorageService(this._repository);

  /// Tamanho mÃ¡ximo: 5MB
  static const int _maxSizeBytes = 5 * 1024 * 1024;

  /// Formatos aceitos
  static const List<String> _allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  /// Faz upload de uma imagem COM VALIDAÃ‡ÃƒO
  ///
  /// [file] = XFile (funciona no web e no mobile)
  /// [oldImageUrl] = URL da imagem antiga (serÃ¡ deletada se fornecida)
  ///
  /// Retorna URL pÃºblica da nova imagem
  Future<String> uploadProfileImage(
    XFile file, {
    String? oldImageUrl,
  }) async {
    // LÃª os bytes uma vez â€” funciona no web (blob URL) e no mobile
    final bytes = await file.readAsBytes();

    // VALIDAÃ‡ÃƒO: Arquivo tem conteÃºdo
    if (bytes.isEmpty) {
      throw Exception('âŒ Arquivo de imagem nÃ£o encontrado ou vazio.');
    }

    // VALIDAÃ‡ÃƒO: Tamanho do arquivo
    final fileSize = bytes.length;
    if (fileSize > _maxSizeBytes) {
      final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      throw Exception(
        'âŒ Imagem muito grande ($sizeMB MB). MÃ¡ximo permitido: 5 MB.',
      );
    }

    // VALIDAÃ‡ÃƒO: ExtensÃ£o do arquivo
    final fileName = file.name.toLowerCase();
    final hasValidExtension = _allowedExtensions.any(
      (ext) => fileName.endsWith(ext),
    );

    if (!hasValidExtension) {
      throw Exception(
        'âŒ Formato invÃ¡lido. Use: ${_allowedExtensions.join(", ")}',
      );
    }

    debugPrint(
        'ðŸ“¤ Enviando imagem (${(fileSize / 1024).toStringAsFixed(0)} KB)...');

    // 1ï¸âƒ£ Deleta imagem antiga ANTES de fazer upload
    if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
      await _deleteOldImage(oldImageUrl);
    }

    // 2ï¸âƒ£ Faz upload passando os bytes (web + mobile safe)
    final imageUrl = await _repository.uploadImage(bytes, fileName: fileName);

    return imageUrl;
  }

  /// Deleta uma imagem antiga do Firebase Storage
  Future<void> _deleteOldImage(String imageUrl) async {
    try {
      debugPrint('ðŸ—‘ï¸ Tentando deletar imagem antiga...');
      await _repository.deleteImageByUrl(imageUrl);
    } catch (e) {
      // NÃ£o falha se deleÃ§Ã£o nÃ£o funcionar
      debugPrint('âš ï¸ Erro ao deletar imagem antiga (continuando): $e');
    }
  }

  /// Remove uma imagem (quando o usuÃ¡rio remove a foto)
  Future<void> deleteProfileImage(String imageUrl) async {
    await _deleteOldImage(imageUrl);
  }
}

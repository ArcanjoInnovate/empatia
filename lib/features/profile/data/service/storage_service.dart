import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // XFile
import '../repository/storage_repository.dart';

/// 📸 STORAGE SERVICE
///
/// É o GERENTE de fotos.
/// Valida imagens antes de enviar para o Firebase Storage (substitui o
/// antigo CloudinaryService).
///
/// Usa [XFile] em vez de [File] para funcionar no web e no mobile.
///
/// RESPONSABILIDADES:
/// - Validar tamanho e formato de imagens
/// - Chamar o Repository para upload
/// - Deletar imagens antigas antes de fazer novo upload
/// - Garantir que dados estão corretos
///
/// Mantém os mesmos nomes de método do antigo CloudinaryService
/// (uploadProfileImage / deleteProfileImage) para que ProfileService,
/// DonationService e DreamService não precisem mudar nada além do
/// import e do tipo da dependência injetada.
class StorageService {
  final StorageRepository _repository;

  StorageService(this._repository);

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

  /// Deleta uma imagem antiga do Firebase Storage
  Future<void> _deleteOldImage(String imageUrl) async {
    try {
      debugPrint('🗑️ Tentando deletar imagem antiga...');
      await _repository.deleteImageByUrl(imageUrl);
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
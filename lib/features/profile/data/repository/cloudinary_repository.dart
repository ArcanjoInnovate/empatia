import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// 📤 CLOUDINARY REPOSITORY
///
/// É o CARTEIRO que envia fotos para a nuvem.
/// Conversa diretamente com a API do Cloudinary.
///
/// Usa [Uint8List] em vez de [File] para funcionar no web e no mobile.
///
/// RESPONSABILIDADES:
/// - Fazer upload de imagens
/// - Retornar URL pública da imagem
/// - Extrair public_id de URLs
class CloudinaryRepository {
  static const String _cloudName   = 'dc09lenom';
  static const String _uploadPreset = 'ml_default';

  /// Faz upload de uma imagem para o Cloudinary
  ///
  /// [bytes]    = bytes da imagem (lidos via XFile.readAsBytes())
  /// [fileName] = nome do arquivo com extensão (ex: "foto.jpg")
  ///
  /// Retorna a URL pública da imagem ou lança exceção em caso de erro.
  Future<String> uploadImage(Uint8List bytes, {String fileName = 'image.jpg'}) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url);

      // fromBytes funciona no web e no mobile (fromPath só funciona no mobile)
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: _mediaTypeFromFileName(fileName),
        ),
      );

      request.fields['upload_preset'] = _uploadPreset;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseData);
        final imageUrl = jsonResponse['secure_url'] as String;
        debugPrint('✅ Upload concluído: $imageUrl');
        return imageUrl;
      } else {
        debugPrint('❌ Erro no upload: ${response.statusCode}');
        debugPrint('Resposta: $responseData');
        throw Exception('Erro ao fazer upload da imagem');
      }
    } catch (e) {
      debugPrint('❌ Erro no upload: $e');
      throw Exception('Não foi possível enviar a imagem. Tente novamente.');
    }
  }

  /// Detecta o MediaType pelo nome do arquivo
  MediaType _mediaTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png'))  return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg'); // .jpg / .jpeg / fallback
  }

  /// Extrai o public_id de uma URL do Cloudinary
  ///
  /// Exemplo:
  /// URL: https://res.cloudinary.com/demo/image/upload/v1234567890/sample.jpg
  /// public_id: sample
  String? extractPublicId(String imageUrl) {
    try {
      if (!imageUrl.contains('cloudinary.com')) {
        debugPrint('⚠️ URL não é do Cloudinary: $imageUrl');
        return null;
      }

      final parts = imageUrl.split('/');
      final uploadIndex = parts.indexOf('upload');
      if (uploadIndex == -1) {
        debugPrint('⚠️ Segmento "upload" não encontrado na URL');
        return null;
      }

      final afterUpload = parts.skip(uploadIndex + 1).toList();

      // Remove versão (v1234567890) se existir
      if (afterUpload.isNotEmpty && afterUpload.first.startsWith('v')) {
        afterUpload.removeAt(0);
      }

      final publicIdWithExtension = afterUpload.join('/');
      final publicId = publicIdWithExtension.split('.').first;

      debugPrint('📝 Public ID extraído: $publicId');
      return publicId;
    } catch (e) {
      debugPrint('❌ Erro ao extrair public_id: $e');
      return null;
    }
  }

  /// Remove uma imagem do Cloudinary via Cloud Function
  Future<void> deleteImageViaFunction(String publicId) async {
    try {
      debugPrint('🗑️ Solicitando deleção de: $publicId');

      const functionUrl =
          'https://southamerica-east1-empatia-34400.cloudfunctions.net/deleteCloudinaryImage';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'publicId': publicId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Imagem deletada: ${data['message']}');
      } else if (response.statusCode == 404) {
        debugPrint('⚠️ Imagem não encontrada (pode já ter sido deletada)');
      } else {
        debugPrint('⚠️ Erro ao deletar: ${response.statusCode}');
        debugPrint('Resposta: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao deletar imagem: $e');
      // Não lança exceção — falha na deleção não deve bloquear o upload
    }
  }
}
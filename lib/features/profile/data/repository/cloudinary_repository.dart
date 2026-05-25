import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// 📤 CLOUDINARY REPOSITORY
/// 
/// É o CARTEIRO que envia fotos para a nuvem.
/// Conversa diretamente com a API do Cloudinary.
/// 
/// RESPONSABILIDADES:
/// - Fazer upload de imagens
/// - Retornar URL pública da imagem
/// - Extrair public_id de URLs
class CloudinaryRepository {
  // IMPORTANTE: Substitua com suas credenciais do Cloudinary
  static const String _cloudName = 'dc09lenom';
  static const String _uploadPreset = 'ml_default';
  
  
  /// Faz upload de uma imagem para o Cloudinary
  /// 
  /// [file] = arquivo de imagem a ser enviado
  /// 
  /// Retorna a URL pública da imagem ou lança exceção em caso de erro
  Future<String> uploadImage(File file) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url);
      
      // Adiciona o arquivo
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      
      // Adiciona preset (configuração pré-definida no Cloudinary)
      request.fields['upload_preset'] = _uploadPreset;
      
      // Envia requisição
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

  /// Extrai o public_id de uma URL do Cloudinary
  /// 
  /// Exemplo:
  /// URL: https://res.cloudinary.com/demo/image/upload/v1234567890/sample.jpg
  /// public_id: sample
  /// 
  /// [imageUrl] = URL completa da imagem no Cloudinary
  /// 
  /// Retorna o public_id ou null se não conseguir extrair
  String? extractPublicId(String imageUrl) {
    try {
      // Verifica se é uma URL do Cloudinary
      if (!imageUrl.contains('cloudinary.com')) {
        debugPrint('⚠️ URL não é do Cloudinary: $imageUrl');
        return null;
      }

      // Divide a URL por '/'
      final parts = imageUrl.split('/');
      
      // Procura pelo segmento 'upload'
      final uploadIndex = parts.indexOf('upload');
      if (uploadIndex == -1) {
        debugPrint('⚠️ Segmento "upload" não encontrado na URL');
        return null;
      }

      // O public_id está após 'upload' (pode ter versão v123456789 no meio)
      // Exemplo: .../upload/v1234567890/pasta/imagem.jpg
      // public_id = pasta/imagem
      
      final afterUpload = parts.skip(uploadIndex + 1).toList();
      
      // Remove versão (v1234567890) se existir
      if (afterUpload.isNotEmpty && afterUpload.first.startsWith('v')) {
        afterUpload.removeAt(0);
      }
      
      // Junta o resto e remove extensão
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
  /// 
  /// [publicId] = identificador da imagem (extraído da URL)
  /// 
  /// Nota: A deleção deve ser feita via Cloud Function porque
  /// requer API Key e Secret que não devem ficar no app.
  Future<void> deleteImageViaFunction(String publicId) async {
    try {
      debugPrint('🗑️ Solicitando deleção de: $publicId');
      
      // ⚠️ SUBSTITUA COM SUA URL DA CLOUD FUNCTION
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
        debugPrint('⚠️ Imagem não encontrada no Cloudinary (pode já ter sido deletada)');
      } else {
        debugPrint('⚠️ Erro ao deletar: ${response.statusCode}');
        debugPrint('Resposta: ${response.body}');
      }
      
    } catch (e) {
      debugPrint('❌ Erro ao deletar imagem: $e');
      // Não lançar exceção - falha na deleção não deve bloquear o upload
    }
  }
}
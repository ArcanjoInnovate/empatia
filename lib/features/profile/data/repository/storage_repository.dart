import 'dart:math';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// 📤 STORAGE REPOSITORY
///
/// É o CARTEIRO que envia fotos para a nuvem.
/// Conversa diretamente com o Firebase Storage (substitui o antigo
/// CloudinaryRepository).
///
/// Usa [Uint8List] em vez de [File] para funcionar no web e no mobile.
///
/// RESPONSABILIDADES:
/// - Fazer upload de imagens
/// - Retornar URL pública (download URL) da imagem
/// - Deletar imagens a partir da própria URL pública
class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static final Random _random = Random();

  /// Pasta raiz dentro do bucket onde as imagens enviadas pelo app
  /// são armazenadas (perfis, filhos, sonhos, doações — tudo cai aqui,
  /// separado por um nome de arquivo único).
  static const String _rootFolder = 'uploads';

  /// Tempo máximo de espera por um upload antes de desistir e lançar
  /// um erro claro. Sem isso, se o Storage não responder (regras
  /// bloqueando silenciosamente, bucket não provisionado, falha de
  /// rede persistente), o app fica com o spinner girando para sempre
  /// — o usuário só vê "Enviando imagem..." sem nunca dar erro.
  static const Duration _uploadTimeout = Duration(seconds: 30);

  /// Faz upload de uma imagem para o Firebase Storage
  ///
  /// [bytes]    = bytes da imagem (lidos via XFile.readAsBytes())
  /// [fileName] = nome do arquivo com extensão (ex: "foto.jpg") — usado
  ///              apenas para derivar a extensão e o content-type.
  ///
  /// Retorna a URL pública (download URL) da imagem ou lança exceção
  /// em caso de erro.
  Future<String> uploadImage(Uint8List bytes, {String fileName = 'image.jpg'}) async {
    try {
      final extension = _extensionFromFileName(fileName);
      final uniqueName =
          '${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000000)}$extension';

      final ref = _storage.ref().child(_rootFolder).child(uniqueName);

      final metadata = SettableMetadata(
        contentType: _contentTypeFromFileName(fileName),
      );

      final task = ref.putData(bytes, metadata);

      // Loga eventos do upload — ajuda a diagnosticar travamentos
      // (ex: state fica preso em "running" sem nunca chegar em
      // "success"/"error" → indica bloqueio de regras ou bucket
      // mal configurado, não erro de código).
      task.snapshotEvents.listen((snapshot) {
        debugPrint(
          '📡 Upload ${snapshot.state.name}: '
          '${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes',
        );
      }, onError: (e) {
        debugPrint('📡 Upload snapshotEvents erro: $e');
      });

      await task.timeout(
        _uploadTimeout,
        onTimeout: () {
          throw Exception(
            '❌ Tempo esgotado enviando a imagem (${_uploadTimeout.inSeconds}s). '
            'Verifique sua conexão e se o Firebase Storage está ativado/configurado '
            'corretamente no projeto.',
          );
        },
      );

      final imageUrl = await ref.getDownloadURL().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          '❌ Tempo esgotado obtendo a URL da imagem enviada.',
        ),
      );

      debugPrint('✅ Upload concluído: $imageUrl');
      return imageUrl;
    } on FirebaseException catch (e) {
      debugPrint('❌ Erro no upload (Firebase): ${e.code} — ${e.message}');
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw Exception(
          '❌ Sem permissão para enviar a imagem. Verifique as regras de '
          'segurança do Firebase Storage.',
        );
      }
      throw Exception('Não foi possível enviar a imagem. Tente novamente.');
    } catch (e) {
      debugPrint('❌ Erro no upload: $e');
      throw Exception('Não foi possível enviar a imagem. Tente novamente.');
    }
  }

  /// Detecta a extensão do arquivo a partir do nome (com o ponto incluído)
  String _extensionFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png'))  return '.png';
    if (lower.endsWith('.webp')) return '.webp';
    if (lower.endsWith('.jpeg')) return '.jpeg';
    return '.jpg'; // fallback
  }

  /// Detecta o content-type pelo nome do arquivo
  String _contentTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png'))  return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg'; // .jpg / .jpeg / fallback
  }

  /// Remove uma imagem do Firebase Storage a partir da sua URL pública
  /// (download URL). Diferente do Cloudinary, o Storage permite
  /// reconstruir a referência (`Reference`) direto a partir da URL —
  /// não precisamos extrair nenhum "public_id" manualmente nem passar
  /// por uma Cloud Function.
  Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      debugPrint('🗑️ Solicitando deleção de: $imageUrl');

      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      debugPrint('✅ Imagem deletada: ${ref.fullPath}');
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint('⚠️ Imagem não encontrada (pode já ter sido deletada)');
        return;
      }
      debugPrint('⚠️ Erro ao deletar: ${e.code} — ${e.message}');
      // Não lança exceção — falha na deleção não deve bloquear o fluxo
      // que está chamando (ex: upload de uma nova foto).
    } catch (e) {
      debugPrint('❌ Erro ao deletar imagem: $e');
    }
  }
}
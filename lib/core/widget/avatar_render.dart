import 'package:flutter/material.dart';
import 'package:empatia/core/theme/app_avatars.dart';

/// 🖼️ AVATAR RENDER
///
/// Substitui todos os antigos `Text(emoji, style: TextStyle(fontSize: ..))`
/// usados como avatar de usuário/criança.
///
/// Aceita o valor cru vindo do banco (campo `profileEmoji` / `emoji` /
/// `childEmoji` / `userProfileEmoji`):
///   • Se for um caminho de asset (`assets/...`) → renderiza a ilustração.
///   • Se for um emoji legado (dado antigo não migrado) → ainda renderiza
///     como texto, para nunca quebrar a tela.
///   • Se for nulo/vazio → mostra um placeholder neutro.
class AvatarRender extends StatelessWidget {
  final String? value;
  final double size;
  final BoxFit fit;

  const AvatarRender({
    Key? key,
    required this.value,
    required this.size,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  /// Avatar de responsável quando [value] está vazio.
  const AvatarRender.parentPlaceholder({Key? key, required this.size})
      : value = AppAvatars.defaultParentAvatar,
        fit = BoxFit.cover,
        super(key: key);

  /// Avatar de criança quando [value] está vazio.
  const AvatarRender.childPlaceholder({Key? key, required this.size})
      : value = AppAvatars.defaultChildAvatar,
        fit = BoxFit.cover,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final v = value;

    if (v == null || v.trim().isEmpty) {
      return Icon(Icons.person, size: size, color: Colors.grey.shade400);
    }

    if (AppAvatars.isAssetPath(v)) {
      return Image.asset(
        v,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.person, size: size, color: Colors.grey.shade400),
      );
    }

    // Compatibilidade: emoji legado que ainda não foi migrado.
    return Center(
      child: Text(v, style: TextStyle(fontSize: size * 0.6)),
    );
  }
}
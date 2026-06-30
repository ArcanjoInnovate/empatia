import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 🌐 SOCIAL LINKS ROW
///
/// Fileira de ícones de redes sociais (Facebook, Instagram, X) — usada
/// tanto no próprio perfil (ProfileHeaderWidget) quanto no perfil
/// público de outros usuários (PublicProfilePage).
///
/// Cada ícone só aparece se o link correspondente estiver preenchido.
/// Ao tocar, abre o link no navegador/app correspondente via
/// [url_launcher] — se o app nativo (Facebook/Instagram/X) estiver
/// instalado, o sistema operacional abre ele direto.
class SocialLinksRow extends StatelessWidget {
  final String? facebook;
  final String? instagram;
  final String? x;

  /// Cor de fundo dos círculos quando usados sobre fundo claro.
  /// Sobre o header gradiente (rosa/roxo), passe `light: true`.
  final bool light;

  const SocialLinksRow({
    Key? key,
    this.facebook,
    this.instagram,
    this.x,
    this.light = false,
  }) : super(key: key);

  /// Facebook está temporariamente fora da exibição (o domínio não é
  /// padronizável como instagram.com/x.com — ver SocialConfirmCard).
  /// Mantemos o campo no modelo/banco para reativar facilmente depois.
  bool get hasAny =>
      (instagram?.trim().isNotEmpty ?? false) ||
      (x?.trim().isNotEmpty ?? false);

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o link.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasAny) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Facebook temporariamente desativado — ver comentário em hasAny.
        if (instagram?.trim().isNotEmpty ?? false)
          _SocialIcon(
            icon: Icons.camera_alt_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFFEDA77), Color(0xFFE1306C), Color(0xFF833AB4)],
            ),
            light: light,
            onTap: () => _open(context, instagram!.trim()),
          ),
        if (x?.trim().isNotEmpty ?? false) ...[
          if (instagram?.trim().isNotEmpty ?? false)
            const SizedBox(width: 10),
          _SocialIcon(
            label: '𝕏',
            color: Colors.black,
            light: light,
            onTap: () => _open(context, x!.trim()),
          ),
        ],
      ],
    );
  }
}

/// 🔎 SOCIAL CONFIRM CARD
///
/// Card que aparece embaixo de um campo de rede social assim que o
/// usuário digita algo — mostra um preview do link e um botão "Abrir e
/// conferir" para a pessoa visualmente confirmar que é o perfil dela
/// mesma antes de salvar (não há como validar isso automaticamente).
class SocialConfirmCard extends StatelessWidget {
  final String platform; // 'Instagram' | 'X'
  final String rawValue; // só o @usuario, sem domínio

  const SocialConfirmCard({
    Key? key,
    required this.platform,
    required this.rawValue,
  }) : super(key: key);

  static const Map<String, String> _domains = {
    'Instagram': 'instagram.com',
    'X': 'x.com',
  };

  /// Limpa o que a pessoa digitou: remove @ na frente, espaços, e se
  /// colar sem querer um link completo, extrai só o último pedaço (o
  /// nome de usuário em si).
  String get _cleanUsername {
    var v = rawValue.trim();
    if (v.contains('/')) {
      final parts = v.split('/').where((p) => p.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) v = parts.last;
    }
    v = v.replaceAll('@', '').trim();
    return v;
  }

  String get _normalizedUrl {
    final domain = _domains[platform] ?? '';
    return 'https://$domain/$_cleanUsername';
  }

  ({IconData? icon, String? label, Color? color, Gradient? gradient}) get _style {
    switch (platform) {
      case 'Facebook':
        return (icon: Icons.facebook, label: null, color: const Color(0xFF1877F2), gradient: null);
      case 'Instagram':
        return (
          icon: Icons.camera_alt_rounded,
          label: null,
          color: null,
          gradient: const LinearGradient(
            colors: [Color(0xFFFEDA77), Color(0xFFE1306C), Color(0xFF833AB4)],
          ),
        );
      case 'X':
      default:
        return (icon: null, label: '𝕏', color: Colors.black, gradient: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (rawValue.trim().isEmpty) return const SizedBox.shrink();

    final s = _style;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3ECFF), width: 1.2),
      ),
      child: Row(
        children: [
          _SocialIcon(
            icon: s.icon,
            label: s.label,
            color: s.color,
            gradient: s.gradient,
            light: false,
            onTap: () {},
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confira se é o link certo',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _normalizedUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final uri = Uri.tryParse(_normalizedUrl);
              if (uri == null) return;
              final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Não foi possível abrir o link.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded, size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Abrir',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final Color? color;
  final Gradient? gradient;
  final bool light;
  final VoidCallback onTap;

  const _SocialIcon({
    this.icon,
    this.label,
    this.color,
    this.gradient,
    required this.light,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gradient == null ? color : null,
          gradient: gradient,
          border: light
              ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 17, color: Colors.white)
              : Text(
                  label ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🖼️ FULLSCREEN IMAGE PAGE
///
/// Exibe uma imagem em tela cheia com suporte a zoom (pinch-to-zoom).
/// Esconde a status bar e a navigation bar para imersão total.
/// Fechar com botão de voltar ou toque no X.
///
/// Uso:
///   Navigator.push(context, FullscreenImagePage.route(imageUrl: url));
///   // ou com heroTag para animação:
///   Navigator.push(context, FullscreenImagePage.route(imageUrl: url, heroTag: 'dream_img_${dream.id}'));
class FullscreenImagePage extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final String? title;

  const FullscreenImagePage({
    Key? key,
    required this.imageUrl,
    this.heroTag,
    this.title,
  }) : super(key: key);

  static Route<void> route({
    required String imageUrl,
    String? heroTag,
    String? title,
  }) {
    return MaterialPageRoute(
      builder: (_) => FullscreenImagePage(
        imageUrl: imageUrl,
        heroTag: heroTag,
        title: title,
      ),
    );
  }

  @override
  State<FullscreenImagePage> createState() => _FullscreenImagePageState();
}

class _FullscreenImagePageState extends State<FullscreenImagePage> {
  bool _showControls = true;
  late final TransformationController _transformCtrl;

  @override
  void initState() {
    super.initState();
    _transformCtrl = TransformationController();
    // Esconde status bar e navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    // Restaura UI do sistema ao sair
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.heroTag != null
        ? Hero(
            tag: widget.heroTag!,
            child: _buildImage(),
          )
        : _buildImage();

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Imagem com zoom ──────────────────────────────────────
            InteractiveViewer(
              transformationController: _transformCtrl,
              minScale: 1.0,
              maxScale: 5.0,
              child: Center(child: image),
            ),

            // ── Barra superior ───────────────────────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              top: _showControls ? 0 : -120,
              left: 0,
              right: 0,
              child: _TopBar(
                title: widget.title,
                onClose: () => Navigator.pop(context),
                onResetZoom: _resetZoom,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Image.network(
      widget.imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded /
                    progress.expectedTotalBytes!
                : null,
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (_, __, ___) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_rounded,
                size: 64, color: Colors.white24),
            SizedBox(height: 12),
            Text(
              'Não foi possível carregar a imagem',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Barra superior ────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String? title;
  final VoidCallback onClose;
  final VoidCallback onResetZoom;

  const _TopBar({
    required this.onClose,
    required this.onResetZoom,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 8,
        bottom: 24,
      ),
      child: Row(
        children: [
          // Botão fechar
          _CircleButton(
            icon: Icons.close_rounded,
            onTap: onClose,
          ),

          // Título (opcional)
          if (title != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ] else
            const Spacer(),

          // Botão resetar zoom
          _CircleButton(
            icon: Icons.zoom_out_map_rounded,
            onTap: onResetZoom,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
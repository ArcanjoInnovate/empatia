import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/dream/controller/dream_controller.dart';
import 'package:empatia/features/dream/presentation/pages/full_screen_image_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 💭 DREAM CARD WIDGET
///
/// Card reutilizável para exibir um sonho com imagem de inspiração.
/// Quando [editable] = true, exibe menu de edição/remoção.
class DreamCardWidget extends StatelessWidget {
  final DreamModel dream;
  final bool editable;
  final VoidCallback? onEdit;

  const DreamCardWidget({
    Key? key,
    required this.dream,
    this.editable = false,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = dream.progress;

    Color progressColor = AppTheme.kidsPink;
    if (progress != null) {
      if (progress >= 0.7) {
        progressColor = AppTheme.kidsGreen;
      } else if (progress >= 0.4) {
        progressColor = AppTheme.kidsYellow;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E6FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kidsPurple.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Imagem de inspiração (se existir) ───────────────────────
          if (dream.imageUrl != null)
            _DreamImage(imageUrl: dream.imageUrl!, dreamTitle: dream.title),

          // ── Conteúdo ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Ícone emoji
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.kidsPurple, Color(0xFFBB86FC)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(dream.emoji ?? '💭',
                            style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Título e data
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dream.title ?? 'Sem título',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          if (dream.date != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              '📅  ${dream.date}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Menu de edição
                    if (editable) ...[
                      const SizedBox(width: 4),
                      _EditMenu(dream: dream, onEdit: onEdit),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Imagem de inspiração ──────────────────────────────────────────────────────

class _DreamImage extends StatelessWidget {
  final String imageUrl;
  final String? dreamTitle;

  const _DreamImage({required this.imageUrl, this.dreamTitle});

  @override
  Widget build(BuildContext context) {
    final heroTag = 'dream_img_$imageUrl';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        FullscreenImagePage.route(
          imageUrl: imageUrl,
          heroTag: heroTag,
          title: dreamTitle,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Hero(
            tag: heroTag,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: const Color(0xFFF5F0FF),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                      color: AppTheme.kidsPurple,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF5F0FF),
                child: Center(
                  child: Icon(Icons.broken_image_rounded,
                      size: 40, color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Menu de edição ────────────────────────────────────────────────────────────

class _EditMenu extends StatelessWidget {
  final DreamModel dream;
  final VoidCallback? onEdit;

  const _EditMenu({required this.dream, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<DreamController>();

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          color: Colors.grey.shade400, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit?.call();
        } else if (value == 'delete') {
          _confirmDelete(context, ctrl);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_rounded, size: 16, color: AppTheme.kidsPurple),
            SizedBox(width: 10),
            Text('Editar'),
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
            SizedBox(width: 10),
            Text('Remover', style: TextStyle(color: Colors.red)),
          ]),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, DreamController ctrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remover sonho?'),
        content: Text(
            'Tem certeza que deseja remover "${dream.title ?? "este sonho"}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.deleteDream(dream.id!, imageUrl: dream.imageUrl);
            },
            child: const Text('Remover',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Slider de progresso ───────────────────────────────────────────────────────

class _ProgressSlider extends StatefulWidget {
  final DreamModel dream;
  final Color progressColor;

  const _ProgressSlider({
    required this.dream,
    required this.progressColor,
  });

  @override
  State<_ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<_ProgressSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.dream.progress ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 8,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: widget.progressColor,
        inactiveTrackColor: Colors.grey.shade100,
        thumbColor: widget.progressColor,
        overlayColor: widget.progressColor.withOpacity(0.15),
      ),
      child: Slider(
        value: _value,
        onChanged: (v) => setState(() => _value = v),
        onChangeEnd: (v) {
          context.read<DreamController>().updateProgress(
                widget.dream.id!,
                v,
              );
        },
      ),
    );
  }
}
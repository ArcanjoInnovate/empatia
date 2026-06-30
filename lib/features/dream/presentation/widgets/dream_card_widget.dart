import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/core/widget/avatar_render.dart';
import 'package:empatia/core/theme/app_avatars.dart';
import 'package:empatia/features/dream/controller/dream_controller.dart';
import 'package:empatia/features/dream/presentation/pages/full_screen_image_page.dart';
import 'package:flutter/material.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/theme/app_icons.dart';
import 'package:provider/provider.dart';

/// 💭 DREAM CARD WIDGET
///
/// Card redesenhado com hierarquia visual clara:
///   1. Imagem de inspiração (opcional, 16:9)
///   2. Chip do filho vinculado — identidade imediata
///   3. Emoji + Título + Descrição
///   4. Barra de progresso com label
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

  // Cor da barra de progresso por nível
  List<Color> get _progressColors {
    final p = dream.progress ?? 0;
    if (p >= 0.7) return AppTheme.progressHigh;
    if (p >= 0.4) return AppTheme.progressMid;
    return AppTheme.progressLow;
  }

  Color get _progressColor => _progressColors.first;

  bool get _hasChild =>
      dream.childId != null && dream.childId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0E6FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kidsPurple.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Imagem de inspiração ───────────────────────────────
          if (dream.imageUrl != null)
            _DreamImage(imageUrl: dream.imageUrl!, dreamTitle: dream.title),

          // ── 2. Corpo do card ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha topo: chip do filho + menu
                Row(
                  children: [
                    if (_hasChild) ...[
                      _ChildChip(
                        emoji: dream.childEmoji ?? '👶',
                        name: dream.childName ?? '',
                      ),
                    ],
                    const Spacer(),
                    if (editable)
                      _EditMenu(dream: dream, onEdit: onEdit),
                  ],
                ),

                const SizedBox(height: 14),

                // Emoji + Título
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EmojiBox(emoji: dream.emoji ?? '💭'),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dream.title ?? 'Sem título',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryBlue,
                              height: 1.25,
                            ),
                          ),
                          if (dream.date != null &&
                              dream.date!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              dream.date!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary
                                    .withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

               
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip do filho ─────────────────────────────────────────────────────────────

class _ChildChip extends StatelessWidget {
  final String emoji;
  final String name;

  const _ChildChip({required this.emoji, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.childCardBg,
            AppTheme.childCardBg.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.childCardAccent.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: AvatarRender(value: emoji, size: 14),
          ),
          const SizedBox(width: 5),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.childCardAccent,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Emoji box ─────────────────────────────────────────────────────────────────

class _EmojiBox extends StatelessWidget {
  final String emoji;
  const _EmojiBox({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.kidsPurple, Color(0xFFBB86FC)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kidsPurple.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
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
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(23)),
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
      icon:
          Icon(Icons.more_vert_rounded, color: Colors.grey.shade400, size: 20),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            Icon(AppIcons.edit, size: 16, color: AppTheme.kidsPurple),
            SizedBox(width: 10),
            Text('Editar'),
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(AppIcons.delete, size: 16, color: Colors.red),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            child:
                const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/core/widget/avatar_render.dart';
import 'package:empatia/core/theme/app_avatars.dart';
import 'package:empatia/features/dream/controller/dream_controller.dart';
import 'package:empatia/features/dream/presentation/pages/full_screen_image_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/theme/app_icons.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS LOCAIS
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _K {
  static const purple     = AppTheme.kidsPurple;
  static const purpleSoft = Color(0xFFF0E6FF);
  static const purpleBg   = Color(0xFFF5F0FF);
  static const navy       = AppTheme.primaryBlue;
  static const r16 = 16.0;
  static const r20 = 20.0;
  static const r24 = 24.0;
  static const r99 = 99.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// LINHA SUPERIOR "SEGURA" — evita overflow entre os badges do topo do hero
// ─────────────────────────────────────────────────────────────────────────────

class _SafeTopRow extends StatelessWidget {
  final Widget left;
  final Widget? right;
  const _SafeTopRow({required this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: left,
          ),
        ),
        if (right != null) const SizedBox(width: 8),
        if (right != null)
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: right!,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 💭 DREAM CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────
//
// Card redesenhado com hierarquia visual completa, no mesmo espírito dos
// cards do feed e da busca:
///   1. Hero — foto de inspiração (ou banner gradiente) com badge "Sonho",
///      chip do filho sobreposto e menu de edição flutuante
///   2. Emoji + Título + data
///   3. Bloco de impacto emocional (microcopy rotativo)
///   4. Barra de progresso com label dinâmico por nível
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

  bool get _hasChild => dream.childId != null && dream.childId!.isNotEmpty;

  bool get _hasImage => dream.imageUrl != null && dream.imageUrl!.isNotEmpty;

  bool get _hasDate => dream.date != null && dream.date!.isNotEmpty;

  static const _gradients = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFF7C3AED), Color(0xFF4F46E5)],
    [Color(0xFF2563EB), Color(0xFF1E3A5F)],
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  ];

  List<Color> _gradient(String? id) {
    final idx = (id?.codeUnits.fold(0, (a, b) => a + b) ?? 0) % _gradients.length;
    return _gradients[idx];
  }

  static const _impactCopies = [
    '✨ Um sonho esperando acontecer',
    '💛 Cada passo te aproxima dele',
    '🌟 Continue — você está no caminho certo',
    '❤️ Esse sonho já é uma conquista',
    '🎯 Cada apoio conta para chegar lá',
  ];

  String _impactCopy(String? id) {
    final idx = ((id?.codeUnits.fold(0, (a, b) => a + b) ?? 0) + 2) % _impactCopies.length;
    return _impactCopies[idx];
  }

  @override
  Widget build(BuildContext context) {
    final progress = (dream.progress ?? 0).clamp(0.0, 1.0);
    final colors = _gradient(dream.id);
    final heroTag = 'dream_img_${dream.id ?? dream.imageUrl ?? dream.title}';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(_K.r24),
        border: Border.all(color: _K.purpleSoft, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _K.purple.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: _K.purple.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Hero ─────────────────────────────────────────────
          _DreamHero(
            dream: dream,
            heroTag: heroTag,
            hasImage: _hasImage,
            hasChild: _hasChild,
            colors: colors,
            editable: editable,
            onEdit: onEdit,
          ),

          // ── 2. Corpo do card ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji + Título + data
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EmojiBox(emoji: dream.emoji ?? '💭', colors: colors),
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
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: _K.navy,
                              height: 1.25,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (_hasDate) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 11,
                                    color: AppTheme.textSecondary
                                        .withValues(alpha: 0.55)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    dream.date!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.textSecondary
                                          .withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── 3. Bloco de impacto emocional ──────────────────
                _ImpactBlock(copy: _impactCopy(dream.id)),

                const SizedBox(height: 16),

              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero: foto ou banner gradiente + overlays ─────────────────────────────────

class _DreamHero extends StatelessWidget {
  final DreamModel dream;
  final String heroTag;
  final bool hasImage;
  final bool hasChild;
  final List<Color> colors;
  final bool editable;
  final VoidCallback? onEdit;

  const _DreamHero({
    required this.dream,
    required this.heroTag,
    required this.hasImage,
    required this.hasChild,
    required this.colors,
    required this.editable,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 176,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                FullscreenImagePage.route(
                  imageUrl: dream.imageUrl!,
                  heroTag: heroTag,
                  title: dream.title,
                ),
              ),
              child: Hero(
                tag: heroTag,
                child: Image.network(
                  dream.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, p) => p == null
                      ? child
                      : _GradientPlaceholder(
                          colors: colors, emoji: dream.emoji ?? '💭'),
                  errorBuilder: (_, __, ___) => _GradientPlaceholder(
                      colors: colors, emoji: dream.emoji ?? '💭'),
                ),
              ),
            )
          else
            _GradientPlaceholder(colors: colors, emoji: dream.emoji ?? '💭'),

          // Scrim para legibilidade dos badges/overlay
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),

          // ── Topo: badge "Sonho" + menu de edição ─────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _SafeTopRow(
              left: const _DreamPill(),
              right: editable ? _EditButton(dream: dream, onEdit: onEdit) : null,
            ),
          ),

          // ── Rodapé: chip do filho ─────────────────────────────────
          if (hasChild)
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: _ChildChip(
                emoji: dream.childEmoji ?? '👶',
                name: dream.childName ?? '',
              ),
            ),

          // ── Botão fullscreen (só quando há foto) ──────────────────
          if (hasImage)
            Positioned(
              right: 12,
              bottom: hasChild ? 52 : 12,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  FullscreenImagePage.route(
                    imageUrl: dream.imageUrl!,
                    heroTag: '${heroTag}_fs',
                    title: dream.title,
                  ),
                ),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fullscreen_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  final List<Color> colors;
  final String emoji;
  const _GradientPlaceholder({required this.colors, required this.emoji});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -8,
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 96,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
            Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ],
        ),
      );
}

// ── Badge "Sonho" ──────────────────────────────────────────────────────────────

class _DreamPill extends StatelessWidget {
  const _DreamPill();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(_K.r99),
          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💭', style: TextStyle(fontSize: 11)),
            SizedBox(width: 4),
            Text(
              'Sonho',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}

// ── Chip do filho (sobreposto no hero) ──────────────────────────────────────────

class _ChildChip extends StatelessWidget {
  final String emoji;
  final String name;
  const _ChildChip({required this.emoji, required this.name});

  @override
  Widget build(BuildContext context) {
    if (name.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(_K.r99),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(child: AvatarRender(value: emoji, size: 18)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _K.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Bloco de impacto emocional ────────────────────────────────────────────────

class _ImpactBlock extends StatelessWidget {
  final String copy;
  const _ImpactBlock({required this.copy});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _K.purpleBg,
        borderRadius: BorderRadius.circular(_K.r16),
        border: Border.all(color: _K.purple.withValues(alpha: 0.16), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _K.purple.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome_rounded, size: 14, color: _K.purple),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              copy,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _K.purple,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barra de progresso ────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double progress;
  final List<Color> colors;
  const _ProgressBar({required this.progress, required this.colors});

  String get _label {
    final pct = (progress * 100).round();
    if (pct >= 100) return 'Sonho realizado! 🎉';
    if (pct >= 70) return 'Quase lá! 🚀';
    if (pct >= 40) return 'No caminho certo ⭐';
    if (pct > 0) return 'Começando agora 🌱';
    return 'Ainda não iniciado';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                _label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: colors.last,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(_K.r99),
          child: Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                color: colors.first.withValues(alpha: 0.12),
              ),
              LayoutBuilder(
                builder: (context, constraints) => AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  height: 10,
                  width: constraints.maxWidth * progress.clamp(0.02, 1.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(_K.r99),
                    boxShadow: [
                      BoxShadow(
                        color: colors.last.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Emoji box ─────────────────────────────────────────────────────────────────

class _EmojiBox extends StatelessWidget {
  final String emoji;
  final List<Color> colors;
  const _EmojiBox({required this.emoji, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.30),
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

// ── Botão de edição (flutuante no hero) ──────────────────────────────────────

class _EditButton extends StatelessWidget {
  final DreamModel dream;
  final VoidCallback? onEdit;
  const _EditButton({required this.dream, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<DreamController>();

    return PopupMenuButton<String>(
      icon: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        HapticFeedback.lightImpact();
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
            Icon(AppIcons.edit, size: 16, color: _K.purple),
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
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
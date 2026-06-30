import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/widget/verification_block_dialog.dart';
import 'package:empatia/features/dream/presentation/pages/dream_detail_page.dart';
import 'package:empatia/features/dream/presentation/pages/verification_block_dialog.dart';
import 'package:empatia/features/search/controller/search_controller.dart'
    show SearchResult;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 💫 DREAM SEARCH CARD
///
/// Psicologia aplicada:
///   - Identifiable Person Effect: criança em destaque máximo (foto + nome)
///   - Goal Gradient Effect: barra animada + texto emocional dinâmico
///   - Social Proof: contador de apoiadores
///   - Impact Visualization: CTA menciona a criança pelo nome
///
/// Layout (aspect-ratio 3:4):
///   ┌─────────────────────┐
///   │                     │
///   │   [foto da criança] │  70% do card
///   │                     │
///   │─────────────────────│
///   │ 😊 João, 8 anos     │
///   │ "Meu sonho é..."   │
///   │ ████████░░ 78%      │
///   │ ✨ Falta pouco...   │
///   └─────────────────────┘
class DreamSearchCard extends StatelessWidget {
  final SearchResult result;

  const DreamSearchCard({Key? key, required this.result}) : super(key: key);

  String get _heroTag => 'dream_card_${result.id}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => pushIfVerified(
        context,
        currentUser: context.read<UserModel?>(),
        feature: 'ver os detalhes deste sonho',
        route: DreamDetailPage.route(result: result, heroTag: _heroTag),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFF8FF),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Foto ocupa 70% da altura total ─────────────────────
              Expanded(
                flex: 70,
                child: _CardPhoto(result: result, heroTag: _heroTag),
              ),

              // ── Área de texto: 30% ─────────────────────────────────
              Expanded(
                flex: 30,
                child: _CardTextArea(result: result),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Foto + badges ─────────────────────────────────────────────────────────────

class _CardPhoto extends StatelessWidget {
  final SearchResult result;
  final String heroTag;

  const _CardPhoto({required this.result, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Imagem
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: _PhotoOrPlaceholder(result: result, heroTag: heroTag),
        ),

        // Gradient suave no rodapé da foto para transição com área branca
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 32,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFFEFF8FF).withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),

        // Badge "Sonho" — canto superior esquerdo
        const Positioned(
          top: 10,
          left: 10,
          child: _DreamBadge(),
        ),
      ],
    );
  }
}

class _PhotoOrPlaceholder extends StatelessWidget {
  final SearchResult result;
  final String heroTag;

  const _PhotoOrPlaceholder({required this.result, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    if (result.photoUrl != null && result.photoUrl!.isNotEmpty) {
      return Hero(
        tag: heroTag,
        child: Image.network(
          result.photoUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : const _Placeholder(loading: true),
          errorBuilder: (_, __, ___) => const _Placeholder(loading: false),
        ),
      );
    }
    return const _Placeholder(loading: false);
  }
}

class _Placeholder extends StatelessWidget {
  final bool loading;
  const _Placeholder({required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD6EAFF), Color(0xFFB8D9FF)],
        ),
      ),
      child: Center(
        child: loading
            ? const CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF5B9BD5))
            : const Text('✨', style: TextStyle(fontSize: 44)),
      ),
    );
  }
}

// ── Badge tipo ────────────────────────────────────────────────────────────────

class _DreamBadge extends StatelessWidget {
  const _DreamBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✨', style: TextStyle(fontSize: 10)),
          SizedBox(width: 3),
          Text(
            'Sonho',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Área de texto ─────────────────────────────────────────────────────────────

class _CardTextArea extends StatelessWidget {
  final SearchResult result;

  const _CardTextArea({required this.result});

  @override
  Widget build(BuildContext context) {
    final childName = result.childName;
    final childEmoji = result.childEmoji ?? '😊';
    final progress = result.dreamProgress ?? 0.0;
    final hasChild = childName != null && childName.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Nome da criança — destaque máximo ──────────────────────
          if (hasChild) ...[
            Row(
              children: [
                Text(childEmoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    childName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E3A5F),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],

          // ── Título do sonho ────────────────────────────────────────
          Flexible(
            child: Text(
              result.title ?? 'Um sonho especial',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
          ),

          const Spacer(),

          // ── Barra de progresso animada ─────────────────────────────
          if (progress > 0) _AnimatedProgressRow(progress: progress),
        ],
      ),
    );
  }
}

// ── Barra de progresso com animação e texto emocional ────────────────────────

class _AnimatedProgressRow extends StatefulWidget {
  final double progress;
  const _AnimatedProgressRow({required this.progress});

  @override
  State<_AnimatedProgressRow> createState() => _AnimatedProgressRowState();
}

class _AnimatedProgressRowState extends State<_AnimatedProgressRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _barColor(double p) {
    if (p >= 0.75) return const Color(0xFF16A34A); // verde conquista
    if (p >= 0.40) return const Color(0xFFF59E0B); // âmbar progresso
    return const Color(0xFF60A5FA); // azul acolhedor (nunca vermelho)
  }

  String _emotionalText(double p) {
    final pct = (p * 100).round();
    if (pct >= 100) return '🎉 Sonho realizado!';
    if (pct >= 75) return '✨ Falta muito pouco!';
    if (pct >= 40) return '💛 Mais da metade já foi!';
    if (pct > 0) return '❤️ Cada ajuda conta';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress.clamp(0.0, 1.0);
    final pct = (p * 100).round();
    final color = _barColor(p);
    final text = _emotionalText(p);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barra animada
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: p * _anim.value,
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Percentual + texto emocional
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
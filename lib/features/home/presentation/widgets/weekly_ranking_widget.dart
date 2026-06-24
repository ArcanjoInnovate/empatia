// lib/features/home/presentation/widgets/weekly_ranking_widget.dart
//
// Seção de Ranking Semanal com pódio animado, runner-up rows
// e botão "Ver ranking completo".
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:empatia/features/home/presentation/constants/home_constants.dart';

// ═══════════════════════════════════════════════════════════════
// WIDGET PRINCIPAL
// ═══════════════════════════════════════════════════════════════

class WeeklyRankingWidget extends StatelessWidget {
  final AnimationController animation;

  const WeeklyRankingWidget({Key? key, required this.animation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final top3 = kMockDonors.take(3).toList();
    final rest = kMockDonors.skip(3).toList();

    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kGradientStart, kGradientMid, kGradientEnd],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: kGradientMid.withValues(alpha: 0.40),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decoração de fundo
              Positioned(
                right: -20,
                top: -20,
                child: Text(
                  '🏆',
                  style: TextStyle(
                    fontSize: 130,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                left: -15,
                bottom: -15,
                child: Text(
                  '⭐',
                  style: TextStyle(
                    fontSize: 90,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  children: [
                    _RankingHeader(),
                    const SizedBox(height: 24),

                    // Pódio: 2º | 1º | 3º
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: PodiumCard(
                              donor: top3[1], position: 2, anim: animation),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: PodiumCard(
                              donor: top3[0], position: 1, anim: animation),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PodiumCard(
                              donor: top3[2], position: 3, anim: animation),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Divider(
                        color: Colors.white.withValues(alpha: 0.15), height: 1),
                    const SizedBox(height: 16),

                    // 4º e 5º lugar
                    ...List.generate(
                      rest.length,
                      (i) => RunnerUpRow(donor: rest[i], position: i + 4),
                    ),

                    const SizedBox(height: 12),
                    _ViewAllButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CABEÇALHO DO RANKING
// ─────────────────────────────────────────────────────────────

class _RankingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text('🏆', style: TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ranking Semanal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'Heróis da nossa comunidade ✨',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: kGold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kGold.withValues(alpha: 0.5)),
          ),
          child: const Text(
            'Esta semana',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: kGold,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTÃO VER TUDO
// ─────────────────────────────────────────────────────────────

class _ViewAllButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {/* TODO: ranking completo */},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ver ranking completo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CARD DO PÓDIO
// ═══════════════════════════════════════════════════════════════

class PodiumCard extends StatelessWidget {
  final Map<String, dynamic> donor;
  final int position;
  final AnimationController anim;

  const PodiumCard({
    Key? key,
    required this.donor,
    required this.position,
    required this.anim,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFirst = position == 1;
    final podiumColor =
        position == 1 ? kGold : position == 2 ? kSilver : kBronze;
    final medal = position == 1 ? '🥇' : position == 2 ? '🥈' : '🥉';

    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) {
        final delay = position == 1 ? 0.0 : position == 2 ? 0.15 : 0.25;
        final t = ((anim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutBack.transform(t);
        return Transform.scale(
          scale: 0.7 + 0.3 * curve,
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFirst) ...[
            const Text('👑', style: TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
          ] else
            const SizedBox(height: 30),

          // Avatar com glow
          Container(
            width: isFirst ? 72 : 58,
            height: isFirst ? 72 : 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: podiumColor.withValues(alpha: 0.15),
              border:
                  Border.all(color: podiumColor, width: isFirst ? 2.5 : 2),
              boxShadow: isFirst
                  ? [
                      BoxShadow(
                        color: podiumColor.withValues(alpha: 0.5),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                donor['emoji'] as String,
                style: TextStyle(fontSize: isFirst ? 32 : 26),
              ),
            ),
          ),

          const SizedBox(height: 6),
          Text(medal, style: TextStyle(fontSize: isFirst ? 20 : 16)),
          const SizedBox(height: 4),

          Text(
            (donor['name'] as String).split(' ').first,
            style: TextStyle(
              fontSize: isFirst ? 13 : 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // Badge especial no 1º lugar
          if (isFirst) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kGold.withValues(alpha: 0.5)),
              ),
              child: Text(
                donor['badge'] as String,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: kGold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Doações
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: podiumColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎁', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 3),
                Text(
                  '${donor['donations']}',
                  style: TextStyle(
                    fontSize: isFirst ? 12 : 10,
                    fontWeight: FontWeight.w900,
                    color: podiumColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Sonhos
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('❤️', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 3),
                Text(
                  '${donor['dreams']}',
                  style: TextStyle(
                    fontSize: isFirst ? 11 : 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Plataforma do pódio
          Container(
            height: isFirst ? 8 : 5,
            decoration: BoxDecoration(
              color: podiumColor.withValues(alpha: 0.4),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RUNNER-UP ROW (4º, 5º lugar)
// ═══════════════════════════════════════════════════════════════

class RunnerUpRow extends StatelessWidget {
  final Map<String, dynamic> donor;
  final int position;

  const RunnerUpRow({Key? key, required this.donor, required this.position})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Posição
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                '$position°',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(donor['emoji'] as String,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donor['name'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  donor['city'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // Métricas
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MiniMetric(label: '${donor['donations']}', icon: '🎁'),
              const SizedBox(height: 2),
              MiniMetric(label: '${donor['dreams']}', icon: '❤️'),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MINI MÉTRICA
// ═══════════════════════════════════════════════════════════════

class MiniMetric extends StatelessWidget {
  final String label;
  final String icon;

  const MiniMetric({Key? key, required this.label, required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
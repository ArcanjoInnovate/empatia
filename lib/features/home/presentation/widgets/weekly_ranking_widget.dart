// lib/features/home/presentation/widgets/weekly_ranking_widget.dart
//
// WeeklyRankingWidget — carrossel compacto (max 160px) na Home
// RankingPage         — tela completa com pódio + top 10
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:empatia/features/home/presentation/constants/home_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════
// TOKENS
// ═══════════════════════════════════════════════════════════════

abstract final class _R {
  static const gold    = Color(0xFFFFD700);
  static const goldD   = Color(0xFFF59E0B);
  static const silver  = Color(0xFFB0BEC5);
  static const bronze  = Color(0xFFCD7F32);
  static const navy    = Color(0xFF0F1F3D);
  static const blue    = Color(0xFF1E3A8A);
  static const purple  = Color(0xFF3B1FA0);
  static const white   = Colors.white;

  static Color medal(int pos) {
    if (pos == 1) return gold;
    if (pos == 2) return silver;
    return bronze;
  }

  static String emoji(int pos) {
    if (pos == 1) return '🥇';
    if (pos == 2) return '🥈';
    return '🥉';
  }

  static String badge(int pos) {
    if (pos == 1) return '⭐ Líder da Semana';
    if (pos == 2) return '❤️ Herói da Comunidade';
    return '🏆 Maior Doador';
  }
}

// ═══════════════════════════════════════════════════════════════
// WEEKLY RANKING WIDGET — compacto, carrossel auto-animado
// ═══════════════════════════════════════════════════════════════

class WeeklyRankingWidget extends StatefulWidget {
  /// Mantido por compatibilidade com home_page.dart — pode ser null
  final AnimationController? animation;

  const WeeklyRankingWidget({Key? key, this.animation}) : super(key: key);

  @override
  State<WeeklyRankingWidget> createState() => _WeeklyRankingWidgetState();
}

class _WeeklyRankingWidgetState extends State<WeeklyRankingWidget> {
  late final PageController _page;
  Timer? _timer;
  int _current = 0;

  final _donors = kMockDonors.take(3).toList();

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 1.0);
    _startAuto();
  }

  void _startAuto() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _donors.length;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho ──────────────────────────────────────
          Row(
            children: [
              const Text(
                '🏆',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Ranking Semanal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F1F3D),
                  letterSpacing: 0.1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RankingPage()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver Ranking',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _R.blue.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: _R.blue.withValues(alpha: 0.60),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Carrossel ───────────────────────────────────────
          SizedBox(
            height: 130,
            child: PageView.builder(
              controller: _page,
              itemCount: _donors.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, i) {
                return _RankSlide(
                  donor: _donors[i],
                  position: i + 1,
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ── Indicador de página ─────────────────────────────
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_donors.length, (i) {
                final active = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? _R.medal(_current + 1)
                        : Colors.grey.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SLIDE DO CARROSSEL
// ─────────────────────────────────────────────────────────────

class _RankSlide extends StatelessWidget {
  final Map<String, dynamic> donor;
  final int position;
  const _RankSlide({required this.donor, required this.position});

  @override
  Widget build(BuildContext context) {
    final isFirst  = position == 1;
    final medal    = _R.medal(position);
    final gradient = _slideGradient(position);

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: medal.withValues(alpha: isFirst ? 0.30 : 0.15),
            blurRadius: isFirst ? 20 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Decoração de fundo
          Positioned(
            right: -18,
            top: -18,
            child: Text(
              _R.emoji(position),
              style: TextStyle(
                fontSize: 80,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),

          // Conteúdo principal
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Row(
              children: [
                // Avatar com brilho
                _SlideAvatar(
                  emoji: donor['emoji'] as String,
                  medal: medal,
                  isFirst: isFirst,
                ),

                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Posição
                      Row(
                        children: [
                          if (isFirst)
                            const Text(
                              '👑  ',
                              style: TextStyle(fontSize: 13),
                            ),
                          Text(
                            '${position}° Lugar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: medal,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Nome
                      Text(
                        (donor['name'] as String).split(' ').first,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 5),

                      // Doações
                      Text(
                        '${donor['donations']} doações realizadas',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Badge vertical
                _VerticalBadge(
                  label: _R.badge(position),
                  color: medal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _slideGradient(int pos) {
    if (pos == 1) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F1F3D), Color(0xFF1A1060), Color(0xFF3B1FA0)],
        stops: [0.0, 0.5, 1.0],
      );
    }
    if (pos == 2) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A2A4A), Color(0xFF1E3A8A)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2C1810), Color(0xFF7C3D1A)],
    );
  }
}

class _SlideAvatar extends StatelessWidget {
  final String emoji;
  final Color medal;
  final bool isFirst;
  const _SlideAvatar(
      {required this.emoji, required this.medal, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    final size = isFirst ? 72.0 : 60.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: medal.withValues(alpha: 0.15),
        border: Border.all(
          color: medal.withValues(alpha: isFirst ? 0.90 : 0.60),
          width: isFirst ? 2.5 : 2.0,
        ),
        boxShadow: isFirst
            ? [
                BoxShadow(
                  color: medal.withValues(alpha: 0.50),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: isFirst ? 34 : 28),
        ),
      ),
    );
  }
}

class _VerticalBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _VerticalBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RANKING PAGE — tela completa dedicada
// ═══════════════════════════════════════════════════════════════

class RankingPage extends StatefulWidget {
  const RankingPage({Key? key}) : super(key: key);

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1F3D),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── AppBar decorativa ────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: const Color(0xFF0F1F3D),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _RankingPageHero(anim: _anim),
              ),
            ),

            // ── Pódio top 3 ─────────────────────────────────
            SliverToBoxAdapter(
              child: _FullPodium(anim: _anim),
            ),

            // ── Lista 4º ao último ───────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final donor = kMockDonors[i + 3];
                    return _FullRunnerUp(
                      donor: donor,
                      position: i + 4,
                      anim: _anim,
                      delay: 0.1 * i,
                    );
                  },
                  childCount: (kMockDonors.length - 3).clamp(0, 97),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RANKING PAGE — hero do topo
// ─────────────────────────────────────────────────────────────

class _RankingPageHero extends StatelessWidget {
  final AnimationController anim;
  const _RankingPageHero({required this.anim});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F1F3D),
            Color(0xFF1A1060),
            Color(0xFF3B1FA0),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: 20,
            child: Text(
              '🏆',
              style: TextStyle(
                fontSize: 120,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Column(
              children: [
                const Text(
                  '🏆',
                  style: TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ranking Semanal',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Os heróis que mais transformaram vidas',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.60),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PÓDIO COMPLETO NA RANKING PAGE
// ─────────────────────────────────────────────────────────────

class _FullPodium extends StatelessWidget {
  final AnimationController anim;
  const _FullPodium({required this.anim});

  @override
  Widget build(BuildContext context) {
    final top3 = kMockDonors.take(3).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🥇 Maiores Doadores',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F1F3D),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _PodiumCol(
                    donor: top3[1],
                    position: 2,
                    anim: anim,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: _PodiumCol(
                    donor: top3[0],
                    position: 1,
                    anim: anim,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PodiumCol(
                    donor: top3[2],
                    position: 3,
                    anim: anim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumCol extends StatelessWidget {
  final Map<String, dynamic> donor;
  final int position;
  final AnimationController anim;
  const _PodiumCol({
    required this.donor,
    required this.position,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = position == 1;
    final medal = _R.medal(position);
    final delay = position == 1 ? 0.0 : position == 2 ? 0.15 : 0.25;
    final podH = isFirst ? 64.0 : position == 2 ? 48.0 : 34.0;
    final avatarSize = isFirst ? 72.0 : 56.0;

    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) {
        final t = ((anim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutBack.transform(t);
        return Transform.scale(
          scale: 0.65 + 0.35 * curve,
          alignment: Alignment.bottomCenter,
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isFirst) ...[
            const Text('👑', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
          ] else
            SizedBox(height: isFirst ? 0 : position == 2 ? 28 : 48),

          // Avatar
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medal.withValues(alpha: 0.12),
              border: Border.all(
                color: medal,
                width: isFirst ? 2.5 : 2,
              ),
              boxShadow: isFirst
                  ? [
                      BoxShadow(
                        color: medal.withValues(alpha: 0.45),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                donor['emoji'] as String,
                style: TextStyle(fontSize: isFirst ? 32 : 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _R.emoji(position),
            style: TextStyle(fontSize: isFirst ? 20 : 16),
          ),
          const SizedBox(height: 4),
          Text(
            (donor['name'] as String).split(' ').first,
            style: TextStyle(
              fontSize: isFirst ? 13 : 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F1F3D),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: medal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🎁 ${donor['donations']}',
              style: TextStyle(
                fontSize: isFirst ? 12 : 10,
                fontWeight: FontWeight.w800,
                color: medal == _R.gold ? const Color(0xFFB45309) : medal,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Plataforma
          Container(
            height: podH,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  medal.withValues(alpha: 0.45),
                  medal.withValues(alpha: 0.20),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(
              child: Text(
                '${position}°',
                style: TextStyle(
                  fontSize: isFirst ? 15 : 12,
                  fontWeight: FontWeight.w900,
                  color: medal == _R.gold ? const Color(0xFFB45309) : medal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RUNNER-UP ROWS NA RANKING PAGE
// ─────────────────────────────────────────────────────────────

class _FullRunnerUp extends StatelessWidget {
  final Map<String, dynamic> donor;
  final int position;
  final AnimationController anim;
  final double delay;
  const _FullRunnerUp({
    required this.donor,
    required this.position,
    required this.anim,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) {
        final t = ((anim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final dx = (1.0 - Curves.easeOutCubic.transform(t)) * 40;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Posição
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: Center(
                child: Text(
                  '$position°',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0E6FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  donor['emoji'] as String,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donor['name'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F1F3D),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    donor['city'] as String,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            // Métricas
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Metric(icon: '🎁', value: '${donor['donations']}'),
                const SizedBox(height: 2),
                _Metric(icon: '❤️', value: '${donor['dreams']}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String icon;
  final String value;
  const _Metric({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════
// ALIASES PÚBLICOS — não quebrar imports existentes
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
  Widget build(BuildContext context) =>
      _PodiumCol(donor: donor, position: position, anim: anim);
}

class RunnerUpRow extends StatelessWidget {
  final Map<String, dynamic> donor;
  final int position;
  const RunnerUpRow({
    Key? key,
    required this.donor,
    required this.position,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      _FullRunnerUp(
        donor: donor,
        position: position,
        anim: AnimationController(
          vsync: Navigator.of(context),
          value: 1.0,
          duration: Duration.zero,
        ),
        delay: 0,
      );
}

class MiniMetric extends StatelessWidget {
  final String label;
  final String icon;
  const MiniMetric({Key? key, required this.label, required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) =>
      _Metric(icon: icon, value: label);
}
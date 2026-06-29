// lib/features/ranking/presentation/pages/ranking_page.dart
//
// RankingPage — pódio animado + lista top 100 + gatilhos motivacionais
// Todas as cores centralizadas em AppTheme / AppDecorations.
// ─────────────────────────────────────────────────────────────────────

import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/ranking/controller/ranking_controller.dart';
import 'package:empatia/features/ranking/data/repository/ranking_repository.dart';
import 'package:empatia/features/ranking/presentation/widget/weekly_ranking_widget.dart'
    show RankAvatar;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ══════════════════════════════════════════════════════════════
// HELPERS LOCAIS
// ══════════════════════════════════════════════════════════════

String _rankEmoji(int pos) {
  if (pos == 1) return '🥇';
  if (pos == 2) return '🥈';
  return '🥉';
}

String _rankTitle(int pos) {
  if (pos == 1) return 'Guardião Supremo';
  if (pos == 2) return 'G. de Prata';
  if (pos == 3) return 'G. de Bronze';
  if (pos <= 10) return 'Herói';
  if (pos <= 30) return 'Benfeitor';
  return 'Doador';
}

// ══════════════════════════════════════════════════════════════
// RANKING PAGE
// ══════════════════════════════════════════════════════════════

class RankingPage extends StatefulWidget {
  final RankingController controller;
  final String? currentUserId;

  const RankingPage({
    Key? key,
    required this.controller,
    this.currentUserId,
  }) : super(key: key);

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
      duration: const Duration(milliseconds: 900),
    );
    widget.controller.addListener(_onController);
    if (widget.controller.isLoaded) _anim.forward();
  }

  void _onController() {
    if (!mounted) return;
    setState(() {});
    if (widget.controller.isLoaded) _anim.forward(from: 0);
  }

  @override
  void dispose() {
    _anim.dispose();
    widget.controller.removeListener(_onController);
    super.dispose();
  }

  ({RankingEntry? entry, RankingEntry? above}) _currentUserContext() {
    if (widget.currentUserId == null) return (entry: null, above: null);
    final entries = widget.controller.entries;
    final idx = entries.indexWhere((e) => e.id == widget.currentUserId);
    if (idx < 0) return (entry: null, above: null);
    final above = idx > 0 ? entries[idx - 1] : null;
    return (entry: entries[idx], above: above);
  }

  @override
  Widget build(BuildContext context) {
    final ctx = _currentUserContext();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        // Fundo pastel roxo — não navy
        backgroundColor: AppTheme.rankingBackground,
        body: RefreshIndicator(
          onRefresh: widget.controller.refresh,
          color: AppTheme.rankingRefreshColor, // kidsYellowGold
          backgroundColor: AppTheme.kidsPurple,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── AppBar ───────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                // AppBar colapsada usa o primeiro stop do header (kidsPink)
                backgroundColor: AppTheme.kidsPink,
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
                  background: _PageHero(
                    anim: _anim,
                    daysLeft: widget.controller.daysUntilReset,
                    userEntry: ctx.entry,
                  ),
                ),
              ),

              // ── Banner do usuário logado ──────────────────────
              if (ctx.entry != null && ctx.above != null)
                SliverToBoxAdapter(
                  child: _UserPositionBanner(
                    entry: ctx.entry!,
                    above: ctx.above!,
                  ),
                ),

              // ── Corpo ────────────────────────────────────────
              ..._buildBody(ctx),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(
      ({RankingEntry? entry, RankingEntry? above}) ctx) {
    if (widget.controller.isLoading) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.rankingAccent, // kidsPurple
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      ];
    }

    if (widget.controller.hasError) {
      return [
        SliverToBoxAdapter(
          child: _PageError(
            message: widget.controller.error,
            onRetry: widget.controller.refresh,
          ),
        ),
      ];
    }

    if (widget.controller.isEmpty) {
      return [const SliverToBoxAdapter(child: _PageEmpty())];
    }

    final entries = widget.controller.entries;
    final top3    = entries.take(3).toList();
    final rest    = entries.skip(3).toList();

    return [
      SliverToBoxAdapter(
        child: _FullPodium(top3: top3, anim: _anim),
      ),
      if (rest.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final e         = rest[i];
                final isCurrent = e.id == widget.currentUserId;
                final aboveEntry = i > 0
                    ? rest[i - 1]
                    : (top3.isNotEmpty ? top3.last : null);
                return _RunnerUpRow(
                  entry: e,
                  anim: _anim,
                  delay: (0.08 * i).clamp(0.0, 0.7),
                  isCurrentUser: isCurrent,
                  aboveEntry: isCurrent ? aboveEntry : null,
                );
              },
              childCount: rest.length,
            ),
          ),
        ),
    ];
  }
}

// ══════════════════════════════════════════════════════════════
// HERO DO TOPO
// ══════════════════════════════════════════════════════════════

class _PageHero extends StatelessWidget {
  final AnimationController anim;
  final int? daysLeft;
  final RankingEntry? userEntry;

  const _PageHero({required this.anim, this.daysLeft, this.userEntry});

  @override
  Widget build(BuildContext context) {
    final String subtitle;
    if (daysLeft != null && daysLeft! > 0) {
      subtitle =
          'Ranking reinicia em $daysLeft ${daysLeft == 1 ? 'dia' : 'dias'}';
    } else if (daysLeft == 0) {
      subtitle = 'Última chance de subir — reinicia hoje!';
    } else {
      subtitle = 'Os que mais transformaram vidas esta semana';
    }

    return Container(
      decoration: AppDecorations.rankingHeader, // pink → yellow → purple
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: 20,
            child: Text(
              '🏆',
              style: TextStyle(
                fontSize: 120,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Column(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                const Text(
                  'Guardiões desta Semana',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: AppDecorations.rankingCountdownPillHero,
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
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

// ══════════════════════════════════════════════════════════════
// BANNER DE POSIÇÃO DO USUÁRIO
// ══════════════════════════════════════════════════════════════

class _UserPositionBanner extends StatelessWidget {
  final RankingEntry entry;
  final RankingEntry above;

  const _UserPositionBanner({required this.entry, required this.above});

  @override
  Widget build(BuildContext context) {
    final gap = above.score - entry.score;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppDecorations.rankingUserBanner, // purple → pink
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Apenas $gap pts ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.kidsYellowGold,
                    ),
                  ),
                  TextSpan(
                    text: 'te separam de ${above.firstName} '
                        '(${above.position}°) — você é um '
                        '${_rankTitle(entry.position)}',
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

// ══════════════════════════════════════════════════════════════
// PÓDIO TOP 3
// ══════════════════════════════════════════════════════════════

class _FullPodium extends StatelessWidget {
  final List<RankingEntry> top3;
  final AnimationController anim;
  const _FullPodium({required this.top3, required this.anim});

  @override
  Widget build(BuildContext context) {
    final slots = List<RankingEntry?>.filled(3, null);
    for (int i = 0; i < top3.length && i < 3; i++) slots[i] = top3[i];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: AppDecorations.rankingPodiumCard, // branco, borda lilás
      child: Column(
        children: [
          const Text(
            '🏆 Hall dos Guardiões',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 24),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                    flex: 3,
                    child: _PodiumCol(
                        entry: slots[1], position: 2, anim: anim)),
                const SizedBox(width: 8),
                Expanded(
                    flex: 4,
                    child: _PodiumCol(
                        entry: slots[0], position: 1, anim: anim)),
                const SizedBox(width: 8),
                Expanded(
                    flex: 3,
                    child: _PodiumCol(
                        entry: slots[2], position: 3, anim: anim)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumCol extends StatelessWidget {
  final RankingEntry? entry;
  final int position;
  final AnimationController anim;

  const _PodiumCol({
    required this.entry,
    required this.position,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst    = position == 1;
    final medal      = AppTheme.rankingMedalColor(position);
    final textColor  = AppTheme.rankingMedalTextColor(position);
    final delay      = position == 1 ? 0.0 : position == 2 ? 0.15 : 0.25;
    final podH       = isFirst ? 64.0 : position == 2 ? 48.0 : 34.0;
    final avatarSize = isFirst ? 72.0 : 56.0;

    // Slot vazio
    if (entry == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medal.withValues(alpha: 0.08),
              border: Border.all(
                  color: medal.withValues(alpha: 0.25), width: 2),
            ),
            child: Center(
              child: Text(
                '✦',
                style: TextStyle(
                  fontSize: avatarSize * 0.35,
                  color: medal.withValues(alpha: 0.40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(_rankEmoji(position),
              style: TextStyle(fontSize: isFirst ? 20 : 16)),
          const SizedBox(height: 4),
          Text(
            'Pode ser\nvocê',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isFirst ? 10 : 9,
              color: medal.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: podH,
            decoration: AppDecorations.rankingPodiumEmpty(position),
            child: Center(
              child: Text(
                '${position}°',
                style: TextStyle(
                  fontSize: isFirst ? 15 : 12,
                  fontWeight: FontWeight.w900,
                  color: medal.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) {
        final t     = ((anim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutBack.transform(t);
        return Transform.scale(
          scale: 0.65 + 0.35 * curve,
          alignment: Alignment.bottomCenter,
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFirst) ...[
            const Text('👑', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
          ] else
            const Spacer(),

          RankAvatar(
            entry: entry!,
            position: position,
            size: avatarSize,
            glow: isFirst,
          ),

          const SizedBox(height: 8),
          Text(_rankEmoji(position),
              style: TextStyle(fontSize: isFirst ? 20 : 16)),
          const SizedBox(height: 4),
          Text(
            entry!.firstName,
            style: TextStyle(
              fontSize: isFirst ? 13 : 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _rankTitle(position),
            style: TextStyle(
              fontSize: isFirst ? 9 : 8,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: AppDecorations.rankingPodiumScorePill(position),
            child: Text(
              isFirst
                  ? '🎁 ${entry!.count} ${entry!.count == 1 ? 'vida' : 'vidas'}'
                  : '🎁 ${entry!.count}',
              style: TextStyle(
                fontSize: isFirst ? 11 : 9,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: podH,
            decoration: AppDecorations.rankingPodiumFilled(position),
            child: Center(
              child: Text(
                '${position}°',
                style: TextStyle(
                  fontSize: isFirst ? 15 : 12,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// RUNNER-UP ROWS — 4° ao 100°
// ══════════════════════════════════════════════════════════════

class _RunnerUpRow extends StatelessWidget {
  final RankingEntry entry;
  final AnimationController anim;
  final double delay;
  final bool isCurrentUser;
  final RankingEntry? aboveEntry;

  const _RunnerUpRow({
    required this.entry,
    required this.anim,
    required this.delay,
    this.isCurrentUser = false,
    this.aboveEntry,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) {
        final t  = ((anim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final dx = (1.0 - Curves.easeOutCubic.transform(t)) * 40;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.fromLTRB(14, isCurrentUser ? 14 : 12, 14, 12),
        decoration: isCurrentUser
            ? AppDecorations.rankingRunnerUpRowSelf  // bgPastelPink + borda pink
            : AppDecorations.rankingRunnerUpRow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Posição
                Container(
                  width: 34,
                  height: 34,
                  decoration: AppDecorations.rankingPositionBox(
                      isSelf: isCurrentUser),
                  child: Center(
                    child: Text(
                      '${entry.position}°',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isCurrentUser
                            ? AppTheme.kidsPink
                            : AppTheme.textCharcoal,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                RankAvatar(
                  entry: entry,
                  position: isCurrentUser ? 1 : 4,
                  size: 40,
                  glow: false,
                ),

                const SizedBox(width: 12),

                // Nome + título + cidade
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isCurrentUser ? 'Você' : entry.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: AppDecorations.rankingSelfTitlePill,
                              child: Text(
                                _rankTitle(entry.position),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.kidsPink,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (entry.location.isNotEmpty)
                        Text(
                          entry.location,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary
                                .withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                ),

                // Métricas
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Metric(icon: '🎁', value: '${entry.count}'),
                    const SizedBox(height: 2),
                    _Metric(icon: '⭐', value: '${entry.score} pts'),
                  ],
                ),
              ],
            ),

            // Gap motivacional — só na linha do usuário logado
            if (isCurrentUser && aboveEntry != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: AppDecorations.rankingGapBox,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🚀', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      'Faltam ${aboveEntry!.score - entry.score} pts para '
                      'superar ${aboveEntry!.firstName} '
                      '(${aboveEntry!.position}°)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.rankingAccent, // kidsPurple
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ESTADOS DA PÁGINA
// ══════════════════════════════════════════════════════════════

class _PageEmpty extends StatelessWidget {
  const _PageEmpty();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
        child: Column(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            const Text(
              'Nenhum Guardião ainda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'A primeira doação desta semana garante o título de Guardião Pioneiro.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary.withValues(alpha: 0.80),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _PageError extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const _PageError({this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
        child: Column(
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar o ranking',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Verifique sua conexão e tente novamente.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary.withValues(alpha: 0.80),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: AppDecorations.rankingPageRetryButton,
                child: const Text(
                  'Tentar novamente',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════
// METRIC TAG
// ══════════════════════════════════════════════════════════════

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
              color: AppTheme.textCharcoal,
            ),
          ),
        ],
      );
}

// ══════════════════════════════════════════════════════════════
// ALIASES PÚBLICOS — retrocompatibilidade
// ══════════════════════════════════════════════════════════════

class PodiumCard extends StatelessWidget {
  final RankingEntry entry;
  final int position;
  final AnimationController anim;
  const PodiumCard({
    Key? key,
    required this.entry,
    required this.position,
    required this.anim,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      _PodiumCol(entry: entry, position: position, anim: anim);
}

class RunnerUpRow extends StatelessWidget {
  final RankingEntry entry;
  const RunnerUpRow({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) => _RunnerUpRow(
        entry: entry,
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
  Widget build(BuildContext context) => _Metric(icon: icon, value: label);
}
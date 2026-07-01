// lib/features/ranking/presentation/widget/weekly_ranking_widget.dart
//
// WeeklyRankingWidget — carrossel compacto (top 3) exibido na Home
// Todas as cores centralizadas em AppTheme / AppDecorations.
// ─────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:empatia/core/navigation/router_observer.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/widget/avatar_render.dart';
import 'package:empatia/features/ranking/controller/ranking_controller.dart';
import 'package:empatia/features/ranking/data/repository/ranking_repository.dart';
import 'package:empatia/features/ranking/presentation/page/ranking_page.dart';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// HELPERS LOCAIS
// ══════════════════════════════════════════════════════════════

String _rankEmoji(int pos) {
  if (pos == 1) return '🥇';
  if (pos == 2) return '🥈';
  return '🥉';
}

String _rankIdentity(int pos) {
  if (pos == 1) return 'Guardião Supremo';
  if (pos == 2) return 'G. de Prata';
  return 'G. de Bronze';
}

String _rankBadge(int pos) {
  if (pos == 1) return '👑 Guardião Supremo';
  if (pos == 2) return '🥈 G. de Prata';
  return '🥉 G. de Bronze';
}

// ══════════════════════════════════════════════════════════════
// WEEKLY RANKING WIDGET
// ══════════════════════════════════════════════════════════════

class WeeklyRankingWidget extends StatefulWidget {
  final RankingController controller;

  const WeeklyRankingWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  State<WeeklyRankingWidget> createState() => _WeeklyRankingWidgetState();
}

class _WeeklyRankingWidgetState extends State<WeeklyRankingWidget>
    with RouteAware {
  late final PageController _page;
  Timer? _timer;
  int _current = 0;

  /// Rota desta página (Home). Usada para registrar/cancelar o
  /// RouteObserver — precisamos saber quando uma página é empurrada por
  /// cima da Home (didPushNext) e quando voltamos a ela (didPopNext).
  ModalRoute<dynamic>? _route;

  /// Controla se este widget está "na frente" no momento. Enquanto for
  /// false (outra rota está por cima), o timer de auto-scroll fica
  /// pausado — evita que o PageView anime por baixo bem na hora da
  /// transição de pop, o que causava o flash/"fantasma" visual ao voltar
  /// para a Home.
  bool _isVisible = true;

  List<RankingEntry> get _top3 =>
      widget.controller.entries.take(3).toList();

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 1.0);
    widget.controller.addListener(_onController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && _route != route) {
      if (_route != null) {
        appRouteObserver.unsubscribe(this);
      }
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  // ── RouteAware ──────────────────────────────────────────────
  // Disparado quando outra rota é empurrada por cima desta (ex.: ao
  // abrir a página de ranking completo).
  @override
  void didPushNext() {
    _isVisible = false;
    _timer?.cancel();
  }

  // Disparado quando a rota de cima é removida e voltamos a ver esta
  // página novamente.
  @override
  void didPopNext() {
    _isVisible = true;
    if (widget.controller.isLoaded && _top3.isNotEmpty) {
      _startAuto();
    }
  }

  void _onController() {
    if (!mounted) return;
    setState(() {});
    if (_isVisible && widget.controller.isLoaded && _top3.isNotEmpty) {
      _timer?.cancel();
      _startAuto();
    }
  }

  void _startAuto() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_isVisible || _top3.isEmpty) return;
      final next = (_current + 1) % _top3.length;
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
    widget.controller.removeListener(_onController);
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days     = widget.controller.daysUntilReset;
    final dayLabel = days == 0
        ? 'Reinicia hoje'
        : days == 1
            ? 'Reinicia amanhã'
            : 'Reinicia em $days dias';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho ──────────────────────────────────────
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      'Guardiões da Semana',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                        letterSpacing: 0.1,
                      ),
                    ),

                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RankingPage(controller: widget.controller),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver todos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.kidsPurple.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppTheme.kidsPurple.withValues(alpha: 0.60),
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
            child: _buildCarousel(),
          ),

          const SizedBox(height: 10),

          // ── Indicador de página ─────────────────────────────
          if (_top3.isNotEmpty)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_top3.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 22 : 7,
                    height: 7,
                    decoration: active
                        ? AppDecorations.rankingPageDotActive(_current + 1)
                        : AppDecorations.rankingPageDotInactive,
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    if (widget.controller.isLoading) return const _CarouselSkeleton();
    if (widget.controller.hasError) {
      return _CarouselError(onRetry: widget.controller.refresh);
    }
    if (_top3.isEmpty) return const _CarouselEmpty();

    return PageView.builder(
      controller: _page,
      itemCount: _top3.length,
      onPageChanged: (i) => setState(() => _current = i),
      itemBuilder: (context, i) => _RankSlide(
        entry: _top3[i],
        position: i + 1,
        nextEntry: i + 1 < _top3.length ? _top3[i + 1] : null,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SLIDE DO CARROSSEL
// ══════════════════════════════════════════════════════════════

class _RankSlide extends StatelessWidget {
  final RankingEntry entry;
  final int position;
  final RankingEntry? nextEntry;

  const _RankSlide({
    required this.entry,
    required this.position,
    this.nextEntry,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = position == 1;
    final medal   = AppTheme.rankingMedalColor(position);

    final countLabel = entry.count == 1
        ? '1 vida tocada esta semana'
        : '${entry.count} vidas tocadas esta semana';

    final gap = (!isFirst && nextEntry != null)
        ? entry.score - nextEntry!.score
        : null;

    // Removida a navegação para o PublicProfilePage a partir deste
    // slide — o card do carrossel agora é só informativo (sem
    // GestureDetector/onTap). "Ver todos" continua levando à RankingPage.
    return Container(
      margin: EdgeInsets.zero,
      decoration: AppDecorations.rankingSlide(position),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Emoji decorativo de fundo
          Positioned(
            right: -18,
            top: -18,
            child: Text(
              _rankEmoji(position),
              style: TextStyle(
                fontSize: 80,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Row(
              children: [
                RankAvatar(
                  entry: entry,
                  position: position,
                  size: isFirst ? 72 : 60,
                  glow: isFirst,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Identidade
                      Row(
                        children: [
                          if (isFirst)
                            const Text('👑  ', style: TextStyle(fontSize: 13)),
                          Text(
                            _rankIdentity(position),
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
                      Text(
                        entry.firstName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '🎁 $countLabel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Gap motivacional
                      if (gap != null) ...[
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: AppDecorations.rankingSlideGapBadge,
                          child: Text(
                            '⚡ $gap pts atrás do ${position - 1}°',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.90),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _VerticalBadge(
                    label: _rankBadge(position), position: position),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ESTADOS DO CARROSSEL
// ══════════════════════════════════════════════════════════════

class _CarouselSkeleton extends StatelessWidget {
  const _CarouselSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        decoration: AppDecorations.rankingCarouselSkeleton,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.rankingAccent,
            strokeWidth: 2,
          ),
        ),
      );
}

class _CarouselError extends StatelessWidget {
  final VoidCallback onRetry;
  const _CarouselError({required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        decoration: AppDecorations.rankingCarouselSkeleton,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            const Text(
              'Erro ao carregar ranking',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textCharcoal,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: AppDecorations.rankingRetryButton,
                child: const Text(
                  'Tentar novamente',
                  style: TextStyle(
                    fontSize: 11,
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

class _CarouselEmpty extends StatelessWidget {
  const _CarouselEmpty();

  @override
  Widget build(BuildContext context) => Container(
        decoration: AppDecorations.rankingCarouselEmpty,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('👑', style: TextStyle(fontSize: 28)),
              SizedBox(height: 6),
              Text(
                'O trono está vazio',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Primeira doação desta semana\nganha o título de Guardião Pioneiro',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xCCFFFFFF),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
// COMPONENTES COMPARTILHADOS
// ══════════════════════════════════════════════════════════════

/// Avatar circular com borda de medalha e glow opcional.
class RankAvatar extends StatelessWidget {
  final RankingEntry entry;
  final int position;
  final double size;
  final bool glow;

  const RankAvatar({
    Key? key,
    required this.entry,
    required this.position,
    required this.size,
    this.glow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        entry.profileImage != null && entry.profileImage!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: AppDecorations.rankingAvatar(pos: position, glow: glow),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                entry.profileImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    AvatarRender(value: entry.avatarEmoji, size: size),
              )
            : AvatarRender(value: entry.avatarEmoji, size: size),
      ),
    );
  }
}

class _VerticalBadge extends StatelessWidget {
  final String label;
  final int position;
  const _VerticalBadge({required this.label, required this.position});

  @override
  Widget build(BuildContext context) => RotatedBox(
        quarterTurns: 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: AppDecorations.rankingVerticalBadge(position),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white, // badge sobre gradiente vibrante → branco
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
}
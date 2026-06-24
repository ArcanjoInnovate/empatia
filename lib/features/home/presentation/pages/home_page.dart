// lib/features/home/presentation/pages/home_page.dart
//
// Tela principal do app Empatia — Feed Premium
// Arquitetura: StatefulWidget + FeedController (ChangeNotifier)
//
// Esta página orquestra os widgets extraídos:
//   - home_constants.dart        → cores, mocks, chips, insights
//   - weekly_ranking_widget.dart → pódio + ranking semanal
//   - feed_cards.dart            → FeedCard, InsightBlock, badges...
//   - filter_widgets.dart        → FilterChip, TypeChip, FilterSheet
// ─────────────────────────────────────────────────────────────

import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_icons.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/home/controllers/feed_controller.dart';
import 'package:empatia/features/home/data/models/feed_item_.dart';
import 'package:empatia/features/home/data/repositories/feed_repository.dart';
import 'package:empatia/features/home/presentation/constants/home_constants.dart';
import 'package:empatia/features/home/presentation/widgets/feeds_card.dart';
import 'package:empatia/features/home/presentation/widgets/filter_widgets.dart';
import 'package:empatia/features/home/presentation/widgets/weekly_ranking_widget.dart';
import 'package:flutter/material.dart' hide FilterChip;

// ═══════════════════════════════════════════════════════════════
// HOME PAGE
// ═══════════════════════════════════════════════════════════════

class HomePage extends StatefulWidget {
  final UserModel user;
  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final FeedController _feed;
  final _scrollController = ScrollController();
  late final AnimationController _rankingAnim;

  @override
  void initState() {
    super.initState();

    // Animação de entrada do ranking
    _rankingAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _feed = FeedController(
      FeedRepository(),
      currentUserId: widget.user.id ?? '',
    )..init();
    _feed.addListener(() {
      if (mounted) setState(() {});
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final max = _scrollController.position.maxScrollExtent;
    final cur = _scrollController.position.pixels;
    if (cur >= max - 300 && _feed.hasMore && !_feed.isLoadingMore) {
      _feed.loadMore();
    }
  }

  @override
  void dispose() {
    _rankingAnim.dispose();
    _scrollController.dispose();
    _feed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _feed.refresh,
        color: AppTheme.kidsPurple,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── 1. Header ──────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader()),

            // ── 2. Ranking Semanal ─────────────────────────────
            SliverToBoxAdapter(
              child: WeeklyRankingWidget(animation: _rankingAnim),
            ),

            // ── 3. Filtros (chips animados) ────────────────────
            SliverToBoxAdapter(child: _buildFilterChips()),

            // ── 4. Feed + blocos de destaque + paginação ───────
            _buildFeedContent(),
            SliverToBoxAdapter(child: _buildLoadMoreIndicator()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // HEADER
  // ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bom dia' : hour < 18 ? 'Boa tarde' : 'Boa noite';
    final greetEmoji = hour < 12 ? '🌅' : hour < 18 ? '☀️' : '🌙';

    return Container(
      decoration: AppDecorations.homeHeader,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EMPATIA',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(greetEmoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          '$greeting, ${widget.user.name?.split(' ').first ?? 'Amigo'}! 👋',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {/* TODO: notificações */},
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    AppIcons.notificationsOutline,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // CHIPS DE FILTRO + ATALHO PARA O BOTTOM SHEET GEOGRÁFICO
  // ────────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    final currentType = _feed.filter.type;
    final hasGeoFilter = _feed.filter.stateCode != null || _feed.filter.city != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Título da seção + botão filtro geográfico
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Comunidade',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryBlue,
                  letterSpacing: 0.2,
                ),
              ),
              GestureDetector(
                onTap: _showFilterSheet,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: hasGeoFilter
                        ? const LinearGradient(
                            colors: [AppTheme.kidsPurple, Color(0xFFBB86FC)],
                          )
                        : null,
                    color: hasGeoFilter ? null : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: hasGeoFilter
                          ? Colors.transparent
                          : AppTheme.kidsPurple.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.kidsPurple.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 15,
                        color: hasGeoFilter ? Colors.white : AppTheme.kidsPurple,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        hasGeoFilter ? 'Filtros ativos' : 'Filtrar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: hasGeoFilter ? Colors.white : AppTheme.kidsPurple,
                        ),
                      ),
                      if (hasGeoFilter) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _feed.clearFilters,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Chips de tipo — scroll horizontal
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: kFilterChips.length,
            itemBuilder: (context, i) {
              final chip = kFilterChips[i];
              final chipType = chip['type'] as FeedItemType?;
              final isSelected = currentType == chipType;
              return FilterChip(
                emoji: chip['emoji'] as String,
                label: chip['label'] as String,
                selected: isSelected,
                onTap: () {
                  // Passa o tipo explicitamente (mesmo quando null) para que
                  // o chip "Todos" sempre limpe o filtro de tipo corretamente.
                  _feed.applyFilter(_feed.filter.copyWith(type: chipType));
                },
              );
            },
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // FEED CONTENT
  // ────────────────────────────────────────────────────────────

  Widget _buildFeedContent() {
    if (_feed.status == FeedStatus.loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(child: CircularProgressIndicator(color: AppTheme.kidsPurple)),
        ),
      );
    }

    if (_feed.status == FeedStatus.error) {
      return SliverToBoxAdapter(child: _buildErrorState());
    }

    if (_feed.items.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }

    // Insere um bloco de destaque a cada 4 cards
    const insightInterval = 4;
    final feedCount = _feed.items.length;
    final insightCount = feedCount ~/ insightInterval;
    final totalCount = feedCount + insightCount;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Tamanho do bloco: insightInterval itens de feed + 1 insight
          const blockSize = insightInterval + 1;
          final posInBlock = index % blockSize;
          final block = index ~/ blockSize;

          // Última posição do bloco → bloco de destaque
          if (posInBlock == insightInterval) {
            return InsightBlock(data: kInsights[block % kInsights.length]);
          }

          // Item do feed
          final feedIndex = block * insightInterval + posInBlock;
          if (feedIndex >= feedCount) return const SizedBox.shrink();
          return FeedCard(item: _feed.items[feedIndex]);
        },
        childCount: totalCount,
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (!_feed.isLoadingMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: CircularProgressIndicator(color: AppTheme.kidsPurple, strokeWidth: 2),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kPurpleSoft, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kidsPurple.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text('🌟', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 14),
            Text(
              _feed.filter.hasAny
                  ? 'Nenhum resultado para esses filtros'
                  : 'Nenhum item ainda',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _feed.filter.hasAny
                  ? 'Tente ajustar os filtros.'
                  : 'Seja o primeiro a compartilhar!',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (_feed.filter.hasAny) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _feed.clearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.kidsPurple, Color(0xFFBB86FC)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Limpar filtros',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Algo deu errado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _feed.error ?? 'Tente novamente.',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _feed.refresh,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.kidsPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
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
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // BOTTOM SHEET DE FILTROS
  // ────────────────────────────────────────────────────────────

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(controller: _feed),
    );
  }
}
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_icons.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:empatia/features/dream/presentation/pages/full_screen_image_page.dart';
import 'package:empatia/features/home/controllers/feed_controller.dart';
import 'package:empatia/features/home/data/models/feed_filter.dart';
import 'package:empatia/features/home/data/models/feed_item_.dart';
import 'package:empatia/features/home/data/repositories/feed_repository.dart';
import 'package:empatia/features/home/data/services/ibge_service.dart';
import 'package:flutter/material.dart';


class HomePage extends StatefulWidget {
  final UserModel user;

  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FeedController _feed;
  final _scrollController = ScrollController();

  // ── Dados mockados do ranking (substituir por dados reais futuramente) ──────
  static const _mockDonors = [
    {
      'name': 'Ana Carolina Mendes',
      'emoji': '👩',
      'donations': 47,
      'city': 'São Paulo, SP',
    },
    {
      'name': 'Pedro Augusto Lima',
      'emoji': '👨',
      'donations': 38,
      'city': 'Belo Horizonte, MG',
    },
    {
      'name': 'Mariana Silva',
      'emoji': '👩‍🦱',
      'donations': 31,
      'city': 'Rio de Janeiro, RJ',
    },
    {
      'name': 'João Ferreira',
      'emoji': '🧔',
      'donations': 24,
      'city': 'Curitiba, PR',
    },
    {
      'name': 'Fernanda Costa',
      'emoji': '👩‍🦰',
      'donations': 19,
      'city': 'Fortaleza, CE',
    },
  ];

  // ── Anúncios inline do feed ───────────────────────────────────────────────
  static const _inlineAds = [
    {
      'title': 'Bingo da Solidariedade',
      'subtitle': 'Participe e ajude mais famílias!',
      'emoji': '🎟️',
      'colors': [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    },
    {
      'title': 'Novidade chegando',
      'subtitle': 'Fique ligado nas novidades!',
      'emoji': '🎈',
      'colors': [Color(0xFFFF6B9D), Color(0xFFFF1493)],
    },
    {
      'title': 'Evento Empatia',
      'subtitle': 'Diversão e solidariedade garantidas',
      'emoji': '🎮',
      'colors': [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    },
  ];

  @override
  void initState() {
    super.initState();
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
          slivers: [
            // 1. Cabeçalho
            SliverToBoxAdapter(child: _buildHeader()),
            // 2. Ranking de doadores
            SliverToBoxAdapter(child: _buildDonorRanking()),
            // 3. Cabeçalho do feed com filtros
            SliverToBoxAdapter(child: const SizedBox(height: 8)),
            SliverToBoxAdapter(child: _buildFeedHeader()),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            // 4 + 5. Feed principal com anúncios intercalados
            _buildFeedContent(),
            SliverToBoxAdapter(child: _buildLoadMoreIndicator()),
            SliverToBoxAdapter(child: const SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bom dia'
        : hour < 18
        ? 'Boa tarde'
        : 'Boa noite';
    final greetEmoji = hour < 12
        ? '🌅'
        : hour < 18
        ? '☀️'
        : '🌙';

    return Container(
      decoration: AppDecorations.homeHeader,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EMPATIA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(greetEmoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          '$greeting, ${widget.user.name?.split(' ').first ?? 'Amigo'}!',
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: AppDecorations.homeNotificationBadge,
                child: const Icon(
                  AppIcons.notificationsOutline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Ranking de Doadores ───────────────────────────────────────────

  Widget _buildDonorRanking() {
    final top3 = _mockDonors.take(3).toList();
    final rest = _mockDonors.skip(3).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF4527A0), Color(0xFF6A1B9A)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4527A0).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decoração de fundo sutil
          Positioned(
            right: -30,
            top: -30,
            child: Text(
              '🏆',
              style: TextStyle(
                fontSize: 140,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Text(
              '⭐',
              style: TextStyle(
                fontSize: 100,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título da seção
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('🏆', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ranking de Doadores',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            'Heróis da nossa comunidade',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Pódio — top 3
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 2º lugar
                    Expanded(child: _buildPodiumItem(top3[1], 2)),
                    const SizedBox(width: 8),
                    // 1º lugar (maior)
                    Expanded(child: _buildPodiumItem(top3[0], 1)),
                    const SizedBox(width: 8),
                    // 3º lugar
                    Expanded(child: _buildPodiumItem(top3[2], 3)),
                  ],
                ),

                const SizedBox(height: 16),

                // Divisor
                Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                const SizedBox(height: 12),

                // 4º e 5º lugar em lista
                ...List.generate(rest.length, (i) {
                  final donor = rest[i];
                  final position = i + 4;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
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
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              donor['emoji'] as String,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
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
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${donor['donations']} doações',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 4),

                // Botão Ver Ranking Completo
                GestureDetector(
                  onTap: () {
                    // TODO: navegar para tela de ranking completo
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ver Ranking Completo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
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

  Widget _buildPodiumItem(Map<String, dynamic> donor, int position) {
    final isFirst = position == 1;
    final medal = position == 1
        ? '🥇'
        : position == 2
        ? '🥈'
        : '🥉';
    final podiumColor = position == 1
        ? const Color(0xFFFFD700)
        : position == 2
        ? const Color(0xFFB0BEC5)
        : const Color(0xFFFF8C42);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirst) ...[
          Text(
            '👑',
            style: TextStyle(
              fontSize: 18,
              color: Colors.yellow.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          width: isFirst ? 58 : 50,
          height: isFirst ? 58 : 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(isFirst ? 18 : 15),
            border: Border.all(
              color: podiumColor.withValues(alpha: 0.7),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              donor['emoji'] as String,
              style: TextStyle(fontSize: isFirst ? 28 : 24),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(medal, style: TextStyle(fontSize: isFirst ? 18 : 16)),
        const SizedBox(height: 4),
        Text(
          (donor['name'] as String).split(' ').first,
          style: TextStyle(
            fontSize: isFirst ? 12 : 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: podiumColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${donor['donations']}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: podiumColor,
            ),
          ),
        ),
        SizedBox(height: isFirst ? 0 : 0),
      ],
    );
  }

  // ── Anúncio inline do feed ────────────────────────────────────────

  Widget _buildInlineAd(int adIndex) {
    final ad = _inlineAds[adIndex % _inlineAds.length];
    final colors = ad['colors'] as List<Color>;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Text(
              ad['emoji'] as String,
              style: TextStyle(
                fontSize: 80,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Text(
                  ad['emoji'] as String,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad['title'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ad['subtitle'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Patrocinado',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
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

  // ══════════════════════════════════════════════════════════════════════════════
  // PATCH: _buildFeedHeader em home_page.dart
  // Substituir o método inteiro por este
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildFeedHeader() {
    final filter = _feed.filter;
    final hasFilter = filter.hasAny;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linha: título à esquerda, botão filtrar à direita ─────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Comunidade',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.kidsPurple,
                ),
              ),
              GestureDetector(
                onTap: _showFilterSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: hasFilter
                        ? const LinearGradient(
                            colors: [AppTheme.kidsPurple, Color(0xFFBB86FC)],
                          )
                        : null,
                    color: hasFilter ? null : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasFilter
                          ? Colors.transparent
                          : AppTheme.kidsPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: hasFilter ? Colors.white : AppTheme.kidsPurple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Filtrar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: hasFilter ? Colors.white : AppTheme.kidsPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Chip "Limpar filtros" abaixo do título (só quando ativo) ──────
          if (hasFilter) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _feed.clearFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.errorRed.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      size: 10,
                      color: AppTheme.errorRed,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Limpar filtros',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Chips dos filtros ativos ───────────────────────────────────────
          if (hasFilter) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (filter.type != null)
                  _ActiveFilterChip(
                    label: filter.type == FeedItemType.dream
                        ? '💭 Sonhos'
                        : '🎁 Doações',
                    onRemove: () =>
                        _feed.applyFilter(filter.copyWith(type: null)),
                  ),
                // Exibe nome completo do estado (ex: "GO — Goiás")
                if (filter.stateCode != null)
                  _ActiveFilterChip(
                    label: filter.stateName != null
                        ? '${filter.stateCode} — ${filter.stateName}'
                        : filter.stateCode!,
                    onRemove: () => _feed.applyFilter(
                      filter.copyWith(
                        stateCode: null,
                        stateName: null,
                        city: null,
                      ),
                    ),
                  ),
                if (filter.city != null)
                  _ActiveFilterChip(
                    label: filter.city!,
                    onRemove: () =>
                        _feed.applyFilter(filter.copyWith(city: null)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedContent() {
    if (_feed.status == FeedStatus.loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.kidsPurple),
          ),
        ),
      );
    }

    if (_feed.items.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }

    // A cada bloco de 6 posições: 5 itens de feed + 1 anúncio
    const adInterval = 6; // 5 itens + 1 ad por bloco
    final feedCount = _feed.items.length;
    // Quantos anúncios cabem
    final adCount = feedCount ~/ 5;
    final totalCount = feedCount + adCount;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        // Posição dentro do bloco (0..5)
        final posInBlock = index % adInterval;
        // Índice do bloco
        final block = index ~/ adInterval;

        // Última posição do bloco (índice 5) → anúncio
        if (posInBlock == adInterval - 1) {
          return _buildInlineAd(block);
        }

        // Caso contrário → item do feed
        final feedIndex = block * 5 + posInBlock;
        if (feedIndex >= feedCount) return const SizedBox.shrink();
        return _FeedCard(item: _feed.items[feedIndex]);
      }, childCount: totalCount),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (!_feed.isLoadingMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.kidsPurple,
          strokeWidth: 2,
        ),
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
          border: Border.all(color: const Color(0xFFF0E6FF), width: 1.5),
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
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheet de filtros ───────────────────────────────────────

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(controller: _feed),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CARD UNIFICADO DO FEED
// ══════════════════════════════════════════════════════════════════════════════

class _FeedCard extends StatelessWidget {
  final FeedItem item;
  const _FeedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return item.type == FeedItemType.dream
        ? _DreamCard(item: item)
        : _DonationCard(item: item);
  }
}

// ── Card de Sonho ─────────────────────────────────────────────────────────────

class _DreamCard extends StatelessWidget {
  final FeedItem item;
  const _DreamCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0E6FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kidsPurple.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem — 4:3, toque abre fullscreen
          if (item.imageUrl != null)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                FullscreenImagePage.route(
                  imageUrl: item.imageUrl!,
                  heroTag: 'dream_img_${item.id}',
                  title: item.title,
                ),
              ),
              child: Hero(
                tag: 'dream_img_${item.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(23),
                  ),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
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
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF5F0FF),
                        child: Center(
                          child: Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 60),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha topo: tipo + filho + local
                Row(
                  children: [
                    _TypeBadge(
                      label: 'Sonho',
                      emoji: '💭',
                      color: AppTheme.kidsPurple,
                    ),
                    const SizedBox(width: 8),
                    if (item.childName != null)
                      _ChildChip(
                        emoji: item.childEmoji ?? '👶',
                        name: item.childName!,
                      ),
                    const Spacer(),
                    if (item.city != null)
                      _LocationBadge(city: item.city!, state: item.state),
                  ],
                ),

                const SizedBox(height: 12),

                // Autor + título + emoji
                Row(
                  children: [
                    _Avatar(
                      emoji: item.userProfileEmoji,
                      imageUrl: item.userProfileImage,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.userName ?? 'Alguém',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryBlue,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(item.emoji, style: const TextStyle(fontSize: 34)),
                  ],
                ),

                if (item.date != null && item.date!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.date!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Interações
                Row(
                  children: [
                    _InteractionBtn(
                      icon: AppIcons.favorite,
                      count: item.likesCount,
                      color: AppTheme.kidsPink,
                    ),
                    const SizedBox(width: 16),
                    _InteractionBtn(
                      icon: AppIcons.chat,
                      count: item.commentsCount,
                      color: AppTheme.primaryBlueMid,
                    ),
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

// ── Card de Doação ────────────────────────────────────────────────────────────

class _DonationCard extends StatelessWidget {
  final FeedItem item;
  const _DonationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final catLabel = DonationModel.categoryLabel(item.category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE4F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kidsPink.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(23),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          color: const Color(0xFFFFF0F7),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                  : null,
                              color: AppTheme.kidsPink,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFFFF0F7),
                    child: Center(
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 60),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha topo: tipo + categoria + local
                Row(
                  children: [
                    _TypeBadge(
                      label: 'Doação',
                      emoji: '🎁',
                      color: AppTheme.kidsPink,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.kidsPink.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        catLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.kidsPink,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (item.city != null)
                      _LocationBadge(city: item.city!, state: item.state),
                  ],
                ),

                const SizedBox(height: 14),

                // Emoji + título + descrição
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.kidsPink, Color(0xFFFF8FB3)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.kidsPink.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryBlue,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.description != null &&
                              item.description!.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              item.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.85,
                                ),
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

                const SizedBox(height: 14),

                // Badge disponível + botão interesse
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.kidsGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: AppTheme.kidsGreenDeep,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Disponível',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.kidsGreenDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.kidsPink, Color(0xFFFF8FB3)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.kidsPink.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Tenho interesse',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
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

// ── Widgets auxiliares dos cards ──────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  const _TypeBadge({
    required this.label,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildChip extends StatelessWidget {
  final String emoji;
  final String name;
  const _ChildChip({required this.emoji, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.childCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.childCardAccent.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.childCardAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationBadge extends StatelessWidget {
  final String city;
  final String? state;
  const _LocationBadge({required this.city, this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on_rounded,
          size: 12,
          color: AppTheme.textSecondary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 2),
        Text(
          state != null ? '$city, $state' : city,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? emoji;
  final String? imageUrl;
  const _Avatar({this.emoji, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.kidsPink, AppTheme.kidsPinkDeep],
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    emoji ?? '👤',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              )
            : Center(
                child: Text(
                  emoji ?? '👤',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
      ),
    );
  }
}

class _InteractionBtn extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  const _InteractionBtn({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 5),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.kidsPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.kidsPurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.kidsPurple,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: AppTheme.kidsPurple,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FILTER SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _FilterSheet extends StatefulWidget {
  final FeedController controller;
  const _FilterSheet({required this.controller});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late FeedItemType? _type;
  late IbgeEstado? _selectedEstado;
  late String? _selectedCity;

  @override
  void initState() {
    super.initState();
    final f = widget.controller.filter;
    _type = f.type;
    _selectedCity = f.city;

    // Restaura estado selecionado anteriormente
    final sigla = f.stateCode;
    _selectedEstado = sigla != null
        ? widget.controller.estados.where((e) => e.sigla == sigla).firstOrNull
        : null;

    // Se já havia estado selecionado e cidades ainda não carregadas, carrega
    if (_selectedEstado != null && widget.controller.cidades.isEmpty) {
      widget.controller.fetchCidadesByEstado(_selectedEstado!.sigla);
    }
  }

  InputDecoration _dropdownDecoration() => InputDecoration(
        filled: true,
        fillColor: AppTheme.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppTheme.kidsPurple.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppTheme.kidsPurple.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.kidsPurple, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Handle ──────────────────────────────────────────
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Filtrar feed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Tipo ────────────────────────────────────────────
                const Text(
                  'Tipo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _TypeChip(
                      label: 'Tudo',
                      emoji: '✨',
                      selected: _type == null,
                      onTap: () => setState(() => _type = null),
                    ),
                    const SizedBox(width: 6),
                    _TypeChip(
                      label: 'Sonhos',
                      emoji: '💭',
                      selected: _type == FeedItemType.dream,
                      onTap: () => setState(
                        () => _type = _type == FeedItemType.dream
                            ? null
                            : FeedItemType.dream,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _TypeChip(
                      label: 'Doações',
                      emoji: '🎁',
                      selected: _type == FeedItemType.donation,
                      onTap: () => setState(
                        () => _type = _type == FeedItemType.donation
                            ? null
                            : FeedItemType.donation,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Estado (IBGE) ────────────────────────────────────
                Row(
                  children: [
                    const Text(
                      'Estado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (ctrl.loadingEstados) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppTheme.kidsPurple,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                if (ctrl.loadingEstados)
                  // Skeleton enquanto carrega
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.kidsPurple.withValues(alpha: 0.3),
                      ),
                    ),
                  )
                else if (ctrl.estados.isEmpty)
                  GestureDetector(
                    onTap: ctrl.init,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.errorRed.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 16,
                              color: AppTheme.errorRed.withValues(alpha: 0.7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ctrl.ibgeError ?? 'Sem estados disponíveis.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.errorRed.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            'Tentar novamente',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.errorRed.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<IbgeEstado>(
                    value: _selectedEstado,
                    isExpanded: true,
                    hint: const Text('Selecione um estado',
                        style: TextStyle(fontSize: 13)),
                    decoration: _dropdownDecoration(),
                    menuMaxHeight: 320,
                    items: [
                      const DropdownMenuItem<IbgeEstado>(
                        value: null,
                        child: Text('Todos os estados',
                            style: TextStyle(fontSize: 13)),
                      ),
                      ...ctrl.estados.map(
                        (e) => DropdownMenuItem<IbgeEstado>(
                          value: e,
                          child: Text(
                            '${e.sigla} — ${e.nome}',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (estado) {
                      setState(() {
                        _selectedEstado = estado;
                        _selectedCity = null;
                      });
                      if (estado != null) {
                        ctrl.fetchCidadesByEstado(estado.sigla);
                      } else {
                        ctrl.clearCidades();
                      }
                    },
                  ),

                // ── Cidade (IBGE) ────────────────────────────────────
                if (_selectedEstado != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Cidade',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (ctrl.loadingCidades) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppTheme.kidsPurple,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (ctrl.loadingCidades)
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.kidsPurple.withValues(alpha: 0.3),
                        ),
                      ),
                    )
                  else if (ctrl.cidades.isEmpty)
                    Text(
                      'Nenhuma cidade encontrada.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade400),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      isExpanded: true,
                      hint: const Text('Selecione uma cidade',
                          style: TextStyle(fontSize: 13)),
                      decoration: _dropdownDecoration(),
                      menuMaxHeight: 320,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todas as cidades',
                              style: TextStyle(fontSize: 13)),
                        ),
                        ...ctrl.cidades.map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (city) =>
                          setState(() => _selectedCity = city),
                    ),
                ],

                const SizedBox(height: 28),

                // ── Botão aplicar ────────────────────────────────────
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    ctrl.applyFilter(
                      FeedFilter(
                        type: _type,
                        stateCode: _selectedEstado?.sigla,
                        stateName: _selectedEstado?.nome,
                        city: _selectedCity,
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.kidsPurple, Color(0xFFBB86FC)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kidsPurple.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Aplicar filtros',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppTheme.kidsPurple, Color(0xFFBB86FC)],
                )
              : null,
          color: selected ? null : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppTheme.kidsPurple.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.kidsPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
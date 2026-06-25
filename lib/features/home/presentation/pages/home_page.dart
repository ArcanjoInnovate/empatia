// lib/features/home/presentation/pages/home_page.dart
//
// Home — hierarquia: Hero Header → Ranking → Filtros → Feed
// ─────────────────────────────────────────────────────────────

import 'package:empatia/core/data/models/user_model.dart';
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
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════

abstract final class _H {
  static const navy    = Color(0xFF0F1F3D);
  static const blue    = Color(0xFF1E3A8A);
  static const blueMid = Color(0xFF2563EB);
  static const purple  = Color(0xFF7C3AED);
  static const purpleL = Color(0xFFA78BFA);
  static const white   = Colors.white;
  static const gold    = Color(0xFFFFD700);
}

// ═══════════════════════════════════════════════════════════════
// HOME PAGE
// ═══════════════════════════════════════════════════════════════

class HomePage extends StatefulWidget {
  final UserModel user;
  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FeedController _feed;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _feed = FeedController(
      FeedRepository(),
      currentUserId: widget.user.id ?? '',
    )..init();
    _feed.addListener(() { if (mounted) setState(() {}); });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300 &&
        _feed.hasMore &&
        !_feed.isLoadingMore) {
      _feed.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _feed.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        body: RefreshIndicator(
          onRefresh: _feed.refresh,
          color: _H.purple,
          displacement: 20,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // 1 ── HERO HEADER
              SliverToBoxAdapter(
                child: _HeroHeader(
                  user: widget.user,
                  onNotifications: () {/* TODO */},
                  onProfile: () {/* TODO */},
                ),
              ),

              // 2 ── RANKING SEMANAL
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: const WeeklyRankingWidget(),
                ),
              ),

              // 3 ── FILTROS + TÍTULO DA SEÇÃO
              SliverToBoxAdapter(child: _buildFilterSection()),

              // 4 ── FEED
              _buildFeedSliver(),

              // Indicador de carregamento de mais
              SliverToBoxAdapter(child: _buildLoadMore()),

              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // SEÇÃO DE FILTROS
  // ────────────────────────────────────────────────────────────

  Widget _buildFilterSection() {
    final hasGeo = _feed.filter.stateCode != null || _feed.filter.city != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da seção
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Explorar Comunidade',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _H.navy,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Sonhos e doações perto de você',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _H.navy.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botão de filtro geográfico
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: hasGeo
                          ? const LinearGradient(
                              colors: [_H.purple, _H.purpleL])
                          : null,
                      color: hasGeo ? null : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: hasGeo
                            ? Colors.transparent
                            : _H.purple.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _H.purple.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded,
                            size: 15,
                            color: hasGeo ? Colors.white : _H.purple),
                        const SizedBox(width: 5),
                        Text(
                          hasGeo ? 'Filtros ativos' : 'Filtrar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: hasGeo ? Colors.white : _H.purple,
                          ),
                        ),
                        if (hasGeo) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _feed.clearFilters,
                            child: const Icon(Icons.close_rounded,
                                size: 13, color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Chips de tipo (scroll horizontal)
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
                final isSelected = _feed.filter.type == chipType;
                return FilterChip(
                  emoji: chip['emoji'] as String,
                  label: chip['label'] as String,
                  selected: isSelected,
                  onTap: () =>
                      _feed.applyFilter(_feed.filter.copyWith(type: chipType)),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // FEED SLIVER
  // ────────────────────────────────────────────────────────────

  Widget _buildFeedSliver() {
    if (_feed.status == FeedStatus.loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(
            child: CircularProgressIndicator(
              color: _H.purple, strokeWidth: 2),
          ),
        ),
      );
    }

    if (_feed.status == FeedStatus.error) {
      return SliverToBoxAdapter(child: _ErrorState(
        message: _feed.error,
        onRetry: _feed.refresh,
      ));
    }

    if (_feed.items.isEmpty) {
      return SliverToBoxAdapter(child: _EmptyState(
        hasFilter: _feed.filter.hasAny,
        onClear: _feed.clearFilters,
      ));
    }

    // Insere InsightBlock a cada 5 cards
    const interval = 5;
    final count = _feed.items.length;
    final blocks = count ~/ interval;
    final total = count + blocks;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          const blockSize = interval + 1;
          final posInBlock = index % blockSize;
          final block = index ~/ blockSize;

          if (posInBlock == interval) {
            return InsightBlock(
                data: kInsights[block % kInsights.length]);
          }

          final feedIndex = block * interval + posInBlock;
          if (feedIndex >= count) return const SizedBox.shrink();
          return FeedCard(item: _feed.items[feedIndex]);
        },
        childCount: total,
      ),
    );
  }

  Widget _buildLoadMore() {
    if (!_feed.isLoadingMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: CircularProgressIndicator(
            color: _H.purple, strokeWidth: 2),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // FILTER SHEET
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

// ═══════════════════════════════════════════════════════════════
// HERO HEADER
// ═══════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const _HeroHeader({
    required this.user,
    required this.onNotifications,
    required this.onProfile,
  });

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String get _greetEmoji {
    final h = DateTime.now().hour;
    if (h < 12) return '🌅';
    if (h < 18) return '☀️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = user.name?.split(' ').first ?? 'Amigo';
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F1F3D),
            Color(0xFF1E3A8A),
            Color(0xFF3B1FA0),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // ── Decorações de fundo ──────────────────────────────
          Positioned(
            right: -30,
            top: topPad - 10,
            child: Text(
              '✨',
              style: TextStyle(
                fontSize: 110,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: 0,
            child: Text(
              '❤️',
              style: TextStyle(
                fontSize: 90,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Círculo decorativo
          Positioned(
            right: 60,
            bottom: 20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          // ── Conteúdo ──────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha de topo: nome do app + botões
                Row(
                  children: [
                    // Logo textual
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Text(
                        'EMPATIA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Botão notificações
                    _HeaderIconBtn(
                      icon: AppIcons.notificationsOutline,
                      onTap: onNotifications,
                    ),
                    const SizedBox(width: 10),
                    // Botão perfil
                    _HeaderIconBtn(
                      icon: AppIcons.person,
                      onTap: onProfile,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Linha do usuário: avatar + saudação
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    _UserAvatar(user: user),
                    const SizedBox(width: 14),
                    // Saudação + nome
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _greetEmoji,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _greeting,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.70),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            firstName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                      ],
                    ),

                const SizedBox(height: 20),

                // Linha de impacto + ranking
                Row(
                  children: [
                    // Impacto do mês
                    Expanded(
                      child: _StatPill(
                        emoji: '❤️',
                        text: 'Você ajudou 3 famílias este mês',
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Posição no ranking
                    _RankPill(position: 18),
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

// ── Avatar do usuário no header ──────────────────────────────

class _UserAvatar extends StatelessWidget {
  final UserModel user;
  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = user.profileImage != null &&
        user.profileImage!.isNotEmpty;
    final emoji = user.profileEmoji ?? '👤';

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                user.profileImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _EmojiAvatar(emoji: emoji),
              )
            : _EmojiAvatar(emoji: emoji),
      ),
    );
  }
}

class _EmojiAvatar extends StatelessWidget {
  final String emoji;
  const _EmojiAvatar({required this.emoji});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white.withValues(alpha: 0.12),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 30)),
        ),
      );
}

// ── Botão ícone do header ─────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.20)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}

// ── Pill de impacto ───────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String emoji;
  final String text;
  const _StatPill({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.3,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
      );
}

// ── Pill de posição no ranking ────────────────────────────────

class _RankPill extends StatelessWidget {
  final int? position;
  const _RankPill({this.position});

  @override
  Widget build(BuildContext context) {
    if (position == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          '⭐ Sem posição',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.60),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.20),
            const Color(0xFFFFA500).withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            '#$position no ranking',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFD700),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClear;
  const _EmptyState({required this.hasFilter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text('🌟', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 14),
            Text(
              hasFilter
                  ? 'Nenhum resultado para esses filtros'
                  : 'Ainda não há publicações',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E3A5F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Tente ajustar ou limpar os filtros.'
                  : 'Seja o primeiro a compartilhar um sonho!',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (hasFilter) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                    ),
                    borderRadius: BorderRadius.circular(22),
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
}

// ═══════════════════════════════════════════════════════════════
// ERROR STATE
// ═══════════════════════════════════════════════════════════════

class _ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const _ErrorState({this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: AppTheme.errorRed.withValues(alpha: 0.12)),
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
                color: Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Tente novamente em instantes.',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(22),
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
}
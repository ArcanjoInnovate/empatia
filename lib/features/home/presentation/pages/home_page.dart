// lib/features/home/presentation/pages/home_page.dart

import 'dart:async';

import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_avatars.dart';
import 'package:empatia/core/widget/avatar_render.dart';
import 'package:empatia/core/theme/app_icons.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/home/controllers/feed_controller.dart';
import 'package:empatia/features/home/controllers/user_status_controller.dart';
import 'package:empatia/features/home/data/models/feed_item_.dart';
import 'package:empatia/features/home/data/repositories/feed_repository.dart';
import 'package:empatia/features/home/data/repositories/user_stats_repository.dart';
import 'package:empatia/features/home/presentation/constants/home_constants.dart';
import 'package:empatia/features/home/presentation/widgets/feeds_card.dart';
import 'package:empatia/features/home/presentation/widgets/filter_widgets.dart';
import 'package:empatia/features/notification/controller/notification_controller.dart';
import 'package:empatia/features/notification/presentation/page/notification_page.dart';
import 'package:empatia/features/profile/data/repository/profile_repository.dart';
import 'package:empatia/features/ranking/controller/ranking_controller.dart';
import 'package:empatia/features/ranking/presentation/widget/weekly_ranking_widget.dart';
import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  final UserModel user;
  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FeedController         _feed;
  late final UserStatsController    _userStats;
  late final RankingController      _ranking;
  late final NotificationController _notifications;
  final _scrollController = ScrollController();

  // Mantém o UserModel sempre atualizado via stream do Firebase
  late UserModel _currentUser;
  StreamSubscription<UserModel?>? _userSub;

  @override
  void initState() {
    super.initState();

    _currentUser = widget.user;

    _feed = FeedController(
      FeedRepository(),
      currentUserId: widget.user.id ?? '',
    )..init();
    _feed.addListener(() { if (mounted) setState(() {}); });

    _userStats = UserStatsController(widget.user.id ?? '')..load();
    _userStats.addListener(() { if (mounted) setState(() {}); });

    _ranking = RankingController()..load();
    _ranking.addListener(() { if (mounted) setState(() {}); });

    _notifications = NotificationController(uid: widget.user.id ?? '')..init();
    _notifications.addListener(() { if (mounted) setState(() {}); });

    _scrollController.addListener(_onScroll);

    // Assina o stream do perfil para refletir edições em tempo real
    _userSub = ProfileRepository().watchUser().listen((user) {
      if (mounted && user != null) setState(() => _currentUser = user);
    });
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300 &&
        _feed.hasMore &&
        !_feed.isLoadingMore) {
      _feed.loadMore();
    }
  }

  Future<void> _onRefresh() => Future.wait([
    _feed.refresh(),
    _userStats.refresh(),
    _ranking.load(),
  ]);

  @override
  void dispose() {
    _userSub?.cancel();
    _scrollController.dispose();
    _feed.dispose();
    _userStats.dispose();
    _ranking.dispose();
    _notifications.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.kidsPurple,
          displacement: 20,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _HeroHeader(
                  user: _currentUser,
                  stats: _userStats.stats,
                  statsLoading: _userStats.loading,
                  unreadNotifications: _notifications.unreadCount,
                  onNotifications: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsPage(
                          controller: _notifications,
                        ),
                      ),
                    );
                  },
                  onProfile: () {/* TODO */},
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: WeeklyRankingWidget(controller: _ranking),
                ),
              ),

              SliverToBoxAdapter(child: _buildFilterSection()),

              _buildFeedSliver(),

              SliverToBoxAdapter(child: _buildLoadMore()),

              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final hasGeo = _feed.filter.stateCode != null || _feed.filter.city != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                          color: AppTheme.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Sonhos e doações perto de você',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: hasGeo
                          ? const LinearGradient(colors: [
                              AppTheme.kidsPurple,
                              AppTheme.kidsPurpleLight,
                            ])
                          : null,
                      color: hasGeo ? null : AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: hasGeo
                            ? Colors.transparent
                            : AppTheme.kidsPurple.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kidsPurple.withValues(alpha: 0.12),
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
                          color: hasGeo ? Colors.white : AppTheme.kidsPurple,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hasGeo ? 'Filtros ativos' : 'Filtrar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: hasGeo ? Colors.white : AppTheme.kidsPurple,
                          ),
                        ),
                        if (hasGeo) ...[
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

          const SizedBox(height: 16),

          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: kFilterChips.length,
              itemBuilder: (context, i) {
                final chip     = kFilterChips[i];
                final chipType = chip['type'] as FeedItemType?;
                final isSelected = _feed.filter.type == chipType;
                return FilterChip(
                  emoji: chip['emoji'] as String,
                  label: chip['label'] as String,
                  selected: isSelected,
                  onTap: () => _feed.applyFilter(
                      _feed.filter.copyWith(type: chipType)),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFeedSliver() {
    if (_feed.status == FeedStatus.loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(
            child: CircularProgressIndicator(
              color: AppTheme.kidsPurple,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_feed.status == FeedStatus.error) {
      return SliverToBoxAdapter(
        child: _ErrorState(
          message: _feed.error,
          onRetry: _feed.refresh,
        ),
      );
    }

    if (_feed.items.isEmpty) {
      return SliverToBoxAdapter(
        child: _EmptyState(
          hasFilter: _feed.filter.hasAny,
          onClear: _feed.clearFilters,
        ),
      );
    }

    const interval = 5;
    final count  = _feed.items.length;
    final blocks = count ~/ interval;
    final total  = count + blocks;

    // UID do usuário logado — passado para cada FeedCard para exibir
    // o badge "Meu item" nos cards que pertencem a este usuário.
    final currentUserId = _currentUser.id ?? '';

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          const blockSize  = interval + 1;
          final posInBlock = index % blockSize;
          final block      = index ~/ blockSize;

          if (posInBlock == interval) {
            return InsightBlock(data: kInsights[block % kInsights.length]);
          }

          final feedIndex = block * interval + posInBlock;
          if (feedIndex >= count) return const SizedBox.shrink();

          // ✅ currentUserId passado aqui
          return FeedCard(
            item: _feed.items[feedIndex],
            currentUserId: currentUserId,
          );
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
          color: AppTheme.kidsPurple,
          strokeWidth: 2,
        ),
      ),
    );
  }

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
  final UserStats stats;
  final bool statsLoading;
  final int unreadNotifications;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const _HeroHeader({
    required this.user,
    required this.stats,
    required this.statsLoading,
    required this.unreadNotifications,
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
    final topPad    = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.profileHeaderGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: topPad - 10,
            child: Text(
              '✨',
              style: TextStyle(
                fontSize: 110,
                color: Colors.white.withValues(alpha: 0.06),
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
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: 20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20)),
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
                    _HeaderIconBtn(
                      icon: AppIcons.notificationsOutline,
                      badge: unreadNotifications,
                      onTap: onNotifications,
                    ),
                    
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _UserAvatar(user: user),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(_greetEmoji,
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 5),
                              Text(
                                _greeting,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.75),
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

                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        loading: statsLoading,
                        donatedThisMonth: stats.donatedThisMonth,
                        dreamsReceived: stats.dreamsReceived,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _RankPill(
                      position: stats.rankingPosition,
                      loading: statsLoading,
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

class _UserAvatar extends StatelessWidget {
  final UserModel user;
  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = user.profileImage != null && user.profileImage!.isNotEmpty;

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.40), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: Colors.white.withValues(alpha: 0.15),
          child: hasPhoto
              ? Image.network(
                  user.profileImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      AvatarRender(value: user.profileEmoji, size: 62),
                )
              : AvatarRender(value: user.profileEmoji, size: 62),
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            if (badge > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.kidsRed,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
}

class _StatPill extends StatelessWidget {
  final bool loading;
  final int donatedThisMonth;
  final int dreamsReceived;

  const _StatPill({
    required this.loading,
    required this.donatedThisMonth,
    required this.dreamsReceived,
  });

  String get _emoji {
    if (loading) return '⏳';
    if (donatedThisMonth > 0) return '❤️';
    if (dreamsReceived > 0)   return '✨';
    return '💜';
  }

  String get _text {
    if (loading) return 'Calculando impacto...';
    if (donatedThisMonth > 0) {
      final s = donatedThisMonth == 1 ? 'família' : 'famílias';
      return 'Você ajudou $donatedThisMonth $s este mês';
    }
    if (dreamsReceived > 0) {
      final s = dreamsReceived == 1 ? 'sonho realizado' : 'sonhos realizados';
      return '$dreamsReceived $s ✨';
    }
    return 'Comece a ajudar hoje!';
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _text,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.90),
                  height: 1.3,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
      );
}

class _RankPill extends StatelessWidget {
  final int? position;
  final bool loading;
  const _RankPill({this.position, this.loading = false});

  @override
  Widget build(BuildContext context) {
    if (loading || position == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Text(
          loading ? '🏆 ...' : '⭐ Sem posição',
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
            AppTheme.kidsYellowGold.withValues(alpha: 0.25),
            AppTheme.accentOrange.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: AppTheme.kidsYellowGold.withValues(alpha: 0.45)),
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
              color: AppTheme.kidsYellowGold,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY / ERROR STATE
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
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kidsPurple.withValues(alpha: 0.07),
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
                color: AppTheme.textDark,
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
                      colors: [AppTheme.kidsPurple, AppTheme.kidsPurpleLight],
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
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.12)),
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
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Tente novamente em instantes.',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.kidsPink, AppTheme.kidsPurple],
                  ),
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
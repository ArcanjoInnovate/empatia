// lib/features/notifications/presentation/pages/notifications_page.dart

import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/notification/controller/notification_controller.dart';
import 'package:empatia/features/notification/data/model/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  final NotificationController controller;

  const NotificationsPage({Key? key, required this.controller})
      : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.rankingBackground,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── AppBar ──────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 110,
              backgroundColor: AppTheme.kidsPink,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (widget.controller.unreadCount > 0)
                  TextButton(
                    onPressed: widget.controller.markAllAsRead,
                    child: const Text(
                      'Marcar todas lidas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.profileHeaderGradient,
                  ),
                  child: const SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 48, 20, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔔 Notificações',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Corpo ────────────────────────────────────────────
            if (widget.controller.loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.rankingAccent,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (widget.controller.all.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final n = widget.controller.all[i];
                      return _NotificationTile(
                        notification: n,
                        onTap: () => _onTap(n),
                      );
                    },
                    childCount: widget.controller.all.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onTap(AppNotification n) {
    widget.controller.markAsRead(n);
    // Navegar para o chat se houver chatId
    if (n.chatId != null) {
      // TODO: Navigator.push para ChatPage com chatId
    }
  }
}

// ── Tile individual ───────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  Color _accentColor() {
    switch (notification.type) {
      case NotificationType.firstMessage:  return AppTheme.kidsPink;
      case NotificationType.message:       return AppTheme.kidsPurple;
      case NotificationType.donationDone:  return AppTheme.kidsGreen;
      case NotificationType.rankingReset:  return AppTheme.kidsYellowGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.read;
    final accent   = _accentColor();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isUnread
              ? accent.withValues(alpha: 0.06)
              : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnread
                ? accent.withValues(alpha: 0.30)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    notification.type.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary
                            .withValues(alpha: 0.80),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatTime(notification.dateTime),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary
                            .withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return 'agora mesmo';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours   < 24) return 'há ${diff.inHours}h';
    if (diff.inDays    == 1) return 'ontem, ${DateFormat('HH:mm').format(dt)}';
    if (diff.inDays    < 7)  return DateFormat('EEEE', 'pt_BR').format(dt);
    return DateFormat('dd/MM/yyyy').format(dt);
  }
}

// ── Estado vazio ──────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔔', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma notificação ainda',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quando alguém se interessar por\numa das suas publicações, você verá aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary.withValues(alpha: 0.75),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
}
// lib/features/home/presentation/widgets/feed_cards.dart
//
// Cards do feed: sonhos, doações, blocos de destaque (Insight)
// e todos os widgets auxiliares (badges, avatar, interações...).
// ─────────────────────────────────────────────────────────────

import 'package:empatia/core/theme/app_icons.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:empatia/features/dream/presentation/pages/full_screen_image_page.dart';
import 'package:empatia/features/home/data/models/feed_item_.dart';
import 'package:empatia/features/home/presentation/constants/home_constants.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// FEED CARD — wrapper que decide qual card renderizar
// ═══════════════════════════════════════════════════════════════

class FeedCard extends StatelessWidget {
  final FeedItem item;
  const FeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return item.type == FeedItemType.dream
        ? DreamCard(item: item)
        : DonationCard(item: item);
  }
}

// ═══════════════════════════════════════════════════════════════
// CARD DE SONHO
// ═══════════════════════════════════════════════════════════════

class DreamCard extends StatelessWidget {
  final FeedItem item;
  const DreamCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kPurpleSoft, width: 1.5),
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
          // ── Imagem ────────────────────────────────────────────
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(23)),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) =>
                          progress == null
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
                // ── Badges: tipo + filho + local ──────────────
                Row(
                  children: [
                    FeedTypeBadge(
                      label: 'Sonho',
                      emoji: '💭',
                      color: AppTheme.kidsPurple,
                    ),
                    const SizedBox(width: 8),
                    if (item.childName != null)
                      ChildChip(
                        emoji: item.childEmoji ?? '👶',
                        name: item.childName!,
                      ),
                    const Spacer(),
                    if (item.city != null)
                      LocationBadge(city: item.city!, state: item.state),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Autor + título ────────────────────────────
                Row(
                  children: [
                    UserAvatar(
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

                // ── Interações ────────────────────────────────
                Row(
                  children: [
                    InteractionBtn(
                      icon: AppIcons.favorite,
                      count: item.likesCount,
                      color: AppTheme.kidsPink,
                    ),
                    const SizedBox(width: 16),
                    InteractionBtn(
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

// ═══════════════════════════════════════════════════════════════
// CARD DE DOAÇÃO
// ═══════════════════════════════════════════════════════════════

class DonationCard extends StatelessWidget {
  final FeedItem item;
  const DonationCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final catLabel = DonationModel.categoryLabel(item.category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kPinkSoft, width: 1.5),
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
          // ── Imagem ────────────────────────────────────────────
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(23)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) =>
                      progress == null
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
                // ── Linha topo ────────────────────────────────
                Row(
                  children: [
                    FeedTypeBadge(
                      label: 'Doação',
                      emoji: '🎁',
                      color: AppTheme.kidsPink,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                      LocationBadge(city: item.city!, state: item.state),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Emoji + título + descrição ─────────────────
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
                                color: AppTheme.textSecondary
                                    .withValues(alpha: 0.85),
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

                // ── Status + botão interesse ───────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.kidsGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle,
                              size: 7, color: AppTheme.kidsGreenDeep),
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
                    GestureDetector(
                      onTap: () {/* TODO: interesse */},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.kidsPink, Color(0xFFFF8FB3)],
                          ),
                          borderRadius: BorderRadius.circular(22),
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

// ═══════════════════════════════════════════════════════════════
// BLOCO DE DESTAQUE (Insight Block)
// ═══════════════════════════════════════════════════════════════

class InsightBlock extends StatelessWidget {
  final Map<String, dynamic> data;
  const InsightBlock({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = data['gradient'] as List<Color>;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                data['emoji'] as String,
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
                  data['text'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['sub'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withValues(alpha: 0.7),
            size: 14,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════

class FeedTypeBadge extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  const FeedTypeBadge({
    super.key,
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
                fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class ChildChip extends StatelessWidget {
  final String emoji;
  final String name;
  const ChildChip({super.key, required this.emoji, required this.name});

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

class LocationBadge extends StatelessWidget {
  final String city;
  final String? state;
  const LocationBadge({super.key, required this.city, this.state});

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

class UserAvatar extends StatelessWidget {
  final String? emoji;
  final String? imageUrl;
  const UserAvatar({super.key, this.emoji, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.network(
          imageUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emojiAvatar(),
        ),
      );
    }
    return _emojiAvatar();
  }

  Widget _emojiAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.kidsPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Text(emoji ?? '👤', style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

class InteractionBtn extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  const InteractionBtn({
    super.key,
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 5),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const ActiveFilterChip({
    super.key,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.kidsPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppTheme.kidsPurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.kidsPurple,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 12, color: AppTheme.kidsPurple),
          ),
        ],
      ),
    );
  }
}
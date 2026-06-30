// lib/features/home/presentation/widgets/feeds_card.dart
//
// Cards do feed — DreamCard, DonationCard, InsightBlock e auxiliares.
// ─────────────────────────────────────────────────────────────────────

import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/widget/verification_block_dialog.dart';
import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:empatia/features/donation/presentation/pages/donation_detail_page.dart';
import 'package:empatia/features/dream/presentation/pages/dream_detail_page.dart';
import 'package:empatia/features/dream/presentation/pages/full_screen_image_page.dart';
import 'package:empatia/features/dream/presentation/pages/verification_block_dialog.dart';
import 'package:empatia/features/home/data/models/feed_item_.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ═══════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════

abstract final class _K {
  // Dream
  static const purple      = Color(0xFF7C3AED);
  static const purpleDeep  = Color(0xFF5B21B6);
  static const purpleLight = Color(0xFFF5F0FF);
  static const purpleSoft  = Color(0xFFEDE9FE);

  // Donation
  static const pink      = Color(0xFFFF5C8D);
  static const pinkDeep  = Color(0xFFE0457A);
  static const pinkLight = Color(0xFFFFF0F6);
  static const pinkSoft  = Color(0xFFFFE4F0);

  // Shared
  static const navy    = Color(0xFF1E3A5F);
  static const body    = Color(0xFF374151);
  static const muted   = Color(0xFF6B7280);
  static const subtle  = Color(0xFF9CA3AF);
  static const white   = Colors.white;
  static const surface = Color(0xFFF9FAFB);
  static const green   = Color(0xFF16A34A);
  static const greenBg = Color(0xFFDCFCE7);
  static const amber   = Color(0xFFF59E0B);

  // "Meu item" badge
  static const myItemBg     = Color(0xFF0EA5E9); // azul-céu
  static const myItemBorder = Color(0xFF0284C7);

  // Radius
  static const r4  = 4.0;
  static const r8  = 8.0;
  static const r12 = 12.0;
  static const r16 = 16.0;
  static const r20 = 20.0;
  static const r28 = 28.0;
  static const r99 = 99.0;
}

// ═══════════════════════════════════════════════════════════════
// BADGE "MEU ITEM"
// Renderizado no topo-direito do hero quando o item pertence
// ao usuário logado.
// ═══════════════════════════════════════════════════════════════

class _MyItemBadge extends StatelessWidget {
  const _MyItemBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: _K.myItemBg,
          borderRadius: BorderRadius.circular(_K.r99),
          border: Border.all(color: _K.myItemBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: _K.myItemBg.withValues(alpha: 0.40),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✏️', style: TextStyle(fontSize: 10)),
            SizedBox(width: 4),
            Text(
              'Meu item',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// FEED CARD — router
// ═══════════════════════════════════════════════════════════════

class FeedCard extends StatelessWidget {
  final FeedItem item;

  /// UID do usuário logado — usado para identificar itens próprios.
  final String? currentUserId;

  const FeedCard({
    super.key,
    required this.item,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return item.type == FeedItemType.dream
        ? DreamCard(item: item, currentUserId: currentUserId)
        : DonationCard(item: item, currentUserId: currentUserId);
  }
}

// ═══════════════════════════════════════════════════════════════
// DREAM CARD
// ═══════════════════════════════════════════════════════════════

class DreamCard extends StatefulWidget {
  final FeedItem item;

  /// UID do usuário logado. Quando igual a [item.userId], exibe o badge
  /// "Meu item" no canto superior direito do hero.
  final String? currentUserId;

  const DreamCard({super.key, required this.item, this.currentUserId});

  @override
  State<DreamCard> createState() => _DreamCardState();
}

class _DreamCardState extends State<DreamCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.reverse();
  void _onTapUp(TapUpDetails _) {
    _ctrl.forward();
    HapticFeedback.lightImpact();
    final heroTag = 'feed_dream_${widget.item.id}';
    pushIfVerified(
      context,
      currentUser: context.read<UserModel?>(),
      feature: 'ver os detalhes deste sonho',
      route: DreamDetailPage.route(
        result: widget.item.toSearchResult(),
        heroTag: heroTag,
      ),
    );
  }
  void _onTapCancel() => _ctrl.forward();

  static const _copies = [
    '✨ Um sonho esperando acontecer',
    '💛 Cada apoio transforma uma vida',
    '🌟 Uma criança real por trás desta história',
    '❤️ Conheça esta família',
    '🎯 Seu gesto pode mudar tudo',
  ];
  String _microcopy(String id) {
    final idx = (id.codeUnits.fold(0, (a, b) => a + b) + 2) % _copies.length;
    return _copies[idx];
  }

  bool get _isMyItem =>
      widget.currentUserId != null &&
      widget.currentUserId!.isNotEmpty &&
      widget.item.userId == widget.currentUserId;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final heroTag = 'feed_dream_${item.id}';
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final hasStory = item.date != null && item.date!.isNotEmpty;
    final hasChild = item.childName != null && item.childName!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Container(
            decoration: BoxDecoration(
              color: _K.white,
              borderRadius: BorderRadius.circular(_K.r28),
              border: Border.all(color: _K.purpleSoft, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _K.purple.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: _K.purple.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DreamHero(
                  item: item,
                  heroTag: heroTag,
                  hasImage: hasImage,
                  isMyItem: _isMyItem,
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _DreamBadge(),
                          const SizedBox(width: 8),
                          if (hasChild)
                            _ChildPill(
                              emoji: item.childEmoji ?? '👶',
                              name: item.childName!,
                            ),
                          const Spacer(),
                          if (item.city != null)
                            _LocationPill(
                              city: item.city!,
                              state: item.state,
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _K.navy,
                          height: 1.25,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (hasStory) ...[
                        const SizedBox(height: 12),
                        _FamilyStorySnippet(story: item.date!),
                      ],

                      const SizedBox(height: 16),

                      _ImpactBlock(
                        copy: _microcopy(item.id),
                        color: _K.purple,
                        bg: _K.purpleLight,
                      ),

                      const SizedBox(height: 16),

                      _DreamFooter(item: item),

                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero visual do DreamCard ──────────────────────────────────

class _DreamHero extends StatelessWidget {
  final FeedItem item;
  final String heroTag;
  final bool hasImage;

  /// Quando true, exibe o badge "Meu item" no topo-direito.
  final bool isMyItem;

  const _DreamHero({
    required this.item,
    required this.heroTag,
    required this.hasImage,
    required this.isMyItem,
  });

  static const _grads = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFF7C3AED), Color(0xFF4F46E5)],
    [Color(0xFF2563EB), Color(0xFF1E3A5F)],
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  ];

  List<Color> _gradient(String id) {
    final idx = id.codeUnits.fold(0, (a, b) => a + b) % _grads.length;
    return _grads[idx];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradient(item.id);

    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Hero(
              tag: heroTag,
              child: Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : _GradientPlaceholder(
                        colors: colors, emoji: item.emoji),
                errorBuilder: (_, __, ___) =>
                    _GradientPlaceholder(colors: colors, emoji: item.emoji),
              ),
            )
          else
            _GradientPlaceholder(colors: colors, emoji: item.emoji),

          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.60),
                ],
              ),
            ),
          ),

          if (item.childName != null && item.childName!.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                children: [
                  Text(
                    item.childEmoji ?? '⭐',
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.childName!,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Badge "Meu item" ────────────────────────────────────
          if (isMyItem)
            const Positioned(
              top: 12,
              right: 12,
              child: _MyItemBadge(),
            ),

          if (hasImage)
            Positioned(
              top: 12,
              // Empurra o botão de fullscreen para a esquerda quando
              // o badge "Meu item" também está visível.
              right: isMyItem ? 88 : 12,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  FullscreenImagePage.route(
                    imageUrl: item.imageUrl!,
                    heroTag: 'dream_fullscreen_${item.id}',
                    title: item.title,
                  ),
                ),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  final List<Color> colors;
  final String emoji;
  const _GradientPlaceholder({required this.colors, required this.emoji});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Center(
          child: Text(emoji,
              style: TextStyle(
                fontSize: 64,
                shadows: [
                  Shadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12),
                ],
              )),
        ),
      );
}

// ── Relato da família ─────────────────────────────────────────

class _FamilyStorySnippet extends StatelessWidget {
  final String story;
  const _FamilyStorySnippet({required this.story});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(_K.r12),
        border: Border.all(color: const Color(0xFFF0E6D3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"',
            style: TextStyle(
              fontSize: 36,
              height: 0.75,
              fontWeight: FontWeight.w900,
              color: _K.purple.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              story,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                color: _K.body,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bloco de impacto emocional ────────────────────────────────

class _ImpactBlock extends StatelessWidget {
  final String copy;
  final Color color;
  final Color bg;
  const _ImpactBlock({
    required this.copy,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_K.r12),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              copy,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.35,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 11,
            color: color.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

// ── Rodapé do DreamCard ───────────────────────────────────────

class _DreamFooter extends StatelessWidget {
  final FeedItem item;
  const _DreamFooter({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AuthorAvatar(
          emoji: item.userProfileEmoji,
          imageUrl: item.userProfileImage,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.userName ?? 'Família',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _K.navy,
                ),
              ),
              if (item.likesCount > 0 || item.commentsCount > 0)
                Text(
                  _socialText(item.likesCount, item.commentsCount),
                  style: const TextStyle(
                    fontSize: 11,
                    color: _K.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            pushIfVerified(
              context,
              currentUser: context.read<UserModel?>(),
              feature: 'ver os detalhes deste sonho',
              route: DreamDetailPage.route(
                result: item.toSearchResult(),
                heroTag: 'feed_dream_${item.id}',
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
              ),
              borderRadius: BorderRadius.circular(_K.r99),
              boxShadow: [
                BoxShadow(
                  color: _K.purple.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Ver história',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _socialText(int likes, int comments) {
    final parts = <String>[];
    if (likes > 0) parts.add('❤️ $likes ${likes == 1 ? "pessoa sensibilizada" : "pessoas sensibilizadas"}');
    if (comments > 0) parts.add('💬 $comments ${comments == 1 ? "interesse" : "interesses"}');
    return parts.join('  ·  ');
  }
}

// ═══════════════════════════════════════════════════════════════
// DONATION CARD
// ═══════════════════════════════════════════════════════════════

class DonationCard extends StatefulWidget {
  final FeedItem item;

  /// UID do usuário logado. Quando igual a [item.userId], exibe o badge
  /// "Meu item" no canto superior direito do hero.
  final String? currentUserId;

  const DonationCard({super.key, required this.item, this.currentUserId});

  @override
  State<DonationCard> createState() => _DonationCardState();
}

class _DonationCardState extends State<DonationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.reverse();
  void _onTapUp(TapUpDetails _) {
    _ctrl.forward();
    HapticFeedback.lightImpact();
    final heroTag = 'feed_donation_${widget.item.id}';
    pushIfVerified(
      context,
      currentUser: context.read<UserModel?>(),
      feature: 'ver os detalhes desta doação',
      route: DonationDetailPage.route(
        result: widget.item.toSearchResult(),
        heroTag: heroTag,
      ),
    );
  }
  void _onTapCancel() => _ctrl.forward();

  static const _valueCopies = [
    '♻️ Este item pode ganhar uma nova história',
    '💝 Sua retirada ajuda outra família agora',
    '🌎 Reutilizar também é um ato de empatia',
    '✨ Um gesto simples que transforma vidas',
    '🤝 Compartilhar é a maior forma de amor',
  ];

  String _valueCopy(String id) {
    final idx = (id.codeUnits.fold(0, (a, b) => a + b) + 1) % _valueCopies.length;
    return _valueCopies[idx];
  }

  bool get _isMyItem =>
      widget.currentUserId != null &&
      widget.currentUserId!.isNotEmpty &&
      widget.item.userId == widget.currentUserId;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final heroTag = 'feed_donation_${item.id}';
    final catLabel = DonationModel.categoryLabel(item.category);
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final hasDesc = item.description != null && item.description!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Container(
            decoration: BoxDecoration(
              color: _K.white,
              borderRadius: BorderRadius.circular(_K.r28),
              border: Border.all(color: _K.pinkSoft, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _K.pink.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: _K.pink.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DonationHero(
                  item: item,
                  heroTag: heroTag,
                  hasImage: hasImage,
                  catLabel: catLabel,
                  isMyItem: _isMyItem,
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _CatPill(label: catLabel),
                          const Spacer(),
                          if (item.city != null)
                            _LocationPill(
                              city: item.city!,
                              state: item.state,
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _K.navy,
                          height: 1.25,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (hasDesc) ...[
                        const SizedBox(height: 10),
                        Text(
                          item.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: _K.body,
                            height: 1.55,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      _ImpactBlock(
                        copy: _valueCopy(item.id),
                        color: _K.pink,
                        bg: _K.pinkLight,
                      ),

                      const SizedBox(height: 16),

                      _DonationFooter(item: item),

                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero do DonationCard ──────────────────────────────────────

class _DonationHero extends StatelessWidget {
  final FeedItem item;
  final String heroTag;
  final bool hasImage;
  final String catLabel;

  /// Quando true, exibe o badge "Meu item" no topo-direito.
  final bool isMyItem;

  const _DonationHero({
    required this.item,
    required this.heroTag,
    required this.hasImage,
    required this.catLabel,
    required this.isMyItem,
  });

  bool get _isUnavailable =>
      item.status == 'donated' ||
      item.status == 'fulfilled' ||
      item.status == 'reserved';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Hero(
              tag: heroTag,
              child: Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : _DonationPlaceholder(emoji: item.emoji),
                errorBuilder: (_, __, ___) =>
                    _DonationPlaceholder(emoji: item.emoji),
              ),
            )
          else
            _DonationPlaceholder(emoji: item.emoji),

          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.04),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Badge de status no topo-esquerdo
          Positioned(
            top: 12,
            left: 12,
            child: _StatusBadge(status: item.status),
          ),

          // Badge "indisponível" ou "Meu item" no topo-direito.
          // Prioridade: "Meu item" > status de indisponibilidade.
          Positioned(
            top: 12,
            right: 12,
            child: isMyItem
                ? const _MyItemBadge()
                : _isUnavailable
                    ? _UnavailableBadge(status: item.status)
                    : const SizedBox.shrink(),
          ),

          Positioned(
            right: 16,
            bottom: 12,
            child: Text(item.emoji,
                style: const TextStyle(
                    fontSize: 42,
                    shadows: [
                      Shadow(color: Colors.black38, blurRadius: 8)
                    ])),
          ),
        ],
      ),
    );
  }
}

class _DonationPlaceholder extends StatelessWidget {
  final String emoji;
  const _DonationPlaceholder({required this.emoji});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF0F6), Color(0xFFEFF6FF)],
          ),
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 64)),
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  final String? status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final available = status == null || status!.isEmpty || status == 'available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: available
            ? const Color(0xFF2563EB).withValues(alpha: 0.88)
            : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(_K.r99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            available ? '🎁' : '📦',
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(width: 5),
          Text(
            available ? 'Disponível' : 'Doação',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableBadge extends StatelessWidget {
  final String? status;
  const _UnavailableBadge({required this.status});

  Color get _color {
    if (status == 'reserved') return _K.amber;
    return _K.green;
  }

  String get _label {
    switch (status) {
      case 'reserved':  return '✨ Reservado';
      case 'donated':   return '🎉 Doado';
      case 'fulfilled': return '❤️ Realizado';
      default:          return status ?? '';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(_K.r99),
        ),
        child: Text(
          _label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}

// ── Rodapé do DonationCard ────────────────────────────────────

class _DonationFooter extends StatelessWidget {
  final FeedItem item;
  const _DonationFooter({required this.item});

  bool get _available =>
      item.status == null ||
      item.status!.isEmpty ||
      item.status == 'available';

  @override
  Widget build(BuildContext context) {
    final hasAuthor = item.userName != null && item.userName!.isNotEmpty;

    return Row(
      children: [
        _AuthorAvatar(
          emoji: item.userProfileEmoji,
          imageUrl: item.userProfileImage,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasAuthor ? item.userName! : 'Doador',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _K.navy,
                ),
              ),
              const SizedBox(height: 3),
              _InlineStatusPill(available: _available),
            ],
          ),
        ),

        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            pushIfVerified(
              context,
              currentUser: context.read<UserModel?>(),
              feature: 'ver os detalhes desta doação',
              route: DonationDetailPage.route(
                result: item.toSearchResult(),
                heroTag: 'feed_donation_${item.id}',
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5C8D), Color(0xFFE0457A)],
              ),
              borderRadius: BorderRadius.circular(_K.r99),
              boxShadow: [
                BoxShadow(
                  color: _K.pink.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('❤️', style: TextStyle(fontSize: 13)),
                SizedBox(width: 5),
                Text(
                  'Tenho Interesse',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineStatusPill extends StatelessWidget {
  final bool available;
  const _InlineStatusPill({required this.available});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 7,
            color: available ? _K.green : _K.amber,
          ),
          const SizedBox(width: 4),
          Text(
            available ? 'Disponível' : 'Reservado',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: available ? _K.green : _K.amber,
            ),
          ),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════
// INSIGHT BLOCK
// ═══════════════════════════════════════════════════════════════

class InsightBlock extends StatelessWidget {
  final Map<String, dynamic> data;
  const InsightBlock({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = data['gradient'] as List<Color>;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_K.r28),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
              borderRadius: BorderRadius.circular(_K.r16),
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
                    color: Colors.white.withValues(alpha: 0.82),
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
// WIDGETS AUXILIARES COMPARTILHADOS
// ═══════════════════════════════════════════════════════════════

class _DreamBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _K.purple.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(_K.r99),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💭', style: TextStyle(fontSize: 11)),
            SizedBox(width: 4),
            Text(
              'Sonho',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _K.purple,
              ),
            ),
          ],
        ),
      );
}

class _ChildPill extends StatelessWidget {
  final String emoji;
  final String name;
  const _ChildPill({required this.emoji, required this.name});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(_K.r99),
          border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      );
}

class _CatPill extends StatelessWidget {
  final String label;
  const _CatPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _K.pink.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(_K.r99),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _K.pink,
          ),
        ),
      );
}

class _LocationPill extends StatelessWidget {
  final String city;
  final String? state;
  const _LocationPill({required this.city, this.state});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 12,
            color: _K.muted.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 2),
          Text(
            state != null ? '$city, $state' : city,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _K.muted.withValues(alpha: 0.85),
            ),
          ),
        ],
      );
}

class _AuthorAvatar extends StatelessWidget {
  final String? emoji;
  final String? imageUrl;
  const _AuthorAvatar({this.emoji, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          imageUrl!,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _K.purple.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(emoji ?? '👤', style: const TextStyle(fontSize: 18)),
        ),
      );
}

// ── Aliases públicos (retrocompatibilidade) ───────────────────

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
  Widget build(BuildContext context) => Container(
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

class ChildChip extends StatelessWidget {
  final String emoji;
  final String name;
  const ChildChip({super.key, required this.emoji, required this.name});

  @override
  Widget build(BuildContext context) => _ChildPill(emoji: emoji, name: name);
}

class LocationBadge extends StatelessWidget {
  final String city;
  final String? state;
  const LocationBadge({super.key, required this.city, this.state});

  @override
  Widget build(BuildContext context) =>
      _LocationPill(city: city, state: state);
}

class UserAvatar extends StatelessWidget {
  final String? emoji;
  final String? imageUrl;
  const UserAvatar({super.key, this.emoji, this.imageUrl});

  @override
  Widget build(BuildContext context) =>
      _AuthorAvatar(emoji: emoji, imageUrl: imageUrl);
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
  Widget build(BuildContext context) => Row(
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

class ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const ActiveFilterChip({
    super.key,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.kidsPurple.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.kidsPurple.withValues(alpha: 0.3)),
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
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/donation/presentation/pages/donation_detail_page.dart';
import 'package:empatia/features/dream/presentation/widgets/dream_search_card.dart';
import 'package:empatia/features/search/controller/search_controller.dart'
    show SearchResult;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH RESULT CARD — router
//
//  'dream'    → DreamSearchCard    (emotional card, applied psychology)
//  'donation' → _DonationCard      (image card with badges + hero transition)
// ─────────────────────────────────────────────────────────────────────────────

class SearchResultCard extends StatelessWidget {
  final SearchResult result;

  const SearchResultCard({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (result.type == 'dream') {
      return DreamSearchCard(result: result);
    }
    return _DonationCard(result: result);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DONATION CARD
// ══════════════════════════════════════════════════════════════════════════════

class _DonationCard extends StatelessWidget {
  final SearchResult result;
  const _DonationCard({required this.result});

  bool get _hasStatus =>
      result.status != null &&
      result.status!.isNotEmpty &&
      result.status != 'available';

  @override
  Widget build(BuildContext context) {
    final heroTag = 'search_donation_${result.id}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        DonationDetailPage.route(result: result, heroTag: heroTag),
      ),
      child: AspectRatio(
        // 3:4.2 — taller than wide, ensures footer always has room
        aspectRatio: 3 / 4.2,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Image / placeholder ────────────────────────────────
              _DonationBg(result: result, heroTag: heroTag),

              // ── Dark gradient scrim (bottom 55 %) ─────────────────
              const _BottomGradient(),

              // ── Top-left: category badge ───────────────────────────
              const Positioned(
                top: 12,
                left: 12,
                child: _DonationBadge(),
              ),

              // ── Top-right: status badge (when relevant) ────────────
              if (_hasStatus)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _StatusBadge(status: result.status),
                ),

              // ── Bottom: title + location ───────────────────────────
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: _DonationFooter(result: result),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE / PLACEHOLDER
// ─────────────────────────────────────────────────────────────────────────────

class _DonationBg extends StatelessWidget {
  final SearchResult result;
  final String heroTag;
  const _DonationBg({required this.result, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final url = result.photoUrl;
    if (url != null && url.isNotEmpty) {
      return Hero(
        tag: heroTag,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, p) =>
              p == null ? child : const _DonationPlaceholder(loading: true),
          errorBuilder: (_, __, ___) =>
              const _DonationPlaceholder(loading: false),
        ),
      );
    }
    return const _DonationPlaceholder(loading: false);
  }
}

class _DonationPlaceholder extends StatelessWidget {
  final bool loading;
  const _DonationPlaceholder({required this.loading});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xFFFFF0F6),
        child: Center(
          child: loading
              ? CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.kidsPink,
                )
              : const Text('🎁', style: TextStyle(fontSize: 48)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// GRADIENT SCRIM — starts at mid-card so title + location are always legible
// ─────────────────────────────────────────────────────────────────────────────

class _BottomGradient extends StatelessWidget {
  const _BottomGradient();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.38, 1.0],
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.80),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGES
// ─────────────────────────────────────────────────────────────────────────────

class _DonationBadge extends StatelessWidget {
  const _DonationBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎁', style: TextStyle(fontSize: 12)),
            SizedBox(width: 5),
            Text(
              'Doação',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
              ),
            ),
          ],
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  final String? status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'reserved':
        return AppTheme.donationReservedColor;
      case 'donated':
      case 'fulfilled':
        return AppTheme.kidsGreenDeep;
      default:
        return Colors.black54;
    }
  }

  String get _label {
    switch (status) {
      case 'reserved':
        return 'Reservado';
      case 'donated':
        return 'Doado';
      case 'fulfilled':
        return 'Realizado';
      default:
        return status ?? '';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(10),
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

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER — title (up to 3 lines) + location row
// ─────────────────────────────────────────────────────────────────────────────

class _DonationFooter extends StatelessWidget {
  final SearchResult result;
  const _DonationFooter({required this.result});

  @override
  Widget build(BuildContext context) {
    final city     = result.city?.trim()  ?? '';
    final state    = result.state?.trim() ?? '';
    final location = [
      if (city.isNotEmpty)  city,
      if (state.isNotEmpty) state,
    ].join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title — 3 lines max, larger text, stronger shadow
        Text(
          result.title ?? 'Sem título',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.3,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 8),
              Shadow(color: Colors.black26, blurRadius: 2),
            ],
          ),
        ),

        // Location row
        if (location.isNotEmpty) ...[
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 12,
                color: Colors.white70,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
import 'dart:ui';

import 'package:empatia/features/search/controller/search_controller.dart'
    show SearchResult;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _Palette {
  // Brand
  static const primary      = Color(0xFF2563EB);
  static const primaryDeep  = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFFEFF6FF);
  static const primaryBorder= Color(0xFFBFDBFE);

  // Text
  static const navy         = Color(0xFF1E3A5F);
  static const body         = Color(0xFF374151);
  static const muted        = Color(0xFF6B7280);
  static const subtle       = Color(0xFF9CA3AF);

  // Surface
  static const surface      = Color(0xFFF9FAFB);
  static const border       = Color(0xFFE5E7EB);
  static const white        = Colors.white;

  // Semantic
  static const green  = Color(0xFF16A34A);
  static const amber  = Color(0xFFF59E0B);
  static const blue   = Color(0xFF3B82F6);
}

abstract final class _Radius {
  static const sm  = 8.0;
  static const md  = 12.0;
  static const lg  = 16.0;
  static const xl  = 20.0;
  static const pill= 100.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// DREAM DETAIL PAGE
// ─────────────────────────────────────────────────────────────────────────────

class DreamDetailPage extends StatelessWidget {
  final SearchResult result;
  final String heroTag;

  const DreamDetailPage({
    Key? key,
    required this.result,
    required this.heroTag,
  }) : super(key: key);

  static Route<void> route({
    required SearchResult result,
    required String heroTag,
  }) =>
      MaterialPageRoute(
        builder: (_) => DreamDetailPage(result: result, heroTag: heroTag),
      );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: _Palette.white,
      body: Stack(
        children: [
          // ── Scrollable content ─────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Collapsible hero photo
              SliverAppBar(
                expandedHeight: mq.size.height * 0.40,
                pinned: true,
                stretch: true,
                backgroundColor: _Palette.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: _BackButton(),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  stretchModes: const [StretchMode.zoomBackground],
                  background: _HeroPhoto(result: result, heroTag: heroTag),
                ),
              ),

              // Page body
              SliverToBoxAdapter(child: _PageBody(result: result)),

              // Space so CTA never covers content
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),

          // ── Fixed CTA ──────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _CtaBar(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACK BUTTON (with backdrop blur)
// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 38,
              height: 38,
              color: Colors.black.withValues(alpha: 0.22),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _Palette.white,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO PHOTO
// ─────────────────────────────────────────────────────────────────────────────

class _HeroPhoto extends StatelessWidget {
  final SearchResult result;
  final String heroTag;

  const _HeroPhoto({required this.result, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final url = result.photoUrl;

    return Hero(
      tag: heroTag,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main image / fallback gradient
          url != null && url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _GradientPlaceholder(),
                )
              : _GradientPlaceholder(),

          // Bottom fade — white transition into body
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.55, 1.0],
                colors: [Colors.transparent, _Palette.white],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDBEAFE), Color(0xFFBFD9FF)],
          ),
        ),
        child: const Center(
          child: Text('✨', style: TextStyle(fontSize: 72)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE BODY
// ─────────────────────────────────────────────────────────────────────────────

class _PageBody extends StatelessWidget {
  final SearchResult result;
  const _PageBody({required this.result});

  @override
  Widget build(BuildContext context) {
    final childName   = result.childName?.trim()   ?? '';
    final childEmoji  = result.childEmoji?.trim()  ?? '';
    final dreamEmoji  = result.dreamEmoji?.trim()  ?? '';
    final title       = result.title?.trim()       ?? '';
    final description = result.description?.trim() ?? '';
    final city        = result.city?.trim()        ?? '';
    final state       = result.state?.trim()       ?? '';
    final dreamDate   = result.dreamDate?.trim()   ?? '';
    final progress    = result.dreamProgress;

    final hasLocation = city.isNotEmpty || state.isNotEmpty;
    final location    = [
      if (city.isNotEmpty)  city,
      if (state.isNotEmpty) state,
    ].join(', ');
    final hasInfoSection = hasLocation || dreamDate.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Dream emoji pill ───────────────────────────────────────
          if (dreamEmoji.isNotEmpty) ...[
            _Pill(emoji: dreamEmoji),
            const SizedBox(height: 12),
          ],

          // ── Title ──────────────────────────────────────────────────
          if (title.isNotEmpty)
            Text(
              title,
              softWrap: true,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _Palette.navy,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),

          // ── Child name chip ────────────────────────────────────────
          if (childName.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ChildChip(name: childName, emoji: childEmoji),
          ],

          // ── Location · Date row ────────────────────────────────────
          if (hasLocation || dreamDate.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MetaRow(location: location, dreamDate: dreamDate),
          ],

          // ── Progress ───────────────────────────────────────────────
          if (progress != null && progress > 0) ...[
            const SizedBox(height: 24),
            _DreamProgress(progress: progress),
          ],

          // ── Description ────────────────────────────────────────────
          if (description.isNotEmpty) ...[
            const SizedBox(height: 28),
            _SectionLabel(
              childName.isNotEmpty
                  ? 'Sobre o sonho de $childName'
                  : 'Sobre este sonho',
            ),
            const SizedBox(height: 10),
            _DescriptionCard(text: description),
          ],

          // ── Info section ───────────────────────────────────────────
          if (hasInfoSection) ...[
            const SizedBox(height: 28),
            const _SectionLabel('Informações'),
            const SizedBox(height: 10),
            _InfoCard(city: city, state: state, dreamDate: dreamDate),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

/// Dream emoji pill badge
class _Pill extends StatelessWidget {
  final String emoji;
  const _Pill({required this.emoji});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _Palette.primaryLight,
          borderRadius: BorderRadius.circular(_Radius.pill),
          border: Border.all(color: _Palette.primaryBorder),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      );
}

/// Child name chip with emoji
class _ChildChip extends StatelessWidget {
  final String name;
  final String emoji;
  const _ChildChip({required this.name, required this.emoji});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _Palette.primaryLight,
          borderRadius: BorderRadius.circular(_Radius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji.isNotEmpty) ...[
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                name,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _Palette.primary,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Inline location · date metadata
class _MetaRow extends StatelessWidget {
  final String location;
  final String dreamDate;
  const _MetaRow({required this.location, required this.dreamDate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (location.isNotEmpty) ...[
          const Icon(Icons.location_on_rounded,
              size: 13, color: _Palette.subtle),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              location,
              style: const TextStyle(
                fontSize: 13,
                color: _Palette.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        if (location.isNotEmpty && dreamDate.isNotEmpty) ...[
          const SizedBox(width: 10),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: _Palette.subtle,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
        ],
        if (dreamDate.isNotEmpty) ...[
          const Icon(Icons.auto_stories_rounded,
              size: 12, color: _Palette.subtle),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              dreamDate,
              style: const TextStyle(
                fontSize: 13,
                color: _Palette.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Section label — sentence case, soft weight
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _Palette.muted,
          letterSpacing: 0.3,
        ),
      );
}

/// Description card
class _DescriptionCard extends StatelessWidget {
  final String text;
  const _DescriptionCard({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.circular(_Radius.lg),
          border: Border.all(color: _Palette.border),
        ),
        child: Text(
          text,
          softWrap: true,
          style: const TextStyle(
            fontSize: 15,
            color: _Palette.body,
            height: 1.75,
          ),
        ),
      );
}

/// Info card — grouped tiles
class _InfoCard extends StatelessWidget {
  final String city;
  final String state;
  final String dreamDate;
  const _InfoCard({
    required this.city,
    required this.state,
    required this.dreamDate,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    if (city.isNotEmpty)      tiles.add(_InfoTile(icon: Icons.location_city_rounded, label: 'Cidade', value: city));
    if (state.isNotEmpty)     tiles.add(_InfoTile(icon: Icons.map_rounded,           label: 'Estado', value: state));
    if (dreamDate.isNotEmpty) tiles.add(_InfoTile(icon: Icons.auto_stories_rounded, label: 'Descrição',   value: dreamDate));

    return Container(
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(_Radius.lg),
        border: Border.all(color: _Palette.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i < tiles.length - 1)
              const Divider(height: 1, thickness: 1, color: _Palette.border),
          ],
        ],
      ),
    );
  }
}

/// Single info tile inside the info card
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _Palette.primaryLight,
                borderRadius: BorderRadius.circular(_Radius.sm),
              ),
              child: Icon(icon, size: 15, color: _Palette.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _Palette.subtle,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _Palette.navy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED PROGRESS BAR
// ─────────────────────────────────────────────────────────────────────────────

class _DreamProgress extends StatefulWidget {
  final double progress;
  const _DreamProgress({required this.progress});

  @override
  State<_DreamProgress> createState() => _DreamProgressState();
}

class _DreamProgressState extends State<_DreamProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _color(double p) {
    if (p >= 0.75) return _Palette.green;
    if (p >= 0.40) return _Palette.amber;
    return _Palette.blue;
  }

  @override
  Widget build(BuildContext context) {
    final p     = widget.progress.clamp(0.0, 1.0);
    final pct   = (p * 100).round();
    final color = _color(p);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(_Radius.lg),
        border: Border.all(color: _Palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progresso do sonho',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _Palette.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$pct% concluído',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _Palette.subtle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Animated counter
              AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => Text(
                  '${(_anim.value * pct).round()}%',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: p * _anim.value,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIXED CTA BAR
// ─────────────────────────────────────────────────────────────────────────────

class _CtaBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPad),
      decoration: BoxDecoration(
        color: _Palette.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: _AnimatedCtaButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Em breve você poderá entrar em contato com a família!',
              ),
              backgroundColor: _Palette.navy,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_Radius.md),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED CTA BUTTON — scale + gradient + shadow
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedCtaButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedCtaButton({required this.onPressed});

  @override
  State<_AnimatedCtaButton> createState() => _AnimatedCtaButtonState();
}

class _AnimatedCtaButtonState extends State<_AnimatedCtaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
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
    widget.onPressed();
  }
  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: _ctrl.value,
          child: child,
        ),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_Palette.blue, _Palette.primaryDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_Radius.lg),
            boxShadow: [
              BoxShadow(
                color: _Palette.primary.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Saber Como Ajudar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _Palette.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
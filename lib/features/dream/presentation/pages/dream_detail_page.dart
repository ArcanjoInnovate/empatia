import 'dart:ui';

import 'package:empatia/features/search/controller/search_controller.dart'
    show SearchResult;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _T {
  // Brand
  static const pink        = Color(0xFFFF5C8D);
  static const pinkDeep    = Color(0xFFE0457A);
  static const pinkLight   = Color(0xFFFFF0F6);
  static const pinkBorder  = Color(0xFFFFD6E7);

  static const blue        = Color(0xFF2563EB);

  // Semantic
  static const green       = Color(0xFF16A34A);
  static const greenLight  = Color(0xFFDCFCE7);
  static const amber       = Color(0xFFF59E0B);
  static const amberLight  = Color(0xFFFEF3C7);

  // Text
  static const navy        = Color(0xFF1E3A5F);
  static const body        = Color(0xFF374151);
  static const muted       = Color(0xFF6B7280);
  static const subtle      = Color(0xFF9CA3AF);

  // Surface
  static const white       = Colors.white;
  static const surface     = Color(0xFFF9FAFB);
  // Creme suave — transmite acolhimento, papel, carta
  static const cream       = Color(0xFFFFFBF5);
  static const creamBorder = Color(0xFFF0E6D3);
  static const creamDeep   = Color(0xFFE8D5B7);

  static const border      = Color(0xFFE5E7EB);
  static const borderWarm  = Color(0xFFFFD6E7);

  // Radius
  static const r8  = 8.0;
  static const r12 = 12.0;
  static const r16 = 16.0;
  static const r20 = 20.0;
  static const r24 = 24.0;
  static const r99 = 99.0;
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.white,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // 1 — Hero emocional
                _HeroSliver(result: result, heroTag: heroTag),

                // 2+ — Corpo da página em sequência narrativa
                SliverToBoxAdapter(child: _PageBody(result: result)),

                // Espaço para CTA não cobrir conteúdo
                const SliverToBoxAdapter(child: SizedBox(height: 128)),
              ],
            ),

            // CTA fixo
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _CtaBar(childName: result.childName?.trim() ?? ''),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEÇÃO 1 — HERO EMOCIONAL
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSliver extends StatelessWidget {
  final SearchResult result;
  final String heroTag;
  const _HeroSliver({required this.result, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return SliverAppBar(
      expandedHeight: mq.size.height * 0.50,
      pinned: true,
      stretch: true,
      backgroundColor: _T.navy,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: _BackButton(),
      title: _CollapsedTitle(title: result.title ?? ''),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: _HeroBackground(result: result, heroTag: heroTag),
      ),
    );
  }
}

class _CollapsedTitle extends StatelessWidget {
  final String title;
  const _CollapsedTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _T.white,
        ),
      );
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 38,
                height: 38,
                color: Colors.black.withValues(alpha: 0.25),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _T.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      );
}

class _HeroBackground extends StatelessWidget {
  final SearchResult result;
  final String heroTag;
  const _HeroBackground({required this.result, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final url        = result.photoUrl;
    final childName  = result.childName?.trim()  ?? '';
    final childEmoji = result.childEmoji?.trim() ?? '⭐';
    final dreamEmoji = result.dreamEmoji?.trim() ?? '';
    final title      = result.title?.trim()      ?? '';
    final city       = result.city?.trim()       ?? '';
    final state      = result.state?.trim()      ?? '';
    final location   = [
      if (city.isNotEmpty)  city,
      if (state.isNotEmpty) state,
    ].join(', ');

    return Hero(
      tag: heroTag,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagem ou placeholder
          if (url != null && url.isNotEmpty)
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _HeroPlaceholder(),
            )
          else
            const _HeroPlaceholder(),

          // Overlay gradiente em 4 camadas
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.35, 0.70, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.52),
                  Colors.black.withValues(alpha: 0.86),
                ],
              ),
            ),
          ),

          // Identidade da criança (nome grande + localização)
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (childName.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(childEmoji,
                          style: const TextStyle(fontSize: 30)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          childName,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: _T.white,
                            height: 1.1,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (title.isNotEmpty)
                  Row(
                    children: [
                      if (dreamEmoji.isNotEmpty) ...[
                        Text(dreamEmoji,
                            style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _T.white.withValues(alpha: 0.90),
                            height: 1.4,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 6),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
          ),
        ),
        child: const Center(
          child: Text('⭐', style: TextStyle(fontSize: 80)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE BODY — hierarquia narrativa
//
//  ① Âncora do sonho (título + emoji)
//  ② RELATO DA FAMÍLIA ← DESTAQUE MÁXIMO
//  ③ Impacto
//  ④ Progresso
//  ⑤ Prova social
//  ⑥ Informações complementares
// ─────────────────────────────────────────────────────────────────────────────

class _PageBody extends StatelessWidget {
  final SearchResult result;
  const _PageBody({required this.result});

  @override
  Widget build(BuildContext context) {
    final childName   = result.childName?.trim()   ?? '';
    final childEmoji  = result.childEmoji?.trim()  ?? '';
    final dreamEmoji  = result.dreamEmoji?.trim()  ?? '✨';
    final title       = result.title?.trim()       ?? '';
    final description = result.description?.trim() ?? '';
    // dreamDate contém o relato real da família
    final familyStory = result.dreamDate?.trim()   ?? '';
    final city        = result.city?.trim()        ?? '';
    final state       = result.state?.trim()       ?? '';
    final progress    = result.dreamProgress;

    // Usa o relato da família; fallback para description se dreamDate vazio
    final storyText = familyStory.isNotEmpty ? familyStory : description;

    final location = [
      if (city.isNotEmpty)  city,
      if (state.isNotEmpty) state,
    ].join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ① Âncora: pill do sonho — transição suave do hero para o corpo
        _DreamAnchor(
          dreamEmoji: dreamEmoji,
          title: title,
          childName: childName,
        ),

        // ② RELATO DA FAMÍLIA — seção mais importante da tela
        if (storyText.isNotEmpty) ...[
          const SizedBox(height: 8),
          _FamilyStorySection(
            description: storyText,
            childName: childName,
            childEmoji: childEmoji,
          ),
        ],

        // ③ Impacto do sonho
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ImpactSection(childName: childName),
        ),

        // ④ Progresso inspirador
        if (progress != null && progress > 0) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _InspiringProgress(
              progress: progress,
              childName: childName,
            ),
          ),
        ],

        // ⑤ Prova social
        const SizedBox(height: 24),
        const _SocialProofSection(),

        // ⑥ Informações complementares
        if (location.isNotEmpty) ...[
          const SizedBox(height: 24),
          _InfoSection(
            city: city,
            state: state,
            title: title,
          ),
        ],

        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ① ÂNCORA DO SONHO
// Pill compacto que ancora a leitura antes do grande relato
// ─────────────────────────────────────────────────────────────────────────────

class _DreamAnchor extends StatelessWidget {
  final String dreamEmoji;
  final String title;
  final String childName;
  const _DreamAnchor({
    required this.dreamEmoji,
    required this.title,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox(height: 20);

    final name = childName.isNotEmpty ? childName : 'esta criança';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Linha decorativa vertical
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_T.pink, _T.pinkDeep],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O sonho de $name',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _T.pink,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (dreamEmoji.isNotEmpty) ...[
                      Text(dreamEmoji,
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _T.navy,
                          height: 1.2,
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

// ─────────────────────────────────────────────────────────────────────────────
// ② RELATO DA FAMÍLIA — SEÇÃO PRINCIPAL
//
// Aparência de carta / depoimento real.
// Fundo creme acolhedor, aspas decorativas grandes, tipografia editorial,
// assinatura da família ao final.
// ─────────────────────────────────────────────────────────────────────────────

class _FamilyStorySection extends StatelessWidget {
  final String description;
  final String childName;
  final String childEmoji;

  const _FamilyStorySection({
    required this.description,
    required this.childName,
    required this.childEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label da seção ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _T.navy,
                  borderRadius: BorderRadius.circular(_T.r99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('💌', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 5),
                    Text(
                      'Mensagem da família',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _T.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Card principal — carta/depoimento ──────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _T.cream,
            borderRadius: BorderRadius.circular(_T.r24),
            border: Border.all(color: _T.creamBorder, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Faixa superior decorativa com textura de papel
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFD6E7), Color(0xFFFFE8B2), Color(0xFFD6EDFF)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_T.r24),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aspas de abertura decorativas
                    const _OpeningQuote(),

                    const SizedBox(height: 12),

                    // Corpo do relato — tipografia editorial
                    Text(
                      description,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 17,
                        color: _T.body,
                        height: 1.85,
                        letterSpacing: 0.15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Divisor elegante
                    Row(
                      children: [
                        Container(
                          height: 1,
                          width: 32,
                          color: _T.creamDeep,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '✦',
                          style: TextStyle(
                            fontSize: 10,
                            color: _T.creamDeep,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: _T.creamDeep,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Assinatura da família
                    _FamilySignature(
                      childName: childName,
                      childEmoji: childEmoji,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Nota de autenticidade abaixo do card ───────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded,
                  size: 13, color: _T.pink),
              const SizedBox(width: 5),
              Text(
                'Relato real compartilhado pela família',
                style: TextStyle(
                  fontSize: 11,
                  color: _T.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Aspas tipográficas de abertura em destaque visual
class _OpeningQuote extends StatelessWidget {
  const _OpeningQuote();

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aspa principal grande
          Text(
            '"',
            style: TextStyle(
              fontSize: 80,
              height: 0.6,
              fontWeight: FontWeight.w900,
              color: _T.pink.withValues(alpha: 0.20),
              fontFamily: 'Georgia', // serif para elegância
            ),
          ),
          const SizedBox(width: 6),
          // Segunda aspa menor para profundidade
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '"',
              style: TextStyle(
                fontSize: 48,
                height: 0.6,
                fontWeight: FontWeight.w900,
                color: _T.pink.withValues(alpha: 0.12),
                fontFamily: 'Georgia',
              ),
            ),
          ),
        ],
      );
}

/// Assinatura da família ao final do relato
class _FamilySignature extends StatelessWidget {
  final String childName;
  final String childEmoji;
  const _FamilySignature({
    required this.childName,
    required this.childEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final hasName = childName.isNotEmpty;
    final emoji   = childEmoji.isNotEmpty ? childEmoji : '👨‍👩‍👧';

    return Row(
      children: [
        // Avatar da criança / família
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _T.pinkLight,
            shape: BoxShape.circle,
            border: Border.all(color: _T.pinkBorder, width: 1.5),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasName ? 'Família de $childName' : 'A família',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _T.navy,
              ),
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    size: 10, color: _T.pink),
                const SizedBox(width: 4),
                Text(
                  'Com muito amor',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _T.muted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ③ IMPACTO — o que a ação gera
// ─────────────────────────────────────────────────────────────────────────────

class _ImpactSection extends StatelessWidget {
  final String childName;
  const _ImpactSection({required this.childName});

  static const _items = [
    _ImpactItem(emoji: '🌟', text: 'Realizar um sonho especial'),
    _ImpactItem(emoji: '👫', text: 'Criar memórias afetivas únicas'),
    _ImpactItem(emoji: '💪', text: 'Desenvolver confiança e autonomia'),
    _ImpactItem(emoji: '❤️', text: 'Sentir que alguém se importa'),
  ];

  @override
  Widget build(BuildContext context) {
    final name = childName.isNotEmpty ? childName : 'essa criança';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(emoji: '🎁', label: 'Seu apoio pode ajudar $name a:'),
        const SizedBox(height: 14),
        ..._items.map((item) => _ImpactRow(item: item)),
      ],
    );
  }
}

class _ImpactItem {
  final String emoji;
  final String text;
  const _ImpactItem({required this.emoji, required this.text});
}

class _ImpactRow extends StatelessWidget {
  final _ImpactItem item;
  const _ImpactRow({required this.item});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _T.pinkLight,
                borderRadius: BorderRadius.circular(_T.r12),
                border: Border.all(color: _T.pinkBorder),
              ),
              child: Center(
                child: Text(item.emoji,
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _T.body,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ④ PROGRESSO INSPIRADOR
// ─────────────────────────────────────────────────────────────────────────────

class _InspiringProgress extends StatefulWidget {
  final double progress;
  final String childName;
  const _InspiringProgress({required this.progress, required this.childName});

  @override
  State<_InspiringProgress> createState() => _InspiringProgressState();
}

class _InspiringProgressState extends State<_InspiringProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _message(double p) {
    if (p >= 0.90) return 'Quase lá! Seja a última peça desta história ✨';
    if (p >= 0.60) return 'Mais algumas pessoas podem completar este sonho!';
    if (p >= 0.30) return 'O sonho está crescendo com cada apoio recebido.';
    return 'Este sonho está começando sua jornada. Seja o primeiro!';
  }

  Color _color(double p) {
    if (p >= 0.75) return _T.green;
    if (p >= 0.40) return _T.amber;
    return _T.pink;
  }

  Color _lightColor(double p) {
    if (p >= 0.75) return _T.greenLight;
    if (p >= 0.40) return _T.amberLight;
    return _T.pinkLight;
  }

  @override
  Widget build(BuildContext context) {
    final p     = widget.progress.clamp(0.0, 1.0);
    final pct   = (p * 100).round();
    final color = _color(p);
    final light = _lightColor(p);
    final name  = widget.childName.isNotEmpty ? widget.childName : 'este sonho';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: light,
        borderRadius: BorderRadius.circular(_T.r20),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('❤️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sonho em progresso',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _T.muted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'O sonho de $name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => Text(
                  '${(_anim.value * pct).round()}%',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (p * _anim.value).clamp(0.0, 1.0),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (p * _anim.value).clamp(0.0, 1.0),
                  child: Container(
                    height: 5,
                    margin: const EdgeInsets.only(top: 1.5, left: 3, right: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _message(p),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ⑤ PROVA SOCIAL
// ─────────────────────────────────────────────────────────────────────────────

class _SocialProofSection extends StatelessWidget {
  const _SocialProofSection();

  static const _avatarColors = [
    Color(0xFFFF5C8D),
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFF7C3AED),
  ];
  static const _initials = ['M', 'J', 'A', 'R', 'C'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF2D5A8E)],
        ),
        borderRadius: BorderRadius.circular(_T.r20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✨', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Este sonho já tocou corações',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _T.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 5 * 24.0 + 12,
                height: 38,
                child: Stack(
                  children: List.generate(5, (i) => Positioned(
                    left: i * 24.0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _avatarColors[i],
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1E3A5F), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _initials[i],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _T.white,
                          ),
                        ),
                      ),
                    ),
                  )),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'pessoas demonstraram interesse neste sonho',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _SocialBadge(emoji: '💜', label: 'Sonho verificado'),
              _SocialBadge(emoji: '🔒', label: 'Família segura'),
              _SocialBadge(emoji: '⭐', label: 'Muito aguardado'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialBadge extends StatelessWidget {
  final String emoji;
  final String label;
  const _SocialBadge({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(_T.r99),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _T.white,
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ⑥ INFORMAÇÕES COMPLEMENTARES — grid 2 colunas
// ─────────────────────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final String city;
  final String state;
  final String title;
  const _InfoSection({
    required this.city,
    required this.state,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final location = [
      if (city.isNotEmpty)  city,
      if (state.isNotEmpty) state,
    ].join(', ');

    final tiles = <_InfoTileData>[];
    if (location.isNotEmpty) tiles.add(_InfoTileData('📍', 'Localização', location));
    if (title.isNotEmpty)    tiles.add(_InfoTileData('🎁', 'Sonho',       title));

    if (tiles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(emoji: '📋', label: 'Mais informações'),
          const SizedBox(height: 14),
          _InfoGrid(tiles: tiles),
        ],
      ),
    );
  }
}

class _InfoTileData {
  final String emoji;
  final String label;
  final String value;
  const _InfoTileData(this.emoji, this.label, this.value);
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoTileData> tiles;
  const _InfoGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final a = tiles[i];
      final b = i + 1 < tiles.length ? tiles[i + 1] : null;
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(child: _InfoTile(data: a)),
            if (b != null) ...[
              const SizedBox(width: 10),
              Expanded(child: _InfoTile(data: b)),
            ] else
              const Expanded(child: SizedBox()),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

class _InfoTile extends StatelessWidget {
  final _InfoTileData data;
  const _InfoTile({required this.data});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(_T.r16),
          border: Border.all(color: _T.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(data.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  data.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _T.subtle,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              data.value,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _T.navy,
                height: 1.3,
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED: SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String label;
  const _SectionHeader({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _T.navy,
                height: 1.3,
              ),
            ),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA BAR — emocional e consequente da narrativa
// ─────────────────────────────────────────────────────────────────────────────

class _CtaBar extends StatelessWidget {
  final String childName;
  const _CtaBar({required this.childName});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final name      = childName.isNotEmpty ? childName : 'esta criança';

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomPad),
      decoration: BoxDecoration(
        color: _T.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Você leu a história. Agora pode fazer parte dela.',
            style: TextStyle(
              fontSize: 12,
              color: _T.muted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          _CtaButton(childName: name),
        ],
      ),
    );
  }
}

class _CtaButton extends StatefulWidget {
  final String childName;
  const _CtaButton({required this.childName});

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
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

  void _down(TapDownDetails _) => _ctrl.reverse();
  void _up(TapUpDetails _) {
    _ctrl.forward();
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Em breve você poderá ajudar ${widget.childName}!'),
        backgroundColor: _T.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_T.r12),
        ),
      ),
    );
  }

  void _cancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_T.pink, _T.pinkDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_T.r16),
            boxShadow: [
              BoxShadow(
                color: _T.pink.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('❤️', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Text(
                'Quero Realizar Este Sonho',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _T.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
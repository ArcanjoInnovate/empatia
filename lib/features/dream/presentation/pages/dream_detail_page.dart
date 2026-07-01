import 'dart:ui';

import 'package:empatia/core/widget/avatar_render.dart';
import 'package:empatia/features/chat/data/models/chat_model.dart';
import 'package:empatia/features/chat/data/repositories/chat_repository.dart';
import 'package:empatia/features/chat/presentation/pages/chat_page.dart';
import 'package:empatia/features/profile/presentation/page/profile/public_profile_page.dart';
import 'package:empatia/features/search/controller/search_controller.dart'
    show SearchResult;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _T {
  // Brand
  static const pink = Color(0xFFFF5C8D);
  static const pinkDeep = Color(0xFFE0457A);
  static const pinkLight = Color(0xFFFFF0F6);
  static const pinkBorder = Color(0xFFFFD6E7);

  static const blue = Color(0xFF2563EB);

  // Semantic
  static const green = Color(0xFF16A34A);
  static const greenLight = Color(0xFFDCFCE7);
  static const amber = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFEF3C7);

  // Text
  static const navy = Color(0xFF1E3A5F);
  static const body = Color(0xFF374151);
  static const muted = Color(0xFF6B7280);
  static const subtle = Color(0xFF9CA3AF);

  // Surface
  static const white = Colors.white;
  static const surface = Color(0xFFF9FAFB);
  // Creme suave — transmite acolhimento, papel, carta
  static const cream = Color(0xFFFFFBF5);
  static const creamBorder = Color(0xFFF0E6D3);
  static const creamDeep = Color(0xFFE8D5B7);

  static const border = Color(0xFFE5E7EB);
  static const borderWarm = Color(0xFFFFD6E7);

  // Radius
  static const r8 = 8.0;
  static const r12 = 12.0;
  static const r16 = 16.0;
  static const r20 = 20.0;
  static const r24 = 24.0;
  static const r99 = 99.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI PERFIL DA CRIANÇA — bottom sheet compartilhado
// (mesmo padrão visual do PublicProfilePage)
// ─────────────────────────────────────────────────────────────────────────────

void _showChildMiniProfile(
  BuildContext context, {
  required String name,
  String? avatar,
  int? age,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
      decoration: const BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _T.pinkBorder, width: 2.5),
            ),
            child: ClipOval(child: AvatarRender(value: avatar, size: 96)),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: _T.navy,
            ),
            textAlign: TextAlign.center,
          ),
          if (age != null) ...[
            const SizedBox(height: 4),
            Text(
              '$age ${age == 1 ? 'ano' : 'anos'}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _T.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DREAM DETAIL PAGE
// ─────────────────────────────────────────────────────────────────────────────

class DreamDetailPage extends StatelessWidget {
  final SearchResult result;
  final String heroTag;
  final bool hideCta;

  const DreamDetailPage({
    Key? key,
    required this.result,
    required this.heroTag,
    this.hideCta = false,
  }) : super(key: key);

  static Route<void> route({
    required SearchResult result,
    required String heroTag,
    bool hideCta = false,
  }) => MaterialPageRoute(
    builder: (_) =>
        DreamDetailPage(result: result, heroTag: heroTag, hideCta: hideCta),
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
                SliverToBoxAdapter(child: SizedBox(height: hideCta ? 32 : 128)),
              ],
            ),

            // CTA fixo — oculto quando aberto via contexto do chat
            if (!hideCta)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _CtaBar(
                  childName: result.childName?.trim() ?? '',
                  result: result,
                ),
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
    final url = result.photoUrl;
    final childName = result.childName?.trim() ?? '';
    final childEmoji = result.childEmoji?.trim() ?? '⭐';
    final dreamEmoji = result.dreamEmoji?.trim() ?? '';
    final title = result.title?.trim() ?? '';
    final city = result.city?.trim() ?? '';
    final state = result.state?.trim() ?? '';
    final location = [
      if (city.isNotEmpty) city,
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
                  GestureDetector(
                    onTap: () => _showChildMiniProfile(
                      context,
                      name: childName,
                      avatar: childEmoji,
                      age: result.childAge,
                    ),
                    child: Row(
                      children: [
                        ClipOval(
                          child: AvatarRender(value: childEmoji, size: 30),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                childName,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: _T.white,
                                  height: 1.1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              if (result.childAge != null)
                                Text(
                                  '${result.childAge} ${result.childAge == 1 ? 'ano' : 'anos'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.80),
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (title.isNotEmpty)
                  Row(
                    children: [
                      if (dreamEmoji.isNotEmpty) ...[
                        Text(dreamEmoji, style: const TextStyle(fontSize: 15)),
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
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: Colors.white70,
                      ),
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
    child: const Center(child: Text('⭐', style: TextStyle(fontSize: 80))),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE BODY — hierarquia narrativa
//
//  ① Âncora do sonho (título + emoji)
//  ② RELATO DA FAMÍLIA ← DESTAQUE MÁXIMO
//  ③ Quem está pedindo (card do responsável)
//  ④ Progresso
//  ⑤ Prova social
//  ⑥ Informações complementares
// ─────────────────────────────────────────────────────────────────────────────

class _PageBody extends StatelessWidget {
  final SearchResult result;
  const _PageBody({required this.result});

  @override
  Widget build(BuildContext context) {
    final childName = result.childName?.trim() ?? '';
    final childEmoji = result.childEmoji?.trim() ?? '';
    final childAge = result.childAge;
    final dreamEmoji = result.dreamEmoji?.trim() ?? '✨';
    final title = result.title?.trim() ?? '';
    final description = result.description?.trim() ?? '';
    // dreamDate contém o relato real da família
    final familyStory = result.dreamDate?.trim() ?? '';
    final city = result.city?.trim() ?? '';
    final state = result.state?.trim() ?? '';
    final progress = result.dreamProgress;

    // Usa o relato da família; fallback para description se dreamDate vazio
    final storyText = familyStory.isNotEmpty ? familyStory : description;

    final location = [
      if (city.isNotEmpty) city,
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
            childAge: childAge,
          ),
        ],

        // ③ Quem está pedindo — card do responsável (clicável → perfil público)
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ParentCard(result: result),
        ),

        // ④ Progresso inspirador
        if (progress != null && progress > 0) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _InspiringProgress(progress: progress, childName: childName),
          ),
        ],

        // ⑥ Informações complementares
        if (location.isNotEmpty) ...[
          const SizedBox(height: 24),
          _InfoSection(city: city, state: state, title: title),
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
                      Text(dreamEmoji, style: const TextStyle(fontSize: 15)),
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
  final int? childAge;

  const _FamilyStorySection({
    required this.description,
    required this.childName,
    required this.childEmoji,
    this.childAge,
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
                  horizontal: 10,
                  vertical: 5,
                ),
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
                    colors: [
                      Color(0xFFFFD6E7),
                      Color(0xFFFFE8B2),
                      Color(0xFFD6EDFF),
                    ],
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
                        Container(height: 1, width: 32, color: _T.creamDeep),
                        const SizedBox(width: 10),
                        const Text(
                          '✦',
                          style: TextStyle(fontSize: 10, color: _T.creamDeep),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(height: 1, color: _T.creamDeep),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Assinatura da família (clicável → mini perfil da criança)
                    _FamilySignature(
                      childName: childName,
                      childEmoji: childEmoji,
                      childAge: childAge,
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
              const Icon(Icons.verified_rounded, size: 13, color: _T.pink),
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

/// Assinatura da família ao final do relato — toque abre o mini perfil
class _FamilySignature extends StatelessWidget {
  final String childName;
  final String childEmoji;
  final int? childAge;
  const _FamilySignature({
    required this.childName,
    required this.childEmoji,
    this.childAge,
  });

  @override
  Widget build(BuildContext context) {
    final hasName = childName.isNotEmpty;

    return GestureDetector(
      onTap: hasName
          ? () => _showChildMiniProfile(
              context,
              name: childName,
              avatar: childEmoji,
              age: childAge,
            )
          : null,
      child: Row(
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
            child: ClipOval(child: AvatarRender(value: childEmoji, size: 40)),
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
                  const Icon(Icons.favorite_rounded, size: 10, color: _T.pink),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ③ QUEM ESTÁ PEDINDO — card do responsável (pai/mãe)
// Clicável → abre o PublicProfilePage do dono do sonho
// ─────────────────────────────────────────────────────────────────────────────

class _ParentCard extends StatelessWidget {
  final SearchResult result;
  const _ParentCard({required this.result});

  void _openProfile(BuildContext context) {
    final ownerId = result.ownerId ?? '';
    if (ownerId.isEmpty) return;
    Navigator.push(
      context,
      PublicProfilePage.route(
        uid: ownerId,
        fallbackName: result.ownerName,
        fallbackImage: result.ownerPhotoUrl,
        fallbackCity: result.city,
        fallbackState: result.state,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerName = result.ownerName?.trim() ?? '';
    if (ownerName.isEmpty) return const SizedBox.shrink();

    final hasPhoto = result.ownerPhotoUrl?.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(emoji: '🤝', label: 'Quem está pedindo'),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _openProfile(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(_T.r20),
              border: Border.all(color: _T.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _T.pinkLight,
                  backgroundImage: hasPhoto
                      ? NetworkImage(result.ownerPhotoUrl!)
                      : null,
                  child: hasPhoto
                      ? null
                      : Text(
                          ownerName.isNotEmpty
                              ? ownerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _T.pink,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _T.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _T.pinkLight,
                          borderRadius: BorderRadius.circular(_T.r99),
                          border: Border.all(color: _T.pinkBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('❤️', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 4),
                            Text(
                              'Membro da comunidade',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _T.pinkDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _T.subtle),
              ],
            ),
          ),
        ),
      ],
    );
  }
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
    final p = widget.progress.clamp(0.0, 1.0);
    final pct = (p * 100).round();
    final color = _color(p);
    final light = _lightColor(p);
    final name = widget.childName.isNotEmpty ? widget.childName : 'este sonho';

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
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ].join(', ');

    final tiles = <_InfoTileData>[];
    if (location.isNotEmpty)
      tiles.add(_InfoTileData('📍', 'Localização', location));
    if (title.isNotEmpty) tiles.add(_InfoTileData('🎁', 'Sonho', title));

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
      rows.add(
        Padding(
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
        ),
      );
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
  final SearchResult result;
  const _CtaBar({required this.childName, required this.result});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final name = childName.isNotEmpty ? childName : 'esta criança';

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
          _CtaButton(childName: name, result: result),
        ],
      ),
    );
  }
}

class _CtaButton extends StatefulWidget {
  final String childName;
  final SearchResult result;
  const _CtaButton({required this.childName, required this.result});

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
    _openChat();
  }

  void _cancel() => _ctrl.forward();

  Future<void> _openChat() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ownerId = widget.result.ownerId ?? '';

    if (ownerId.isEmpty || ownerId == myUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ownerId.isEmpty
                ? 'Não foi possível identificar o responsável pelo sonho.'
                : 'Este é o seu próprio sonho!',
          ),
          backgroundColor: _T.navy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_T.r12),
          ),
        ),
      );
      return;
    }

    // Busca dados do perfil do dono antes de abrir o chat
    final userInfo = await ChatRepository.instance.fetchUserInfo(ownerId);
    if (!mounted) return;

    final chatId = ChatModel.buildId(myUid, ownerId);
    final sorted = ([myUid, ownerId]..sort());
    final chat = ChatModel(
      chatId: chatId,
      user1: sorted[0],
      user2: sorted[1],
      otherUid: ownerId,
      origin: ChatOrigin.dream,
      itemId: widget.result.id,
      itemTitle: widget.result.title,
      itemType: 'dream',
      otherName: userInfo['name'] ?? widget.result.ownerName,
      otherAvatar: userInfo['profileImage'] ?? widget.result.ownerPhotoUrl,
      otherEmoji: userInfo['profileEmoji'],
    );

    Navigator.push(
      context,
      ChatPage.route(myUid: myUid, chat: chat, fromDetail: true),
    );
  }

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

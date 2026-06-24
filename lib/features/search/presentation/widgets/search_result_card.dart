import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/donation/presentation/pages/donation_detail_page.dart';
import 'package:empatia/features/dream/presentation/pages/dream_detail_page.dart';
import 'package:empatia/features/search/controller/search_controller.dart'
    show SearchResult;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — compartilhados pelos dois cards
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _C {
  static const pink      = Color(0xFFFF5C8D);
  static const pinkDeep  = Color(0xFFE0457A);
  static const blue      = Color(0xFF2563EB);
  static const blueDeep  = Color(0xFF1D4ED8);
  static const navy      = Color(0xFF1E3A5F);
  static const green     = Color(0xFF16A34A);
  static const amber     = Color(0xFFF59E0B);
  static const white     = Colors.white;
  static const r16       = 16.0;
  static const r20       = 20.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUTER — encaminha para o card correto conforme o tipo
// ─────────────────────────────────────────────────────────────────────────────

class SearchResultCard extends StatelessWidget {
  final SearchResult result;
  const SearchResultCard({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (result.type == 'dream') {
      return _DreamCard(result: result);
    }
    return _DonationCard(result: result);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DREAM CARD
// Vende uma história. O usuário deve pensar: "Quero conhecer essa criança."
// ══════════════════════════════════════════════════════════════════════════════

class _DreamCard extends StatelessWidget {
  final SearchResult result;
  const _DreamCard({required this.result});

  // Gradientes afetivos — variam pelo ID para dar diversidade visual
  static const _gradients = [
    [Color(0xFF667EEA), Color(0xFF764BA2)], // roxo
    [Color(0xFFFF5C8D), Color(0xFFE0457A)], // rosa
    [Color(0xFF2563EB), Color(0xFF1E3A5F)], // azul
    [Color(0xFF16A34A), Color(0xFF065F46)], // verde
    [Color(0xFFF59E0B), Color(0xFFB45309)], // âmbar
  ];

  List<Color> _gradient(String? id) {
    final idx = (id?.codeUnits.fold(0, (a, b) => a + b) ?? 0) %
        _gradients.length;
    return _gradients[idx];
  }

  @override
  Widget build(BuildContext context) {
    final heroTag    = 'search_dream_${result.id}';
    final childName  = result.childName?.trim()  ?? '';
    final childEmoji = result.childEmoji?.trim() ?? '⭐';
    final dreamEmoji = result.dreamEmoji?.trim() ?? '✨';
    final title      = result.title?.trim()      ?? '';
    final city       = result.city?.trim()       ?? '';
    final state      = result.state?.trim()      ?? '';
    final photoUrl   = result.photoUrl;
    final location   = [
      if (city.isNotEmpty)  city,
      if (state.isNotEmpty) state,
    ].join(', ');
    final colors = _gradient(result.id);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        DreamDetailPage.route(result: result, heroTag: heroTag),
      ),
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_C.r20),
          child: Stack(
            fit: StackFit.expand,
            children: [

              // ── Fundo: foto ou gradiente afetivo ──────────────────
              if (photoUrl != null && photoUrl.isNotEmpty)
                Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _DreamGradientBg(colors: colors, emoji: childEmoji),
                )
              else
                _DreamGradientBg(colors: colors, emoji: childEmoji),

              // ── Scrim total — garante legibilidade total ───────────
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),

              // ── Topo: emoji do sonho + badge "Sonho" ──────────────
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dream emoji pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(dreamEmoji,
                              style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          const Text(
                            'Sonho',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Emoji da criança
                    if (childEmoji.isNotEmpty && photoUrl == null)
                      const SizedBox.shrink()
                    else
                      Text(childEmoji,
                          style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),

              // ── Rodapé: história da criança ────────────────────────
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Nome da criança — destaque máximo
                    if (childName.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            childName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                              shadows: [
                                Shadow(color: Colors.black45, blurRadius: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                    ],

                    // Título do sonho
                    if (title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.3,
                          shadows: const [
                            Shadow(color: Colors.black38, blurRadius: 4),
                          ],
                        ),
                      ),

                    const SizedBox(height: 7),

                    // Microcopy emocional + localização
                    Row(
                      children: [
                        Expanded(
                          child: _EmotionalMicrocopy(id: result.id),
                        ),
                      ],
                    ),

                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 10, color: Colors.white60),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white60,
                                fontWeight: FontWeight.w500,
                              ),
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
        ),
      ),
    );
  }
}

/// Fundo gradiente com emoji grande centralizado
class _DreamGradientBg extends StatelessWidget {
  final List<Color> colors;
  final String emoji;
  const _DreamGradientBg({required this.colors, required this.emoji});

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
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: 56,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Microcopy rotativo — cada card tem uma frase diferente
class _EmotionalMicrocopy extends StatelessWidget {
  final String? id;
  const _EmotionalMicrocopy({required this.id});

  static const _copies = [
    '❤️ Conheça esta história',
    '✨ Um sonho esperando acontecer',
    '🌟 Uma criança real por trás deste sonho',
    '💛 Cada apoio transforma vidas',
    '🎯 Compartilhado por uma família',
  ];

  @override
  Widget build(BuildContext context) {
    final idx = ((id?.codeUnits.fold(0, (a, b) => a + b) ?? 0) + 2) %
        _copies.length;
    return Text(
      _copies[idx],
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.80),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DONATION CARD
// Transmite oportunidade e generosidade — não marketplace, não OLX.
// ══════════════════════════════════════════════════════════════════════════════

class _DonationCard extends StatelessWidget {
  final SearchResult result;
  const _DonationCard({required this.result});

  bool get _isUnavailable =>
      result.status == 'donated'   ||
      result.status == 'fulfilled' ||
      result.status == 'reserved';

  @override
  Widget build(BuildContext context) {
    final heroTag  = 'search_donation_${result.id}';
    final title    = result.title?.trim() ?? 'Sem título';
    final city     = result.city?.trim()  ?? '';
    final state    = result.state?.trim() ?? '';
    final location = [
      if (city.isNotEmpty)  city,
      if (state.isNotEmpty) state,
    ].join(', ');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        DonationDetailPage.route(result: result, heroTag: heroTag),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_C.r20),
        child: Stack(
          fit: StackFit.expand,
          children: [

            // ── Foto ou placeholder ────────────────────────────────
            _DonationBg(result: result, heroTag: heroTag),

            // ── Overlay: leve no topo, denso embaixo ──────────────
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.42, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),

            // ── Disponibilidade no topo ────────────────────────────
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge de doação / oportunidade
                  _DonationTopBadge(status: result.status),

                  // Status badge (quando não disponível)
                  if (_isUnavailable)
                    _UnavailableBadge(status: result.status),
                ],
              ),
            ),

            // ── Rodapé: oportunidade + título + local ──────────────
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Microcopy de oportunidade emocional
                  _DonationMicrocopy(
                    status: result.status,
                    id: result.id,
                  ),

                  const SizedBox(height: 4),

                  // Título do item
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 8),
                        Shadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  ),

                  // Localização
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 10, color: Colors.white60),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Overlay de indisponibilidade (subtil) ─────────────
            if (_isUnavailable)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Foto da doação com Hero
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
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF0F6), Color(0xFFEFF6FF)],
          ),
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(
                  strokeWidth: 2, color: _C.pink)
              : const Text('🎁', style: TextStyle(fontSize: 42)),
        ),
      );
}

/// Badge topo-esquerdo — disponibilidade com linguagem emocional
class _DonationTopBadge extends StatelessWidget {
  final String? status;
  const _DonationTopBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final available = status == null ||
        status!.isEmpty ||
        status == 'available';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: available
            ? _C.blue.withValues(alpha: 0.82)
            : Colors.black.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            available ? '🎁' : '📦',
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            'Doação',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge topo-direito — estado emocional quando não disponível
class _UnavailableBadge extends StatelessWidget {
  final String? status;
  const _UnavailableBadge({required this.status});

  Color get _color {
    if (status == 'reserved') return _C.amber;
    return _C.green;
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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          _label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}

/// Microcopy emocional de oportunidade — varia por status e ID
class _DonationMicrocopy extends StatelessWidget {
  final String? status;
  final String? id;
  const _DonationMicrocopy({required this.status, required this.id});

  static const _available = [
    '💙 Disponível para uma nova família',
    '✨ Pode ganhar uma nova história',
    '🎁 Compartilhado com carinho',
    '💛 Em busca de um novo lar',
    '🌟 Uma oportunidade especial',
  ];

  @override
  Widget build(BuildContext context) {
    final String copy;

    switch (status) {
      case 'reserved':
        copy = '✨ Uma família demonstrou interesse';
        break;
      case 'donated':
        copy = '🎉 Este item encontrou um novo lar';
        break;
      case 'fulfilled':
        copy = '❤️ Esta história teve um final feliz';
        break;
      default:
        final idx =
            ((id?.codeUnits.fold(0, (a, b) => a + b) ?? 0) + 1) %
                _available.length;
        copy = _available[idx];
    }

    return Text(
      copy,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.82),
      ),
    );
  }
}
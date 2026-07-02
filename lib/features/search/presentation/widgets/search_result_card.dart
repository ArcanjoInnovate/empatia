// lib/features/search/presentation/widgets/search_result_card.dart

import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_avatars.dart';
import 'package:empatia/core/widget/avatar_render.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/widget/verification_block_dialog.dart';
import 'package:empatia/features/donation/presentation/pages/donation_detail_page.dart';
import 'package:empatia/features/dream/presentation/pages/dream_detail_page.dart';
import 'package:empatia/features/search/controller/search_controller.dart'
    show SearchResult;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — compartilhados pelos dois cards
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _C {
  static const pink = Color(0xFFFF5C8D);
  static const pinkDeep = Color(0xFFE0457A);
  static const blue = Color(0xFF2563EB);
  static const blueDeep = Color(0xFF1D4ED8);
  static const navy = Color(0xFF1E3A5F);
  static const green = Color(0xFF16A34A);
  static const amber = Color(0xFFF59E0B);
  static const white = Colors.white;
  static const r16 = 16.0;
  static const r20 = 20.0;

  // "Meu item" badge
  static const myItemBg = Color(0xFF0EA5E9);
  static const myItemBorder = Color(0xFF0284C7);
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGE "MEU ITEM"
// Exibido no topo-direito do card quando o item pertence ao usuário logado.
// ─────────────────────────────────────────────────────────────────────────────

class _MyItemBadge extends StatelessWidget {
  const _MyItemBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: _C.myItemBg,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: _C.myItemBorder, width: 1),
      boxShadow: [
        BoxShadow(
          color: _C.myItemBg.withValues(alpha: 0.45),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('✏️', style: TextStyle(fontSize: 9)),
        SizedBox(width: 3),
        Text(
          'Meu item',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LINHA SUPERIOR "SEGURA" — impede overflow entre os dois badges do topo
// ─────────────────────────────────────────────────────────────────────────────
//
// Em cards estreitos (grids de 2 colunas, ex. na galeria do PublicProfilePage
// com childAspectRatio baixo), a soma da largura do badge da esquerda + o
// badge da direita ("Meu item", status, etc.) pode superar a largura
// disponível — o clássico "RIGHT OVERFLOWED BY N PIXELS". Isso porque os dois
// badges tinham largura intrínseca fixa dentro de um Row com
// spaceBetween, que não encolhe filhos por padrão.
//
// Esse helper envolve cada lado num Flexible + FittedBox(scaleDown): quando
// sobra espaço, os badges aparecem no tamanho normal; quando o card é
// pequeno demais para os dois lado a lado, eles encolhem proporcionalmente
// ao invés de vazar pra fora do card. Nunca corta texto — dá zoom out.
class _SafeTopRow extends StatelessWidget {
  final Widget left;
  final Widget? right;
  const _SafeTopRow({required this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: left,
          ),
        ),
        if (right != null) const SizedBox(width: 6),
        if (right != null)
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: right!,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DISTÂNCIA — helper de formatação + chip usado nos dois cards
// ─────────────────────────────────────────────────────────────────────────────

/// Formata a distância para exibição compacta:
///   < 1 km   → "850 m"
///   < 10 km  → "3,4 km" (uma casa decimal)
///   >= 10 km → "24 km"  (arredondado)
String _formatDistanceKm(double km) {
  if (km < 1) {
    final meters = (km * 1000).round();
    return '$meters m';
  }
  if (km < 10) {
    final formatted = km.toStringAsFixed(1).replaceAll('.', ',');
    return '$formatted km';
  }
  return '${km.round()} km';
}

/// Chip compacto exibindo a distância até o usuário — usado no rodapé
/// dos cards de doação e sonho quando o modo "Próximo de mim" está ativo.
class _DistanceChip extends StatelessWidget {
  final double distanceKm;
  const _DistanceChip({required this.distanceKm});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.near_me_rounded, size: 9, color: Colors.white),
        const SizedBox(width: 3),
        Text(
          _formatDistanceKm(distanceKm),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUTER — encaminha para o card correto conforme o tipo
// ─────────────────────────────────────────────────────────────────────────────

class SearchResultCard extends StatelessWidget {
  final SearchResult result;

  /// UID do usuário logado. Quando igual a [result.ownerId], exibe o badge
  /// "Meu item" no card.
  final String? currentUserId;

  /// Distância (em km) até o usuário, exibida como badge quando o modo
  /// "Próximo de mim" está ativo. `null` = modo proximidade inativo ou
  /// item sem coordenadas.
  final double? distanceKm;

  /// true quando este card já está sendo exibido dentro do
  /// PublicProfilePage do próprio dono do item (ex: galeria de sonhos/
  /// doações de alguém) — nesse caso, a tela de detalhe não deve
  /// oferecer um link de volta pro mesmo perfil que o usuário já está
  /// vendo.
  final bool hideOwnerLink;

  const SearchResultCard({
    Key? key,
    required this.result,
    this.currentUserId,
    this.distanceKm,
    this.hideOwnerLink = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (result.type == 'dream') {
      return _DreamCard(
        result: result,
        currentUserId: currentUserId,
        distanceKm: distanceKm,
        hideOwnerLink: hideOwnerLink,
      );
    }
    return _DonationCard(
      result: result,
      currentUserId: currentUserId,
      distanceKm: distanceKm,
      hideOwnerLink: hideOwnerLink,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DREAM CARD
// ══════════════════════════════════════════════════════════════════════════════

class _DreamCard extends StatelessWidget {
  final SearchResult result;
  final String? currentUserId;
  final double? distanceKm;
  final bool hideOwnerLink;
  const _DreamCard({
    required this.result,
    this.currentUserId,
    this.distanceKm,
    this.hideOwnerLink = false,
  });

  static const _gradients = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFFFF5C8D), Color(0xFFE0457A)],
    [Color(0xFF2563EB), Color(0xFF1E3A5F)],
    [Color(0xFF16A34A), Color(0xFF065F46)],
    [Color(0xFF06B6D4), Color(0xFF6366F1)],
  ];

  List<Color> _gradient(String? id) {
    final idx =
        (id?.codeUnits.fold(0, (a, b) => a + b) ?? 0) % _gradients.length;
    return _gradients[idx];
  }

  bool get _isMyItem =>
      currentUserId != null &&
      currentUserId!.isNotEmpty &&
      result.ownerId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final heroTag = 'search_dream_${result.id}';
    final childName = result.childName?.trim() ?? '';
    final childEmoji = result.childEmoji?.trim() ?? '⭐';
    final dreamEmoji = result.dreamEmoji?.trim() ?? '✨';
    final title = result.title?.trim() ?? '';
    final city = result.city?.trim() ?? '';
    final state = result.state?.trim() ?? '';
    final photoUrl = result.photoUrl;
    final location = [
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ].join(', ');
    final colors = _gradient(result.id);

    return GestureDetector(
      onTap: () => pushIfVerified(
        context,
        currentUser: context.read<UserModel?>(),
        feature: 'ver os detalhes deste sonho',
        route: DreamDetailPage.route(
          result: result,
          heroTag: heroTag,
          hideOwnerLink: hideOwnerLink,
        ),
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

              // ── Scrim total ────────────────────────────────────────
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

              // ── Topo: emoji do sonho + badge "Sonho" + "Meu item" ─
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: _SafeTopRow(
                  left: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
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
                        Text(
                          dreamEmoji,
                          style: const TextStyle(fontSize: 11),
                        ),
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
                  // Badge "Meu item" ou emoji da criança
                  right: _isMyItem
                      ? const _MyItemBadge()
                      : (childEmoji.isNotEmpty && photoUrl == null
                          ? null
                          : ClipOval(
                              child: AvatarRender(value: childEmoji, size: 18),
                            )),
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
                    if (childName.isNotEmpty) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              result.childAge != null
                                  ? '$childName, ${result.childAge} anos'
                                  : childName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                    ],

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

                    Row(
                      children: [
                        Expanded(child: _EmotionalMicrocopy(id: result.id)),
                      ],
                    ),

                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 10,
                            color: Colors.white60,
                          ),
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
                          if (distanceKm != null) ...[
                            const SizedBox(width: 4),
                            _DistanceChip(distanceKm: distanceKm!),
                          ],
                        ],
                      ),
                    ] else if (distanceKm != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _DistanceChip(distanceKm: distanceKm!),
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

/// Fundo gradiente com avatar da criança centralizado
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
    child: Center(child: AvatarRender(value: emoji, size: 84)),
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
    final idx =
        ((id?.codeUnits.fold(0, (a, b) => a + b) ?? 0) + 2) % _copies.length;
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
// ══════════════════════════════════════════════════════════════════════════════

class _DonationCard extends StatelessWidget {
  final SearchResult result;
  final String? currentUserId;
  final double? distanceKm;
  final bool hideOwnerLink;
  const _DonationCard({
    required this.result,
    this.currentUserId,
    this.distanceKm,
    this.hideOwnerLink = false,
  });

  bool get _isUnavailable =>
      result.status == 'donated' ||
      result.status == 'fulfilled' ||
      result.status == 'reserved';

  bool get _isMyItem =>
      currentUserId != null &&
      currentUserId!.isNotEmpty &&
      result.ownerId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final heroTag = 'search_donation_${result.id}';
    final title = result.title?.trim() ?? 'Sem título';
    final city = result.city?.trim() ?? '';
    final state = result.state?.trim() ?? '';
    final location = [
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ].join(', ');

    return GestureDetector(
      onTap: () => pushIfVerified(
        context,
        currentUser: context.read<UserModel?>(),
        feature: 'ver os detalhes desta doação',
        route: DonationDetailPage.route(
          result: result,
          heroTag: heroTag,
          hideOwnerLink: hideOwnerLink,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_C.r20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Foto ou placeholder ────────────────────────────────
            _DonationBg(result: result, heroTag: heroTag),

            // ── Overlay ───────────────────────────────────────────
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

            // ── Topo: badge de tipo + "Meu item" ou status ────────
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: _SafeTopRow(
                left: _DonationTopBadge(status: result.status),
                // "Meu item" sobrepõe o badge de indisponibilidade
                right: _isMyItem
                    ? const _MyItemBadge()
                    : (_isUnavailable
                        ? _UnavailableBadge(status: result.status)
                        : null),
              ),
            ),

            // ── Rodapé: título + microcopy + local ────────────────
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DonationMicrocopy(status: result.status, id: result.id),

                  const SizedBox(height: 4),

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

                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 10,
                          color: Colors.white60,
                        ),
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
                        if (distanceKm != null) ...[
                          const SizedBox(width: 4),
                          _DistanceChip(distanceKm: distanceKm!),
                        ],
                      ],
                    ),
                  ] else if (distanceKm != null) ...[
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _DistanceChip(distanceKm: distanceKm!),
                    ),
                  ],
                ],
              ),
            ),

            // ── Overlay de indisponibilidade (sutil) ──────────────
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
          ? const CircularProgressIndicator(strokeWidth: 2, color: _C.pink)
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
    final available =
        status == null || status!.isEmpty || status == 'available';

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
          Text(available ? '🎁' : '📦', style: const TextStyle(fontSize: 10)),
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
      case 'reserved':
        return '✨ Reservado';
      case 'donated':
        return '🎉 Doado';
      case 'fulfilled':
        return '❤️ Realizado';
      default:
        return status ?? '';
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
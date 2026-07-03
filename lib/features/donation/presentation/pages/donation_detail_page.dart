import 'dart:ui';

import 'package:empatia/core/widget/pending_confirmation_dialog.dart';
import 'package:empatia/features/chat/data/models/chat_model.dart';
import 'package:empatia/features/chat/data/repositories/chat_repository.dart';
import 'package:empatia/features/chat/presentation/pages/chat_page.dart';
import 'package:empatia/features/profile/presentation/page/profile/public_profile_page.dart';
import 'package:empatia/features/search/controller/search_controller.dart'
    show SearchResult;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _T {
  // Brand
  static const pink       = Color(0xFFFF5C8D);
  static const pinkDeep   = Color(0xFFE0457A);
  static const pinkLight  = Color(0xFFFFF0F6);
  static const pinkBorder = Color(0xFFFFD6E7);

  static const blue       = Color(0xFF2563EB);
  static const blueLight  = Color(0xFFEFF6FF);
  static const blueBorder = Color(0xFFBFDBFE);

  // Semantic
  static const green      = Color(0xFF16A34A);
  static const greenLight = Color(0xFFDCFCE7);
  static const amber      = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFEF3C7);

  // Text
  static const navy       = Color(0xFF1E3A5F);
  static const body       = Color(0xFF374151);
  static const muted      = Color(0xFF6B7280);
  static const subtle     = Color(0xFF9CA3AF);

  // Surface
  static const white      = Colors.white;
  static const surface    = Color(0xFFF9FAFB);
  // Creme — carta, acolhimento, autenticidade
  static const cream      = Color(0xFFFFFBF5);
  static const creamBorder= Color(0xFFF0E6D3);
  static const creamDeep  = Color(0xFFE8D5B7);

  static const border     = Color(0xFFE5E7EB);

  // Radius
  static const r8  = 8.0;
  static const r12 = 12.0;
  static const r16 = 16.0;
  static const r20 = 20.0;
  static const r24 = 24.0;
  static const r99 = 99.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS HELPERS
// ─────────────────────────────────────────────────────────────────────────────

enum _ItemStatus { available, reserved, donated, fulfilled, unknown }

extension _StatusExt on _ItemStatus {
  static _ItemStatus parse(String? s) {
    switch (s) {
      case 'reserved':  return _ItemStatus.reserved;
      case 'donated':   return _ItemStatus.donated;
      case 'fulfilled': return _ItemStatus.fulfilled;
      case 'available': return _ItemStatus.available;
      default:          return s == null ? _ItemStatus.available : _ItemStatus.unknown;
    }
  }

  bool get isUnavailable =>
      this == _ItemStatus.reserved ||
      this == _ItemStatus.donated  ||
      this == _ItemStatus.fulfilled;

  // Rótulo emocional do hero badge
  String get heroBadgeLabel {
    switch (this) {
      case _ItemStatus.available: return '🎁 Disponível para doação';
      case _ItemStatus.reserved:  return '✨ Uma família já demonstrou interesse';
      case _ItemStatus.donated:   return '🎉 Esta doação já encontrou um novo lar';
      case _ItemStatus.fulfilled: return '❤️ Esta história teve um final feliz';
      default:                    return '🎁 Item compartilhado';
    }
  }

  Color get heroBadgeColor {
    switch (this) {
      case _ItemStatus.available: return _T.blue;
      case _ItemStatus.reserved:  return _T.amber;
      case _ItemStatus.donated:
      case _ItemStatus.fulfilled: return _T.green;
      default:                    return _T.muted;
    }
  }

  // Rótulo do CTA
  String get ctaLabel {
    switch (this) {
      case _ItemStatus.available: return '💙 Tenho Interesse Neste Item';
      case _ItemStatus.reserved:  return '✨ Uma família já demonstrou interesse';
      case _ItemStatus.donated:   return '🎉 Esta doação já encontrou um lar';
      case _ItemStatus.fulfilled: return '❤️ Esta história teve um final feliz';
      default:                    return '💙 Tenho Interesse Neste Item';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DONATION DETAIL PAGE
// ─────────────────────────────────────────────────────────────────────────────

class DonationDetailPage extends StatelessWidget {
  final SearchResult result;
  final String heroTag;
  final bool hideCta;
  /// true quando o usuário chegou aqui a partir do PublicProfilePage do
  /// próprio dono desta doação — evita link circular pro mesmo perfil.
  final bool hideOwnerLink;

  const DonationDetailPage({
    Key? key,
    required this.result,
    required this.heroTag,
    this.hideCta = false,
    this.hideOwnerLink = false,
  }) : super(key: key);

  static Route<void> route({
    required SearchResult result,
    required String heroTag,
    bool hideCta = false,
    bool hideOwnerLink = false,
  }) =>
      MaterialPageRoute(
        builder: (_) => DonationDetailPage(
          result: result,
          heroTag: heroTag,
          hideCta: hideCta,
          hideOwnerLink: hideOwnerLink,
        ),
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
                // 1 — Hero premium
                _HeroSliver(result: result, heroTag: heroTag),

                // 2+ — Corpo narrativo
                SliverToBoxAdapter(
                  child: _PageBody(result: result, hideOwnerLink: hideOwnerLink),
                ),

                SliverToBoxAdapter(child: SizedBox(height: hideCta ? 32 : 128)),
              ],
            ),

            // Botão voltar com blur
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: _BackButton(),
            ),

            // CTA fixo — oculto quando aberto via contexto do chat
            if (!hideCta)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: _CtaBar(result: result),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEÇÃO 1 — HERO PREMIUM
// Foto protagonista com overlay e identidade do item
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSliver extends StatelessWidget {
  final SearchResult result;
  final String heroTag;
  const _HeroSliver({required this.result, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final screenH  = MediaQuery.of(context).size.height;
    final status   = _StatusExt.parse(result.status);
    final title    = result.title?.trim()    ?? 'Sem título';
    final category = result.category?.trim() ?? '';
    final city     = result.city?.trim()     ?? '';
    final state    = result.state?.trim()    ?? '';
    final location = [
      if (city.isNotEmpty)  city,
      if (state.isNotEmpty) state,
    ].join(', ');

    return SliverToBoxAdapter(
      child: SizedBox(
        height: screenH * 0.52,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Foto
            _HeroPhoto(photoUrl: result.photoUrl, heroTag: heroTag),

            // Overlay gradiente em 4 camadas
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.30, 0.65, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.50),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),

            // Identidade do item no rodapé do hero
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status badge emocional
                  _HeroStatusBadge(status: status),
                  const SizedBox(height: 10),

                  // Título grande
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _T.white,
                      height: 1.15,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 10),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Categoria + localização em linha
                  Row(
                    children: [
                      if (category.isNotEmpty) ...[
                        _HeroPill(label: category),
                        const SizedBox(width: 8),
                      ],
                      if (location.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 12, color: Colors.white70),
                            const SizedBox(width: 3),
                            Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPhoto extends StatelessWidget {
  final String? photoUrl;
  final String heroTag;
  const _HeroPhoto({required this.photoUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Hero(
        tag: heroTag,
        child: Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, p) =>
              p == null ? child : const _PhotoPlaceholder(loading: true),
          errorBuilder: (_, __, ___) =>
              const _PhotoPlaceholder(loading: false),
        ),
      );
    }
    return const _PhotoPlaceholder(loading: false);
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final bool loading;
  const _PhotoPlaceholder({required this.loading});

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
                  strokeWidth: 2.5, color: _T.pink)
              : const Text('🎁', style: TextStyle(fontSize: 72)),
        ),
      );
}

class _HeroStatusBadge extends StatelessWidget {
  final _ItemStatus status;
  const _HeroStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: status.heroBadgeColor.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(_T.r99),
        ),
        child: Text(
          status.heroBadgeLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _T.white,
          ),
        ),
      );
}

class _HeroPill extends StatelessWidget {
  final String label;
  const _HeroPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(_T.r99),
          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _T.white,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// BACK BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
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
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE BODY — hierarquia narrativa
//
//  ① Âncora do item
//  ② MENSAGEM DO DOADOR ← DESTAQUE MÁXIMO
//  ③ Quem está doando (card de confiança)
//  ④ Impacto da doação
//  ⑤ Localização
// ─────────────────────────────────────────────────────────────────────────────

class _PageBody extends StatelessWidget {
  final SearchResult result;
  final bool hideOwnerLink;
  const _PageBody({required this.result, this.hideOwnerLink = false});

  @override
  Widget build(BuildContext context) {
    final title       = result.title?.trim()       ?? '';
    final description = result.description?.trim() ?? '';
    final ownerName   = result.ownerName?.trim()   ?? '';
    final city        = result.city?.trim()        ?? '';
    final state       = result.state?.trim()       ?? '';
    final status      = _StatusExt.parse(result.status);

    final location = [
      if (city.isNotEmpty)  city,
      if (state.isNotEmpty) state,
    ].join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ① Âncora — oportunidade / percepção de valor
        _OpportunityAnchor(title: title, status: status),

        // ② Mensagem do doador — destaque máximo
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
          _DonorMessageSection(
            description: description,
            ownerName: ownerName,
          ),
        ],

        // ③ Quem está doando
        // Mostra o card sempre que houver pelo menos o ownerId — mesmo sem
        // ownerName/ownerPhotoUrl, o _DonorCard busca o fallback em
        // UsersPublic/{ownerId} (mesmo nó usado pelo PublicProfilePage).
        if (ownerName.isNotEmpty || (result.ownerId?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _DonorCard(result: result, disableLink: hideOwnerLink),
          ),
        ],

        // ④ Impacto
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const _ImpactSection(),
        ),

        // ⑤ Localização
        if (location.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _LocationCard(location: location),
          ),
        ],

        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ① ÂNCORA — OPORTUNIDADE
// Primeiro texto após o hero — gera percepção de valor, não de descarte
// ─────────────────────────────────────────────────────────────────────────────

class _OpportunityAnchor extends StatelessWidget {
  final String title;
  final _ItemStatus status;
  const _OpportunityAnchor({required this.title, required this.status});

  String get _headline {
    switch (status) {
      case _ItemStatus.reserved:
        return '✨ Uma família já demonstrou interesse';
      case _ItemStatus.donated:
      case _ItemStatus.fulfilled:
        return '🎉 Este item encontrou um novo lar';
      default:
        return '✨ Este item pode ganhar uma nova história';
    }
  }

  String _subline(String t) {
    final name = t.isNotEmpty ? t.toLowerCase() : 'este item';
    return switch (status) {
      _ItemStatus.reserved  => 'Alguém já viu valor neste presente. Fique atento a outros itens disponíveis.',
      _ItemStatus.donated   => 'A generosidade desta família criou uma nova memória especial.',
      _ItemStatus.fulfilled => 'A corrente do bem continua. Este item transformou uma história.',
      _ItemStatus.available => 'Um $name em bom estado esperando por quem vai criar novas memórias.',
      // TODO: Handle this case.
      _ItemStatus.unknown => throw UnimplementedError(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.blueLight,
        borderRadius: BorderRadius.circular(_T.r20),
        border: Border.all(color: _T.blueBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _headline,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _T.navy,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _subline(title),
            style: const TextStyle(
              fontSize: 14,
              color: _T.body,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ② MENSAGEM DO DOADOR — SEÇÃO PRINCIPAL
// Aparência de carta / depoimento real
// ─────────────────────────────────────────────────────────────────────────────

class _DonorMessageSection extends StatelessWidget {
  final String description;
  final String ownerName;
  const _DonorMessageSection({
    required this.description,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label badge
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
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
                  'Mensagem do doador',
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
        ),

        const SizedBox(height: 12),

        // Card carta
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
              // Faixa tricolor de topo
              Container(
                height: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFD6E7),
                      Color(0xFFBFDBFE),
                      Color(0xFFBBF7D0),
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
                    // Aspas decorativas
                    _OpeningQuote(),

                    const SizedBox(height: 10),

                    // Relato do doador — tipografia editorial
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
                        Container(width: 32, height: 1, color: _T.creamDeep),
                        const SizedBox(width: 10),
                        const Text('✦',
                            style: TextStyle(fontSize: 10, color: _T.creamDeep)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(height: 1, color: _T.creamDeep),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Assinatura do doador
                    _DonorSignature(ownerName: ownerName),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Nota de autenticidade
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, size: 13, color: _T.blue),
              const SizedBox(width: 5),
              Text(
                'Mensagem real escrita pelo doador',
                style: const TextStyle(
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

class _OpeningQuote extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"',
            style: TextStyle(
              fontSize: 80,
              height: 0.6,
              fontWeight: FontWeight.w900,
              color: _T.blue.withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '"',
              style: TextStyle(
                fontSize: 48,
                height: 0.6,
                fontWeight: FontWeight.w900,
                color: _T.blue.withValues(alpha: 0.10),
              ),
            ),
          ),
        ],
      );
}

class _DonorSignature extends StatelessWidget {
  final String ownerName;
  const _DonorSignature({required this.ownerName});

  @override
  Widget build(BuildContext context) {
    final initials = ownerName.isNotEmpty
        ? ownerName.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';
    final displayName = ownerName.isNotEmpty ? ownerName : 'o doador';

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _T.blueLight,
            shape: BoxShape.circle,
            border: Border.all(color: _T.blueBorder, width: 1.5),
          ),
          child: Center(
            child: Text(
              initials.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _T.blue,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _T.navy,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.volunteer_activism_rounded,
                    size: 11, color: _T.pink),
                const SizedBox(width: 4),
                const Text(
                  'Compartilhando com carinho',
                  style: TextStyle(
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
// ③ QUEM ESTÁ DOANDO — card de confiança
// ─────────────────────────────────────────────────────────────────────────────

class _DonorCard extends StatefulWidget {
  final SearchResult result;
  /// true quando o usuário chegou aqui a partir do PublicProfilePage do
  /// próprio doador — evita link circular pro mesmo perfil.
  final bool disableLink;
  const _DonorCard({required this.result, this.disableLink = false});

  @override
  State<_DonorCard> createState() => _DonorCardState();
}

class _DonorCardState extends State<_DonorCard> {
  // Valores efetivos exibidos — começam com o que já veio no SearchResult
  // e são completados pelo fallback caso estejam vazios.
  late String? _name = widget.result.ownerName?.trim();
  late String? _photoUrl = widget.result.ownerPhotoUrl?.trim();
  late String? _city = widget.result.city?.trim();
  bool _loadingFallback = false;

  String get _ownerId => widget.result.ownerId ?? '';

  bool get _needsFallback =>
      _ownerId.isNotEmpty && ((_name == null || _name!.isEmpty));

  @override
  void initState() {
    super.initState();
    if (_needsFallback) _fetchFallback();
  }

  /// 🔧 FIX: alguns DonationModel/SearchResult chegam sem `ownerName`/
  /// `ownerPhotoUrl` (ex.: doações legadas, ou SearchResult montado via
  /// `SearchResult.fromDonation` antes da correção). Em vez de esconder o
  /// card, buscamos o mesmo nó público que o PublicProfilePage usa.
  Future<void> _fetchFallback() async {
    setState(() => _loadingFallback = true);
    try {
      final snap =
          await FirebaseDatabase.instance.ref('UsersPublic/$_ownerId').get();
      if (!mounted) return;
      if (snap.exists && snap.value is Map) {
        final m = Map<dynamic, dynamic>.from(snap.value as Map);
        setState(() {
          _name = (m['name']?.toString().trim().isNotEmpty ?? false)
              ? m['name'].toString().trim()
              : _name;
          _photoUrl = (m['profileImage']?.toString().trim().isNotEmpty ?? false)
              ? m['profileImage'].toString().trim()
              : _photoUrl;
          _city = (m['city']?.toString().trim().isNotEmpty ?? false)
              ? m['city'].toString().trim()
              : _city;
        });
      }
    } catch (_) {
      // Silencioso — card cai no estado "doador" genérico abaixo.
    } finally {
      if (mounted) setState(() => _loadingFallback = false);
    }
  }

  void _openProfile() {
    if (widget.disableLink) return;
    if (_ownerId.isEmpty) return;
    Navigator.push(
      context,
      PublicProfilePage.route(
        uid: _ownerId,
        fallbackName: _name,
        fallbackImage: _photoUrl,
        fallbackCity: _city,
        fallbackState: widget.result.state,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerName = _name?.trim() ?? '';
    final city = _city?.trim() ?? '';
    final hasOwnerId = _ownerId.isNotEmpty && !widget.disableLink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(emoji: '🤝', label: 'Quem está doando'),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: hasOwnerId ? _openProfile : null,
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
                  backgroundImage: (_photoUrl?.isNotEmpty ?? false)
                      ? NetworkImage(_photoUrl!)
                      : null,
                  child: (_photoUrl?.isNotEmpty ?? false)
                      ? null
                      : (_loadingFallback
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _T.pink,
                              ),
                            )
                          : Text(
                              ownerName.isNotEmpty
                                  ? ownerName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _T.pink,
                              ),
                            )),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerName.isNotEmpty
                            ? ownerName
                            : (_loadingFallback
                                ? 'Carregando...'
                                : 'Doador da comunidade'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _T.navy,
                        ),
                      ),
                      if (city.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 12, color: _T.subtle),
                            const SizedBox(width: 3),
                            Text(
                              city,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _T.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
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
                if (hasOwnerId)
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
// ④ IMPACTO
// ─────────────────────────────────────────────────────────────────────────────

class _ImpactSection extends StatelessWidget {
  const _ImpactSection();

  static const _items = [
    _ImpactItem(emoji: '🎮', text: 'Brincar e criar novas memórias'),
    _ImpactItem(emoji: '📚', text: 'Aprender e se desenvolver'),
    _ImpactItem(emoji: '🌟', text: 'Ganhar algo especial'),
    _ImpactItem(emoji: '❤️', text: 'Sentir o calor da generosidade'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          emoji: '🎁',
          label: 'Esta doação pode ajudar outra criança a:',
        ),
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
                color: _T.blueLight,
                borderRadius: BorderRadius.circular(_T.r12),
                border: Border.all(color: _T.blueBorder),
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
// ⑤ LOCALIZAÇÃO
// ─────────────────────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final String location;
  const _LocationCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(emoji: '📍', label: 'Onde está o item'),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(_T.r16),
            border: Border.all(color: _T.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _T.blueLight,
                  borderRadius: BorderRadius.circular(_T.r12),
                  border: Border.all(color: _T.blueBorder),
                ),
                child: const Center(
                  child: Text('🗺️', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Localização',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _T.subtle,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _T.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
// CTA BAR — acolhedor, não comercial
// ─────────────────────────────────────────────────────────────────────────────

class _CtaBar extends StatelessWidget {
  final SearchResult result;
  const _CtaBar({required this.result});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final status    = _StatusExt.parse(result.status);

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
          if (!status.isUnavailable)
            Text(
              'Você pode ser a próxima parte desta história.',
              style: const TextStyle(
                fontSize: 12,
                color: _T.muted,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          if (!status.isUnavailable) const SizedBox(height: 10),
          _CtaButton(status: status, result: result),
        ],
      ),
    );
  }
}

class _CtaButton extends StatefulWidget {
  final _ItemStatus status;
  final SearchResult result;
  const _CtaButton({required this.status, required this.result});

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

  void _showUnavailableDialog() {
    final isDonated = widget.status == _ItemStatus.donated ||
        widget.status == _ItemStatus.fulfilled;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_T.r20),
        ),
        backgroundColor: _T.white,
        title: Text(
          isDonated ? '🎉 Doação Concluída!' : '✨ Item Reservado',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _T.navy,
          ),
        ),
        content: Text(
          isDonated
              ? 'Este item já encontrou um novo lar. '
                'Que tal explorar outras doações disponíveis?'
              : 'Uma família já demonstrou interesse neste item e ele está reservado. '
                'Fique de olho — outros itens incríveis aparecem por aqui!',
          style: const TextStyle(
            fontSize: 14,
            color: _T.body,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendi',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _T.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _down(TapDownDetails _) {
    if (!widget.status.isUnavailable) _ctrl.reverse();
  }

  void _up(TapUpDetails _) {
    _ctrl.forward();
    if (widget.status.isUnavailable) {
      _showUnavailableDialog();
      return;
    }
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
                ? 'Não foi possível identificar o doador.'
                : 'Esta é a sua própria doação!',
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

    // Busca dados do perfil do doador antes de abrir o chat
    final userInfo = await ChatRepository.instance.fetchUserInfo(ownerId);
    if (!mounted) return;

    final chatId = ChatModel.buildId(myUid, ownerId);

    // Bloqueia entrar num contexto NOVO se já existe uma confirmação de
    // entrega pendente e sem resposta com essa mesma pessoa — precisa
    // resolver isso primeiro, não dá pra simplesmente abrir outra
    // negociação e "fugir" do pedido pendente.
    final hasPending =
        await ChatRepository.instance.hasPendingDeliveryRequest(chatId);
    if (!mounted) return;
    if (hasPending) {
      await showPendingConfirmationDialog(
        context,
        onGoToPendingChat: () async {
          final sorted = ([myUid, ownerId]..sort());
          final pendingChat = ChatModel(
            chatId: chatId,
            user1: sorted[0],
            user2: sorted[1],
            otherUid: ownerId,
            otherName: userInfo['name'] ?? widget.result.ownerName,
            otherAvatar: userInfo['profileImage'] ?? widget.result.ownerPhotoUrl,
            otherEmoji: userInfo['profileEmoji'],
          );
          if (!mounted) return;
          Navigator.push(
            context,
            ChatPage.route(myUid: myUid, chat: pendingChat),
          );
        },
      );
      return;
    }

    final sorted  = ([myUid, ownerId]..sort());
    final chat = ChatModel(
      chatId: chatId,
      user1:  sorted[0],
      user2:  sorted[1],
      otherUid: ownerId,
      origin: ChatOrigin.donation,
      itemId: widget.result.id,
      itemTitle: widget.result.title,
      itemType: 'donation',
      otherName: userInfo['name'] ?? widget.result.ownerName,
      otherAvatar: userInfo['profileImage'] ?? widget.result.ownerPhotoUrl,
      otherEmoji: userInfo['profileEmoji'],
    );

    Navigator.push(context, ChatPage.route(myUid: myUid, chat: chat, fromDetail: true));
  }

  Color get _bgColor {
    if (widget.status.isUnavailable) return const Color(0xFFE5E7EB);
    return _T.blue;
  }

  Color get _fgColor {
    if (widget.status.isUnavailable) return _T.muted;
    return _T.white;
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
            color: widget.status.isUnavailable ? null : null,
            gradient: widget.status.isUnavailable
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(_T.r16),
            boxShadow: widget.status.isUnavailable
                ? null
                : [
                    BoxShadow(
                      color: _T.blue.withValues(alpha: 0.32),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              widget.status.ctaLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
                color: _fgColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
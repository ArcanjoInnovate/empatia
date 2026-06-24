import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/search/controller/search_controller.dart'
    show SearchResult;
import 'package:flutter/material.dart';

/// 📦 DONATION DETAIL PAGE
///
/// Exibe todos os dados de uma doação com layout emocional:
///   - Hero da foto (50% da tela)
///   - Badges de status e categoria sobrepostos
///   - Título, localização, descrição
///   - Avatar + nome do doador (social proof)
///   - CTA fixo no rodapé: "Tenho Interesse"
class DonationDetailPage extends StatelessWidget {
  final SearchResult result;
  final String heroTag;

  const DonationDetailPage({
    Key? key,
    required this.result,
    required this.heroTag,
  }) : super(key: key);

  static Route<void> route({
    required SearchResult result,
    required String heroTag,
  }) =>
      MaterialPageRoute(
        builder: (_) =>
            DonationDetailPage(result: result, heroTag: heroTag),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Conteúdo rolável ────────────────────────────────────────
          CustomScrollView(
            slivers: [
              _HeroSliver(result: result, heroTag: heroTag),
              SliverToBoxAdapter(
                child: _DonationBody(result: result),
              ),
              // Espaço para o CTA fixo não cobrir conteúdo
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // ── Botão voltar flutuante ──────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _BackButton(),
          ),

          // ── CTA fixo no rodapé ──────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _CtaBar(result: result),
          ),
        ],
      ),
    );
  }
}

// ── Hero da foto ──────────────────────────────────────────────────────────────

class _HeroSliver extends StatelessWidget {
  final SearchResult result;
  final String heroTag;
  const _HeroSliver({required this.result, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: screenH * 0.50,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Foto
            _PhotoBackground(photoUrl: result.photoUrl, heroTag: heroTag),

            // Gradiente inferior
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.50, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),

            // Badge de categoria (topo esquerdo)
            if (result.category != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56,
                left: 16,
                child: _CategoryBadge(category: result.category!),
              ),

            // Badge de status (topo direito)
            if (_showStatus(result.status))
              Positioned(
                top: MediaQuery.of(context).padding.top + 56,
                right: 16,
                child: _StatusBadge(status: result.status),
              ),
          ],
        ),
      ),
    );
  }

  bool _showStatus(String? status) =>
      status != null && status.isNotEmpty && status != 'available';
}

class _PhotoBackground extends StatelessWidget {
  final String? photoUrl;
  final String heroTag;
  const _PhotoBackground({required this.photoUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null) {
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
        color: const Color(0xFFFFF0F6),
        child: Center(
          child: loading
              ? CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.kidsPink)
              : const Text('🎁', style: TextStyle(fontSize: 52)),
        ),
      );
}

// ── Corpo da página ───────────────────────────────────────────────────────────

class _DonationBody extends StatelessWidget {
  final SearchResult result;
  const _DonationBody({required this.result});

  @override
  Widget build(BuildContext context) {
    final city = result.city ?? '';
    final state = result.state ?? '';
    final location = [
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            result.title ?? 'Sem título',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryBlue,
              height: 1.2,
            ),
          ),

          // Localização
          if (location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          // Divider
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 20),

          // Descrição
          if (result.description != null &&
              result.description!.isNotEmpty) ...[
            const Text(
              'Sobre o item',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                result.description!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Doador
          if (result.ownerName != null) ...[
            const Text(
              'Quem está doando',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 10),
            _OwnerRow(
              ownerName: result.ownerName!,
              ownerPhotoUrl: result.ownerPhotoUrl,
              city: city,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Doador ────────────────────────────────────────────────────────────────────

class _OwnerRow extends StatelessWidget {
  final String ownerName;
  final String? ownerPhotoUrl;
  final String city;
  const _OwnerRow({
    required this.ownerName,
    required this.ownerPhotoUrl,
    required this.city,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.kidsPink.withValues(alpha: 0.15),
          backgroundImage:
              ownerPhotoUrl != null ? NetworkImage(ownerPhotoUrl!) : null,
          child: ownerPhotoUrl == null
              ? Text(
                  ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.kidsPink,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ownerName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryBlue,
              ),
            ),
            if (city.isNotEmpty)
              Text(
                city,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Badges ────────────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          category,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryBlue,
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
}

// ── Botão voltar ──────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      );
}

// ── CTA fixo ──────────────────────────────────────────────────────────────────

class _CtaBar extends StatelessWidget {
  final SearchResult result;
  const _CtaBar({required this.result});

  bool get _isUnavailable =>
      result.status == 'donated' ||
      result.status == 'fulfilled' ||
      result.status == 'reserved';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _isUnavailable ? null : () => _onInterest(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.kidsPink,
            disabledBackgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.white,
            disabledForegroundColor: AppTheme.textMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            _isUnavailable
                ? _unavailableLabel
                : '❤️ Tenho Interesse',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  String get _unavailableLabel {
    switch (result.status) {
      case 'reserved':
        return 'Item Reservado';
      case 'donated':
      case 'fulfilled':
        return 'Item já Doado';
      default:
        return 'Indisponível';
    }
  }

  void _onInterest(BuildContext context) {
    // TODO: implementar fluxo de interesse (chat / reserva)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Em breve você poderá entrar em contato com o doador!'),
        backgroundColor: AppTheme.kidsPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
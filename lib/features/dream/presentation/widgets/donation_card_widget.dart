import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/donation/controller/donation_controller.dart';
import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS LOCAIS
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _K {
  static const pink     = AppTheme.kidsPink;
  static const navy     = AppTheme.primaryBlue;
  static const green    = AppTheme.kidsGreenDeep;
  static const amber    = AppTheme.donationReservedColor;
  static const r16 = 16.0;
  static const r20 = 20.0;
  static const r99 = 99.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// LINHA SUPERIOR "SEGURA" — evita overflow entre os badges do topo
// ─────────────────────────────────────────────────────────────────────────────

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
// 🎁 DONATION CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────
//
// Card full-bleed no mesmo espírito dos cards de busca/feed:
///   1. Foto (ou placeholder gradiente) ocupando o card inteiro
///   2. Scrim inferior para legibilidade do texto
///   3. Badge de categoria (topo-esquerda) + menu de edição (topo-direita)
///   4. Rodapé: título, microcopy emocional, status
class DonationCardWidget extends StatelessWidget {
  final DonationModel donation;
  final VoidCallback onEdit;

  const DonationCardWidget({
    Key? key,
    required this.donation,
    required this.onEdit,
  }) : super(key: key);

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _DonationFullscreenView(
          donation: donation,
          onEdit: onEdit,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  static const _copies = [
    '💙 Disponível para uma nova família',
    '✨ Pode ganhar uma nova história',
    '🎁 Compartilhado com carinho',
    '💛 Em busca de um novo lar',
    '🌟 Uma oportunidade especial',
  ];

  String _microcopy(String? id, String status) {
    switch (status) {
      case 'reserved':
        return '✨ Uma família demonstrou interesse';
      case 'donated':
        return '🎉 Este item encontrou um novo lar';
      default:
        final idx = ((id?.codeUnits.fold(0, (a, b) => a + b) ?? 0) + 1) % _copies.length;
        return _copies[idx];
    }
  }

  @override
  Widget build(BuildContext context) {
    final catLabel = DonationModel.categoryLabel(donation.category);
    final emoji = donation.emoji ?? DonationModel.categoryEmoji(donation.category);

    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Hero(
          tag: 'donation_image_${donation.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Foto ou placeholder ────────────────────────────────
              donation.photoUrl != null
                  ? Image.network(
                      donation.photoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, p) =>
                          p == null ? child : _Placeholder(emoji: emoji, loading: true),
                      errorBuilder: (_, __, ___) => _Placeholder(emoji: emoji, loading: false),
                    )
                  : _Placeholder(emoji: emoji, loading: false),

              // ── Scrim ───────────────────────────────────────────────
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.42, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),

              // ── Topo: categoria + menu de edição ──────────────────
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: _SafeTopRow(
                  left: _CategoryBadge(emoji: emoji, label: catLabel),
                  right: _EditMenuButton(donation: donation, onEdit: onEdit),
                ),
              ),

              // ── Badge de status (abaixo da categoria, esquerda) ───
              if (donation.status != 'available')
                Positioned(
                  top: 44,
                  left: 10,
                  child: _StatusBadge(status: donation.status),
                ),

              // ── Rodapé: título + microcopy ────────────────────────
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _microcopy(donation.id, donation.status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      donation.title ?? 'Sem título',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 8),
                          Shadow(color: Colors.black26, blurRadius: 2),
                        ],
                      ),
                    ),
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

class _Placeholder extends StatelessWidget {
  final String emoji;
  final bool loading;
  const _Placeholder({required this.emoji, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE3EF), Color(0xFFF3E8FF)],
        ),
      ),
      child: Center(
        child: loading
            ? const CircularProgressIndicator(strokeWidth: 2, color: _K.pink)
            : Text(emoji, style: const TextStyle(fontSize: 44)),
      ),
    );
  }
}

// ── Badge de categoria (topo-esquerda) ───────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String emoji;
  final String label;
  const _CategoryBadge({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(_K.r99),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: _K.pink,
              ),
            ),
          ],
        ),
      );
}

// ── Badge de status (disponível/reservado/doado) ─────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'reserved': return _K.amber;
      case 'donated':  return _K.green;
      default:         return _K.pink;
    }
  }

  String get _label {
    switch (status) {
      case 'reserved': return '✨ Reservado';
      case 'donated':  return '🎉 Doado';
      default:         return DonationModel.statusLabel(status);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(_K.r99),
          boxShadow: [
            BoxShadow(color: _color.withValues(alpha: 0.35), blurRadius: 6),
          ],
        ),
        child: Text(
          _label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
}

// ── Menu de edição (flutuante, topo-direita) ─────────────────────────────────

class _EditMenuButton extends StatelessWidget {
  final DonationModel donation;
  final VoidCallback onEdit;
  const _EditMenuButton({required this.donation, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<DonationController>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (value) {
          HapticFeedback.lightImpact();
          if (value == 'edit') {
            onEdit();
          } else if (value == 'delete') {
            _confirmDelete(context, ctrl);
          } else if (value.startsWith('status_')) {
            final newStatus = value.replaceFirst('status_', '');
            ctrl.updateStatus(donation.id!, newStatus);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              const Icon(Icons.edit_rounded, size: 16, color: _K.pink),
              const SizedBox(width: 10),
              const Text('Editar'),
            ]),
          ),
          const PopupMenuDivider(),
          if (donation.status != 'available')
            PopupMenuItem(
              value: 'status_available',
              child: Row(children: [
                const Icon(Icons.check_circle_outline, size: 16, color: _K.pink),
                const SizedBox(width: 10),
                const Text('Marcar disponível'),
              ]),
            ),
          if (donation.status != 'reserved')
            PopupMenuItem(
              value: 'status_reserved',
              child: Row(children: [
                const Icon(Icons.schedule_rounded, size: 16, color: _K.amber),
                const SizedBox(width: 10),
                const Text('Marcar reservado'),
              ]),
            ),
          if (donation.status != 'donated')
            PopupMenuItem(
              value: 'status_donated',
              child: Row(children: [
                const Icon(Icons.favorite_rounded, size: 16, color: _K.green),
                const SizedBox(width: 10),
                const Text('Marcar doado'),
              ]),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
              SizedBox(width: 10),
              Text('Remover', style: TextStyle(color: Colors.red)),
            ]),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DonationController ctrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remover doação?'),
        content: Text(
            'Tem certeza que deseja remover "${donation.title ?? "este item"}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.deleteDonation(donation.id!, photoUrl: donation.photoUrl);
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Fullscreen view ───────────────────────────────────────────────────────────

class _DonationFullscreenView extends StatelessWidget {
  final DonationModel donation;
  final VoidCallback onEdit;

  const _DonationFullscreenView({
    required this.donation,
    required this.onEdit,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'reserved': return _K.amber;
      case 'donated':  return _K.green;
      default:         return _K.pink;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: 'donation_image_${donation.id}',
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: donation.photoUrl != null
                    ? Image.network(
                        donation.photoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _fullscreenPlaceholder(),
                      )
                    : _fullscreenPlaceholder(),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24, 20, 24, MediaQuery.of(context).padding.bottom + 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          donation.title ?? 'Sem título',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              donation.emoji ?? DonationModel.categoryEmoji(donation.category),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DonationModel.categoryLabel(donation.category),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor(donation.status),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                DonationModel.statusLabel(donation.status),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onEdit();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5C8D), Color(0xFFE0457A)],
                        ),
                        borderRadius: BorderRadius.circular(_K.r99),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Editar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullscreenPlaceholder() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE3EF), Color(0xFFF3E8FF)],
        ),
      ),
      child: Center(
        child: Text(donation.emoji ?? '📦', style: const TextStyle(fontSize: 80)),
      ),
    );
  }
}
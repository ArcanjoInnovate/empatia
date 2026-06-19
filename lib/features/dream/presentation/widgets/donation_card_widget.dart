import 'package:empatia/features/donation/controller/donation_controller.dart';
import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _purple = Color(0xFF8B5CF6);
const _pink   = Color(0xFFFF6B9D);
const _navy   = Color(0xFF1E3A8A);
const _green  = Color(0xFF22C55E);
const _bg     = Color(0xFFF7F8FC);

class DonationCardWidget extends StatelessWidget {
  final DonationModel donation;
  final VoidCallback onEdit;

  const DonationCardWidget({
    required this.donation,
    required this.onEdit,
  });

  // ── Abre o fullscreen da imagem ──────────────────────────────────────
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
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCE7F3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _pink.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Imagem + badges ──────────────────────────────────────────
          Stack(
            children: [
              // ✅ GestureDetector abre o fullscreen ao tocar na imagem
              GestureDetector(
                onTap: () => _openFullscreen(context),
                child: Hero(
                  tag: 'donation_image_${donation.id}',
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: donation.photoUrl != null
                          ? Image.network(
                              donation.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _placeholderImage(),
                            )
                          : _placeholderImage(),
                    ),
                  ),
                ),
              ),

              // Badge de status (canto superior direito)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
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
              ),

              // Menu de edição (canto superior esquerdo)
              Positioned(
                top: 8,
                left: 8,
                child: _EditMenu(donation: donation, onEdit: onEdit),
              ),
            ],
          ),

          // ── Info ─────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.title ?? 'Sem título',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        donation.emoji ??
                            DonationModel.categoryEmoji(donation.category),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          DonationModel.categoryLabel(donation.category),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFFFCE7F3),
      child: Center(
        child: Text(
          donation.emoji ?? '📦',
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'reserved':
        return const Color(0xFFF59E0B);
      case 'donated':
        return _green;
      default:
        return _pink;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Imagem centralizada com Hero ─────────────────────────────
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

          // ── Botão fechar (topo esquerdo) ─────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          // ── Painel inferior com info + botão editar ──────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  // Info
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
                              donation.emoji ??
                                  DonationModel.categoryEmoji(
                                      donation.category),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DonationModel.categoryLabel(donation.category),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Badge status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
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

                  // Botão editar
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onEdit();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [_pink, Color(0xFFFF8FB3)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded,
                              color: Colors.white, size: 16),
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
      color: const Color(0xFFFCE7F3),
      child: Center(
        child: Text(
          donation.emoji ?? '📦',
          style: const TextStyle(fontSize: 80),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'reserved':
        return const Color(0xFFF59E0B);
      case 'donated':
        return _green;
      default:
        return _pink;
    }
  }
}

// ── Menu de edição ────────────────────────────────────────────────────────────

class _EditMenu extends StatelessWidget {
  final DonationModel donation;
  final VoidCallback onEdit;

  const _EditMenu({required this.donation, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<DonationController>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert_rounded,
            color: Colors.grey.shade600, size: 18),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (value) {
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
          const PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              Icon(Icons.edit_rounded, size: 16, color: _pink),
              SizedBox(width: 10),
              Text('Editar'),
            ]),
          ),
          const PopupMenuDivider(),
          if (donation.status != 'available')
            const PopupMenuItem(
              value: 'status_available',
              child: Row(children: [
                Icon(Icons.check_circle_outline, size: 16, color: _pink),
                SizedBox(width: 10),
                Text('Marcar disponível'),
              ]),
            ),
          if (donation.status != 'reserved')
            const PopupMenuItem(
              value: 'status_reserved',
              child: Row(children: [
                Icon(Icons.schedule_rounded,
                    size: 16, color: Color(0xFFF59E0B)),
                SizedBox(width: 10),
                Text('Marcar reservado'),
              ]),
            ),
          if (donation.status != 'donated')
            const PopupMenuItem(
              value: 'status_donated',
              child: Row(children: [
                Icon(Icons.favorite_rounded, size: 16, color: _green),
                SizedBox(width: 10),
                Text('Marcar doado'),
              ]),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline_rounded,
                  size: 16, color: Colors.red),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            child:
                const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
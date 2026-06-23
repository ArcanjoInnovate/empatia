import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/dream/presentation/pages/full_screen_image_page.dart';
import 'package:empatia/features/search/controller/search_controller.dart'
    show SearchResult;
import 'package:flutter/material.dart';

/// 🔍 SEARCH RESULT CARD
///
/// Card unificado para resultados de donation e dream.
/// Exibe foto, título, localização, badge de tipo e badge de status.
class SearchResultCard extends StatelessWidget {
  final SearchResult result;

  const SearchResultCard({Key? key, required this.result}) : super(key: key);

  bool get _isDonation => result.type == 'donation';

  Color get _typeColor =>
      _isDonation ? AppTheme.kidsPink : AppTheme.kidsCyan ?? AppTheme.primaryBlue;

  String get _typeLabel => _isDonation ? '🎁 Doação' : '⭐ Sonho';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE4F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kidsPink.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardImage(result: result, typeColor: _typeColor, typeLabel: _typeLabel),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  result.title ?? 'Sem título',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryBlue,
                    height: 1.3,
                  ),
                ),

                // Localização
                if ((result.city ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          [result.city, result.state]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade400,
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
    );
  }
}

// ── Imagem com badges ─────────────────────────────────────────────────────────

class _CardImage extends StatelessWidget {
  final SearchResult result;
  final Color typeColor;
  final String typeLabel;

  const _CardImage({
    required this.result,
    required this.typeColor,
    required this.typeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final heroTag = 'search_${result.type}_${result.id}';

    Widget image;
    if (result.photoUrl != null) {
      image = Hero(
        tag: heroTag,
        child: Image.network(
          result.photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    } else {
      image = _placeholder();
    }

    return GestureDetector(
      onTap: result.photoUrl != null
          ? () => Navigator.push(
                context,
                FullscreenImagePage.route(
                  imageUrl: result.photoUrl!,
                  heroTag: heroTag,
                  title: result.title,
                ),
              )
          : null,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
            child: AspectRatio(aspectRatio: 1, child: image),
          ),

          // Badge tipo (donation / dream) — canto superior esquerdo
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                typeLabel,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Badge status — canto superior direito (só se tiver)
          if (result.status != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(result.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(result.status),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.donationPlaceholderBg,
      child: const Center(
        child: Text('📦', style: TextStyle(fontSize: 36)),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'reserved':
        return AppTheme.donationReservedColor;
      case 'donated':
      case 'fulfilled':
        return AppTheme.kidsGreenDeep;
      default:
        return Colors.grey.shade400;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'available':
        return 'Disponível';
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
}
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/features/profile/presentation/widgets/profile/profile_children_widget.dart';
import 'package:empatia/features/profile/presentation/widgets/profile/profile_dreams_widget.dart';
import 'package:empatia/features/profile/presentation/widgets/profile/profile_shared_widgets.dart';
import 'package:flutter/material.dart';

// ─── Design tokens ────────────────────────────────────────────────────────
const _pink   = Color(0xFFFF6B9D);
const _navy   = Color(0xFF1E3A8A);
const _bg     = Color(0xFFF7F8FC);
const _purple = Color(0xFF8B5CF6);

/// 💚 DONOR PROFILE BODY
///
/// Corpo da tela exibido quando activeMode == "donor".
/// Exibe: banner motivacional, filhos e sonhos.
/// O doador vê o que tem disponível na tela de feed — aqui é só o perfil dele.
class ProfileDonorBody extends StatelessWidget {
  final UserModel user;
  const ProfileDonorBody({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),

          // ── Banner motivacional ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _DonorBannerWidget(user: user),
          ),

          const SizedBox(height: 24),

          // ── Divisor ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(height: 1, color: const Color(0xFFEEEEEE)),
          ),
          const SizedBox(height: 24),

          // ── Filhos ──
          ProfileSectionWidget(
            emoji: '👨‍👩‍👧‍👦',
            title: 'Meus Filhos',
            count: user.children?.length,
            child: ProfileChildrenWidget(children: user.children),
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(height: 1, color: const Color(0xFFEEEEEE)),
          ),
          const SizedBox(height: 8),

          // ── Sonhos ──
          ProfileSectionWidget(
            emoji: '💭',
            title: 'Meus Sonhos',
            count: user.dreams?.length,
            child: ProfileDreamsWidget(dreams: user.dreams),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Banner motivacional ──────────────────────────────────────────────────────

class _DonorBannerWidget extends StatelessWidget {
  final UserModel user;
  const _DonorBannerWidget({required this.user});

  @override
  Widget build(BuildContext context) {
    // Localização formatada
    final location = [
      if (user.neighborhood != null) user.neighborhood,
      if (user.city != null) user.city,
      if (user.state != null) user.state,
    ].join(', ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0F6), Color(0xFFF3EEFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _pink.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_pink, _purple]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.volunteer_activism_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Modo Doador Ativo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Você está fazendo a diferença! 💛',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No feed, você vê os pedidos de doação próximos a você e pode ajudar quem precisa.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: _pink, size: 15),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
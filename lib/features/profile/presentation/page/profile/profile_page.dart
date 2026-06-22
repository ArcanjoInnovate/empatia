import 'package:empatia/features/donation/controller/donation_controller.dart';
import 'package:empatia/features/request/controller/request_controller.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/features/profile/controller/profile_controller.dart';
import 'package:empatia/features/profile/presentation/widgets/profile/profile_children_widget.dart';
import 'package:empatia/features/profile/presentation/widgets/profile/profile_dreams_widget.dart';
import 'package:empatia/features/profile/presentation/widgets/profile/profile_header_widget.dart';
import 'package:empatia/features/profile/presentation/widgets/profile/profile_shared_widgets.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 👤 PROFILE PAGE
///
/// Perfil unificado — o mesmo usuário pode DOAR e RECEBER.
/// Não há mais modo "donor" vs "receiver".
///
/// Seções:
///   1. Header (avatar, nome, status, localização)
///   2. Resumo de atividade (contadores dinâmicos)
///   3. O que estou oferecendo (Donations)
///   4. Meus pedidos (Requests)
///   5. Meus Filhos
///   6. Meus Sonhos
class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ProfileController>();

    return StreamBuilder<UserModel?>(
      stream: controller.userStream,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user == null) {
          return const Scaffold(
            backgroundColor: AppTheme.profileBackground,
            body: Center(child: CircularProgressIndicator(color: AppTheme.kidsPink)),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.profileBackground,
          body: CustomScrollView(
            slivers: [
              // ── Header com avatar, nome, meta e status ──
              ProfileHeaderWidget(user: user),

              // ── Body ──
              SliverToBoxAdapter(
                child: _ProfileBody(user: user),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final UserModel user;
  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.profileBody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),

          // ── Contadores de atividade ──
          _ActivitySummary(user: user),

          _divider(),
          const SizedBox(height: 8),

          // ── Filhos ──
          ProfileSectionWidget(
            emoji: '👨‍👩‍👧‍👦',
            title: 'Meus Filhos',
            count: user.children?.length,
            child: ProfileChildrenWidget(children: user.children),
          ),

          const SizedBox(height: 8),
          _divider(),
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

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(height: 1, color: AppTheme.dividerColor),
      );
}

// ── Resumo de atividade ───────────────────────────────────────────────────────

/// Três cards com contadores: ofertas ativas, pedidos abertos, filhos.
class _ActivitySummary extends StatelessWidget {
  final UserModel user;
  const _ActivitySummary({required this.user});

  @override
  Widget build(BuildContext context) {
    final donationCtrl = context.read<DonationController>();
    final requestCtrl  = context.read<RequestController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Ofertas ativas
          Expanded(
            child: StreamBuilder(
              stream: donationCtrl.watchMyDonations(),
              builder: (_, snap) {
                final count = (snap.data ?? [])
                    .where((d) => d.status == 'available')
                    .length;
                return _SummaryCard(
                  emoji: '🎁',
                  count: count,
                  label: 'Ofertas\nativas',
                  color: AppTheme.kidsPink,
                );
              },
            ),
          ),
          const SizedBox(width: 10),

          // Pedidos abertos
          Expanded(
            child: StreamBuilder(
              stream: requestCtrl.watchMyRequests(),
              builder: (_, snap) {
                final count = (snap.data ?? [])
                    .where((r) => r.status == 'open')
                    .length;
                return _SummaryCard(
                  emoji: '🙏',
                  count: count,
                  label: 'Pedidos\nabertos',
                  color: AppTheme.primaryBlue,
                );
              },
            ),
          ),
          const SizedBox(width: 10),

          // Total de filhos
          Expanded(
            child: _SummaryCard(
              emoji: '👶',
              count: user.children?.length ?? 0,
              label: 'Filhos\ncadastrados',
              color: AppTheme.kidsPurple,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String emoji;
  final int count;
  final String label;
  final Color color;

  const _SummaryCard({
    required this.emoji,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: AppDecorations.profileSummaryCard,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  } 
}
import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/donation/controller/donation_controller.dart';
import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:empatia/features/donation/widgets/donation_item_form_sheet.dart';
import 'package:empatia/features/dream/controller/dream_controller.dart';
import 'package:empatia/features/dream/presentation/pages/verification_block_dialog.dart';
import 'package:empatia/features/dream/presentation/widgets/donation_card_widget.dart';
import 'package:empatia/features/dream/presentation/widgets/dream_card_widget.dart';
import 'package:empatia/features/dream/presentation/widgets/dream_form_sheet.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:empatia/features/request/controller/request_controller.dart';
import 'package:empatia/features/request/data/model/request_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DreamPage extends StatelessWidget {
  const DreamPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserModel?>();

    return Scaffold(
      backgroundColor: AppTheme.dreamBackground,
      body: CustomScrollView(
        slivers: [
          _DreamHeader(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _ReceivedDonationsSection(),
                _FunDivider(),
                _MyDonationsSection(),
                _FunDivider(),
                _DreamsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: currentUser == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                if (!ProfileService.isFullyVerified(currentUser)) {
                  showVerificationRequiredDialog(
                    context,
                    feature: 'publicar um sonho',
                  );
                  return;
                }
                showDreamFormSheet(context, currentUser: currentUser);
              },
              backgroundColor: AppTheme.accentPurple,
              elevation: 6,
              icon: const Text('✨', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Novo sonho!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
    );
  }
}

// ── Divisor decorativo ────────────────────────────────────────────────────────

class _FunDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                // Usa lista de cores do AppTheme — transparente → teal → transparente
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  AppTheme.accentTeal.withOpacity(0.4),
                  Colors.transparent,
                ]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('🌟', style: TextStyle(fontSize: 15)),
          ),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  AppTheme.accentTeal.withOpacity(0.4),
                  Colors.transparent,
                ]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DreamHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dreamCtrl    = context.read<DreamController>();
    final requestCtrl  = context.read<RequestController>();
    final donationCtrl = context.read<DonationController>();

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.blurBackground],
        background: Stack(
          children: [
            // Gradiente de fundo
            Container(decoration: AppDecorations.dreamHeaderBackground),

            // Decorações de fundo
            Positioned(
              top: 18, right: 20,
              child: Text('☁️',
                  style: TextStyle(
                      fontSize: 38,
                      color: Colors.white.withOpacity(0.18))),
            ),
            Positioned(
              top: 50, left: 8,
              child: Text('☁️',
                  style: TextStyle(
                      fontSize: 24,
                      color: Colors.white.withOpacity(0.12))),
            ),
            Positioned(
              bottom: 50, right: 55,
              child: Text('⭐',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.3))),
            ),
            Positioned(
              bottom: 64, left: 28,
              child: Text('🌈',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.22))),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          // era: BoxDecoration inline com Colors.white.withOpacity(0.2)
                          decoration: AppDecorations.dreamHeaderIconBox,
                          child: const Text('🌠',
                              style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Meus Sonhos',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Realize seus desejos! ✨',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Estatísticas
                    Row(
                      children: [
                        StreamBuilder<List<DreamModel>>(
                          stream: dreamCtrl.watchDreams(),
                          builder: (_, snap) => _StatBubble(
                            emoji: '💭',
                            value: '${snap.data?.length ?? 0}',
                            label: 'Sonhos',
                            color: AppTheme.accentPurple,
                          ),
                        ),
                        const SizedBox(width: 10),
                        StreamBuilder<List<DonationModel>>(
                          stream: donationCtrl.watchMyDonations(),
                          builder: (_, snap) => _StatBubble(
                            emoji: '🎁',
                            value: '${snap.data?.length ?? 0}',
                            label: 'Doações',
                            color: AppTheme.accentPink,
                            glow: (snap.data?.length ?? 0) > 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        StreamBuilder<List<RequestModel>>(
                          stream: requestCtrl.watchMyRequests(),
                          builder: (_, snap) {
                            final n = (snap.data ?? [])
                                .where((r) => r.status == 'fulfilled')
                                .length;
                            return _StatBubble(
                              emoji: '🎉',
                              value: '$n',
                              label: 'Recebidas',
                              color: AppTheme.accentGreen,
                              glow: n > 0,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  final bool glow;

  const _StatBubble({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: glow
          ? AppDecorations.dreamStatBubbleActive(color)
          : AppDecorations.dreamStatBubble,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              Text(label,
                  style: TextStyle(
                      fontSize: 8,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Seção: Doações recebidas ──────────────────────────────────────────────────

class _ReceivedDonationsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RequestModel>>(
      stream: context.read<RequestController>().watchMyRequests(),
      builder: (context, snapshot) {
        final received =
            (snapshot.data ?? []).where((r) => r.status == 'fulfilled').toList();
        return _SectionWrapper(
          emoji: '🎁',
          title: 'Presentinhos recebidos',
          count: received.isEmpty ? null : received.length,
          countColor: AppTheme.accentGreen,
          child: received.isEmpty
              ? _EmptyState(
                  emoji: '📭',
                  title: 'Nenhum presentinho ainda!',
                  subtitle: 'Quando alguém te ajudar, aparece aqui 🤗',
                  borderColor: AppTheme.accentGreen,
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: received.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _ReceivedCard(request: received[i]),
                ),
        );
      },
    );
  }
}

class _ReceivedCard extends StatelessWidget {
  final RequestModel request;
  const _ReceivedCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.dreamReceivedCard,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: AppDecorations.dreamReceivedCardIcon,
            child: Center(
              child: Text(request.emoji ?? '🎁',
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title ?? 'Doação recebida',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: AppDecorations.dreamFulfilledBadge,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✅', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        'Atendido!',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentGreen.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Text('🎊', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}

// ── Seção: Minhas Doações ─────────────────────────────────────────────────────

class _MyDonationsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl      = context.read<DonationController>();
    final userModel = context.watch<UserModel?>();

    return StreamBuilder<List<DonationModel>>(
      stream: ctrl.watchMyDonations(),
      builder: (context, snapshot) {
        final donations = snapshot.data ?? [];
        return _SectionWrapper(
          emoji: '🧸',
          title: 'Minhas Doações',
          count: donations.isEmpty ? null : donations.length,
          countColor: AppTheme.accentPink,
          trailing: _AddButton(
            label: 'Doar 💝',
            color: AppTheme.accentPink,
            onTap: () {
              if (userModel == null) return;
              if (!ProfileService.isFullyVerified(userModel)) {
                showVerificationRequiredDialog(context,
                    feature: 'criar uma doação');
                return;
              }
              showDonationItemFormSheet(context, currentUser: userModel);
            },
          ),
          child: donations.isEmpty
              ? _EmptyState(
                  emoji: '🧸',
                  title: 'Nenhuma doação ainda!',
                  subtitle:
                      'Compartilhe brinquedos e itens que você não usa 💕',
                  borderColor: AppTheme.accentPink,
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: donations.length,
                  itemBuilder: (_, i) => DonationCardWidget(
                    donation: donations[i],
                    onEdit: () {
                      if (userModel == null) return;
                      showDonationItemFormSheet(context,
                          currentUser: userModel, donation: donations[i]);
                    },
                  ),
                ),
        );
      },
    );
  }
}

// ── Seção: Meus Sonhos ────────────────────────────────────────────────────────

class _DreamsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl        = context.read<DreamController>();
    final currentUser = context.watch<UserModel?>();

    return StreamBuilder<List<DreamModel>>(
      stream: ctrl.watchDreams(),
      builder: (context, snapshot) {
        final dreams = snapshot.data ?? [];
        return _SectionWrapper(
          emoji: '🌠',
          title: 'Meus Sonhos',
          count: dreams.isEmpty ? null : dreams.length,
          countColor: AppTheme.accentPurple,
          child: dreams.isEmpty
              ? _EmptyState(
                  emoji: '🌙',
                  title: 'Que sonho você tem?',
                  subtitle:
                      'Toque no botão ✨ para adicionar seu primeiro sonho!',
                  borderColor: AppTheme.accentPurple,
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dreams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => DreamCardWidget(
                    dream: dreams[i],
                    editable: true,
                    onEdit: currentUser == null
                        ? null
                        : () => showDreamFormSheet(
                              context,
                              currentUser: currentUser,
                              dream: dreams[i],
                            ),
                  ),
                ),
        );
      },
    );
  }
}

// ── Helpers de UI ─────────────────────────────────────────────────────────────

class _SectionWrapper extends StatelessWidget {
  final String emoji, title;
  final int? count;
  final Color? countColor;
  final Widget child;
  final Widget? trailing;

  const _SectionWrapper({
    required this.emoji,
    required this.title,
    required this.child,
    this.count,
    this.countColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = countColor ?? AppTheme.accentTeal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: AppDecorations.dreamSectionIcon(color),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 19)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryBlue,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  // era: BoxDecoration inline com color.withOpacity(0.15)
                  decoration: AppDecorations.dreamSectionCountChip(color),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AddButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: AppDecorations.dreamAddButton(color),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color borderColor;

  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: AppDecorations.dreamEmptyState(borderColor),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
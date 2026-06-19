import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
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

// ─── Aliases do AppTheme ────────────────────────────────────────────────
const _blue   = AppTheme.primaryBlue;
const _teal   = AppTheme.accentTeal;
const _pink   = AppTheme.accentPink;
const _purple = AppTheme.accentPurple;
const _green  = AppTheme.accentGreen;

class DreamPage extends StatelessWidget {
  const DreamPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserModel?>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
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
              backgroundColor: _purple,
              elevation: 6,
              icon: const Text('✨', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Novo sonho!',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15),
              ),
            ),
    );
  }
}

// ── Divisor com estrelinhas ───────────────────────────────────────────────────

class _FunDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Container(height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent, _teal.withOpacity(0.4), Colors.transparent,
                ]),
                borderRadius: BorderRadius.circular(2),
              ))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('🌟', style: TextStyle(fontSize: 16))),
          Expanded(child: Container(height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent, _teal.withOpacity(0.4), Colors.transparent,
                ]),
                borderRadius: BorderRadius.circular(2),
              ))),
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
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      backgroundColor: _blue,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.blurBackground],
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF4DB8C4), Color(0xFF9C27B0)],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Positioned(top: 18, right: 20,
                child: Text('☁️', style: TextStyle(fontSize: 40, color: Colors.white.withOpacity(0.18)))),
            Positioned(top: 52, left: 8,
                child: Text('☁️', style: TextStyle(fontSize: 26, color: Colors.white.withOpacity(0.12)))),
            Positioned(bottom: 58, right: 55,
                child: Text('⭐', style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.3)))),
            Positioned(bottom: 72, left: 28,
                child: Text('🌈', style: TextStyle(fontSize: 20, color: Colors.white.withOpacity(0.22)))),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('🌠', style: TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Meus Sonhos',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text('Realize seus desejos! ✨',
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        StreamBuilder<List<DreamModel>>(
                          stream: dreamCtrl.watchDreams(),
                          builder: (_, snap) => _StatBubble(
                            emoji: '💭', value: '${snap.data?.length ?? 0}',
                            label: 'Sonhos', color: _purple,
                          ),
                        ),
                        const SizedBox(width: 10),
                        StreamBuilder<List<DonationModel>>(
                          stream: donationCtrl.watchMyDonations(),
                          builder: (_, snap) => _StatBubble(
                            emoji: '🎁', value: '${snap.data?.length ?? 0}',
                            label: 'Doações', color: _pink,
                            glow: (snap.data?.length ?? 0) > 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        StreamBuilder<List<RequestModel>>(
                          stream: requestCtrl.watchMyRequests(),
                          builder: (_, snap) {
                            final n = (snap.data ?? []).where((r) => r.status == 'fulfilled').length;
                            return _StatBubble(
                              emoji: '🎉', value: '$n',
                              label: 'Recebidas', color: _green, glow: n > 0,
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
  const _StatBubble({required this.emoji, required this.value, required this.label, required this.color, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: glow ? color.withOpacity(0.25) : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glow ? color.withOpacity(0.6) : Colors.white.withOpacity(0.25), width: 1.5),
        boxShadow: glow ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10)] : [],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w700)),
        ]),
      ]),
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
        final received = (snapshot.data ?? []).where((r) => r.status == 'fulfilled').toList();
        return _SectionWrapper(
          emoji: '🎁', title: 'Presentinhos recebidos',
          count: received.isEmpty ? null : received.length, countColor: _green,
          child: received.isEmpty
              ? const _EmptyState(emoji: '📭', title: 'Nenhum presentinho ainda!',
                  subtitle: 'Quando alguém te ajudar, aparece aqui 🤗',
                  borderColor: Color(0xFF4CAF50))
              : ListView.separated(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
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
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: _green.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_green.withOpacity(0.18), _teal.withOpacity(0.18)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: Text(request.emoji ?? '🎁', style: const TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(request.title ?? 'Doação recebida', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _blue)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: _green.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('✅', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              Text('Atendido!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _green.withOpacity(0.9))),
            ]),
          ),
        ])),
        const Text('🎊', style: TextStyle(fontSize: 26)),
      ]),
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
          emoji: '🧸', title: 'Minhas Doações',
          count: donations.isEmpty ? null : donations.length, countColor: _pink,
          trailing: _AddButton(
            label: 'Doar 💝', color: _pink,
            onTap: () {
              if (userModel == null) return;
              if (!ProfileService.isFullyVerified(userModel)) {
                showVerificationRequiredDialog(
                  context,
                  feature: 'criar uma doação',
                );
                return;
              }
              showDonationItemFormSheet(context, currentUser: userModel);
            },
          ),
          child: donations.isEmpty
              ? const _EmptyState(emoji: '🧸', title: 'Nenhuma doação ainda!',
                  subtitle: 'Compartilhe brinquedos e itens que você não usa 💕',
                  borderColor: Color(0xFFE91E63))
              : GridView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72,
                  ),
                  itemCount: donations.length,
                  itemBuilder: (_, i) => DonationCardWidget(
                    donation: donations[i],
                    onEdit: () {
                      if (userModel == null) return;
                      showDonationItemFormSheet(context, currentUser: userModel, donation: donations[i]);
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
          emoji: '🌠', title: 'Meus Sonhos',
          count: dreams.isEmpty ? null : dreams.length, countColor: _purple,
          child: dreams.isEmpty
              ? const _EmptyState(emoji: '🌙', title: 'Que sonho você tem?',
                  subtitle: 'Toque no botão ✨ para adicionar seu primeiro sonho!',
                  borderColor: Color(0xFF9C27B0))
              : ListView.separated(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  itemCount: dreams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => DreamCardWidget(
                    dream: dreams[i], editable: true,
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
    required this.emoji, required this.title, required this.child,
    this.count, this.countColor, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                (countColor ?? _teal).withOpacity(0.22),
                (countColor ?? _teal).withOpacity(0.08),
              ]),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _blue)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: (countColor ?? _teal).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: countColor ?? _teal)),
            ),
          ],
          const Spacer(),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 14),
        child,
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color borderColor;
  const _EmptyState({required this.emoji, required this.title, required this.subtitle, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor.withOpacity(0.4), width: 2),
        boxShadow: [BoxShadow(color: borderColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 46)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _blue)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.5)),
      ]),
    );
  }
}
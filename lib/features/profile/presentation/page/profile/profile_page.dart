import 'package:empatia/core/models/user_model.dart';
import 'package:empatia/features/profile/controller/profile_controller.dart';
import 'package:empatia/features/profile/presentation/widgets/profile/profile_children_widget.dart';
import 'package:empatia/features/profile/presentation/widgets/profile/profile_dreams_widget.dart';
import 'package:empatia/features/profile/presentation/widgets/profile/profile_header_widget.dart';
import 'package:empatia/features/profile/presentation/widgets/profile/profile_shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────
const _pink = Color(0xFFFF6B9D);
const _bg   = Color(0xFFF7F8FC);

/// 👤 PROFILE PAGE
///
/// Página enxuta — apenas monta o layout com os widgets separados.
/// Toda lógica de UI fica nos widgets filhos.
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
            backgroundColor: _bg,
            body: Center(child: CircularProgressIndicator(color: _pink)),
          );
        }

        return Scaffold(
          backgroundColor: _bg,
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
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),

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

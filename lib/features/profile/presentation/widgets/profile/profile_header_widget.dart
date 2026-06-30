import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/widget/avatar_render.dart';
import 'package:empatia/core/widget/social_links_row.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:empatia/features/profile/presentation/page/edit_profile/edit_profile.dart';
import 'package:empatia/features/settings/features/account_verification/presentation/pages/account_settings_page.dart';
import 'package:empatia/features/settings/presentation/pages/settings_page.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_icons.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final UserModel user;

  const ProfileHeaderWidget({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 360,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.kidsPink,
      automaticallyImplyLeading: false,
      actions: const [],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: _HeaderBackground(user: user),
      ),
    );
  }
}

// ── Background do header ─────────────────────────────────────────────────────

class _HeaderBackground extends StatelessWidget {
  final UserModel user;
  const _HeaderBackground({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.profileHeaderBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MEU PERFIL',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.backgroundColor,
                      letterSpacing: 2,
                    ),
                  ),
                  Row(
                    children: [
                      _iconBtn(AppIcons.edit, onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => EditProfilePage(currentUser: user)));
                      }),
                      const SizedBox(width: 8),
                      _iconBtn(AppIcons.settings, onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SettingsPage()));
                      }),
                    ],
                  ),
                ],
              ),
            ),

            // ── Conteúdo principal ──
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ProfileAvatarWidget(user: user),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user.name ?? 'Usuário',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.backgroundColor,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              VerificationChipWidget(user: user),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ProfileMetaRowWidget(user: user),
                    if (user.status != null) ...[
                      const SizedBox(height: 12),
                      ProfileStatusBannerWidget(user: user),
                    ],
                    if ((user.socialFacebook?.isNotEmpty ?? false) ||
                        (user.socialInstagram?.isNotEmpty ?? false) ||
                        (user.socialX?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 12),
                      SocialLinksRow(
                        facebook: user.socialFacebook,
                        instagram: user.socialInstagram,
                        x: user.socialX,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, {required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppTheme.backgroundColor, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: AppDecorations.profileHeaderIconButton.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

class ProfileAvatarWidget extends StatelessWidget {
  final UserModel user;
  const ProfileAvatarWidget({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullyVerified = ProfileService.isFullyVerified(user);

    return Container(
      width: 88,
      height: 88,
      decoration: AppDecorations.profileAvatarRing(verified: fullyVerified),
      child: ClipOval(
        child: user.profileImage != null
            ? Image.network(
                user.profileImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    AvatarRender(value: user.profileEmoji, size: 88),
              )
            : AvatarRender(value: user.profileEmoji, size: 88),
      ),
    );
  }
}

// ── Verification chip ────────────────────────────────────────────────────────

class VerificationChipWidget extends StatelessWidget {
  final UserModel user;
  const VerificationChipWidget({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullyVerified = ProfileService.isFullyVerified(user);

    return GestureDetector(
      onTap: () => _showVerificationSheet(context, user),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: AppDecorations.verificationChip(verified: fullyVerified),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fullyVerified
                  ? AppIcons.verified
                  : AppIcons.shieldOutline,
              color: fullyVerified ? AppTheme.kidsGreen : AppTheme.backgroundColor,
              size: 13,
            ),
            const SizedBox(width: 5),
            Text(
              fullyVerified ? 'Perfil Verificado' : 'Não verificado',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fullyVerified ? AppTheme.kidsGreen : AppTheme.backgroundColor,
              ),
            ),
            if (fullyVerified) ...[
              const SizedBox(width: 4),
              const Text('⭐', style: TextStyle(fontSize: 11)),
            ],
            if (!fullyVerified) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: AppDecorations.verificationBadge,
                child: const Text('Verificar',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.backgroundColor)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showVerificationSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VerificationSheetWidget(user: user),
    );
  }
}

// ── Meta row ─────────────────────────────────────────────────────────────────

/// Layout em duas linhas:
///   Linha 1 — idade + gênero (itens curtos, nunca estouram)
///   Linha 2 — localização (largura total, com ellipsis se necessário)
class ProfileMetaRowWidget extends StatelessWidget {
  final UserModel user;
  const ProfileMetaRowWidget({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ── Itens da linha 1: idade e gênero ──
    final topItems = <_MetaItem>[];

    if (user.age != null) {
      topItems.add(_MetaItem('🎂', '${user.age} anos'));
    }

    if (user.sexo != null) {
      final label = user.sexo == 'masculino'
          ? 'Masculino'
          : user.sexo == 'outro'
              ? 'Outro'
              : 'Feminino';
      final icon = user.sexo == 'masculino'
          ? '♂️'
          : user.sexo == 'outro'
              ? '⚧️'
              : '♀️';
      topItems.add(_MetaItem(icon, label));
    }

    // ── Item da linha 2: localização ──
    String? locationLabel;
    if (user.neighborhood != null || user.city != null || user.state != null) {
      final partes = <String>[];
      if (user.neighborhood != null) partes.add(user.neighborhood!);
      if (user.city != null) partes.add(user.city!);
      if (user.state != null) partes.add(user.state!);
      locationLabel = partes.join(', ');
    }

    if (topItems.isEmpty && locationLabel == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: AppDecorations.profileMetaRow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Linha 1: idade · gênero ──
          if (topItems.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: topItems.asMap().entries.map((e) {
                final isLast = e.key == topItems.length - 1;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.value.emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      e.value.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.backgroundColor,
                      ),
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppTheme.backgroundColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),

          // ── Linha 2: localização ──
          if (locationLabel != null) ...[
            if (topItems.isNotEmpty) const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📍', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    locationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.backgroundColor,
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

class _MetaItem {
  final String emoji;
  final String label;
  const _MetaItem(this.emoji, this.label);
}

// ── Status banner ─────────────────────────────────────────────────────────────

class ProfileStatusBannerWidget extends StatelessWidget {
  final UserModel user;
  const ProfileStatusBannerWidget({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: AppDecorations.profileStatusBanner,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💖', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              user.status!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.kidsPink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Verification sheet ────────────────────────────────────────────────────────

class VerificationSheetWidget extends StatelessWidget {
  final UserModel user;
  const VerificationSheetWidget({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailVerified   = user.emailVerified == true;
    final profileComplete = user.profileCompleted == true;
    final fullyVerified   = ProfileService.isFullyVerified(user);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 24),

          // Ícone principal
          Container(
            width: 72, height: 72,
            decoration: AppDecorations.verificationSheetIcon(verified: fullyVerified),
            child: Icon(
              fullyVerified
                  ? AppIcons.verified
                  : AppIcons.shieldOutline,
              color: AppTheme.backgroundColor, size: 34,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            fullyVerified ? 'Perfil Verificado! 🎉' : 'Verificar Perfil',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 6),
          Text(
            fullyVerified
                ? 'Parabéns! Seu perfil tem a confiança da comunidade.'
                : 'Complete as etapas abaixo para ganhar o selo de verificação.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade500, height: 1.5),
          ),
          const SizedBox(height: 24),

          // ── Etapa 1: E-mail ──
          _buildStep(
            context,
            icon: AppIcons.email,
            title: 'Verificar e-mail',
            subtitle: emailVerified
                ? 'E-mail confirmado ✓'
                : 'Confirme seu endereço de e-mail',
            done: emailVerified,
            onTap: emailVerified ? null : () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AccountSettingsPage())),
          ),
          const SizedBox(height: 10),

          // ── Etapa 2: Perfil completo ──
          _buildStep(
            context,
            icon: AppIcons.person,
            title: 'Completar perfil',
            subtitle: profileComplete
                ? 'Todas as informações preenchidas ✓'
                : 'Preencha nome, sexo, cidade e bairro',
            done: profileComplete,
            onTap: profileComplete
                ? null
                : () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => EditProfilePage(currentUser: user)));
                  },
          ),

          if (fullyVerified) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: AppDecorations.verifiedMemberBanner,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('⭐', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Text(
                    'Você é um membro verificado!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.verifiedTextDark,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool done,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: AppDecorations.verificationStepCard(done: done),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: AppDecorations.verificationStepIcon(done: done),
              child: Icon(
                done ? AppIcons.check : icon,
                color: AppTheme.backgroundColor, size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: done ? AppTheme.verifiedTextDark : AppTheme.primaryBlue)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: done
                              ? AppTheme.verifiedTextDark.withOpacity(0.7)
                              : Colors.grey.shade500)),
                ],
              ),
            ),
            if (!done && onTap != null)
              Icon(AppIcons.chevronRight,
                  color: Colors.grey.shade400, size: 22),
            if (done)
              const Icon(AppIcons.verified, color: AppTheme.kidsGreen, size: 20),
          ],
        ),
      ),
    );
  }
}
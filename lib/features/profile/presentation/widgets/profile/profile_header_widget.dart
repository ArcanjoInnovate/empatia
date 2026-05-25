import 'package:empatia/core/models/user_model.dart';
import 'package:empatia/features/profile/presentation/page/edit_profile/edit_profile.dart';
import 'package:empatia/features/setting/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';

// ─── Design tokens ────────────────────────────────────────────────────────
const _pink   = Color(0xFFFF6B9D);
const _navy   = Color(0xFF1E3A8A);
const _amber  = Color(0xFFFFC837);
const _purple = Color(0xFF8B5CF6);
const _green  = Color(0xFF4ADE80);

/// 🎨 PROFILE HEADER WIDGET
///
/// SliverAppBar com gradiente, avatar, nome, badge de verificação,
/// metadados (idade · gênero · localização) e status.
class ProfileHeaderWidget extends StatelessWidget {
  final UserModel user;

  const ProfileHeaderWidget({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: _pink,
      automaticallyImplyLeading: false,
      actions: const [],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.blurBackground],
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B9D), Color(0xFFE040A0), Color(0xFF8B5CF6)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
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
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  Row(
                    children: [
                      _iconBtn(Icons.edit_rounded, onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const EditProfilePage()));
                      }),
                      const SizedBox(width: 8),
                      _iconBtn(Icons.settings_rounded, onTap: () {
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                                  color: Colors.white,
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
      icon: Icon(icon, color: Colors.white, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

// ── Avatar ───────────────────────────────────────────────────────────────────

class ProfileAvatarWidget extends StatelessWidget {
  final UserModel user;
  const ProfileAvatarWidget({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipOval(
        child: user.profileImage != null
            ? Image.network(
                user.profileImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _emojiCenter(user.profileEmoji ?? '👤', 48),
              )
            : _emojiCenter(user.profileEmoji ?? '👤', 48),
      ),
    );
  }

  Widget _emojiCenter(String emoji, double size) => Center(
        child: Text(emoji, style: TextStyle(fontSize: size)),
      );
}

// ── Verification chip ────────────────────────────────────────────────────────

class VerificationChipWidget extends StatelessWidget {
  final UserModel user;
  const VerificationChipWidget({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final verified = user.isVerified == true;
    return GestureDetector(
      onTap: () => _showVerificationSheet(context, user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: verified
              ? _green.withOpacity(0.2)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: verified ? _green : Colors.white38,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              verified ? Icons.verified_rounded : Icons.shield_outlined,
              color: verified ? _green : Colors.white70,
              size: 13,
            ),
            const SizedBox(width: 5),
            Text(
              verified ? 'Verificado' : 'Não verificado',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: verified ? _green : Colors.white70,
              ),
            ),
            if (!verified) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _amber,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Verificar',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
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

class ProfileMetaRowWidget extends StatelessWidget {
  final UserModel user;
  const ProfileMetaRowWidget({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = <_MetaItem>[];

    if (user.age != null) items.add(_MetaItem('🎂', '${user.age} anos'));

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
      items.add(_MetaItem(icon, label));
    }

    if (user.neighborhood != null || user.city != null || user.state != null) {
      final partes = <String>[];
      if (user.neighborhood != null) partes.add(user.neighborhood!);
      if (user.city != null) partes.add(user.city!);
      if (user.state != null) partes.add(user.state!);
      items.add(_MetaItem('📍', partes.join(', ')));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      // ← CORREÇÃO: constraints para não ultrapassar a tela
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 80,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          final isLocation = e.value.emoji == '📍';
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.value.emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              // ← CORREÇÃO: localização tem largura máxima, outros itens são min
              if (isLocation)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    e.value.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Text(
                  e.value.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Colors.white38,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
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
                color: _pink,
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 24),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: user.isVerified == true
                    ? [_green, const Color(0xFF22C55E)]
                    : [_pink, _purple],
              ),
            ),
            child: Icon(
              user.isVerified == true
                  ? Icons.verified_rounded
                  : Icons.shield_outlined,
              color: Colors.white, size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.isVerified == true ? 'Perfil Verificado! 🎉' : 'Verificar Perfil',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: _navy),
          ),
          const SizedBox(height: 6),
          Text(
            user.isVerified == true
                ? 'Seu perfil já está verificado.'
                : 'Complete as etapas para ganhar a confiança da comunidade.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade500, height: 1.5),
          ),
          const SizedBox(height: 24),
          if (user.isVerified != true) ...[
            _buildStep(context,
              icon: Icons.phone_rounded,
              title: 'Verificar telefone',
              subtitle: 'Confirme seu número via SMS',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
            _buildStep(context,
              icon: Icons.cake_rounded,
              title: 'Verificar idade',
              subtitle: 'Confirme sua data de nascimento',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
            _buildStep(context,
              icon: Icons.person_rounded,
              title: 'Completar perfil',
              subtitle: 'Preencha todas as informações',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()));
              },
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_pink, _purple]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _navy)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}

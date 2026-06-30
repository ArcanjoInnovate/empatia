import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';

// ── Design tokens (mesmos do app) ──────────────────────────────────────────

/// 🔒 NAVEGAÇÃO PROTEGIDA POR VERIFICAÇÃO
///
/// Navega para [route] somente se [currentUser] estiver com o perfil
/// totalmente verificado (e-mail confirmado + perfil completo).
/// Caso contrário, exibe o [showVerificationRequiredDialog] em vez de navegar.
///
/// ⚠️ IMPORTANTE: `currentUser == null` é AMBÍGUO — pode significar
/// "usuário deslogado" OU "ainda carregando" (o StreamProvider global
/// começa com `initialData: null` e só preenche quando o primeiro evento
/// do Firebase chega). Para não bloquear usuários verificados só porque
/// os dados ainda não chegaram, distinguimos os dois casos usando o
/// FirebaseAuth.instance.currentUser (síncrono, sempre correto).
///
/// Uso:
///   pushIfVerified(
///     context,
///     currentUser: currentUser,
///     feature: 'ver os detalhes deste sonho',
///     route: DreamDetailPage.route(result: result, heroTag: heroTag),
///   );
void pushIfVerified(
  BuildContext context, {
  required UserModel? currentUser,
  required String feature,
  required Route<void> route,
}) {
  // Caso 1: dados já carregados — decide normalmente.
  if (currentUser != null) {
    if (!ProfileService.isFullyVerified(currentUser)) {
      showVerificationRequiredDialog(context, feature: feature);
      return;
    }
    Navigator.push(context, route);
    return;
  }

  // Caso 2: currentUser == null, mas o Firebase Auth mostra que HÁ alguém
  // logado → os dados do perfil ainda não chegaram (corrida de inicialização),
  // não é falta de verificação. Avisa e não bloqueia com o diálogo pesado.
  if (FirebaseAuth.instance.currentUser != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Carregando seu perfil... tente de novo em um instante.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  // Caso 3: realmente deslogado.
  showVerificationRequiredDialog(context, feature: feature);
}

/// 🔒 VERIFICATION REQUIRED DIALOG
///
/// Dialog estilizado que bloqueia ações que exigem perfil verificado.
/// Substitui o SnackBar genérico por uma tela clara e amigável.
///
/// Uso:
///   showVerificationRequiredDialog(
///     context,
///     feature: 'criar uma doação',  // ex: 'criar uma doação' | 'publicar um sonho'
///   );
Future<void> showVerificationRequiredDialog(
  BuildContext context, {
  required String feature,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _VerificationRequiredDialog(feature: feature),
  );
}

class _VerificationRequiredDialog extends StatelessWidget {
  final String feature;

  const _VerificationRequiredDialog({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 2),
      child: Container(
        decoration: AppDecorations.verificationBlockDialog,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Banner gradiente com ícone ────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.kidsPink, AppTheme.kidsPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    // Ícone em círculo branco semitransparente
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '🔒',
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Verificação necessária',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.backgroundColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Conteúdo ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  children: [
                    // Mensagem principal
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: AppTheme.textCharcoal,
                        ),
                        children: [
                          const TextSpan(text: 'Para '),
                          TextSpan(
                            text: feature,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const TextSpan(
                            text:
                                ', é necessário que seu perfil esteja verificado.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider sutil
                    Divider(color: Colors.grey.shade100, thickness: 1.5),
                    const SizedBox(height: 14),

                    // Motivo da exigência
                    _InfoRow(
                      emoji: '🛡️',
                      title: 'Segurança da plataforma',
                      subtitle:
                          'A verificação garante que quem doa e quem recebe são pessoas reais.',
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      emoji: '✉️',
                      title: 'Confirme seu e-mail',
                      subtitle:
                          'Acesse a caixa de entrada e clique no link que enviamos para você.',
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      emoji: '👤',
                      title: 'Complete seu perfil',
                      subtitle:
                          'Adicione nome, foto e sua cidade para liberar todas as funcionalidades.',
                    ),

                    const SizedBox(height: 24),

                    // Botão principal – Ir para o perfil
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.kidsPink, AppTheme.kidsPurple],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Entendido, vou verificar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.backgroundColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ));
  }
}

// ── Linha de informação ────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone emoji em badge
        Container(
          width: 36,
          height: 36,
          decoration: AppDecorations.verificationBlockInfoBadge,
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),

        // Texto
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
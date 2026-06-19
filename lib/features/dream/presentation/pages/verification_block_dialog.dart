import 'package:flutter/material.dart';

// ── Design tokens (mesmos do app) ──────────────────────────────────────────
const _pink   = Color(0xFFFF6B9D);
const _navy   = Color(0xFF1E3A8A);
const _purple = Color(0xFF8B5CF6);

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
    barrierColor: Colors.black.withOpacity(0.55),
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _pink.withOpacity(0.18),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: _purple.withOpacity(0.10),
              blurRadius: 60,
              offset: const Offset(0, 24),
            ),
          ],
        ),
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
                    colors: [_pink, _purple],
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
                        color: Colors.white.withOpacity(0.22),
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
                        color: Colors.white,
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
                          color: Color(0xFF374151),
                        ),
                        children: [
                          const TextSpan(text: 'Para '),
                          TextSpan(
                            text: feature,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _navy,
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
                            colors: [_pink, _purple],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Entendido, vou verificar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Botão secundário – Fechar
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Fechar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
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
      ),
    );
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
          decoration: BoxDecoration(
            color: _pink.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
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
                  color: _navy,
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
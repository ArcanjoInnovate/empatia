// lib/features/chat/presentation/widgets/pending_confirmation_dialog.dart
//
// Diálogo mostrado quando o usuário tenta entrar num chat/contexto NOVO
// (a partir de DreamDetailPage ou DonationDetailPage) com alguém que já
// tem uma confirmação de entrega pendente e não respondida no chat que
// já existe entre os dois. Bloqueia a entrada no contexto novo até a
// pendência ser resolvida — evita que a pessoa "fuja" de responder um
// pedido de confirmação abrindo uma negociação diferente.

import 'package:flutter/material.dart';

Future<void> showPendingConfirmationDialog(
  BuildContext context, {
  required VoidCallback onGoToPendingChat,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogCtx) => _PendingConfirmationDialog(
      onGoToPendingChat: () {
        Navigator.of(dialogCtx).pop();
        onGoToPendingChat();
      },
      onClose: () => Navigator.of(dialogCtx).pop(),
    ),
  );
}

class _PendingConfirmationDialog extends StatelessWidget {
  final VoidCallback onGoToPendingChat;
  final VoidCallback onClose;

  const _PendingConfirmationDialog({
    required this.onGoToPendingChat,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFB923C), Color(0xFFF97316)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFB923C).withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('📦', style: TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Confirmação pendente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            const Text(
              'Você tem um pedido de confirmação de entrega ainda sem '
              'resposta com essa pessoa. Resolva essa pendência antes de '
              'começar uma nova conversa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onGoToPendingChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFB923C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Ir para a conversa pendente',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onClose,
                child: const Text(
                  'Fechar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
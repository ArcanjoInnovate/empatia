// lib/features/chat/presentation/widgets/message_bubble.dart

import 'package:empatia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../data/models/chat_message_model.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool showTimestamp;
  final String otherUid;

  /// true quando a mensagem anterior era do mesmo remetente (menos de 2 min)
  /// → remove o raio "cauda" do lado para agrupar visualmente
  final bool isGroupedWithPrev;

  /// true quando a próxima mensagem é do mesmo remetente (menos de 2 min)
  final bool isGroupedWithNext;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.otherUid,
    this.showTimestamp    = false,
    this.isGroupedWithPrev = false,
    this.isGroupedWithNext = false,
  });

  @override
  Widget build(BuildContext context) {
    final readByOther = isMine && message.isReadBy(otherUid);
    // Última mensagem do grupo → mostrar hora + status
    final showMeta = !isGroupedWithNext;

    return Padding(
      padding: EdgeInsets.only(
        left:   isMine ? 56 : 12,
        right:  isMine ? 12 : 56,
        // Espaço menor entre msgs do mesmo grupo, maior entre grupos
        bottom: isGroupedWithNext ? 2 : 6,
      ),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [

          // ── Separador de data/hora elegante ───────────────
          if (showTimestamp)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 20),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.withValues(alpha: 0.18),
                        thickness: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color:        Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.14)),
                        boxShadow: [
                          BoxShadow(
                            color:     Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset:    const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatDateWithTime(message.dateTime),
                        style: TextStyle(
                          fontSize:   11,
                          color:      Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Divider(
                        color: Colors.grey.withValues(alpha: 0.18),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Bolha ─────────────────────────────────────────
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: isMine
                  ? const LinearGradient(
                      colors: [
                        AppTheme.kidsPurpleViolet,
                        AppTheme.primaryBlue,
                      ],
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    )
                  : null,
              color: isMine ? null : Colors.white,
              // Agrupamento: remove o "bico" nas msgs intermediárias
              borderRadius: _borderRadius(),
              boxShadow: [
                BoxShadow(
                  color:     isMine
                      ? AppTheme.kidsPurpleViolet.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset:    const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize:   15,
                color:      isMine ? Colors.white : AppTheme.primaryBlue,
                height:     1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // ── Hora + leitura (só na última do grupo) ─────────
          if (showMeta)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.dateTime),
                    style: TextStyle(
                      fontSize:   10,
                      color:      Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all_rounded,
                      size:  13,
                      color: readByOther
                          ? AppTheme.primaryBlueMid
                          : Colors.grey.shade300 ?? Colors.grey.shade400,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Raio adaptativo para efeito de agrupamento
  BorderRadius _borderRadius() {
    const r  = Radius.circular(20);
    const rS = Radius.circular(5); // "bico" do grupo

    if (isMine) {
      return BorderRadius.only(
        topLeft:     r,
        topRight:    isGroupedWithPrev ? rS : r,
        bottomLeft:  r,
        bottomRight: isGroupedWithNext ? rS : r,
      );
    } else {
      return BorderRadius.only(
        topLeft:     isGroupedWithPrev ? rS : r,
        topRight:    r,
        bottomLeft:  isGroupedWithNext ? rS : r,
        bottomRight: r,
      );
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateWithTime(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day   = DateTime(dt.year, dt.month, dt.day);
    final time  = _formatTime(dt);
    if (day == today) return 'Hoje • $time';
    if (day == today.subtract(const Duration(days: 1))) return 'Ontem • $time';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} • $time';
  }
}
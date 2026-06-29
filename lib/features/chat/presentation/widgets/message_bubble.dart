// lib/features/chat/presentation/widgets/message_bubble.dart

import 'package:empatia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../data/models/chat_message_model.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool showTimestamp;
  final String otherUid;
  final bool isGroupedWithPrev;
  final bool isGroupedWithNext;

  // Callback para quando o outro usuário quer responder uma delivery_request
  final void Function(ChatMessage msg, bool confirmed)? onRespondDelivery;
  // true se já existe delivery_confirmed ou delivery_denied para este request
  final bool isAnswered;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.otherUid,
    this.showTimestamp    = false,
    this.isGroupedWithPrev = false,
    this.isGroupedWithNext = false,
    this.onRespondDelivery,
    this.isAnswered = false,
  });

  @override
  Widget build(BuildContext context) {
    // Eventos de entrega têm visual próprio — centralizado
    if (message.type.isDeliveryEvent) {
      return _DeliveryEventBubble(
        message:           message,
        isMine:            isMine,
        showTimestamp:     showTimestamp,
        isAnswered:        isAnswered,
        onRespondDelivery: onRespondDelivery,
      );
    }

    final readByOther = isMine && message.isReadBy(otherUid);
    final showMeta    = !isGroupedWithNext;

    return Padding(
      padding: EdgeInsets.only(
        left:   isMine ? 56 : 12,
        right:  isMine ? 12 : 56,
        bottom: isGroupedWithNext ? 2 : 6,
      ),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showTimestamp) _TimestampDivider(dateTime: message.dateTime),

          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: isMine
                  ? const LinearGradient(
                      colors: [AppTheme.kidsPurpleViolet, AppTheme.primaryBlue],
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    )
                  : null,
              color: isMine ? null : Colors.white,
              borderRadius: _borderRadius(),
              boxShadow: [
                BoxShadow(
                  color: isMine
                      ? AppTheme.kidsPurpleViolet.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset:     const Offset(0, 2),
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
                          : Colors.grey.shade300,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  BorderRadius _borderRadius() {
    const r  = Radius.circular(20);
    const rS = Radius.circular(5);
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

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ══════════════════════════════════════════════════════════════
// DELIVERY EVENT BUBBLE — visual especial, centralizado
// ══════════════════════════════════════════════════════════════

class _DeliveryEventBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool showTimestamp;
  final bool isAnswered;
  final void Function(ChatMessage msg, bool confirmed)? onRespondDelivery;

  const _DeliveryEventBubble({
    required this.message,
    required this.isMine,
    required this.showTimestamp,
    this.isAnswered = false,
    this.onRespondDelivery,
  });

  @override
  Widget build(BuildContext context) {
    final type = message.type;

    Color bgColor;
    Color borderColor;
    Color iconBg;
    IconData icon;
    String label;
    String sublabel;

    switch (type) {
      case ChatMessageType.deliveryRequest:
        bgColor     = const Color(0xFFF0F7FF);
        borderColor = AppTheme.primaryBlueMid.withValues(alpha: 0.30);
        iconBg      = AppTheme.primaryBlueMid.withValues(alpha: 0.12);
        icon        = Icons.local_shipping_rounded;
        label       = isMine ? 'Você marcou como entregue' : 'Entrega marcada';
        sublabel    = isAnswered
            ? 'Já respondido'
            : isMine
                ? 'Aguardando confirmação do outro participante'
                : 'Confirme se recebeu o item';
        break;
      case ChatMessageType.deliveryConfirmed:
        bgColor     = const Color(0xFFF0FDF4);
        borderColor = AppTheme.kidsGreenDeep.withValues(alpha: 0.35);
        iconBg      = AppTheme.kidsGreenDeep.withValues(alpha: 0.12);
        icon        = Icons.check_circle_rounded;
        label       = 'Doação concluída! 🎉';
        sublabel    = isMine
            ? 'Você confirmou o recebimento'
            : 'Recebimento confirmado pela outra pessoa';
        break;
      case ChatMessageType.deliveryDenied:
        bgColor     = const Color(0xFFFFF5F5);
        borderColor = AppTheme.errorRed.withValues(alpha: 0.35);
        iconBg      = AppTheme.errorRed.withValues(alpha: 0.10);
        icon        = Icons.cancel_rounded;
        label       = 'Recebimento não confirmado';
        sublabel    = isMine
            ? 'Você negou o recebimento'
            : 'A outra pessoa não confirmou';
        break;
      default:
        return const SizedBox.shrink();
    }

    final iconColor = type == ChatMessageType.deliveryConfirmed
        ? AppTheme.kidsGreenDeep
        : type == ChatMessageType.deliveryDenied
            ? AppTheme.errorRed
            : AppTheme.primaryBlueMid;

    // Botões visíveis apenas para o receptor E somente se ainda não respondido
    final showActions = type == ChatMessageType.deliveryRequest
        && !isMine
        && !isAnswered;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        children: [
          if (showTimestamp) _TimestampDivider(dateTime: message.dateTime),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        bgColor,
              borderRadius: BorderRadius.circular(16),
              border:       Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color:      iconColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset:     const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color:  iconBg,
                        shape:  BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize:   13.5,
                              fontWeight: FontWeight.w800,
                              color:      iconColor,
                              height:     1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (message.deliveryItemTitle != null)
                            Text(
                              '"${message.deliveryItemTitle}"',
                              style: TextStyle(
                                fontSize:   12,
                                fontWeight: FontWeight.w600,
                                color:      iconColor.withValues(alpha: 0.80),
                                fontStyle:  FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 2),
                          Text(
                            sublabel,
                            style: TextStyle(
                              fontSize:   11.5,
                              color:      iconColor.withValues(alpha: 0.65),
                              height:     1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Botões de ação — só para o receptor do request
                if (showActions) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFDDE3F0)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
// Nas chamadas dos botões, passa o estado de sending
                        child: _ActionButton(
                          label:    'Não recebi',
                          icon:     Icons.close_rounded,
                          color:    AppTheme.errorRed,
                          disabled: onRespondDelivery == null,
                          onTap:    () => onRespondDelivery?.call(message, false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          label:    'Recebi! ✅',
                          icon:     Icons.check_rounded,
                          color:    AppTheme.kidsGreenDeep,
                          filled:   true,
                          disabled: onRespondDelivery == null,
                          onTap:    () => onRespondDelivery?.call(message, true),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Horário abaixo do card
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _formatTime(message.dateTime),
              style: TextStyle(
                fontSize:   10,
                color:      Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final bool disabled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.filled   = false,
    this.disabled = false,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  // Trava local: uma vez pressionado, bloqueia novos taps mesmo antes
  // do callback chegar no controller (evita duplo disparo por double-tap).
  bool _tapped  = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || _tapped;
    return GestureDetector(
      onTapDown:   isDisabled ? null : (_) => setState(() => _pressed = true),
      onTapUp:     isDisabled ? null : (_) {
        setState(() { _pressed = false; _tapped = true; });
        widget.onTap?.call();
      },
      onTapCancel: isDisabled ? null : () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.withValues(alpha: 0.08)
              : widget.filled
                  ? (_pressed ? widget.color.withValues(alpha: 0.80) : widget.color)
                  : (_pressed ? widget.color.withValues(alpha: 0.10) : widget.color.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDisabled
                ? Colors.grey.withValues(alpha: 0.20)
                : widget.color.withValues(alpha: widget.filled ? 0 : 0.35),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isDisabled && _tapped)
              SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.grey.shade400,
                ),
              )
            else
              Icon(widget.icon, size: 16,
                  color: isDisabled ? Colors.grey.shade400
                      : widget.filled ? Colors.white : widget.color),
            const SizedBox(width: 5),
            Text(
              widget.label,
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w700,
                color: isDisabled ? Colors.grey.shade400
                    : widget.filled ? Colors.white : widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TIMESTAMP DIVIDER — compartilhado
// ══════════════════════════════════════════════════════════════

class _TimestampDivider extends StatelessWidget {
  final DateTime dateTime;
  const _TimestampDivider({required this.dateTime});

  String _label() {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day   = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final time  = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    if (day == today) return 'Hoje • $time';
    if (day == today.subtract(const Duration(days: 1))) return 'Ontem • $time';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} • $time';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 20),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.18), thickness: 1)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(color: Colors.grey.withValues(alpha: 0.14)),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset:     const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                _label(),
                style: TextStyle(
                  fontSize:      11,
                  color:         Colors.grey.shade500,
                  fontWeight:    FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.18), thickness: 1)),
          ],
        ),
      ),
    );
  }
}
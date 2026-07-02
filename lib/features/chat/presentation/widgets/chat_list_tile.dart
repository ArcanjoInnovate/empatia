// lib/features/chat/presentation/widgets/chat_list_tile.dart

import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/theme/app_avatars.dart';
import 'package:empatia/core/widget/avatar_render.dart';
import 'package:empatia/features/chat/data/models/chat_model.dart';
import 'package:empatia/features/chat/data/repositories/chat_repository.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// CHAT LIST TILE — card contextual com miniatura e status
// ═══════════════════════════════════════════════════════════════

class ChatListTile extends StatefulWidget {
  final ChatModel chat;
  final String myUid;
  final VoidCallback onTap;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.myUid,
    required this.onTap,
  });

  @override
  State<ChatListTile> createState() => _ChatListTileState();
}

class _ChatListTileState extends State<ChatListTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.97,
      upperBound: 1.0,
      value:    1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat        = widget.chat;
    final hasUnread   = chat.unread > 0;
    final isLastMine  = chat.lastSenderId == widget.myUid;
    final isDream     = (chat.itemType ?? 'dream') != 'donation';
    final isCompleted = chat.completed;

    return GestureDetector(
      onTapDown:   (_) => _ctrl.reverse(),
      onTapUp:     (_) { _ctrl.forward(); widget.onTap(); },
      onTapCancel: ()  => _ctrl.forward(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder:   (_, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: Container(
          margin:  const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color:        AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: isCompleted
                ? Border.all(color: AppTheme.kidsGreenDark.withValues(alpha: 0.45), width: 1.5)
                : hasUnread
                    ? Border.all(
                        color: isDream
                            ? AppTheme.kidsPurpleViolet.withValues(alpha: 0.25)
                            : AppTheme.kidsPink.withValues(alpha: 0.25),
                        width: 1.5,
                      )
                    : Border.all(color: Colors.grey.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? AppTheme.kidsGreenDark.withValues(alpha: 0.10)
                    : hasUnread
                        ? (isDream ? AppTheme.kidsPurpleViolet : AppTheme.kidsPink)
                            .withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                blurRadius: isCompleted ? 14 : hasUnread ? 12 : 8,
                offset:     const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Banner "Doação concluída" ───────────────────
              if (isCompleted)
                Container(
                  width:   double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
                  color:   AppTheme.kidsGreenDark.withValues(alpha: 0.09),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 13, color: AppTheme.kidsGreenDark),
                      const SizedBox(width: 5),
                      Text(
                        isDream ? 'Sonho realizado! 🎉' : 'Doação concluída! 🎉',
                        style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w700,
                          color:      AppTheme.kidsGreenDark,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Conteúdo ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _PresenceAvatar(
                          otherUid: chat.otherUid,
                          name:     chat.otherName,
                          emoji:    chat.otherEmoji,
                          imageUrl: chat.otherAvatar,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nome + timestamp
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      chat.otherName ?? 'Usuário',
                                      style: TextStyle(
                                        fontSize:   14.5,
                                        fontWeight: hasUnread
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isCompleted
                                            ? AppTheme.kidsGreenDark
                                            : AppTheme.primaryBlue,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(chat.lastTimestamp),
                                    style: TextStyle(
                                      fontSize:   11,
                                      color: isCompleted
                                          ? AppTheme.kidsGreenDark.withValues(alpha: 0.65)
                                          : hasUnread
                                              ? AppTheme.kidsPurpleViolet
                                              : AppTheme.textSecondary,
                                      fontWeight: hasUnread
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // Última mensagem
                              Row(
                                children: [
                                  if (isLastMine) ...[
                                    Icon(
                                      Icons.done_all_rounded,
                                      size:  14,
                                      color: chat.otherHasRead
                                          ? (isCompleted
                                              ? AppTheme.kidsGreenDark
                                              : AppTheme.primaryBlueMid)
                                          : Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 3),
                                  ],
                                  if (isCompleted) ...[
                                    Icon(Icons.check_circle_outline_rounded,
                                        size: 13,
                                        color: AppTheme.kidsGreenDark.withValues(alpha: 0.70)),
                                    const SizedBox(width: 3),
                                  ],
                                  Expanded(
                                    child: Text(
                                      chat.lastMessage?.isNotEmpty == true
                                          ? chat.lastMessage!
                                          : (isCompleted
                                              ? 'Entrega confirmada pelos dois lados'
                                              : 'Inicie a conversa ✨'),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: isCompleted
                                            ? AppTheme.kidsGreenDark.withValues(alpha: 0.80)
                                            : hasUnread
                                                ? AppTheme.textDarkGray
                                                : AppTheme.textSecondary,
                                        fontWeight: isCompleted || hasUnread
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        height: 1.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (hasUnread) ...[
                                    const SizedBox(width: 8),
                                    _UnreadBadge(
                                      count:   chat.unread,
                                      isDream: isDream,
                                      isCompleted: isCompleted,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ── Contexto (sonho/doação) ─────────────
                    if (chat.itemTitle != null && chat.itemTitle!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _ContextChip(
                        chat:        chat,
                        isDream:     isDream,
                        isCompleted: isCompleted,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int? ts) {
    if (ts == null) return '';
    final dt    = DateTime.fromMillisecondsSinceEpoch(ts);
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day   = DateTime(dt.year, dt.month, dt.day);
    if (day == today) {
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    }
    if (day == today.subtract(const Duration(days: 1))) return 'Ontem';
    return '${dt.day}/${dt.month}';
  }
}

// ─────────────────────────────────────────────────────────────
// CHIP DE CONTEXTO — miniatura + título + status
// ─────────────────────────────────────────────────────────────

class _ContextChip extends StatelessWidget {
  final ChatModel chat;
  final bool isDream;
  final bool isCompleted;

  const _ContextChip({
    required this.chat,
    required this.isDream,
    this.isCompleted = false,
  });

  Color get _accent => isCompleted
      ? AppTheme.kidsGreenDark
      : isDream ? AppTheme.kidsPurpleViolet : AppTheme.kidsPink;

  Color get _bg => isCompleted
      ? AppTheme.kidsGreenDark.withValues(alpha: 0.07)
      : isDream
          ? AppTheme.kidsPurpleViolet.withValues(alpha: 0.06)
          : AppTheme.kidsPink.withValues(alpha: 0.06);

  String get _emoji => isCompleted ? '✅' : isDream ? '💭' : '🎁';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:    const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:        _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: isCompleted ? 0.25 : 0.12)),
      ),
      child: Row(
        children: [
          // Miniatura ou emoji
          if (!isCompleted && chat.itemPhotoUrl != null && chat.itemPhotoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                chat.itemPhotoUrl!,
                width:  40,
                height: 40,
                fit:    BoxFit.cover,
                errorBuilder: (_, __, ___) => _emojiThumb(_emoji, _accent),
              ),
            )
          else
            _emojiThumb(_emoji, _accent),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted
                      ? (isDream ? 'Sonho realizado' : 'Doação entregue')
                      : (isDream ? 'Sonho' : 'Doação'),
                  style: TextStyle(
                    fontSize:   10,
                    fontWeight: FontWeight.w700,
                    color:      _accent.withValues(alpha: isCompleted ? 0.85 : 0.70),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  chat.itemTitle!,
                  style: TextStyle(
                    fontSize:   12.5,
                    fontWeight: FontWeight.w700,
                    color:      _accent,
                    height:     1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          _JourneyStatus(chat: chat, isDream: isDream),
        ],
      ),
    );
  }

  Widget _emojiThumb(String emoji, Color bg) => Container(
        width:  40,
        height: 40,
        decoration: BoxDecoration(
          color:        bg.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// STATUS DA JORNADA
// ─────────────────────────────────────────────────────────────

class _JourneyStatus extends StatelessWidget {
  final ChatModel chat;
  final bool isDream;

  const _JourneyStatus({required this.chat, required this.isDream});

  _StatusInfo _status() {
    final unread = chat.unread;
    final hasMsg = chat.lastMessage?.isNotEmpty == true;

    if (chat.completed) {
      return _StatusInfo('✅', 'Concluída', AppTheme.kidsGreenDark);
    }
    if (!hasMsg) {
      return _StatusInfo('🟡', 'Interesse\ndemonstrado', AppTheme.kidsAmber);
    }
    if (unread > 0) {
      return _StatusInfo('🔵', 'Conversando', AppTheme.primaryBlueMid);
    }
    return _StatusInfo('🟣', 'Em andamento', AppTheme.kidsPurpleViolet);
  }

  @override
  Widget build(BuildContext context) {
    final s = _status();
    return Column(
      children: [
        Text(s.emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 2),
        Text(
          s.label,
          style: TextStyle(
            fontSize:  9,
            color:     s.color,
            fontWeight: FontWeight.w700,
            height:    1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatusInfo {
  final String emoji;
  final String label;
  final Color  color;
  const _StatusInfo(this.emoji, this.label, this.color);
}

// ─────────────────────────────────────────────────────────────
// BADGE DE NÃO LIDAS
// ─────────────────────────────────────────────────────────────

class _UnreadBadge extends StatelessWidget {
  final int count;
  final bool isDream;
  final bool isCompleted;
  const _UnreadBadge({
    required this.count,
    required this.isDream,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 20),
        height:  20,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          gradient: isCompleted
              ? LinearGradient(
                  colors: [AppTheme.kidsGreenDark, AppTheme.kidsGreenDark.withValues(alpha: 0.75)],
                )
              : LinearGradient(
                  colors: isDream
                      ? [AppTheme.kidsPurpleViolet, AppTheme.primaryBlue]
                      : [AppTheme.kidsPink, AppTheme.kidsPinkDeep],
                ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(
              fontSize:   10,
              fontWeight: FontWeight.w800,
              color:      Colors.white,
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// AVATAR COM DOT DE PRESENÇA EM TEMPO REAL
// ─────────────────────────────────────────────────────────────

class _PresenceAvatar extends StatelessWidget {
  final String otherUid;
  final String? name;
  final String? emoji;
  final String? imageUrl;

  const _PresenceAvatar({
    required this.otherUid,
    this.name,
    this.emoji,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: ChatRepository.instance.presenceStream(otherUid),
      builder: (context, snap) {
        final online = snap.data?['online'] == true;
        return Stack(
          children: [
            _AvatarImage(name: name, emoji: emoji, imageUrl: imageUrl),
            if (online)
              Positioned(
                bottom: 0,
                right:  0,
                child: Container(
                  width:  12,
                  height: 12,
                  decoration: BoxDecoration(
                    color:  AppTheme.kidsGreenDark,
                    shape:  BoxShape.circle,
                    border: Border.all(color: AppTheme.cardBackground, width: 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AvatarImage extends StatelessWidget {
  final String? name;
  final String? emoji;
  final String? imageUrl;
  const _AvatarImage({this.name, this.emoji, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          imageUrl!,
          width: 50, height: 50, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    // Se temos um avatar ilustrado (novo formato), mostra a imagem.
    if (AppAvatars.isAssetPath(emoji)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 50, height: 50,
          color: AppTheme.surfaceBlueTint,
          child: AvatarRender(value: emoji, size: 50),
        ),
      );
    }

    // Fallback: emoji legado ou inicial do nome.
    final letter = name?.isNotEmpty == true ? name![0].toUpperCase() : null;
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.kidsPurpleViolet, AppTheme.primaryBlue],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          emoji ?? letter ?? '👤',
          style: TextStyle(
            fontSize:   emoji != null ? 23 : 18,
            color:      Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
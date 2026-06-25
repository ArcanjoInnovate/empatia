// lib/features/chat/presentation/pages/chat_page.dart
// Refatoração visual — lógica, controllers e fluxo intocados.

import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/chat/controller/chat_controller.dart';
import 'package:empatia/features/chat/data/models/chat_message_model.dart';
import 'package:empatia/features/chat/data/models/chat_model.dart';
import 'package:empatia/features/chat/data/repositories/chat_repository.dart';
import 'package:empatia/features/chat/presentation/widgets/message_bubble.dart';
import 'package:empatia/features/donation/presentation/pages/donation_detail_page.dart';
import 'package:empatia/features/dream/presentation/pages/dream_detail_page.dart';
import 'package:empatia/features/search/data/repositories/search_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════
// CHAT PAGE
// ═══════════════════════════════════════════════════════════════

class ChatPage extends StatefulWidget {
  final String myUid;
  final ChatModel chat;

  const ChatPage({super.key, required this.myUid, required this.chat});

  static Route<void> route({required String myUid, required ChatModel chat}) =>
      MaterialPageRoute(builder: (_) => ChatPage(myUid: myUid, chat: chat));

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late final ChatController _ctrl;
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode  = FocusNode();

  int _prevMsgCount  = 0;
  double _prevInsets = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = ChatController(myUid: widget.myUid, chat: widget.chat);
    _ctrl.addListener(_onState);
    _ctrl.init();
  }

  // Chamado pelo SO toda vez que o teclado sobe ou desce
  @override
  void didChangeMetrics() {
    final insets = WidgetsBinding.instance.platformDispatcher.views.first
        .viewInsets.bottom;
    // Teclado subiu (insets aumentou) → scroll para o fim no próximo frame,
    // quando o layout já foi recalculado com o novo tamanho
    if (insets > _prevInsets) {
      _prevInsets = insets;
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
    } else {
      _prevInsets = insets;
    }
  }

  void _onState() {
    if (!mounted) return;
    setState(() {});
    final count = _ctrl.messages.length;
    if (count > _prevMsgCount) {
      _prevMsgCount = count;
      // Nova mensagem: jump imediato sem animação para não perder o fim
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
    }
  }

  /// Jump imediato — sem animação, sem depender de maxScrollExtent estático.
  /// Usa jumpTo(double.maxFinite) que o Flutter clipa no valor máximo real,
  /// garantindo que chegamos ao fim independente do momento do layout.
  void _jumpToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.unfocus();
    _ctrl.removeListener(_onState);
    _ctrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    _inputCtrl.clear();
    await _ctrl.sendMessage(text.trim());
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  bool get _isDream => (widget.chat.itemType ?? 'dream') != 'donation';

  void _unfocus() {
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        // Qualquer toque fora do TextField fecha o teclado e remove o foco.
        // behavior.translucent garante que o toque chega aos filhos também.
        onTap: _unfocus,
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _ChatAppBar(
                chat:     chat,
                online:   _ctrl.otherOnline,
                lastSeen: _ctrl.otherLastSeen,
              ),

              if (chat.itemId != null && chat.itemTitle?.isNotEmpty == true)
                _ContextCard(chat: chat, focusNode: _focusNode),

              Expanded(child: _buildBody()),

              _InputBar(
                controller: _inputCtrl,
                focusNode:  _focusNode,
                isDream:    _isDream,
                sending:    _ctrl.sending,
                onSend:     _send,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_ctrl.loading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppTheme.kidsPurpleViolet, strokeWidth: 2),
      );
    }
    if (_ctrl.error != null) {
      return Center(
        child: Text(_ctrl.error!,
            style: const TextStyle(color: AppTheme.errorRed)),
      );
    }
    if (!_ctrl.chatExistsInDb || _ctrl.messages.isEmpty) {
      return _EmptyChat(
        chat:      widget.chat,
        isDream:   _isDream,
        onSuggest: (text) {
          _inputCtrl.text = text;
          _focusNode.requestFocus();
          _inputCtrl.selection =
              TextSelection.fromPosition(TextPosition(offset: text.length));
        },
        onInputTap: () => _focusNode.requestFocus(),
      );
    }

    final msgs     = _ctrl.messages;
    final otherUid = widget.chat.otherUid;
    final total    = msgs.length;

    return ListView.builder(
      controller: _scrollCtrl,
      padding:    const EdgeInsets.fromLTRB(0, 12, 0, 8),
      itemCount:  total,
      itemBuilder: (context, i) {
        final msg    = msgs[i];
        final isMine = msg.senderId == widget.myUid;

        final prevSame = i > 0 &&
            msgs[i - 1].senderId == msg.senderId &&
            msg.timestamp - msgs[i - 1].timestamp < 120000;
        final nextSame = i < total - 1 &&
            msgs[i + 1].senderId == msg.senderId &&
            msgs[i + 1].timestamp - msg.timestamp < 120000;

        final showTs = i == 0 ||
            msg.timestamp - msgs[i - 1].timestamp > 600000;

        return MessageBubble(
          message:           msg,
          isMine:            isMine,
          otherUid:          otherUid,
          showTimestamp:     showTs,
          isGroupedWithPrev: prevSame && !showTs,
          isGroupedWithNext: nextSame,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// APP BAR
// ═══════════════════════════════════════════════════════════════

class _ChatAppBar extends StatelessWidget {
  final ChatModel chat;
  final bool online;
  final int? lastSeen;

  const _ChatAppBar({
    required this.chat,
    required this.online,
    this.lastSeen,
  });

  bool get _isDream => (chat.itemType ?? 'dream') != 'donation';

  String get _presenceText {
    if (online) return 'Online agora';
    if (lastSeen == null) return 'Offline';
    final dt   = DateTime.fromMillisecondsSinceEpoch(lastSeen!);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Visto agora há pouco';
    if (diff.inMinutes < 60) return 'Visto há ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      return 'Visto às '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    return 'Visto em '
        '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final topPad  = MediaQuery.of(context).padding.top;
    final hasItem = chat.itemTitle?.isNotEmpty == true;

    return Container(
      color: AppTheme.primaryBlue,
      padding: EdgeInsets.fromLTRB(0, topPad, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape:  BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25), width: 2),
                ),
                child: ClipOval(child: _AvatarContent(chat: chat, size: 44)),
              ),
              if (online)
                Positioned(
                  bottom: 0, right: -1,
                  child: Container(
                    width: 13, height: 13,
                    decoration: BoxDecoration(
                      color:  AppTheme.kidsGreenDark,
                      shape:  BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.primaryBlue, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chat.otherName ?? 'Usuário',
                    style: const TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.w800,
                      color:      Colors.white,
                      height:     1.15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      if (online)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                                color: AppTheme.kidsGreen,
                                shape: BoxShape.circle),
                          ),
                        ),
                      Text(
                        _presenceText,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: online
                              ? AppTheme.kidsGreen
                              : Colors.white.withValues(alpha: 0.50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (hasItem) ...[
                    const SizedBox(height: 1),
                    Text(
                      '${_isDream ? '💭' : '🎁'}  ${chat.itemTitle!}',
                      style: TextStyle(
                        fontSize:   11,
                        color:      Colors.white.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarContent extends StatelessWidget {
  final ChatModel chat;
  final double size;
  const _AvatarContent({required this.chat, required this.size});

  @override
  Widget build(BuildContext context) {
    final url = chat.otherAvatar;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final emoji  = chat.otherEmoji;
    final letter = chat.otherName?.isNotEmpty == true
        ? chat.otherName![0].toUpperCase()
        : null;
    return Container(
      width: size, height: size,
      color: Colors.white.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          emoji ?? letter ?? '👤',
          style: TextStyle(
            fontSize:   emoji != null ? size * 0.46 : size * 0.38,
            color:      Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CARD DE CONTEXTO + TIMELINE
// ═══════════════════════════════════════════════════════════════

class _ContextCard extends StatefulWidget {
  final ChatModel chat;
  final FocusNode focusNode;
  const _ContextCard({required this.chat, required this.focusNode});

  @override
  State<_ContextCard> createState() => _ContextCardState();
}

class _ContextCardState extends State<_ContextCard> {
  bool _pressed = false;

  bool get _isDream => (widget.chat.itemType ?? 'dream') != 'donation';

  @override
  Widget build(BuildContext context) {
    final chat   = widget.chat;
    final accent = _isDream ? AppTheme.kidsPurpleViolet : AppTheme.kidsPink;
    final label  = _isDream ? 'Sobre o sonho' : 'Sobre a doação';
    final emoji  = _isDream ? '💭' : '🎁';

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); _openDetail(context); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_pressed ? 0.985 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDream
                ? [
                    AppTheme.kidsPurpleViolet.withValues(alpha: 0.08),
                    AppTheme.primaryBlue.withValues(alpha: 0.04),
                  ]
                : [
                    AppTheme.kidsPink.withValues(alpha: 0.08),
                    AppTheme.kidsPinkDeep.withValues(alpha: 0.03),
                  ],
            begin: Alignment.centerLeft,
            end:   Alignment.centerRight,
          ),
          border: Border(
            bottom: BorderSide(
                color: accent.withValues(alpha: 0.12), width: 1),
            left: BorderSide(color: accent, width: 3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            // Thumbnail com glow
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color:      accent.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset:     const Offset(0, 3),
                  ),
                ],
              ),
              child: _ItemThumbnail(
                imageUrl: chat.itemPhotoUrl,
                emoji:    emoji,
                accent:   accent,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color:        accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize:      8.5,
                        fontWeight:    FontWeight.w800,
                        color:         accent,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.itemTitle!,
                    style: TextStyle(
                      fontSize:   13.5,
                      fontWeight: FontWeight.w800,
                      color:      accent,
                      height:     1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Seta animada
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 30, height: 30,
              decoration: BoxDecoration(
                color:  accent.withValues(alpha: _pressed ? 0.18 : 0.10),
                shape:  BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: accent,
                size:  16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context) async {
    HapticFeedback.lightImpact();
    // Unfocus antes de navegar — evita que o Flutter snapshote o foco
    widget.focusNode.unfocus();
    FocusScope.of(context).unfocus();

    final chat    = widget.chat;
    final isDream = _isDream;
    SearchResult? result = await ChatRepository.instance
        .fetchItemForContext(chat.itemId!, chat.itemType ?? 'dream');
    result ??= SearchResult(
      id:       chat.itemId!,
      type:     chat.itemType ?? 'dream',
      title:    chat.itemTitle,
      photoUrl: chat.itemPhotoUrl,
      ownerId:  isDream ? chat.user1 : chat.user2,
    );
    if (!context.mounted) return;

    // .then() garante unfocus quando a tela fechar, independente de RouteObserver
    final route = isDream
        ? DreamDetailPage.route(
            result: result,
            heroTag: 'chat_dream_${chat.itemId}',
            hideCta: true)
        : DonationDetailPage.route(
            result: result,
            heroTag: 'chat_donation_${chat.itemId}',
            hideCta: true);

    Navigator.push(context, route).then((_) {
      if (!context.mounted) return;
      widget.focusNode.unfocus();
      FocusScope.of(context).unfocus();
    });
  }
}

class _ItemThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String emoji;
  final Color accent;
  const _ItemThumbnail(
      {this.imageUrl, required this.emoji, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(imageUrl!,
            width: 40, height: 40, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _ph()),
      );
    }
    return _ph();
  }

  Widget _ph() => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color:        accent.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
      );
}

// ═══════════════════════════════════════════════════════════════
// EMPTY CHAT
// ═══════════════════════════════════════════════════════════════

class _EmptyChat extends StatelessWidget {
  final ChatModel chat;
  final bool isDream;
  final ValueChanged<String> onSuggest;
  final VoidCallback onInputTap;

  const _EmptyChat({
    required this.chat,
    required this.isDream,
    required this.onSuggest,
    required this.onInputTap,
  });

  List<String> get _suggestions => isDream
      ? [
          'Olá! Gostaria de ajudar. ❤️',
          'Como posso contribuir?',
          'Posso conversar sobre este sonho?'
        ]
      : [
          'Olá! Tenho interesse. 😊',
          'O item ainda está disponível?',
          'Podemos conversar?'
        ];

  @override
  Widget build(BuildContext context) {
    final accent = isDream ? AppTheme.kidsPurpleViolet : AppTheme.kidsPink;
    final name   = chat.otherName?.split(' ').first ?? 'a pessoa';

    return GestureDetector(
      onTap:     onInputTap,
      behavior:  HitTestBehavior.opaque,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.08),
                  ),
                ),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDream
                          ? [AppTheme.kidsPurpleViolet, AppTheme.primaryBlue]
                          : [AppTheme.kidsPink, AppTheme.kidsPinkDeep],
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:      accent.withValues(alpha: 0.28),
                        blurRadius: 22,
                        offset:     const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(isDream ? '💌' : '🤝',
                        style: const TextStyle(fontSize: 30)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              isDream
                  ? 'Você pode ajudar a realizar este sonho'
                  : 'Interessado nesta doação?',
              style: const TextStyle(
                fontSize:   19,
                fontWeight: FontWeight.w900,
                color:      AppTheme.primaryBlue,
                height:     1.25,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isDream
                  ? 'Apresente-se e diga como gostaria de ajudar $name.'
                  : 'Envie uma mensagem para combinar os próximos passos com $name.',
              style: TextStyle(
                fontSize: 13.5,
                color:    AppTheme.textSecondary.withValues(alpha: 0.85),
                height:   1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border:       Border.all(color: accent.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Text(isDream ? '✨' : '♻️',
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isDream
                          ? 'Sua ajuda pode aproximar esta criança da realização deste sonho.'
                          : 'Sua retirada ajuda outra família imediatamente.',
                      style: TextStyle(
                        fontSize:   12.5,
                        fontWeight: FontWeight.w600,
                        color:      accent,
                        height:     1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sugestões para começar',
                style: TextStyle(
                  fontSize:      11.5,
                  fontWeight:    FontWeight.w700,
                  color:         AppTheme.textSecondary.withValues(alpha: 0.70),
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _suggestions
                  .map((s) => _SuggestionChip(
                        text:  s,
                        color: accent,
                        onTap: () => onSuggest(s),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Nada é salvo até você enviar a primeira mensagem.',
              style: TextStyle(
                fontSize: 11,
                color:    AppTheme.textSecondary.withValues(alpha: 0.45),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;
  const _SuggestionChip(
      {required this.text, required this.color, required this.onTap});

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withValues(alpha: 0.10)
              : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: widget.color.withValues(alpha: _pressed ? 0.40 : 0.20),
          ),
          boxShadow: _pressed
              ? null
              : [
                  BoxShadow(
                    color:      widget.color.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset:     const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize:   13,
            fontWeight: FontWeight.w600,
            color:      widget.color,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// INPUT BAR
// ═══════════════════════════════════════════════════════════════

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDream;
  final bool sending;
  final ValueChanged<String> onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isDream,
    required this.sending,
    required this.onSend,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
    widget.focusNode.addListener(_onFocus);
  }

  void _onText() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty || widget.sending) return;
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    // padding inferior da safe area (barra de navegação do dispositivo)
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final accent    = widget.isDream
        ? AppTheme.kidsPurpleViolet
        : AppTheme.kidsPink;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomPad),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: _focused
                ? accent.withValues(alpha: 0.20)
                : Colors.grey.withValues(alpha: 0.10),
            width: _focused ? 1.5 : 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset:     const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _focused
                    ? accent.withValues(alpha: 0.04)
                    : const Color(0xFFF2F4F8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _focused
                      ? accent.withValues(alpha: 0.30)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller:         widget.controller,
                focusNode:          widget.focusNode,
                maxLines:           5,
                minLines:           1,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  fontSize: 15,
                  color:    AppTheme.primaryBlue,
                  height:   1.4,
                ),
                decoration: InputDecoration(
                  hintText: widget.isDream
                      ? 'Escreva como deseja ajudar...'
                      : 'Envie uma mensagem ao doador...',
                  hintStyle: TextStyle(
                    fontSize:   14.5,
                    color:      AppTheme.textSecondary.withValues(alpha: 0.50),
                    fontWeight: FontWeight.w400,
                  ),
                  border:         InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve:    Curves.easeOutBack,
            width:    _hasText ? 46 : 40,
            height:   _hasText ? 46 : 40,
            decoration: BoxDecoration(
              gradient: _hasText
                  ? LinearGradient(
                      colors: widget.isDream
                          ? [AppTheme.kidsPurpleViolet, AppTheme.primaryBlue]
                          : [AppTheme.kidsPink, AppTheme.kidsPinkDeep],
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    )
                  : null,
              color:  _hasText ? null : const Color(0xFFEBEDF2),
              shape:  BoxShape.circle,
              boxShadow: _hasText
                  ? [
                      BoxShadow(
                        color:      accent.withValues(alpha: 0.32),
                        blurRadius: 12,
                        offset:     const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(23),
                onTap: _hasText && !widget.sending ? _submit : null,
                child: Center(
                  child: widget.sending
                      ? SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _hasText ? Colors.white : accent,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          size:  20,
                          color: _hasText
                              ? Colors.white
                              : Colors.grey.shade400,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
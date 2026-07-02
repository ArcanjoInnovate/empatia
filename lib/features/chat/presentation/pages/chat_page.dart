// lib/features/chat/presentation/pages/chat_page.dart

import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/widget/verification_block_dialog.dart';
import 'package:empatia/features/profile/presentation/page/profile/public_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:empatia/core/theme/app_avatars.dart';
import 'package:empatia/core/widget/avatar_render.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/chat/controller/chat_controller.dart';
import 'package:empatia/features/chat/data/models/chat_message_model.dart';
import 'package:empatia/features/chat/data/models/chat_model.dart';
import 'package:empatia/features/chat/data/repositories/chat_repository.dart';
import 'package:empatia/features/chat/presentation/widgets/message_bubble.dart';
import 'package:empatia/features/donation/presentation/pages/donation_detail_page.dart';
import 'package:empatia/features/dream/presentation/pages/dream_detail_page.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:empatia/features/search/data/repositories/search_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

// ═══════════════════════════════════════════════════════════════
// CHAT PAGE
// ═══════════════════════════════════════════════════════════════

class ChatPage extends StatefulWidget {
  final String myUid;
  final ChatModel chat;
  /// true quando aberto a partir de DreamDetailPage ou DonationDetailPage
  final bool fromDetail;

  const ChatPage({
    super.key,
    required this.myUid,
    required this.chat,
    this.fromDetail = false,
  });

  static Route<void> route({
    required String myUid,
    required ChatModel chat,
    bool fromDetail = false,
  }) =>
      MaterialPageRoute(
          builder: (_) =>
              ChatPage(myUid: myUid, chat: chat, fromDetail: fromDetail));

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
    _ctrl = ChatController(
        myUid: widget.myUid, chat: widget.chat, fromDetail: widget.fromDetail);
    _ctrl.addListener(_onState);
    _ctrl.init();
  }

  @override
  void didChangeMetrics() {
    final insets = WidgetsBinding.instance.platformDispatcher.views.first
        .viewInsets.bottom;
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
    }
    // Mostra efeito de conclusão quando chegar — só 1x por sessão, mesma
    // lógica do diálogo de terceiro. Sem essa trava local, cada
    // notifyListeners() disparado enquanto showCompletionEffect ainda não
    // foi dispensado (dismissCompletionEffect só roda dentro do próprio
    // dialog, no próximo frame) agendava OUTRO popup — daí os múltiplos
    // diálogos abrindo em sequência.
    if (_ctrl.showCompletionEffect && !_completionDialogShown) {
      _completionDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCompletionOverlay();
      });
    }
    // Item já concluído por outra pessoa (não este chat) — bloqueia e avisa.
    // Só dispara uma vez por usuário+chat+item (persistido no RTDB via
    // ChatController), não mais uma vez por sessão/abertura do chat.
    if (_ctrl.showUnavailableDialog && !_unavailableDialogShown) {
      _unavailableDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showItemUnavailableDialog();
      });
    }
  }

  bool _unavailableDialogShown = false;
  bool _completionDialogShown  = false;

  void _showItemUnavailableDialog() {
    final isDream = _isDream;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogCtx) => _ItemUnavailableDialog(
        isDream: isDream,
        itemTitle: widget.chat.itemTitle,
        onClose: () {
          Navigator.of(dialogCtx).pop();
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

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

  void _showCompletionOverlay() {
    _ctrl.dismissCompletionEffect();
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _CompletionDialog(
        itemTitle: widget.chat.itemTitle ?? 'Item',
        isDream:   _isDream,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: _unfocus,
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _ChatAppBar(
                    chat:      chat,
                    online:    _ctrl.otherOnline,
                    lastSeen:  _ctrl.otherLastSeen,
                    completed: _ctrl.completed,
                  ),

                  if (chat.itemId != null && chat.itemTitle?.isNotEmpty == true)
                    _ContextCard(chat: chat, focusNode: _focusNode),

                  // Banner de doação concluída — informativo, não bloqueia o input
                  if (_ctrl.completed)
                    widget.fromDetail
                        ? _HistoricCompletedBanner(isDream: _isDream, itemTitle: chat.itemTitle)
                        : _CompletedBanner(isDream: _isDream, itemTitle: chat.itemTitle),

                  // Banner de troca de contexto — aparece quando o usuário abre
                  // o chat por um item diferente do que está ativo na conversa
                  if (_ctrl.isContextSwitch)
                    _ContextSwitchBanner(
                      isDream:   _isDream,
                      itemTitle: chat.itemTitle,
                    ),

                  Expanded(child: _buildBody()),

                  // Barra de entrega — oculta quando concluído, quando eu enviei
                  // um request sem resposta, ou quando ainda não há ao menos
                  // 1 mensagem de texto de cada lado (evita confirm prematuro)
                  // Oculta quando: concluído, request pendente enviado por
                  // mim, troca de contexto, ou item já indisponível (foi
                  // concluído em outro chat) — sem o itemUnavailable aqui,
                  // dava pra mandar um novo pedido de confirmação mesmo com
                  // o campo de texto travado.
                  if (!_ctrl.completed && !_ctrl.itemUnavailable && !_ctrl.iSentPendingRequest && !_ctrl.isContextSwitch && _ctrl.canSendDelivery)
                    _DeliveryBar(
                      chat:              chat,
                      isDream:           _isDream,
                      sending:           _ctrl.sending,
                      hasPendingRequest: _ctrl.hasPendingRequest,
                      iAmPublisher:      _ctrl.iAmPublisher,
                      onDelivery: () async {
                        final title = widget.chat.itemTitle ?? 'Item';
                        final type  = widget.chat.itemType  ?? 'dream';
                        await _ctrl.sendDeliveryRequest(
                          itemTitle: title,
                          itemType:  type,
                        );
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) => _jumpToBottom());
                      },
                    ),

                  _InputBar(
                    controller: _inputCtrl,
                    focusNode:  _focusNode,
                    isDream:    _isDream,
                    sending:    _ctrl.sending,
                    // Bloqueia digitar/enviar quando: este chat já concluiu
                    // a troca (completed), o item foi concluído por outra
                    // pessoa (itemUnavailable), OU o controller ainda está
                    // carregando (loading) — sem o loading aqui, existia uma
                    // janela onde itemUnavailable ainda não tinha sido
                    // determinado (é assíncrono) e o campo ficava digitável,
                    // permitindo criar uma conversa real sobre um item já
                    // indisponível antes do bloqueio "pegar".
                    disabled:   _ctrl.completed || _ctrl.itemUnavailable || _ctrl.loading,
                    loading:    _ctrl.loading,
                    itemUnavailable: _ctrl.itemUnavailable,
                    onSend:     _send,
                  ),
                ],
              ),

              // Confetes flutuantes quando showCompletionEffect (já foi para dialog,
              // mas mantemos uma camada de partículas leve sobre o chat)
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

    // Pré-calcula quais delivery_requests já foram respondidos
    // para esconder os botões de todos (sender e receptor)
    final answeredRequestIds = <String>{};
    for (final m in msgs) {
      if ((m.type == ChatMessageType.deliveryConfirmed ||
           m.type == ChatMessageType.deliveryDenied) &&
          m.deliveryRequestId != null) {
        answeredRequestIds.add(m.deliveryRequestId!);
      }
    }

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
          isAnswered: msg.type == ChatMessageType.deliveryRequest
              && answeredRequestIds.contains(msg.id),
          onRespondDelivery: (requestMsg, confirmed) {
            _ctrl.respondDelivery(
              requestMsg: requestMsg,
              confirmed:  confirmed,
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BANNER DE DOAÇÃO CONCLUÍDA (persistente no topo)
// ═══════════════════════════════════════════════════════════════

class _CompletedBanner extends StatelessWidget {
  final bool isDream;
  final String? itemTitle;
  const _CompletedBanner({required this.isDream, this.itemTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isDream
                  ? 'Sonho realizado! Esta doação foi concluída.'
                  : 'Doação concluída com sucesso!',
              style: const TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w700,
                color:      Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BANNER DE TROCA DE CONTEXTO
// ═══════════════════════════════════════════════════════════════

class _ContextSwitchBanner extends StatelessWidget {
  final bool isDream;
  final String? itemTitle;
  const _ContextSwitchBanner({required this.isDream, this.itemTitle});

  @override
  Widget build(BuildContext context) {
    final accent = isDream ? AppTheme.kidsPurpleViolet : AppTheme.kidsPink;
    final label  = isDream ? 'Novo sonho selecionado' : 'Nova doação selecionada';
    final body   = isDream
        ? 'Esta conversa será vinculada ao sonho abaixo. Envie uma mensagem para iniciar o processo.'
        : 'Esta conversa será vinculada à doação abaixo. Envie uma mensagem para iniciar o processo.';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color:        accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color:  accent.withValues(alpha: 0.12),
                shape:  BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isDream ? '💭' : '🎁',
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:        accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            fontSize:      7.5,
                            fontWeight:    FontWeight.w800,
                            color:         accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (itemTitle?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      itemTitle!,
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      accent,
                        height:     1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize:   11.5,
                      fontWeight: FontWeight.w500,
                      color:      accent.withValues(alpha: 0.75),
                      height:     1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BANNER HISTÓRICO — informativo, não bloqueia o input
// ═══════════════════════════════════════════════════════════════

class _HistoricCompletedBanner extends StatelessWidget {
  final bool isDream;
  final String? itemTitle;
  const _HistoricCompletedBanner({required this.isDream, this.itemTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withValues(alpha: 0.08),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF16A34A), width: 0),
          top:    BorderSide(color: Color(0xFF16A34A), width: 0),
          left:   BorderSide(color: Color(0xFF16A34A), width: 3),
        ),
      ),
      child: Row(
        children: [
          const Text('✅', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isDream
                  ? 'Sonho realizado! Envie uma mensagem para continuar a conversa.'
                  : 'Doação concluída! Envie uma mensagem para continuar a conversa.',
              style: const TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      Color(0xFF15803D),
                height:     1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DIALOG DE CONCLUSÃO (efeito visual único)
// ═══════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════════════════
// DIÁLOGO — item já indisponível (terceiro, não participou da conclusão)
// ══════════════════════════════════════════════════════════════════════════════

class _ItemUnavailableDialog extends StatefulWidget {
  final bool isDream;
  final String? itemTitle;
  final VoidCallback onClose;

  const _ItemUnavailableDialog({
    required this.isDream,
    required this.itemTitle,
    required this.onClose,
  });

  @override
  State<_ItemUnavailableDialog> createState() => _ItemUnavailableDialogState();
}

class _ItemUnavailableDialogState extends State<_ItemUnavailableDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutBack);
    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withValues(alpha: 0.18),
                blurRadius: 40,
                offset:     const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF64748B), Color(0xFF94A3B8)],
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:      const Color(0xFF64748B).withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset:     const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.isDream ? '🌙' : '📦',
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                widget.isDream ? 'Sonho já realizado' : 'Doação já concluída',
                style: const TextStyle(
                  fontSize:   20,
                  fontWeight: FontWeight.w900,
                  color:      Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              if (widget.itemTitle != null && widget.itemTitle!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.itemTitle!,
                    style: const TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF475569),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Text(
                widget.isDream
                    ? 'Esse sonho já foi realizado por outra pessoa. Não é mais possível conversar sobre ele.'
                    : 'Essa doação já foi entregue para outra pessoa. Não é mais possível conversar sobre ela.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height:   1.45,
                  color:    Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334155),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Entendi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionDialog extends StatefulWidget {
  final String itemTitle;
  final bool isDream;
  const _CompletionDialog({required this.itemTitle, required this.isDream});

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _confettiCtrl;
  late final Animation<double> _scale;
  final _rng = math.Random();

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scale = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);

    // Gera partículas de confete
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x:     _rng.nextDouble(),
        y:     _rng.nextDouble() * -0.5,
        vx:    (_rng.nextDouble() - 0.5) * 0.4,
        vy:    _rng.nextDouble() * 0.6 + 0.3,
        color: _confettiColors[_rng.nextInt(_confettiColors.length)],
        size:  _rng.nextDouble() * 8 + 5,
        rot:   _rng.nextDouble() * math.pi * 2,
      ));
    }

    _scaleCtrl.forward();
    _confettiCtrl.forward();
  }

  static const _confettiColors = [
    Color(0xFFFFD700), Color(0xFFFF6B9D), Color(0xFF7C3AED),
    Color(0xFF22C55E), Color(0xFF3B82F6), Color(0xFFF97316),
  ];

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Partículas de confete
          AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (_, __) {
              return SizedBox(
                width: 320, height: 400,
                child: CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiCtrl.value,
                  ),
                ),
              );
            },
          ),

          // Card principal
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withValues(alpha: 0.18),
                    blurRadius: 40,
                    offset:     const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone animado
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF4ADE80)],
                        begin:  Alignment.topLeft,
                        end:    Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:      const Color(0xFF22C55E).withValues(alpha: 0.40),
                          blurRadius: 24,
                          offset:     const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🎉', style: TextStyle(fontSize: 38)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    widget.isDream ? 'Sonho Realizado!' : 'Doação Concluída!',
                    style: const TextStyle(
                      fontSize:   22,
                      fontWeight: FontWeight.w900,
                      color:      AppTheme.primaryBlue,
                      height:     1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    '"${widget.itemTitle}"',
                    style: const TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w700,
                      color:      AppTheme.kidsPurpleViolet,
                      fontStyle:  FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    widget.isDream
                        ? 'Você ajudou a realizar o sonho de uma criança. Isso ficará para sempre no histórico de doações! ❤️'
                        : 'Esta doação foi registrada no histórico de ambos os participantes e vale pontos no ranking! 🏆',
                    style: TextStyle(
                      fontSize: 13.5,
                      color:    AppTheme.textSecondary.withValues(alpha: 0.80),
                      height:   1.55,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.kidsGreenDeep,
                        foregroundColor: Colors.white,
                        padding:  const EdgeInsets.symmetric(vertical: 14),
                        shape:    RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Incrível! 🎊',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy, size, rot;
  final Color color;
  _Particle({
    required this.x, required this.y, required this.vx,
    required this.vy, required this.size, required this.rot,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  const _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final cx = (p.x + p.vx * progress) * size.width;
      final cy = (p.y + p.vy * progress) * size.height;
      final opacity = (1.0 - progress * 0.8).clamp(0.0, 1.0);

      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rot + progress * math.pi * 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
// APP BAR
// ═══════════════════════════════════════════════════════════════

class _ChatAppBar extends StatelessWidget {
  final ChatModel chat;
  final bool online;
  final int? lastSeen;
  final bool completed;

  const _ChatAppBar({
    required this.chat,
    required this.online,
    this.lastSeen,
    this.completed = false,
  });

  bool get _isDream => (chat.itemType ?? 'dream') != 'donation';

  String get _presenceText {
    if (completed) return '✅ Doação concluída';
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

  /// Abre o perfil público do outro participante, se soubermos o UID dele.
  /// Usa os dados já disponíveis no [chat] como fallback instantâneo —
  /// a PublicProfilePage busca a versão mais atual em `UsersPublic/{uid}`.
  void _openProfile(BuildContext context) {
    if (chat.otherUid.isEmpty) return;
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PublicProfilePage.route(
        uid: chat.otherUid,
        fallbackName: chat.otherName,
        fallbackAvatar: chat.otherEmoji,
        fallbackImage: chat.otherAvatar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad  = MediaQuery.of(context).padding.top;
    final hasItem = chat.itemTitle?.isNotEmpty == true;

    return Container(
      color: completed ? AppTheme.kidsGreenDark : AppTheme.primaryBlue,
      padding: EdgeInsets.fromLTRB(0, topPad, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          // ── Área clicável: avatar + nome + presença + item ──────────
          // Leva ao perfil público do outro participante da conversa.
          Expanded(
            child: InkWell(
              onTap: () => _openProfile(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
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
                        if (online && !completed)
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
                        padding: const EdgeInsets.symmetric(vertical: 4),
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
                                if (online && !completed)
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
                                    color: (online && !completed)
                                        ? AppTheme.kidsGreen
                                        : Colors.white.withValues(alpha: 0.70),
                                    fontWeight: FontWeight.w600,
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
                    // Indicador sutil de que a área é navegável
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.45), size: 20),
                  ],
                ),
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

    if (AppAvatars.isAssetPath(emoji)) {
      return Container(
        width: size, height: size,
        color: Colors.white.withValues(alpha: 0.15),
        child: AvatarRender(value: emoji, size: size),
      );
    }

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
// CARD DE CONTEXTO
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
            bottom: BorderSide(color: accent.withValues(alpha: 0.12), width: 1),
            left:   BorderSide(color: accent, width: 3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 30, height: 30,
              decoration: BoxDecoration(
                color:  accent.withValues(alpha: _pressed ? 0.18 : 0.10),
                shape:  BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_rounded, color: accent, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context) async {
    HapticFeedback.lightImpact();
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

    final currentUser = context.read<UserModel?>();
    if (currentUser == null) {
      if (FirebaseAuth.instance.currentUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Carregando seu perfil... tente de novo em um instante.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      showVerificationRequiredDialog(
        context,
        feature: isDream
            ? 'ver os detalhes deste sonho'
            : 'ver os detalhes desta doação',
      );
      return;
    }
    if (!ProfileService.isFullyVerified(currentUser)) {
      showVerificationRequiredDialog(
        context,
        feature: isDream
            ? 'ver os detalhes deste sonho'
            : 'ver os detalhes desta doação',
      );
      return;
    }

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
  const _ItemThumbnail({this.imageUrl, required this.emoji, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(imageUrl!, width: 40, height: 40, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _ph()),
      );
    }
    return _ph();
  }

  Widget _ph() => Container(
        width: 40, height: 40,
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
      ? ['Olá! Gostaria de ajudar. ❤️', 'Como posso contribuir?', 'Posso conversar sobre este sonho?']
      : ['Olá! Tenho interesse. 😊', 'O item ainda está disponível?', 'Podemos conversar?'];

  @override
  Widget build(BuildContext context) {
    final accent = isDream ? AppTheme.kidsPurpleViolet : AppTheme.kidsPink;
    final name   = chat.otherName?.split(' ').first ?? 'a pessoa';

    return GestureDetector(
      onTap:    onInputTap,
      behavior: HitTestBehavior.opaque,
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
              isDream ? 'Você pode ajudar a realizar este sonho' : 'Interessado nesta doação?',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue, height: 1.25),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isDream
                  ? 'Apresente-se e diga como gostaria de ajudar $name.'
                  : 'Envie uma mensagem para combinar os próximos passos com $name.',
              style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary.withValues(alpha: 0.85), height: 1.6),
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
                  Text(isDream ? '✨' : '♻️', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isDream
                          ? 'Sua ajuda pode aproximar esta criança da realização deste sonho.'
                          : 'Sua retirada ajuda outra família imediatamente.',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: accent, height: 1.45),
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
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textSecondary.withValues(alpha: 0.70), letterSpacing: 0.3),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _suggestions
                  .map((s) => _SuggestionChip(text: s, color: accent, onTap: () => onSuggest(s)))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Nada é salvo até você enviar a primeira mensagem.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withValues(alpha: 0.45)),
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
  const _SuggestionChip({required this.text, required this.color, required this.onTap});

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color:  _pressed ? widget.color.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: widget.color.withValues(alpha: _pressed ? 0.40 : 0.20)),
          boxShadow: _pressed ? null : [
            BoxShadow(color: widget.color.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(widget.text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: widget.color)),
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
  final bool disabled;
  final bool loading;
  final bool itemUnavailable;
  final ValueChanged<String> onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isDream,
    required this.sending,
    required this.onSend,
    this.disabled = false,
    this.loading = false,
    this.itemUnavailable = false,
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
    if (text.isEmpty || widget.sending || widget.disabled) return;
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final accent    = widget.isDream ? AppTheme.kidsPurpleViolet : AppTheme.kidsPink;

    if (widget.disabled) {
      // Enquanto ainda está carregando o estado do chat, mostra um
      // placeholder neutro — não afirma "concluída" antes de saber.
      if (widget.loading) {
        return Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: const Center(
            child: SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      final message = widget.itemUnavailable
          ? '🔒 Esta conversa não está mais disponível'
          : '✅ Esta conversa foi concluída';

      return Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              fontSize:   13,
              color:      (widget.itemUnavailable ? AppTheme.textSecondary : AppTheme.kidsGreenDark)
                  .withValues(alpha: 0.80),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _focused ? accent.withValues(alpha: 0.04) : const Color(0xFFF2F4F8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _focused ? accent.withValues(alpha: 0.30) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller:         widget.controller,
                focusNode:          widget.focusNode,
                maxLines:           5,
                minLines:           1,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15, color: AppTheme.primaryBlue, height: 1.4),
                decoration: InputDecoration(
                  hintText: widget.isDream ? 'Escreva como deseja ajudar...' : 'Envie uma mensagem ao doador...',
                  hintStyle: TextStyle(fontSize: 14.5, color: AppTheme.textSecondary.withValues(alpha: 0.50), fontWeight: FontWeight.w400),
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
                  ? [BoxShadow(color: accent.withValues(alpha: 0.32), blurRadius: 12, offset: const Offset(0, 4))]
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: _hasText ? Colors.white : accent),
                        )
                      : Icon(Icons.send_rounded, size: 20, color: _hasText ? Colors.white : Colors.grey.shade400),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DELIVERY BAR
// ═══════════════════════════════════════════════════════════════

class _DeliveryBar extends StatelessWidget {
  final ChatModel chat;
  final bool isDream;
  final bool sending;
  final bool hasPendingRequest;
  /// true quando EU sou o dono da publicação — só o dono pode iniciar a
  /// declaração de entrega/recebimento. Calculado a partir do userId real
  /// do item, nunca escolhido na UI.
  final bool iAmPublisher;
  final Future<void> Function() onDelivery;

  const _DeliveryBar({
    required this.chat,
    required this.isDream,
    required this.sending,
    required this.hasPendingRequest,
    required this.iAmPublisher,
    required this.onDelivery,
  });

  @override
  Widget build(BuildContext context) {
    if (chat.itemId == null) return const SizedBox.shrink();

    // Se há request pendente, mostra aviso em vez dos botões
    if (hasPendingRequest) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color:        AppTheme.kidsAmber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.kidsAmber.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⏳', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                'Aguardando sua confirmação de entrega acima',
                maxLines: 2,
                style: TextStyle(
                  fontSize:   10,
                  fontWeight: FontWeight.w600,
                  color:      AppTheme.kidsAmber,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Só o dono da publicação vê o botão de iniciar a declaração — o outro
    // lado só vê um aviso, e vai poder CONFIRMAR quando o dono declarar.
    if (!iAmPublisher) {
      final waitingText = isDream
          ? 'Aguardando o dono do sonho confirmar o recebimento'
          : 'Aguardando quem doou confirmar a entrega';
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color:        Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🤝', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  waitingText,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize:   10,
                    fontWeight: FontWeight.w600,
                    color:      AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // dream    → dono do sonho declara que RECEBEU o item
    // donation → dono da doação declara que ENTREGOU o item
    // Dentro de _DeliveryBar.build(), troca o bloco final por:

    final label = isDream ? 'Recebi o item' : 'Entreguei o item';
    final icon  = isDream ? Icons.inventory_2_rounded : Icons.local_shipping_rounded;
    final gradientColors = isDream
        ? [AppTheme.kidsPurpleViolet, AppTheme.primaryBlue]
        : [AppTheme.kidsPink, AppTheme.kidsPinkDeep];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      color: Colors.white,
      child: _DeliveryChip(
        label:      label,
        icon:       icon,
        gradient:   gradientColors,
        sending:    sending,
        onTap:      () => _confirm(context),
      ),
    );
  }

  void _confirm(BuildContext context) {
    final label = isDream
        ? 'Você quer declarar que recebeu o item?'
        : 'Você quer declarar que entregou o item?';
    const sub = 'O outro participante precisará confirmar.';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueMid.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping_rounded, color: AppTheme.primaryBlueMid, size: 28),
            ),
            const SizedBox(height: 16),
            Text(label,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue, height: 1.25),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(sub,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary.withValues(alpha: 0.80), height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlueMid,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () { Navigator.pop(context); onDelivery(); },
                child: const Text('Confirmar e notificar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar',
                  style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.70))),
            ),
          ],
        ),
      ),
    );
  }
}

// _DeliveryChip completo, substitui o antigo:

class _DeliveryChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final bool sending;
  final VoidCallback onTap;
  const _DeliveryChip({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.sending,
    required this.onTap,
  });

  @override
  State<_DeliveryChip> createState() => _DeliveryChipState();
}

class _DeliveryChipState extends State<_DeliveryChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); if (!widget.sending) widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.gradient,
            begin: Alignment.centerLeft,
            end:   Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      widget.gradient.first.withValues(alpha: _pressed ? 0.18 : 0.32),
              blurRadius: _pressed ? 8 : 16,
              offset:     Offset(0, _pressed ? 2 : 6),
            ),
          ],
        ),
        child: widget.sending
            ? const Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 19),
                  const SizedBox(width: 9),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize:   14.5,
                      fontWeight: FontWeight.w800,
                      color:      Colors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
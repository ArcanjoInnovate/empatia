// lib/core/service/notification_display_service.dart
//
// Responsabilidade, hoje simplificada por decisão do produto (a
// personalização visual do push de sistema — avatar composto, canal
// diferenciado, etc — foi retirada por não ser prioridade de MVP):
//
//   1) App ABERTO (foreground): mostra um banner interno no topo da
//      tela (estilo iOS/WhatsApp) em vez de deixar o push de sistema
//      aparecer por cima de quem já está usando o app.
//   2) App minimizado/fechado: volta a usar o comportamento PADRÃO do
//      FCM — o próprio Android exibe a notificação sozinho, com o
//      bloco `notification` que a Cloud Function manda (ver
//      notifications.ts). Nenhum código aqui precisa desenhar nada
//      pra esse caso.
//   3) Toque na notificação (qualquer estado do app): sempre navega
//      pro chat certo.
// ─────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:empatia/core/navigation/router_observer.dart';
import 'package:empatia/features/chat/data/models/chat_model.dart';
import 'package:empatia/features/chat/data/repositories/chat_repository.dart';
import 'package:empatia/features/chat/presentation/pages/chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationDisplayService {
  NotificationDisplayService._();
  static final NotificationDisplayService instance =
      NotificationDisplayService._();

  final _db = FirebaseDatabase.instance.ref();
  bool _initialized = false;

  // ══════════════════════════════════════════════════════════════
  // INIT
  // ══════════════════════════════════════════════════════════════

  /// Chamado uma vez, logo depois de Firebase.initializeApp() no
  /// main.dart.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // App aberto → banner interno, não o push de sistema (esse só
    // apareceria de qualquer forma se a mensagem tivesse o bloco
    // `notification`; como continuamos mandando esse bloco pro
    // Android saber exibir sozinho em background/fechado, também
    // precisamos ouvir aqui pra decidir mostrar o banner em vez disso
    // quando o app já está na tela).
    FirebaseMessaging.onMessage.listen(_showInAppBanner);

    // Toque na notificação de sistema com o app em background (vivo,
    // só não em primeiro plano).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
  }

  /// Chamado uma vez, logo depois do primeiro frame renderizado
  /// (main.dart) — cobre o cenário "app estava TOTALMENTE fechado e o
  /// toque na notificação é o que abriu o app do zero". Nesse caso,
  /// nenhum listener "ao vivo" dispara — perguntamos direto pro FCM
  /// qual foi a mensagem que originou essa abertura.
  Future<void> checkLaunchedFromNotification() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message == null) return;
    await _openChat(message.data['chatId'] as String?);
  }

  // ══════════════════════════════════════════════════════════════
  // BANNER INTERNO — app em primeiro plano
  // ══════════════════════════════════════════════════════════════

  OverlayEntry? _currentBannerEntry;
  Timer? _bannerDismissTimer;

  void _showInAppBanner(RemoteMessage message) {
    final data = message.data;
    final title = data['title'] ?? message.notification?.title ?? '';
    final body  = data['body']  ?? message.notification?.body  ?? '';
    if (title.isEmpty && body.isEmpty) return;

    final chatId   = data['chatId'] as String?;
    final imageUrl = data['senderImageUrl'] as String?;

    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    // Só uma por vez — uma mensagem nova troca o banner anterior em vez
    // de empilhar (mesmo espírito do agrupamento por chat no resto do
    // app).
    _dismissBanner();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _InAppNotificationBanner(
        title: title,
        body: body,
        imageUrl: imageUrl,
        onTap: () {
          _dismissBanner();
          _openChat(chatId);
        },
        onDismiss: _dismissBanner,
      ),
    );

    _currentBannerEntry = entry;
    overlay.insert(entry);

    _bannerDismissTimer = Timer(const Duration(seconds: 4), _dismissBanner);
  }

  void _dismissBanner() {
    _bannerDismissTimer?.cancel();
    _bannerDismissTimer = null;
    try {
      _currentBannerEntry?.remove();
    } catch (_) {
      // já removido — ignora
    }
    _currentBannerEntry = null;
  }

  // ══════════════════════════════════════════════════════════════
  // NAVEGAÇÃO AO TOCAR
  // ══════════════════════════════════════════════════════════════

  void _handleTap(RemoteMessage message) {
    _openChat(message.data['chatId'] as String?);
  }

  Future<void> _openChat(String? chatId) async {
    if (chatId == null || chatId.isEmpty) return;

    // Espera a sessão do Firebase Auth terminar de restaurar, se
    // necessário — no cenário "app abriu agora, do zero, por causa da
    // notificação", esse código pode rodar antes do login persistido
    // ainda ter voltado. Sem esperar aqui, o toque simplesmente não
    // navegava pra lugar nenhum na primeira abertura do dia.
    var myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      try {
        final user = await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((u) => u != null)
            .timeout(const Duration(seconds: 15));
        myUid = user?.uid;
      } catch (_) {
        // Sem sessão nenhuma restaurada a tempo — provavelmente
        // deslogado de verdade, não tem pra onde navegar mesmo.
      }
    }
    if (myUid == null) return;

    // Espera o Navigator existir — o post-frame callback do main.dart
    // normalmente já garante isso, mas fica como rede de segurança.
    var nav = rootNavigatorKey.currentState;
    var attempts = 0;
    while (nav == null && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      nav = rootNavigatorKey.currentState;
      attempts++;
    }
    if (nav == null) return;

    try {
      final snap = await _db.child('Chats/$chatId').get();
      if (!snap.exists || snap.value is! Map) return;
      final chatMap = snap.value as Map;

      final u1 = chatMap['user1']?.toString() ?? '';
      final u2 = chatMap['user2']?.toString() ?? '';
      final otherUid = u1 == myUid ? u2 : u1;

      // fromChatNode() sozinho não busca nome/foto do outro usuário —
      // sem isso, a tela de chat abria mostrando "Usuário" genérico e
      // sem avatar até algo mais tarde recarregar essa informação.
      String? otherName, otherAvatar, otherEmoji;
      try {
        final uSnap = await _db.child('UsersPublic/$otherUid').get();
        if (uSnap.exists && uSnap.value is Map) {
          final u = uSnap.value as Map;
          otherName   = u['name']?.toString();
          otherAvatar = u['profileImage']?.toString();
          otherEmoji  = u['profileEmoji']?.toString();
        }
      } catch (e) {
        debugPrint(
          '[NotificationDisplayService] falha ao buscar UsersPublic/$otherUid: $e',
        );
      }

      final chat = ChatModel(
        chatId: chatId,
        user1: u1,
        user2: u2,
        otherUid: otherUid,
        origin: ChatOriginExt.fromString(chatMap['item_type']?.toString()),
        itemId: chatMap['item_id']?.toString(),
        itemTitle: chatMap['item_title']?.toString(),
        itemType: chatMap['item_type']?.toString(),
        itemPhotoUrl: chatMap['item_photo_url']?.toString(),
        otherName: otherName,
        otherAvatar: otherAvatar,
        otherEmoji: otherEmoji,
      );

      nav.push(ChatPage.route(myUid: myUid, chat: chat));
      // Sincroniza presença/last_read normalmente ao entrar no chat.
      unawaited(ChatRepository.instance.markAsRead(chatId, myUid));
    } catch (e) {
      debugPrint('[NotificationDisplayService] falha ao abrir chat: $e');
    }
  }
}

// ══════════════════════════════════════════════════════════════
// BANNER — cartão que desliza do topo, estilo iOS/WhatsApp, exibido
// só quando o app já está aberto (ver _showInAppBanner acima).
// ══════════════════════════════════════════════════════════════

class _InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppNotificationBanner({
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<_InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _dismissWithAnimation() {
    _ctrl.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topInset + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slide,
        child: SafeArea(
          bottom: false,
          child: Dismissible(
            key: const ValueKey('in_app_notification_banner'),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismiss(),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {
                  widget.onTap();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: (widget.imageUrl != null &&
                                  widget.imageUrl!.isNotEmpty)
                              ? Image.network(
                                  widget.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _bannerFallbackAvatar(),
                                )
                              : _bannerFallbackAvatar(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (widget.body.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.80),
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _dismissWithAnimation,
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bannerFallbackAvatar() => Container(
        color: const Color(0xFF8B5CF6),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
      );
}
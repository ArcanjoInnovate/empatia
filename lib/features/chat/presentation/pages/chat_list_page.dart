// lib/features/chat/presentation/pages/chat_list_page.dart

import 'dart:async';

import 'package:empatia/core/theme/app_icons.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/chat/data/models/chat_model.dart';
import 'package:empatia/features/chat/data/repositories/chat_repository.dart';
import 'package:empatia/features/chat/presentation/widgets/chat_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chat_page.dart';

// ═══════════════════════════════════════════════════════════════
// CHAT LIST PAGE
// ═══════════════════════════════════════════════════════════════

class ChatListPage extends StatefulWidget {
  final String myUid;
  final String? myName;
  final String? myEmoji;
  final String? myAvatar;

  const ChatListPage({
    super.key,
    required this.myUid,
    this.myName,
    this.myEmoji,
    this.myAvatar,
  });

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with SingleTickerProviderStateMixin {
  final _repo = ChatRepository.instance;
  late final TabController _tab;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    // 🔧 FIX: antes o listener só atualizava `_tabIndex` quando
    // `!_tab.indexIsChanging` — ou seja, só DEPOIS que a animação interna
    // do TabController (usada por padrão para deslizar o indicador de uma
    // TabBar/TabBarView) terminasse. Como aqui não existe TabBar/TabBarView
    // sendo arrastada (o seletor é o `_SegmentedControl` customizado), essa
    // animação não tem nenhum propósito visual — só atrasava a atualização
    // da lista filtrada em ~300ms+ a cada troca, sem necessidade.
    //
    // `_tab.index` já é atualizado para o novo valor no exato instante em
    // que `animateTo()` é chamado (antes mesmo da animação começar), então
    // reagir a QUALQUER mudança — não só ao fim da animação — deixa a
    // troca de tab instantânea.
    _tab.addListener(() {
      if (_tab.index != _tabIndex) {
        HapticFeedback.selectionClick();
        setState(() => _tabIndex = _tab.index);
      }
    });

    // 🔧 Repara, em segundo plano, chats afetados pelo bug antigo que
    // resetava `completed` ao enviar mensagem depois de uma conclusão.
    // Fire-and-forget: qualquer correção aparece sozinha via inboxStream,
    // sem precisar de refresh manual. Seguro de rodar toda vez que a
    // lista abre — não faz nada em chats já consistentes.
    _repo.repairAllChatsForUser(widget.myUid);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: StreamBuilder<List<ChatModel>>(
          stream: _repo.inboxStream(widget.myUid),
          builder: (context, snap) {
            final all      = snap.data ?? [];
            final loading  = snap.connectionState == ConnectionState.waiting &&
                all.isEmpty;
            final filtered = _filter(all, _tabIndex);
            final urgent   = filtered
                .where((c) => c.unread > 0)
                .toList();
            final rest     = filtered
                .where((c) => c.unread == 0)
                .toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ── HEADER ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _ChatHeader(
                    allChats: all,
                    tabController: _tab,
                    tabIndex: _tabIndex,
                  ),
                ),

                if (loading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.kidsPurpleViolet,
                        strokeWidth: 2,
                      ),
                    ),
                  )

                else if (snap.hasError)
                  SliverFillRemaining(
                    child: _ErrorState(
                      onRetry: () => setState(() {}),
                    ),
                  )

                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(
                      tabIndex: _tabIndex,
                      onExplore: () {
                        // Volta para Home (index 0) via pop ou sinaliza nav
                        Navigator.of(context).maybePop();
                      },
                    ),
                  )

                else ...[

                  // ── PRECISAM DE ATENÇÃO ──────────────────────
                  if (urgent.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionLabel(
                        emoji: '🔔',
                        label: 'Precisam da sua atenção',
                        count: urgent.length,
                        color: AppTheme.kidsPurpleViolet,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _AnimatedTile(
                          index: i,
                          child: ChatListTile(
                            chat:   urgent[i],
                            myUid:  widget.myUid,
                            onTap:  () => _openChat(urgent[i]),
                          ),
                        ),
                        childCount: urgent.length,
                      ),
                    ),
                    if (rest.isNotEmpty)
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 8),
                      ),
                  ],

                  // ── OUTRAS CONVERSAS ─────────────────────────
                  if (rest.isNotEmpty) ...[
                    if (urgent.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _SectionLabel(
                          emoji: '💬',
                          label: 'Conversas',
                          count: rest.length,
                          color: AppTheme.textGrayMid,
                        ),
                      ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _AnimatedTile(
                          index: urgent.isNotEmpty ? i + urgent.length : i,
                          child: ChatListTile(
                            chat:  rest[i],
                            myUid: widget.myUid,
                            onTap: () => _openChat(rest[i]),
                          ),
                        ),
                        childCount: rest.length,
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<ChatModel> _filter(List<ChatModel> all, int idx) {
    switch (idx) {
      case 1:
        return all.where((c) => c.itemType == 'dream' || c.itemType == null).toList();
      case 2:
        return all.where((c) => c.itemType == 'donation').toList();
      default:
        return all;
    }
  }

  void _openChat(ChatModel chat) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            ChatPage(myUid: widget.myUid, chat: chat),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end:   Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HEADER PREMIUM
// ═══════════════════════════════════════════════════════════════

class _ChatHeader extends StatelessWidget {
  final List<ChatModel> allChats;
  final TabController tabController;
  final int tabIndex;

  const _ChatHeader({
    required this.allChats,
    required this.tabController,
    required this.tabIndex,
  });

  // Subtítulos rotativos
  static const _subtitles = [
    'Continue transformando vidas ❤️',
    'Seus contatos do bem',
    'Conversas que geram impacto',
    'Cada mensagem aproxima um sonho',
  ];

  String get _subtitle {
    final h = DateTime.now().hour;
    return _subtitles[h % _subtitles.length];
  }

  String get _activityLabel {
    final total    = allChats.length;
    final unread   = allChats.where((c) => c.unread > 0).length;
    final dreams   = allChats.where((c) => c.itemType == 'dream').length;
    final donations= allChats.where((c) => c.itemType == 'donation').length;

    if (total == 0)   return '💬 Nenhuma conversa ainda';
    if (unread > 0)   return '🔔 $unread ${unread == 1 ? "mensagem" : "mensagens"} não ${unread == 1 ? "lida" : "lidas"}';
    if (donations > 0 && dreams > 0) {
      return '💭 $dreams ${dreams == 1 ? "sonho" : "sonhos"}  ·  🎁 $donations ${donations == 1 ? "doação" : "doações"}';
    }
    return '💬 $total ${total == 1 ? "conversa ativa" : "conversas ativas"}';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.homeHeaderGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título + subtítulo + pill ──────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPad + 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mensagens',
                  style: TextStyle(
                    fontSize:      20,
                    fontWeight:    FontWeight.w900,
                    color:         Colors.white,
                    letterSpacing: -0.3,
                    height:        1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: TextStyle(
                    fontSize:   11.5,
                    fontWeight: FontWeight.w500,
                    color:      Colors.white.withValues(alpha: 0.60),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20)),
                  ),
                  child: Text(
                    _activityLabel,
                    style: const TextStyle(
                      fontSize:   11,
                      fontWeight: FontWeight.w600,
                      color:      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Segmented control — mesmo x=16 que o texto ────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _SegmentedControl(
              controller: tabController,
              tabIndex:   tabIndex,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SEGMENTED CONTROL (substitui TabBar padrão)
// ─────────────────────────────────────────────────────────────

class _SegmentedControl extends StatelessWidget {
  final TabController controller;
  final int tabIndex;

  const _SegmentedControl({
    required this.controller,
    required this.tabIndex,
  });

  static const _items = [
    ('Todas',   null),
    ('💭 Sonhos',  'dream'),
    ('🎁 Doações', 'donation'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color:        Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: Row(
        children: List.generate(_items.length, (i) {
          final selected = i == tabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.index = i,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve:    Curves.easeInOut,
                padding:  const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color:     Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset:    const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _items[i].$1,
                    style: TextStyle(
                      fontSize:   12.5,
                      fontWeight: selected
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: selected
                          ? AppTheme.primaryBlue
                          : Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LABEL DE SEÇÃO
// ═══════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final Color color;

  const _SectionLabel({
    required this.emoji,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w800,
              color:      color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w800,
                color:      color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TILE COM ANIMAÇÃO DE ENTRADA
// ═══════════════════════════════════════════════════════════════

class _AnimatedTile extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedTile({required this.index, required this.child});

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  // 🔧 FIX: antes, cada tile esperava `index * 35ms` pra começar a animar,
  // e a duração da animação também crescia com o índice
  // (`300 + index * 40ms`). Isso é reconstruído toda vez que os slivers
  // mudam — inclusive ao trocar de tab — então numa lista com vários itens
  // visíveis a soma passava de 1s facilmente, dando a sensação de troca
  // de tab "lenta" mesmo os dados já estando prontos na hora.
  //
  // Agora todos os tiles começam a animar IMEDIATAMENTE e com a MESMA
  // duração curta, então a troca de tab fica instantânea — só uma leve
  // transição visual, sem cascata.
  static const _duration = Duration(milliseconds: 160);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _duration);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child:   SlideTransition(position: _slide, child: widget.child),
      );
}

// ═══════════════════════════════════════════════════════════════
// EMPTY STATES
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final int tabIndex;
  final VoidCallback onExplore;
  const _EmptyState({required this.tabIndex, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final isDream    = tabIndex == 1;
    final isDonation = tabIndex == 2;

    final emoji    = isDonation ? '🎁' : isDream ? '💭' : '💬';
    final title    = isDonation
        ? 'Nenhum contato com doadores'
        : isDream
            ? 'Nenhuma conversa sobre sonhos'
            : 'Nenhuma conversa ainda';
    final body     = isDonation
        ? 'Quando você demonstrar interesse em uma doação, a conversa aparecerá aqui.'
        : isDream
            ? 'Quando você quiser ajudar a realizar um sonho, a conversa aparecerá aqui.'
            : 'Quando você demonstrar interesse em um sonho ou doação, suas conversas aparecerão aqui.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDonation
                      ? [AppTheme.kidsPink, AppTheme.kidsPinkDeep]
                      : isDream
                          ? [AppTheme.kidsPurpleViolet, AppTheme.primaryBlue]
                          : [AppTheme.primaryBlue, AppTheme.primaryBlueMid],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color:     (isDonation
                            ? AppTheme.kidsPink
                            : AppTheme.kidsPurpleViolet)
                        .withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset:    const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 36)),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(
                fontSize:   18,
                fontWeight: FontWeight.w900,
                color:      AppTheme.primaryBlue,
                height:     1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              body,
              style: const TextStyle(
                fontSize: 13.5,
                color:    AppTheme.textSecondary,
                height:   1.55,
              ),
              textAlign: TextAlign.center,
            ),

            
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.errorOutline,
                color: AppTheme.errorRed, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar as conversas.',
              style: TextStyle(
                fontSize:   14,
                color:      AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color:        AppTheme.kidsPurpleViolet,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Tentar novamente',
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
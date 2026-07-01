// lib/core/navigation/main_navigation.dart

import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/chat/data/repositories/chat_repository.dart';
import 'package:empatia/features/chat/presentation/pages/chat_list_page.dart';
import 'package:empatia/features/dream/presentation/pages/dream_page.dart';
import 'package:empatia/features/home/presentation/pages/home_page.dart';
import 'package:empatia/features/profile/presentation/page/profile/profile_page.dart';
import 'package:empatia/features/search/presentation/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainNavigation extends StatefulWidget {
  final UserModel user;
  const MainNavigation({super.key, required this.user});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final _chatRepo = ChatRepository.instance;

  @override
  void initState() {
    super.initState();

    // ── RepaintBoundary por aba ──────────────────────────────────
    // Como o IndexedStack mantém TODAS as abas montadas e vivas o tempo
    // todo (nunca são destruídas ao trocar de aba ou ao empurrar/remover
    // outras rotas por cima), suas camadas de composição (layers) ficam
    // "quentes" durante toda a sessão do app — diferente de uma rota
    // normal empurrada via Navigator.push, que é criada do zero a cada
    // vez e destruída no pop.
    //
    // Isso torna o IndexedStack mais sujeito a um glitch de compositor
    // em que uma camada antiga/parcial de uma aba persistente "vaza"
    // visualmente por um frame durante a transição de outra rota (como
    // o PublicProfilePage) — o efeito de "cards fantasmas" relatado.
    //
    // Envolver cada aba em seu próprio RepaintBoundary força o Flutter a
    // isolar cada uma em sua própria camada de composição independente,
    // impedindo esse tipo de vazamento entre elas durante transições.
    _pages = [
      RepaintBoundary(child: HomePage(user: widget.user)),
      RepaintBoundary(child: SearchPage()),
      RepaintBoundary(
        child: ChatListPage(
          myUid: widget.user.id ?? '',
          myName: widget.user.name,
          myEmoji: widget.user.profileEmoji,
          myAvatar: widget.user.profileImage,
        ),
      ),
      RepaintBoundary(child: DreamPage()),
      RepaintBoundary(child: ProfilePage()),
    ];
  }

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = widget.user.id ?? '';

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: myUid.isNotEmpty
            ? _chatRepo.totalUnreadStream(myUid)
            : const Stream.empty(),
        initialData: 0,
        builder: (context, snap) {
          final unread = snap.data ?? 0;
          return _BottomNav(
            currentIndex: _currentIndex,
            unreadChats: unread,
            onTap: _onTabTapped,
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BOTTOM NAV
// ═══════════════════════════════════════════════════════════════

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final int unreadChats;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.unreadChats,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Início'),
    _NavItem(icon: Icons.search_rounded, label: 'Buscar'),
    _NavItem(icon: Icons.chat_bubble_rounded, label: 'Chat'),
    _NavItem(icon: Icons.bedtime_rounded, label: 'Sonhos'),
    _NavItem(icon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isChat = i == 2;
              return _NavButton(
                item: item,
                index: i,
                isActive: currentIndex == i,
                badge: isChat && unreadChats > 0 ? unreadChats : null,
                onTap: onTap,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─────────────────────────────────────────────────────────────
// BOTÃO INDIVIDUAL DA NAV
// ─────────────────────────────────────────────────────────────

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final int index;
  final bool isActive;
  final int? badge;
  final ValueChanged<int> onTap;

  const _NavButton({
    required this.item,
    required this.index,
    required this.isActive,
    this.badge,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _ctrl.reverse();
    widget.onTap(widget.index);
    await _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isActive ? 16 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: widget.isActive
                ? const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.item.icon,
                    color: widget.isActive
                        ? Colors.white
                        : Colors.grey.shade500,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.isActive
                          ? Colors.white
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),

              // Badge de não-lidos
              if (widget.badge != null && widget.badge! > 0)
                Positioned(
                  top: -6,
                  right: -8,
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5C8D), Color(0xFFE0457A)],
                        ),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5C8D)
                                .withValues(alpha: 0.40),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.badge! > 99
                            ? '99+'
                            : '${widget.badge}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
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
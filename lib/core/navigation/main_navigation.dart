import 'package:empatia/core/models/user_model.dart';
import 'package:empatia/features/profile/presentation/page/profile/profile_page.dart';
import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/home_page.dart';

class MainNavigation extends StatefulWidget {
  final UserModel user;
  
  const MainNavigation({
    super.key,
    required this.user,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(user: widget.user),
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔍', style: TextStyle(fontSize: 60)),
            SizedBox(height: 16),
            Text(
              'Buscar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      ),
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💬', style: TextStyle(fontSize: 60)),
            SizedBox(height: 16),
            Text(
              'Chat',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      ),
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💭', style: TextStyle(fontSize: 60)),
            SizedBox(height: 16),
            Text(
              'Sonhos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      ),
      ProfilePage(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
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
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Início',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.search_rounded,
                  label: 'Buscar',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.bedtime_rounded,
                  label: 'Sonhos',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Perfil',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isSpecial = false,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isSpecial
              ? const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFF1493)],
                )
              : isActive
                  ? const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    )
                  : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive || isSpecial
              ? [
                  BoxShadow(
                    color: (isSpecial
                            ? const Color(0xFFFF6B9D)
                            : const Color(0xFF2563EB))
                        .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive || isSpecial
                  ? Colors.white
                  : Colors.grey.shade500,
              size: isSpecial ? 28 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive || isSpecial
                    ? Colors.white
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
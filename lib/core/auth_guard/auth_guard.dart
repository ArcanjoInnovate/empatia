import 'package:empatia/core/models/user_model.dart';
import 'package:empatia/core/navigation/main_navigation.dart';
import 'package:empatia/features/auth/controller/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late AnimationController _floatController;

  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  bool _isInitializing = true;
  UserModel? _userData;
  bool _hasError = false;

  final AuthController controller = AuthController();

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    // Aguarda mínimo de 1.5s para splash não piscar muito rápido
    final splashDelay = Future.delayed(const Duration(milliseconds: 1500));

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Usuário logado - carrega dados
        final userData = await controller.getUserData();
        
        if (!mounted) return;
        
        // Aguarda o tempo mínimo da splash
        await splashDelay;
        
        if (!mounted) return;
        
        setState(() {
          if (userData == null) {
            _userData = _createTempUser(user.uid);
          } else {
            _userData = userData;
          }
          _isInitializing = false;
        });
      } else {
        // Usuário não logado - aguarda splash mínima e vai para login
        await splashDelay;
        
        if (!mounted) return;
        
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      // Erro - aguarda splash mínima e mostra erro
      await splashDelay;
      
      if (!mounted) return;
      
      setState(() {
        _hasError = true;
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mostra splash enquanto inicializa
    if (_isInitializing) {
      return _buildSplash();
    }

    // Erro ao carregar dados
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 50)),
              const SizedBox(height: 16),
              const Text('Erro ao carregar dados'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _userData = null;
                    _isInitializing = true;
                  });
                  _checkAuthAndLoadData();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    // Se tem dados do usuário, vai para MainNavigation
    if (_userData != null) {
      return MainNavigation(user: _userData!);
    }

    // Se não tem dados, vai para LoginPage
    return const LoginPage();
  }

  // Cria usuário temporário se não existir no Firestore
  UserModel _createTempUser(String uid) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    return UserModel(
      id: uid,
      name: firebaseUser?.displayName ?? 'Usuário',
      profileImage: firebaseUser?.photoURL,
      createdAt: DateTime.now(),
    );
  }

  List<Widget> _buildFloatingBubbles() {
    return [
      _buildBubble(top: 100, left: 40, size: 70, delay: 0),
      _buildBubble(top: 200, right: 50, size: 90, delay: 0.5),
      _buildBubble(bottom: 250, left: 30, size: 110, delay: 1),
      _buildBubble(bottom: 350, right: 40, size: 80, delay: 1.5),
      _buildBubble(top: 300, left: 60, size: 60, delay: 0.8),
      _buildBubble(top: 450, right: 70, size: 65, delay: 1.2),
    ];
  }

  Widget _buildSplash() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6B9D), // Pink
              Color(0xFFFFC837), // Yellow
              Color(0xFF8B5CF6), // Purple
              Color(0xFF06B6D4), // Cyan
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            ..._buildFloatingBubbles(),
            ..._buildSparkles(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B9D).withOpacity(0.5),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                  blurRadius: 50,
                                  spreadRadius: 15,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _spinController,
                                  builder: (_, __) => Transform.rotate(
                                    angle: _spinController.value * 2 * math.pi,
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: SweepGradient(
                                          colors: [
                                            Color(0xFFFF6B9D),
                                            Color(0xFFFFC837),
                                            Color(0xFF4ADE80),
                                            Color(0xFF06B6D4),
                                            Color(0xFF8B5CF6),
                                            Color(0xFFFF6B9D),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 115,
                                  height: 115,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFF6B9D),
                                        Color(0xFFFF1493),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFFFF9E6)],
                      ),
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFC837).withOpacity(0.6),
                          blurRadius: 25,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Text(
                      'EMPATIA 💖',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFFFF6B9D), Color(0xFF8B5CF6)],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseAnimation.value * 0.95,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            Text(
                              '✨ Preparando tudo ✨',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFF6B9D),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Só um pouquinho... 🎈',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _bounceController,
                        builder: (_, __) {
                          final delay = index * 0.3;
                          final value = (_bounceController.value + delay) % 1.0;
                          final bounce = math.sin(value * math.pi) * 12;

                          return Transform.translate(
                            offset: Offset(0, -bounce),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    [
                                      const Color(0xFFFF6B9D),
                                      const Color(0xFFFFC837),
                                    ],
                                    [
                                      const Color(0xFF4ADE80),
                                      const Color(0xFF06B6D4),
                                    ],
                                    [
                                      const Color(0xFF8B5CF6),
                                      const Color(0xFFFF6B9D),
                                    ],
                                  ][index],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: [
                                      const Color(0xFFFF6B9D),
                                      const Color(0xFF06B6D4),
                                      const Color(0xFF8B5CF6),
                                    ][index].withOpacity(0.5),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required double delay,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _floatAnimation.value * (1 + delay)),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSparkles() {
    final sparkles = [
      _Sparkle(emoji: '✨', top: 120, left: 20, size: 26),
      _Sparkle(emoji: '⭐', top: 200, right: 30, size: 30),
      _Sparkle(emoji: '💫', top: 350, left: 45, size: 24),
      _Sparkle(emoji: '🌟', bottom: 280, right: 25, size: 28),
      _Sparkle(emoji: '✨', bottom: 180, left: 35, size: 22),
      _Sparkle(emoji: '💖', top: 160, right: 70, size: 26),
      _Sparkle(emoji: '🎈', bottom: 220, left: 70, size: 30),
      _Sparkle(emoji: '🦄', top: 260, left: 15, size: 32),
      _Sparkle(emoji: '🌈', top: 100, right: 45, size: 28),
      _Sparkle(emoji: '🎀', bottom: 320, right: 60, size: 24),
      _Sparkle(emoji: '🌸', top: 380, right: 20, size: 26),
    ];

    return sparkles.map((s) {
      return Positioned(
        top: s.top,
        bottom: s.bottom,
        left: s.left,
        right: s.right,
        child: AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _bounceAnimation.value * 0.7),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnimation.value * 0.95,
                child: Text(s.emoji, style: TextStyle(fontSize: s.size)),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _Sparkle {
  final String emoji;
  final double? top, bottom, left, right;
  final double size;

  const _Sparkle({
    required this.emoji,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
  });
}
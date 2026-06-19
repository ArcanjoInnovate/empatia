import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/navigation/main_navigation.dart' show MainNavigation;
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class SuccessAnimationPage extends StatefulWidget {
  final String message;
  final UserModel user;

  const SuccessAnimationPage({
    super.key,
    required this.message,
    required this.user,
  });

  @override
  State<SuccessAnimationPage> createState() => _SuccessAnimationPageState();
}

class _SuccessAnimationPageState extends State<SuccessAnimationPage>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late AnimationController _confettiController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _confettiAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController, curve: Curves.elasticOut,
    );

    _rotateController = AnimationController(
      vsync: this, duration: const Duration(seconds: 20),
    )..repeat();

    _bounceController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController, curve: Curves.easeIn,
    );

    _confettiController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    );
    _confettiAnimation = CurvedAnimation(
      parent: _confettiController, curve: Curves.easeOutQuad,
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _scaleController.forward();
    _fadeController.forward();
    _confettiController.forward();

    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => MainNavigation(user: widget.user),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    _bounceController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppDecorations.successBackground,
        child: Stack(
          children: [
            ..._buildFallingConfetti(),
            ..._buildBackgroundCircles(),
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSuccessIcon(),
                    const SizedBox(height: 40),
                    _buildMessage(),
                    const SizedBox(height: 24),
                    _buildSubMessage(),
                    const SizedBox(height: 40),
                    _buildLoadingIndicator(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Container(
            width: 180, height: 180,
            decoration: AppDecorations.successIcon,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _rotateController,
                  builder: (_, __) => Transform.rotate(
                    angle: _rotateController.value * 2 * math.pi,
                    child: Container(
                      width: 170, height: 170,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.successIconSweep,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 140, height: 140,
                  decoration: AppDecorations.successIconInner,
                  child: const Icon(Icons.check_rounded, size: 80, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: AppDecorations.successMessageBox,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _bounceAnimation.value * 0.5),
              child: const Text('🎉', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.message,
            style: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w900,
              foreground: AppDecorations.textShader(
                [AppTheme.kidsGreen, AppTheme.kidsCyan],
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _bounceAnimation.value * 0.5),
              child: const Text('✨', style: TextStyle(fontSize: 40)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      decoration: AppDecorations.successSubMessageBox,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🚀', style: TextStyle(fontSize: 24)),
          SizedBox(width: 10),
          Text(
            'Preparando tudo pra você...',
            style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: Color(0xFF059669),
            ),
          ),
          SizedBox(width: 10),
          Text('💖', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.successLoadingBox,
      child: const SizedBox(
        width: 40, height: 40,
        child: CircularProgressIndicator(
          strokeWidth: 5,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kidsPurple),
        ),
      ),
    );
  }

  List<Widget> _buildFallingConfetti() {
    final confettiItems = [
      _ConfettiParticle(emoji: '🎊', delay: 0.0, x: 0.1),
      _ConfettiParticle(emoji: '🎉', delay: 0.1, x: 0.3),
      _ConfettiParticle(emoji: '⭐', delay: 0.2, x: 0.5),
      _ConfettiParticle(emoji: '✨', delay: 0.3, x: 0.7),
      _ConfettiParticle(emoji: '💫', delay: 0.4, x: 0.9),
      _ConfettiParticle(emoji: '🌟', delay: 0.5, x: 0.2),
      _ConfettiParticle(emoji: '🎈', delay: 0.6, x: 0.4),
      _ConfettiParticle(emoji: '🦄', delay: 0.7, x: 0.6),
      _ConfettiParticle(emoji: '🌈', delay: 0.8, x: 0.8),
      _ConfettiParticle(emoji: '💖', delay: 0.9, x: 0.15),
      _ConfettiParticle(emoji: '🎪', delay: 1.0, x: 0.35),
      _ConfettiParticle(emoji: '🧸', delay: 1.1, x: 0.55),
      _ConfettiParticle(emoji: '🎨', delay: 1.2, x: 0.75),
      _ConfettiParticle(emoji: '🍭', delay: 1.3, x: 0.95),
    ];

    return confettiItems.map((particle) {
      return AnimatedBuilder(
        animation: _confettiAnimation,
        builder: (_, __) {
          final progress =
              (_confettiAnimation.value - particle.delay).clamp(0.0, 1.0);
          final screenHeight = MediaQuery.of(context).size.height;
          final screenWidth  = MediaQuery.of(context).size.width;

          return Positioned(
            top: -50 + (screenHeight + 100) * progress,
            left: screenWidth * particle.x +
                math.sin(progress * 4 * math.pi) * 30,
            child: Transform.rotate(
              angle: progress * 4 * math.pi,
              child: Opacity(
                opacity: 1.0 - (progress * 0.3),
                child: Text(particle.emoji,
                    style: const TextStyle(fontSize: 32)),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  List<Widget> _buildBackgroundCircles() {
    return [
      _buildFloatingCircle(top: 100,    left: 50,   size: 80,  opacity: 0.10),
      _buildFloatingCircle(top: 200,    right: 60,  size: 120, opacity: 0.08),
      _buildFloatingCircle(bottom: 150, left: 40,   size: 100, opacity: 0.12),
      _buildFloatingCircle(bottom: 250, right: 80,  size: 90,  opacity: 0.10),
    ];
  }

  Widget _buildFloatingCircle({
    double? top, double? bottom, double? left, double? right,
    required double size, required double opacity,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Container(
            width: size, height: size,
            decoration: AppDecorations.bubble(Colors.white.withOpacity(opacity)),
          ),
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final String emoji;
  final double delay;
  final double x;
  const _ConfettiParticle({
    required this.emoji, required this.delay, required this.x,
  });
}
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/navigation/main_navigation.dart' show MainNavigation;
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────────
// _Responsive — mesma arquitetura do LoginPage:
//   • recebe (width, height) de LayoutBuilder + MediaQuery
//   • scale = (width / 390).clamp(0.86, 1.0) * (isCompact ? 0.92 : 1.0)
//   • tela de animação pura: sem fieldHeight/buttonHeight (não há campos/botões)
// ─────────────────────────────────────────────────────────────────────────────
class _Responsive {
  final double width;
  final double height;

  const _Responsive(this.width, this.height);

  // ── Flags ─────────────────────────────────────────────────────────────────
  bool get isTablet  => width  >= 600;
  bool get isCompact => height <  680;

  // ── Fator base — idêntico ao login ───────────────────────────────────────
  double get scale => (width / 390).clamp(0.86, 1.0) * (isCompact ? 0.92 : 1.0);

  // ── Tipografia ────────────────────────────────────────────────────────────
  double get fontTitle    => 32 * scale;  // mensagem principal
  double get fontSubtitle => 18 * scale;  // sub-mensagem
  double get fontEmoji    => 40 * scale;  // emojis do título
  double get fontSubEmoji => 24 * scale;  // emojis da sub-mensagem
  double get fontConfetti => 32 * scale;  // partículas de confetti

  // ── Espaçamentos ─────────────────────────────────────────────────────────
  double get gapXL => (isCompact ? 28.0 : 40.0) * scale;
  double get gapL  => (isCompact ? 16.0 : 24.0) * scale;
  double get gapM  => (isCompact ?  8.0 : 12.0) * scale;
  double get gapS  => (isCompact ?  6.0 : 10.0) * scale;

  // ── Ícone de sucesso ──────────────────────────────────────────────────────
  double get iconSize      => 180 * scale;
  double get iconRingSize  => 170 * scale;  // anel giratório
  double get iconInnerSize => 140 * scale;  // círculo interno
  double get iconCheckSize =>  80 * scale;  // ícone check

  // ── Caixas de mensagem ────────────────────────────────────────────────────
  double get msgPadH  => 40 * scale;
  double get msgPadV  => 20 * scale;
  double get subPadH  => 32 * scale;
  double get subPadV  => 14 * scale;
  double get loadPad  => 20 * scale;

  // ── Loading indicator ─────────────────────────────────────────────────────
  double get loadingSize  => 40 * scale;
  double get loadingStroke =>  5 * scale;
}

// ─────────────────────────────────────────────────────────────────────────────
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
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation = CurvedAnimation(
        parent: _scaleController, curve: Curves.elasticOut);

    _rotateController = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))
      ..repeat();

    _bounceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(
        parent: _fadeController, curve: Curves.easeIn);

    _confettiController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _confettiAnimation = CurvedAnimation(
        parent: _confettiController, curve: Curves.easeOutQuad);

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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = _Responsive(
          constraints.maxWidth,
          MediaQuery.of(context).size.height,
        );

        return Scaffold(
          body: Container(
            decoration: AppDecorations.successBackground,
            child: Stack(children: [
              ..._buildFallingConfetti(r),
              ..._buildBackgroundCircles(),
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSuccessIcon(r),
                      SizedBox(height: r.gapXL),
                      _buildMessage(r),
                      SizedBox(height: r.gapL),
                      _buildSubMessage(r),
                      SizedBox(height: r.gapXL),
                      _buildLoadingIndicator(r),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  // ── Ícone de sucesso ───────────────────────────────────────────────────────
  Widget _buildSuccessIcon(_Responsive r) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: SizedBox(
            width: r.iconSize, height: r.iconSize,
            child: Stack(alignment: Alignment.center, children: [
              AnimatedBuilder(
                animation: _rotateController,
                builder: (_, __) => Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi,
                  child: Container(
                    width: r.iconRingSize, height: r.iconRingSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.successIconSweep,
                    ),
                  ),
                ),
              ),
              Container(
                width: r.iconInnerSize, height: r.iconInnerSize,
                decoration: AppDecorations.successIconInner,
                child: Icon(Icons.check_rounded,
                    size: r.iconCheckSize, color: Colors.white),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Mensagem principal ─────────────────────────────────────────────────────
  Widget _buildMessage(_Responsive r) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: r.msgPadH, vertical: r.msgPadV),
      decoration: AppDecorations.successMessageBox,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _bounceAnimation.value * 0.5),
              child: Text('🎉',
                  style: TextStyle(fontSize: r.fontEmoji)),
            ),
          ),
          SizedBox(width: r.gapM),
          Flexible(
            child: Text(
              widget.message,
              style: TextStyle(
                fontSize: r.fontTitle,
                fontWeight: FontWeight.w900,
                foreground: AppDecorations.textShader(
                    [AppTheme.kidsGreen, AppTheme.kidsCyan]),
              ),
            ),
          ),
          SizedBox(width: r.gapM),
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _bounceAnimation.value * 0.5),
              child: Text('✨',
                  style: TextStyle(fontSize: r.fontEmoji)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-mensagem ───────────────────────────────────────────────────────────
  Widget _buildSubMessage(_Responsive r) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: r.subPadH, vertical: r.subPadV),
      decoration: AppDecorations.successSubMessageBox,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🚀', style: TextStyle(fontSize: r.fontSubEmoji)),
          SizedBox(width: r.gapS),
          Text(
            'Preparando tudo pra você...',
            style: TextStyle(
              fontSize: r.fontSubtitle,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF059669),
            ),
          ),
          SizedBox(width: r.gapS),
          Text('💖', style: TextStyle(fontSize: r.fontSubEmoji)),
        ],
      ),
    );
  }

  // ── Loading indicator ──────────────────────────────────────────────────────
  Widget _buildLoadingIndicator(_Responsive r) {
    return Container(
      padding: EdgeInsets.all(r.loadPad),
      decoration: AppDecorations.successLoadingBox,
      child: SizedBox(
        width: r.loadingSize, height: r.loadingSize,
        child: CircularProgressIndicator(
          strokeWidth: r.loadingStroke,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.kidsPurple),
        ),
      ),
    );
  }

  // ── Confetti cadente ───────────────────────────────────────────────────────
  List<Widget> _buildFallingConfetti(_Responsive r) {
    const confettiItems = [
      _ConfettiParticle(emoji: '🎊', delay: 0.0, x: 0.10),
      _ConfettiParticle(emoji: '🎉', delay: 0.1, x: 0.30),
      _ConfettiParticle(emoji: '⭐', delay: 0.2, x: 0.50),
      _ConfettiParticle(emoji: '✨', delay: 0.3, x: 0.70),
      _ConfettiParticle(emoji: '💫', delay: 0.4, x: 0.90),
      _ConfettiParticle(emoji: '🌟', delay: 0.5, x: 0.20),
      _ConfettiParticle(emoji: '🎈', delay: 0.6, x: 0.40),
      _ConfettiParticle(emoji: '🦄', delay: 0.7, x: 0.60),
      _ConfettiParticle(emoji: '🌈', delay: 0.8, x: 0.80),
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
          // Dimensões via MediaQuery: confetti usa a tela inteira,
          // não o espaço do LayoutBuilder
          final sh = MediaQuery.of(context).size.height;
          final sw = MediaQuery.of(context).size.width;

          return Positioned(
            top:  -50 + (sh + 100) * progress,
            left: sw * particle.x +
                  math.sin(progress * 4 * math.pi) * 30,
            child: Transform.rotate(
              angle: progress * 4 * math.pi,
              child: Opacity(
                opacity: 1.0 - (progress * 0.3),
                child: Text(particle.emoji,
                    style: TextStyle(fontSize: r.fontConfetti)),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  // ── Círculos de fundo ──────────────────────────────────────────────────────
  List<Widget> _buildBackgroundCircles() {
    return [
      _buildFloatingCircle(top: 100,    left:  50, size: 80,  opacity: 0.10),
      _buildFloatingCircle(top: 200,    right: 60, size: 120, opacity: 0.08),
      _buildFloatingCircle(bottom: 150, left:  40, size: 100, opacity: 0.12),
      _buildFloatingCircle(bottom: 250, right: 80, size: 90,  opacity: 0.10),
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
            decoration:
                AppDecorations.bubble(Colors.white.withOpacity(opacity)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ConfettiParticle {
  final String emoji;
  final double delay;
  final double x;
  const _ConfettiParticle({
    required this.emoji, required this.delay, required this.x,
  });
}
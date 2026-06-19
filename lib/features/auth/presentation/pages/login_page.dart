import 'package:empatia/core/navigation/main_navigation.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/auth/controller/auth_controller.dart';
import 'package:empatia/features/auth/presentation/pages/forgout_password_page.dart';
import 'package:empatia/features/auth/presentation/pages/register_page.dart';
import 'package:empatia/features/auth/presentation/pages/sucess_auth_page.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _loginError;

  final AuthController controller = AuthController();

  late AnimationController _floatController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _floatController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() {
      _emailError   = null;
      _passwordError = null;
      _loginError   = null;
    });

    bool hasError = false;

    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = 'Cadê o email? 📧✨');
      hasError = true;
    } else if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      setState(() => _emailError = 'Ops! Email tá estranho 🤔💫');
      hasError = true;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Senha secreta esquecida? 🔐✨');
      hasError = true;
    } else if (_passwordController.text.length < 6) {
      setState(() => _passwordError = 'Senha muito curtinha! 💪🌟');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    final result = await controller.loginUser(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == 'success') {
      final userData = await controller.getUserData();
      if (userData != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuccessAnimationPage(
              message: 'Bem-vindo!',
              user: userData,
            ),
          ),
        );
      } else if (mounted) {
        setState(() => _loginError = 'Erro ao carregar dados! 😅');
      }
    } else {
      setState(() => _loginError = result ?? 'Algo deu errado! 😅');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppDecorations.loginBackground,
        child: Stack(
          children: [
            ..._buildFloatingBubbles(),
            ..._buildSparkles(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildAnimatedLogo(),
                    const SizedBox(height: 32),
                    _buildCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingBubbles() {
    return [
      _buildBubble(top: 80,    left: 30,  size: 60,  opacity: 0.15, delay: 0),
      _buildBubble(top: 150,   right: 40, size: 80,  opacity: 0.10, delay: 0.5),
      _buildBubble(bottom: 200, left: 20, size: 100, opacity: 0.08, delay: 1),
      _buildBubble(bottom: 300, right: 30, size: 70, opacity: 0.12, delay: 1.5),
      _buildBubble(top: 250,   left: 50,  size: 50,  opacity: 0.10, delay: 0.8),
    ];
  }

  Widget _buildBubble({
    double? top, double? bottom, double? left, double? right,
    required double size, required double opacity, required double delay,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _floatAnimation.value * (1 + delay)),
          child: Container(
            width: size, height: size,
            decoration: AppDecorations.bubble(Colors.white.withOpacity(opacity)),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSparkles() {
    final sparkles = [
      _Sparkle(emoji: '✨', top: 100,    left: 15,   size: 24),
      _Sparkle(emoji: '⭐', top: 180,    right: 25,  size: 28),
      _Sparkle(emoji: '💫', top: 300,    left: 35,   size: 22),
      _Sparkle(emoji: '🌟', bottom: 250, right: 20,  size: 26),
      _Sparkle(emoji: '✨', bottom: 150, left: 25,   size: 20),
      _Sparkle(emoji: '💖', top: 140,    right: 60,  size: 24),
      _Sparkle(emoji: '🎈', bottom: 180, left: 60,   size: 28),
      _Sparkle(emoji: '🦄', top: 230,    left: 10,   size: 30),
      _Sparkle(emoji: '🌈', top: 90,     right: 35,  size: 26),
    ];

    return sparkles.map((s) => Positioned(
      top: s.top, bottom: s.bottom, left: s.left, right: s.right,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnimation.value,
              child: Text(s.emoji, style: TextStyle(fontSize: s.size)),
            ),
          ),
        ),
      ),
    )).toList();
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _bounceAnimation.value * 0.5),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 130, height: 130,
                  decoration: AppDecorations.loginLogo,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _floatController,
                        builder: (_, __) => Transform.rotate(
                          angle: _floatController.value * 2 * math.pi,
                          child: Container(
                            width: 122, height: 122,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.logoSweep,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 100, height: 100,
                        decoration: AppDecorations.loginLogoInner,
                        child: const Icon(Icons.favorite, size: 50, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: AppDecorations.appNameTag,
              child: Text(
                'EMPATIA 💖',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  foreground: AppDecorations.textShader(
                    [AppTheme.kidsPink, AppTheme.kidsPurple],
                    width: 200,
                  ),
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: AppDecorations.brandTagBox,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🧸', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 6),
                  Text(
                    'Pingo Brinquedos',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: AppTheme.kidsPink,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text('✨', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: AppDecorations.loginCard,
      child: Column(
        children: [
          Container(height: 10, decoration: AppDecorations.cardRainbowBar),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.loginTitleBox,
                  child: const Column(
                    children: [
                      Text(
                        '👋 Oi, amiguinho!',
                        style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900,
                          color: AppTheme.kidsPink,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Vamos brincar juntos? 🎈',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600,
                          color: AppTheme.kidsPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                _buildMagicField(
                  controller: _emailController,
                  label: 'Seu email 📧',
                  hint: 'exemplo@email.com',
                  icon: '📬',
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() => _emailError = null),
                  gradientColors: AppTheme.gradientEmail,
                ),
                const SizedBox(height: 18),

                _buildMagicField(
                  controller: _passwordController,
                  label: 'Senha secreta 🔐',
                  hint: '••••••••',
                  icon: '🗝️',
                  errorText: _passwordError,
                  obscureText: !_isPasswordVisible,
                  onChanged: (_) => setState(() => _passwordError = null),
                  gradientColors: AppTheme.gradientPassword,
                  suffix: GestureDetector(
                    onTap: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: AppDecorations.passwordTogglePurple,
                      child: Text(
                        _isPasswordVisible ? '🙈' : '👁️',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Esqueci a senha ──────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8,
                      ),
                      decoration: AppDecorations.forgotPasswordLink,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🔑', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 6),
                          Text(
                            'Esqueci a senha',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.kidsPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ────────────────────────────────────────────────────────

                const SizedBox(height: 20),

                if (_loginError != null) ...[
                  _buildErrorBubble(_loginError!),
                  const SizedBox(height: 20),
                ],

                _buildLoginButton(),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            AppTheme.kidsPink.withOpacity(0.3),
                          ]),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '✨ ou ✨',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppTheme.kidsPink,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppTheme.kidsPink.withOpacity(0.3),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: AppDecorations.createAccountButton,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🎉', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 10),
                        Text(
                          'CRIAR CONTA NOVA',
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: 1,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('🚀', style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, __) => Transform.scale(
          scale: _isLoading ? 1.0 : _pulseAnimation.value,
          child: Container(
            width: double.infinity, height: 64,
            decoration: AppDecorations.loginButton,
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 28, height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🎮', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 12),
                        Text(
                          'VAMOS LÁ!',
                          style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('✨', style: TextStyle(fontSize: 28)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMagicField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String icon,
    required List<Color> gradientColors,
    String? errorText,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffix,
    void Function(String)? onChanged,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800,
              foreground: AppDecorations.textShader(gradientColors),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: AppDecorations.fieldOuter(
            gradientColors: gradientColors, hasError: hasError,
          ),
          child: Container(
            decoration: AppDecorations.fieldInner(gradientColors),
            child: Row(
              children: [
                const SizedBox(width: 18),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: AppDecorations.fieldIcon(gradientColors),
                  child: Text(icon, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: controller,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    onChanged: onChanged,
                    style: const TextStyle(
                      fontSize: 16, color: AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                if (suffix != null) ...[suffix, const SizedBox(width: 18)],
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 10),
          _buildErrorBubble(errorText),
        ],
      ],
    );
  }

  Widget _buildErrorBubble(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: AppDecorations.errorBubble,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: AppDecorations.errorIcon,
            child: const Text('😅', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14, color: AppTheme.errorRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkle {
  final String emoji;
  final double? top, bottom, left, right;
  final double size;
  const _Sparkle({
    required this.emoji,
    this.top, this.bottom, this.left, this.right,
    required this.size,
  });
}
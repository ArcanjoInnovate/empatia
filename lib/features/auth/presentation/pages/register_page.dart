import 'package:empatia/features/auth/controller/auth_controller.dart';
import 'package:empatia/features/auth/presentation/pages/sucess_auth_page.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _termsError;
  String? _registerError;

  final AuthController controller = AuthController();

  late AnimationController _floatController;
  late AnimationController _rotateController;
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
    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _floatController.dispose();
    _rotateController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _termsError = null;
      _registerError = null;
    });

    bool hasError = false;

    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = 'Ops! Email tá faltando 📧✨');
      hasError = true;
    } else if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      setState(() => _emailError = 'Email tá estranho, confere? 🤔💫');
      hasError = true;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Cria uma senha legal! 🔐✨');
      hasError = true;
    } else if (_passwordController.text.length < 6) {
      setState(() => _passwordError = 'Senha muito curtinha! Mínimo 6 💪🌟');
      hasError = true;
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = 'Confirma aí! 🔑✨');
      hasError = true;
    } else if (_confirmPasswordController.text != _passwordController.text) {
      setState(() => _confirmPasswordError = 'Senhas diferentes! 😅💫');
      hasError = true;
    }

    if (!_acceptTerms) {
      setState(() => _termsError = 'Precisa aceitar pra continuar! 🤝✨');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    final result = await controller.registerUser(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    final userData = await controller.getUserData();

    if (result == 'success') {
      // ESTA É A MUDANÇA PRINCIPAL! 🎉
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessAnimationPage(
            message: 'Cadastrado!',
            user: userData!,
          ),
        ),
      );
    } else {
      setState(() => _registerError = result ?? 'Algo deu errado! 😅');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFC837), // Yellow
              Color(0xFFFF6B9D), // Pink
              Color(0xFF8B5CF6), // Purple
              Color(0xFF4ADE80), // Green
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Bolhas gigantes flutuantes
            ..._buildGiantBubbles(),

            // Confetes e elementos divertidos
            ..._buildConfetti(),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 24),
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

  List<Widget> _buildGiantBubbles() {
    return [
      _buildBubble(top: 50, left: -40, size: 150, opacity: 0.15),
      _buildBubble(top: 180, right: -50, size: 180, opacity: 0.12),
      _buildBubble(bottom: 150, left: -60, size: 200, opacity: 0.1),
      _buildBubble(bottom: 300, right: -30, size: 140, opacity: 0.13),
      _buildBubble(top: 350, left: 40, size: 100, opacity: 0.12),
    ];
  }

  Widget _buildBubble({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (_, __) => Transform.translate(
          offset: Offset(_floatAnimation.value * 0.5, _floatAnimation.value),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(opacity),
                  Colors.white.withOpacity(opacity * 0.3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildConfetti() {
    final items = [
      _Confetti(emoji: '🎉', top: 90, left: 20, size: 32),
      _Confetti(emoji: '🎈', top: 160, right: 30, size: 28),
      _Confetti(emoji: '⭐', top: 240, left: 15, size: 26),
      _Confetti(emoji: '🌟', top: 320, right: 25, size: 30),
      _Confetti(emoji: '✨', bottom: 280, left: 35, size: 24),
      _Confetti(emoji: '🎊', bottom: 200, right: 20, size: 28),
      _Confetti(emoji: '💫', bottom: 130, left: 25, size: 22),
      _Confetti(emoji: '🦄', top: 200, left: 50, size: 34),
      _Confetti(emoji: '🌈', top: 140, right: 60, size: 30),
      _Confetti(emoji: '🎨', top: 280, right: 50, size: 26),
      _Confetti(emoji: '🧸', bottom: 250, left: 50, size: 28),
      _Confetti(emoji: '🎪', bottom: 170, right: 55, size: 26),
    ];

    return items
        .map(
          (c) => Positioned(
            top: c.top,
            bottom: c.bottom,
            left: c.left,
            right: c.right,
            child: AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: AnimatedBuilder(
                  animation: _rotateController,
                  builder: (_, __) => Transform.rotate(
                    angle: _rotateController.value * 2 * math.pi * 0.1,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (_, __) => Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Text(
                          c.emoji,
                          style: TextStyle(fontSize: c.size),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _bounceAnimation.value * 0.3),
        child: Row(
          children: [
            const Spacer(),
            // Logo central animado
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC837).withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF6B9D).withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Anel colorido girando
                      AnimatedBuilder(
                        animation: _rotateController,
                        builder: (_, __) => Transform.rotate(
                          angle: _rotateController.value * 2 * math.pi,
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const SweepGradient(
                                colors: [
                                  Color(0xFFFFC837),
                                  Color(0xFFFF6B9D),
                                  Color(0xFF8B5CF6),
                                  Color(0xFF4ADE80),
                                  Color(0xFF06B6D4),
                                  Color(0xFFFFC837),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Centro com coração
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFC837), Color(0xFFFFD700)],
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(width: 50), // balance
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC837).withOpacity(0.4),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFFF6B9D).withOpacity(0.3),
            blurRadius: 50,
            spreadRadius: 5,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra arco-íris super vibrante
          Container(
            height: 12,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              gradient: LinearGradient(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
            child: Column(
              children: [
                // Título super empolgante
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFBE6),
                        Color(0xFFFFE6F0),
                        Color(0xFFF3E8FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC837).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (_, __) => Transform.scale(
                              scale: _pulseAnimation.value,
                              child: const Text(
                                '🎉',
                                style: TextStyle(fontSize: 36),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Vem com a gente!',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF6B9D),
                            ),
                          ),
                          const SizedBox(width: 12),
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (_, __) => Transform.scale(
                              scale: _pulseAnimation.value,
                              child: const Text(
                                '🚀',
                                style: TextStyle(fontSize: 36),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'É super rápido e fácil! ✨',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Email
                _buildMagicField(
                  controller: _emailController,
                  label: 'Teu email 📧',
                  hint: 'meuemail@exemplo.com',
                  icon: '📬',
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() => _emailError = null),
                  gradientColors: const [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                ),
                const SizedBox(height: 18),

                // Senha
                _buildMagicField(
                  controller: _passwordController,
                  label: 'Senha secreta 🔐',
                  hint: 'Cria uma senha legal',
                  icon: '🗝️',
                  errorText: _passwordError,
                  obscureText: !_isPasswordVisible,
                  onChanged: (_) => setState(() => _passwordError = null),
                  gradientColors: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  suffix: GestureDetector(
                    onTap: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isPasswordVisible ? '🙈' : '👁️',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Confirmar senha
                _buildMagicField(
                  controller: _confirmPasswordController,
                  label: 'Confirma a senha 🔑',
                  hint: 'Mesma senha de novo',
                  icon: '🎯',
                  errorText: _confirmPasswordError,
                  obscureText: !_isConfirmPasswordVisible,
                  onChanged: (_) =>
                      setState(() => _confirmPasswordError = null),
                  gradientColors: const [Color(0xFFFF6B9D), Color(0xFFFF1493)],
                  suffix: GestureDetector(
                    onTap: () => setState(
                      () => _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isConfirmPasswordVisible ? '🙈' : '👁️',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Checkbox de termos super fofo
                _buildTermsCheckbox(),
                if (_termsError != null) ...[
                  const SizedBox(height: 12),
                  _buildErrorBubble(_termsError!),
                ],
                const SizedBox(height: 24),

                // Erro de registro
                if (_registerError != null) ...[
                  _buildErrorBubble(_registerError!),
                  const SizedBox(height: 20),
                ],

                // Botão de cadastro MEGA chamativo
                _buildRegisterButton(),
                const SizedBox(height: 24),

                // Link para login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Já tem conta? ',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF06B6D4).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Text('🎮', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text(
                              'ENTRAR',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() {
        _acceptTerms = !_acceptTerms;
        if (_acceptTerms) _termsError = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _acceptTerms
                ? [const Color(0xFFE6FFF0), const Color(0xFFF0FFF4)]
                : [const Color(0xFFFFFBE6), const Color(0xFFFFF9E6)],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _acceptTerms
                ? const Color(0xFF4ADE80)
                : const Color(0xFFFFC837),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (_acceptTerms
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFFFC837))
                      .withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: _acceptTerms
                    ? const LinearGradient(
                        colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                      )
                    : null,
                color: _acceptTerms ? null : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _acceptTerms
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFFFC837),
                  width: 3,
                ),
                boxShadow: _acceptTerms
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: _acceptTerms
                  ? const Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                  children: [
                    TextSpan(text: 'Eu aceito os '),
                    TextSpan(
                      text: 'Termos',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(text: ' e a '),
                    TextSpan(
                      text: 'Privacidade',
                      style: TextStyle(
                        color: Color(0xFFFF6B9D),
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(text: ' 🤝✨'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleRegister,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, __) => Transform.scale(
          scale: _isLoading ? 1.0 : _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFC837),
                  Color(0xFFFFD700),
                  Color(0xFFFFAA00),
                  Color(0xFFFFC837),
                ],
              ),
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC837).withOpacity(0.7),
                  blurRadius: 30,
                  spreadRadius: 3,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 8,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🎊', style: TextStyle(fontSize: 32)),
                        SizedBox(width: 14),
                        Text(
                          'VAMOS LÁ!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Color(0x88000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 14),
                        Text('✨', style: TextStyle(fontSize: 32)),
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
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: gradientColors,
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                ),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasError
                  ? [const Color(0xFFFFE6E6), const Color(0xFFFFF0F0)]
                  : [Colors.white, Colors.white],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              width: 3,
              color: hasError ? const Color(0xFFFF6B6B) : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: hasError
                    ? const Color(0xFFFF6B6B).withOpacity(0.4)
                    : gradientColors[0].withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  gradientColors[0].withOpacity(0.15),
                  gradientColors[1].withOpacity(0.08),
                ],
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: controller,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    onChanged: onChanged,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1a1a2e),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE6E6), Color(0xFFFFF0F0)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFF6B6B), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF4444)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B6B).withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Text('😅', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Confetti {
  final String emoji;
  final double? top, bottom, left, right;
  final double size;
  const _Confetti({
    required this.emoji,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
  });
}

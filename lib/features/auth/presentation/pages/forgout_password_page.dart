import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/auth/controller/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────────
// TELA 1 — Digitar e-mail para recuperação
// ─────────────────────────────────────────────────────────────────────────────

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final AuthController _controller = AuthController();

  bool _isLoading = false;
  String? _emailError;
  String? _generalError;

  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
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
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleSendEmail() async {
    setState(() {
      _emailError = null;
      _generalError = null;
      _isLoading = true;
    });

    final error = await _controller.sendResetEmail(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _generalError = error);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ForgotPasswordInstructionsPage(email: _emailController.text.trim()),
      ),
    );
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Não achamos esse email por aqui 🔍✨';
      case 'invalid-email':
        return 'Email tá estranho! Confere aí 📧💫';
      case 'too-many-requests':
        return 'Calma! Muitas tentativas 🕐💫';
      case 'network-request-failed':
        return 'Sem internet! Liga o Wi-Fi 📶✨';
      default:
        return 'Algo deu errado! Tenta de novo 😅💫';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppDecorations.loginBackground,
        child: Stack(
          children: [
            ..._buildBubbles(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildBackButton(context),
                    const SizedBox(height: 32),
                    _buildAnimatedIcon(),
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

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Voltar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _floatAnimation.value),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (_, __) => Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kidsPink.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (_, __) => Transform.rotate(
                      angle: _floatController.value * 2 * math.pi,
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.logoSweep,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.kidsPink, AppTheme.kidsPurple],
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                // ── Título ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.loginTitleBox,
                  child: const Column(
                    children: [
                      Text(
                        '🔑 Esqueceu a senha?',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.kidsPink,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'A gente te ajuda a recuperar! 💪✨',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.kidsPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Texto explicativo ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.kidsPurple.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💡', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Digite o email cadastrado e vamos enviar um link para você criar uma nova senha. Simples assim!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.kidsPurple,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Campo email ──
                _buildEmailField(),
                const SizedBox(height: 20),

                if (_generalError != null) ...[
                  _buildErrorBubble(_generalError!),
                  const SizedBox(height: 20),
                ],

                // ── Botão enviar ──
                _buildSendButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    final hasError = _emailError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 10),
          child: Text(
            'Seu email 📧',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              foreground: AppDecorations.textShader(AppTheme.gradientEmail),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: AppDecorations.fieldOuter(
            gradientColors: AppTheme.gradientEmail,
            hasError: hasError,
          ),
          child: Container(
            decoration: AppDecorations.fieldInner(AppTheme.gradientEmail),
            child: Row(
              children: [
                const SizedBox(width: 18),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: AppDecorations.fieldIcon(AppTheme.gradientEmail),
                  child: const Text('📬', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _emailError = null),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'exemplo@email.com',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 10),
          _buildErrorBubble(_emailError!),
        ],
      ],
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSendEmail,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, __) => Transform.scale(
          scale: _isLoading ? 1.0 : _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.kidsPink, AppTheme.kidsPurple],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kidsPink.withOpacity(0.6),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📩', style: TextStyle(fontSize: 26)),
                        SizedBox(width: 12),
                        Text(
                          'ENVIAR EMAIL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('✨', style: TextStyle(fontSize: 26)),
                      ],
                    ),
            ),
          ),
        ),
      ),
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
                fontSize: 14,
                color: AppTheme.errorRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBubbles() {
    return [
      _bubble(top: 80, left: 30, size: 60, opacity: 0.15),
      _bubble(top: 160, right: 40, size: 80, opacity: 0.10),
      _bubble(bottom: 200, left: 20, size: 100, opacity: 0.08),
      _bubble(bottom: 300, right: 30, size: 70, opacity: 0.12),
    ];
  }

  Widget _bubble({
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
          offset: Offset(0, _floatAnimation.value),
          child: Container(
            width: size,
            height: size,
            decoration: AppDecorations.bubble(
              Colors.white.withOpacity(opacity),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TELA 2 — Instruções pós-envio do email
// ─────────────────────────────────────────────────────────────────────────────

class ForgotPasswordInstructionsPage extends StatefulWidget {
  final String email;

  const ForgotPasswordInstructionsPage({super.key, required this.email});

  @override
  State<ForgotPasswordInstructionsPage> createState() =>
      _ForgotPasswordInstructionsPageState();
}

class _ForgotPasswordInstructionsPageState
    extends State<ForgotPasswordInstructionsPage>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late AnimationController _floatController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  bool _isResending = false;
  bool _resentSuccess = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isResending = true;
      _resentSuccess = false;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
      if (mounted) setState(() => _resentSuccess = true);
    } catch (_) {
      // silencia
    } finally {
      if (mounted) setState(() => _isResending = false);
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
              AppTheme.kidsCyan,
              AppTheme.kidsGreen,
              AppTheme.kidsPurple,
              AppTheme.kidsPink,
            ],
            stops: [0.0, 0.3, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            ..._buildBubbles(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    _buildEmailIcon(),
                    const SizedBox(height: 32),
                    _buildInstructionsCard(),
                    const SizedBox(height: 20),
                    _buildBackToLoginButton(context),
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

  Widget _buildEmailIcon() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kidsCyan.withOpacity(0.6),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: AppTheme.kidsGreen.withOpacity(0.4),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _floatController,
                  builder: (_, __) => Transform.rotate(
                    angle: _floatController.value * 2 * math.pi,
                    child: Container(
                      width: 132,
                      height: 132,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            AppTheme.kidsCyan,
                            AppTheme.kidsGreen,
                            AppTheme.kidsPurple,
                            AppTheme.kidsPink,
                            AppTheme.kidsCyan,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 106,
                  height: 106,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.kidsCyan, AppTheme.kidsGreen],
                    ),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    size: 54,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kidsCyan.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.kidsGreen.withOpacity(0.2),
            blurRadius: 50,
            spreadRadius: 5,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 10,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              gradient: AppTheme.kidsRainbow,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
            child: Column(
              children: [
                // ── Cabeçalho ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE6FFF0), Color(0xFFE6F7FF)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '📬 Email Enviado!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.kidsGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mandamos o link para:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.kidsCyan, AppTheme.kidsGreen],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Passos ──
                _buildStep(
                  number: '1',
                  emoji: '📧',
                  title: 'Abra seu email',
                  description:
                      'Acesse a caixa de entrada do email que você cadastrou no app.',
                  color: AppTheme.kidsCyan,
                ),
                const SizedBox(height: 14),
                _buildStep(
                  number: '2',
                  emoji: '🔍',
                  title: 'Verifique o spam também!',
                  description:
                      'Às vezes o email vai parar na pasta de Spam ou Lixo Eletrônico. Confere lá também! 😊',
                  color: AppTheme.kidsYellow,
                  highlight: true,
                ),
                const SizedBox(height: 14),
                _buildStep(
                  number: '3',
                  emoji: '🔗',
                  title: 'Clique no link',
                  description:
                      'Dentro do email você vai encontrar um botão azul escrito "Redefinir senha". Clica nele!',
                  color: AppTheme.kidsPurple,
                ),
                const SizedBox(height: 14),
                _buildStep(
                  number: '4',
                  emoji: '🔐',
                  title: 'Crie sua nova senha',
                  description:
                      'Você será redirecionado para uma página segura para criar uma senha nova. Use pelo menos 6 caracteres.',
                  color: AppTheme.kidsPink,
                ),
                const SizedBox(height: 14),
                _buildStep(
                  number: '5',
                  emoji: '🎉',
                  title: 'Pronto! É só entrar',
                  description:
                      'Com a nova senha salva, é só voltar pro app e fazer o login normalmente!',
                  color: AppTheme.kidsGreen,
                ),

                const SizedBox(height: 28),

                // ── Dica extra ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBE6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.kidsYellow.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⏱️', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'O link expira em 1 hora!',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Se passar do prazo, volta aqui e solicita um novo link. Tá bem?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFB45309),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Reenviar email ──
                if (_resentSuccess)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6FFF0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.kidsGreen.withOpacity(0.5),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.kidsGreen,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Email reenviado com sucesso! ✅',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.kidsGreenDeep,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _isResending ? null : _resendEmail,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.kidsCyan.withOpacity(0.5),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isResending)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppTheme.kidsCyan,
                              ),
                            )
                          else
                            const Text('📤', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Text(
                            _isResending
                                ? 'Reenviando...'
                                : 'Não recebeu? Reenviar email',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.kidsCyan,
                            ),
                          ),
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

  Widget _buildStep({
    required String number,
    required String emoji,
    required String title,
    required String description,
    required Color color,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? color.withOpacity(0.08) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight ? color.withOpacity(0.5) : Colors.grey.shade200,
          width: highlight ? 2.5 : 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: highlight ? color : AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLoginButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.kidsGreen, AppTheme.kidsCyan],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kidsGreen.withOpacity(0.6),
              blurRadius: 25,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎮', style: TextStyle(fontSize: 26)),
            SizedBox(width: 12),
            Text(
              'VOLTAR PARA O LOGIN',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(width: 12),
            Text('✨', style: TextStyle(fontSize: 26)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBubbles() {
    return [
      _bubble(top: 60, left: 20, size: 70, opacity: 0.12),
      _bubble(top: 180, right: 30, size: 90, opacity: 0.10),
      _bubble(bottom: 150, left: 30, size: 80, opacity: 0.08),
    ];
  }

  Widget _bubble({
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
        animation: _floatController,
        builder: (_, __) {
          final t = Tween<double>(begin: -6, end: 6)
              .animate(
                CurvedAnimation(
                  parent: _floatController,
                  curve: Curves.easeInOut,
                ),
              )
              .value;
          return Transform.translate(
            offset: Offset(0, t),
            child: Container(
              width: size,
              height: size,
              decoration: AppDecorations.bubble(
                Colors.white.withOpacity(opacity),
              ),
            ),
          );
        },
      ),
    );
  }
}

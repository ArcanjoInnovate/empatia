import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/auth/controller/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────────
// _Responsive — espelha exatamente a arquitetura do LoginPage:
//   • recebe (width, height) de LayoutBuilder + MediaQuery
//   • scale = (width / 390).clamp(0.86, 1.0) * (isCompact ? 0.92 : 1.0)
//   • nomenclatura idêntica: gapXL/L/M/S, fontTitle/Subtitle/Label/Body/Button,
//     fieldHeight, buttonHeight
// ─────────────────────────────────────────────────────────────────────────────
class _Responsive {
  final double width;
  final double height;

  const _Responsive(this.width, this.height);

  // ── Flags ──────────────────────────────────────────────────────────────────
  bool get isTablet  => width  >= 600;
  bool get isCompact => height <  680;

  // ── Fator base — idêntico ao login ────────────────────────────────────────
  double get scale => (width / 390).clamp(0.86, 1.0) * (isCompact ? 0.92 : 1.0);

  // ── Largura útil ──────────────────────────────────────────────────────────
  double get contentWidth => isTablet ? 480.0 : width - 32;

  // ── Tipografia ────────────────────────────────────────────────────────────
  double get fontTitle    => 22 * scale;
  double get fontSubtitle => 15 * scale;
  double get fontLabel    => 16 * scale;
  double get fontBody     => 14 * scale;
  double get fontButton   => 17 * scale;  // botões principais
  double get fontCaption  => 13 * scale;
  double get fontStep     => 15 * scale;  // título dos passos
  double get fontStepDesc => 13 * scale;  // descrição dos passos
  double get fontEmail    => 15 * scale;  // chip de email na tela 2

  // ── Espaçamentos ──────────────────────────────────────────────────────────
  double get gapXL => (isCompact ? 20.0 : 32.0) * scale;
  double get gapL  => (isCompact ? 16.0 : 28.0) * scale;
  double get gapM  => (isCompact ? 12.0 : 20.0) * scale;
  double get gapS  => (isCompact ?  6.0 : 10.0) * scale;
  double get gapXS => (isCompact ?  4.0 :  6.0) * scale;

  // ── Alturas fixas ─────────────────────────────────────────────────────────
  double get fieldHeight  => 54 * scale;
  double get buttonHeight => 64 * scale;

  // ── Padding horizontal ────────────────────────────────────────────────────
  double get pagePadH => isTablet ? 40.0 : 20.0;
  double get cardPadH => 28 * scale;

  // ── Logo / ícone animado ──────────────────────────────────────────────────
  double get iconSize      => 120 * scale;
  double get iconRingSize  => iconSize * 0.933;  // 112/120
  double get iconInnerSize => iconSize * 0.733;  // 88/120
  double get iconIconSize  => iconSize * 0.367;  // 44/120

  // ── Ícone da tela 2 (maior) ───────────────────────────────────────────────
  double get icon2Size      => 140 * scale;
  double get icon2RingSize  => icon2Size * 0.943;  // 132/140
  double get icon2InnerSize => icon2Size * 0.757;  // 106/140
  double get icon2IconSize  => icon2Size * 0.386;  // 54/140

  // ── Passos ────────────────────────────────────────────────────────────────
  double get stepBadgeSize => 44 * scale;
  double get stepBadgeR    => 14 * scale;
  double get stepIconSize  => 20 * scale;
  double get stepNumSize   => 20 * scale;
}

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
  late Animation<double>   _floatAnimation;
  late Animation<double>   _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
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
      _emailError   = null;
      _generalError = null;
      _isLoading    = true;
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
        builder: (_) => ForgotPasswordInstructionsPage(
          email: _emailController.text.trim(),
        ),
      ),
    );
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
            decoration: AppDecorations.loginBackground,
            child: Stack(children: [
              ..._buildBubbles(),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: r.contentWidth + r.pagePadH * 2),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: r.pagePadH),
                      child: Column(children: [
                        SizedBox(height: r.gapM),
                        _buildBackButton(context, r),
                        SizedBox(height: r.gapXL),
                        _buildAnimatedIcon(r),
                        SizedBox(height: r.gapXL),
                        _buildCard(r),
                        SizedBox(height: r.gapM),
                      ]),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  // ── Back button ────────────────────────────────────────────────────────────
  Widget _buildBackButton(BuildContext context, _Responsive r) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: 16 * r.scale, vertical: 10 * r.scale),
          decoration: AppDecorations.forgotBackButton,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTheme.backgroundColor, size: 18 * r.scale),
            SizedBox(width: 6 * r.scale),
            Text(
              'Voltar',
              style: TextStyle(
                color: AppTheme.backgroundColor,
                fontWeight: FontWeight.w800,
                fontSize: r.fontSubtitle,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Ícone animado ──────────────────────────────────────────────────────────
  Widget _buildAnimatedIcon(_Responsive r) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _floatAnimation.value),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (_, __) => Transform.scale(
            scale: _pulseAnimation.value,
            child: SizedBox(
              width: r.iconSize, height: r.iconSize,
              child: Stack(alignment: Alignment.center, children: [
                AnimatedBuilder(
                  animation: _floatController,
                  builder: (_, __) => Transform.rotate(
                    angle: _floatController.value * 2 * math.pi,
                    child: Container(
                      width: r.iconRingSize, height: r.iconRingSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.logoSweep,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: r.iconInnerSize, height: r.iconInnerSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.kidsPink, AppTheme.kidsPurple],
                    ),
                  ),
                  child: Icon(Icons.lock_reset_rounded,
                      size: r.iconIconSize, color: AppTheme.backgroundColor),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Card principal ─────────────────────────────────────────────────────────
  Widget _buildCard(_Responsive r) {
    return Container(
      decoration: AppDecorations.loginCard,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Column(children: [
          Container(height: 10, decoration: AppDecorations.cardRainbowBar),
          Padding(
            padding: EdgeInsets.fromLTRB(r.cardPadH, r.gapL, r.cardPadH, r.gapL),
            child: Column(children: [

              // Título
              Container(
                padding: EdgeInsets.all(16 * r.scale),
                decoration: AppDecorations.loginTitleBox,
                child: Column(children: [
                  Text(
                    '🔑 Esqueceu a senha?',
                    style: TextStyle(
                      fontSize: r.fontTitle,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.kidsPink,
                    ),
                  ),
                  SizedBox(height: r.gapXS),
                  Text(
                    'A gente te ajuda a recuperar! 💪✨',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: r.fontSubtitle,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.kidsPurple,
                    ),
                  ),
                ]),
              ),
              SizedBox(height: r.gapM),

              // Texto explicativo
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 16 * r.scale, vertical: 14 * r.scale),
                decoration: AppDecorations.forgotInfoBox,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: TextStyle(fontSize: r.fontLabel + 6)),
                    SizedBox(width: r.gapS),
                    Expanded(
                      child: Text(
                        'Digite o email cadastrado e vamos enviar um link para você criar uma nova senha. Simples assim!',
                        style: TextStyle(
                          fontSize: r.fontBody,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.kidsPurple,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: r.gapL),

              // Campo email
              _buildEmailField(r),
              SizedBox(height: r.gapM),

              if (_generalError != null) ...[
                _buildErrorBubble(_generalError!, r),
                SizedBox(height: r.gapM),
              ],

              // Botão enviar
              _buildSendButton(r),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Campo email ────────────────────────────────────────────────────────────
  Widget _buildEmailField(_Responsive r) {
    final hasError = _emailError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8, bottom: r.gapS),
          child: Text(
            'Seu email 📧',
            style: TextStyle(
              fontSize: r.fontLabel,
              fontWeight: FontWeight.w800,
              foreground: AppDecorations.textShader(AppTheme.gradientEmail),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: r.fieldHeight,
          decoration: AppDecorations.fieldOuter(
            gradientColors: AppTheme.gradientEmail,
            hasError: hasError,
          ),
          child: Container(
            decoration: AppDecorations.fieldInner(AppTheme.gradientEmail),
            child: Row(children: [
              SizedBox(width: 18 * r.scale),
              Container(
                padding: EdgeInsets.all(10 * r.scale),
                decoration: AppDecorations.fieldIcon(AppTheme.gradientEmail),
                child: Text('📬',
                    style: TextStyle(fontSize: 22 * r.scale)),
              ),
              SizedBox(width: 14 * r.scale),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() => _emailError = null),
                  style: TextStyle(
                    fontSize: r.fontBody + 2,
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'exemplo@email.com',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: r.fontBody + 1,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ]),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: r.gapS),
          _buildErrorBubble(_emailError!, r),
        ],
      ],
    );
  }

  // ── Botão enviar ───────────────────────────────────────────────────────────
  Widget _buildSendButton(_Responsive r) {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSendEmail,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, __) => Transform.scale(
          scale: _isLoading ? 1.0 : _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            height: r.buttonHeight,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.kidsPink, AppTheme.kidsPurple]),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kidsPink.withOpacity(0.6),
                  blurRadius: 25, spreadRadius: 2, offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 28, height: 28,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: AppTheme.backgroundColor))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('📩', style: TextStyle(fontSize: r.fontButton + 9)),
                      SizedBox(width: 12 * r.scale),
                      Text('ENVIAR EMAIL',
                          style: TextStyle(
                            fontSize: r.fontButton,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.backgroundColor,
                            letterSpacing: 1.5,
                          )),
                      SizedBox(width: 12 * r.scale),
                      Text('✨', style: TextStyle(fontSize: r.fontButton + 9)),
                    ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Erro bubble ────────────────────────────────────────────────────────────
  Widget _buildErrorBubble(String message, _Responsive r) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: 18 * r.scale, vertical: 14 * r.scale),
      decoration: AppDecorations.errorBubble,
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(8 * r.scale),
          decoration: AppDecorations.errorIcon,
          child: Text('😅',
              style: TextStyle(fontSize: 20 * r.scale)),
        ),
        SizedBox(width: 12 * r.scale),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: r.fontBody,
              color: AppTheme.errorRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ]),
    );
  }

  // ── Bubbles de fundo ───────────────────────────────────────────────────────
  List<Widget> _buildBubbles() {
    return [
      _bubble(top: 80,  left:  30, size: 60, opacity: 0.15),
      _bubble(top: 160, right: 40, size: 80, opacity: 0.10),
      _bubble(bottom: 200, left:  20, size: 100, opacity: 0.08),
      _bubble(bottom: 300, right: 30, size: 70,  opacity: 0.12),
    ];
  }

  Widget _bubble({
    double? top, double? bottom, double? left, double? right,
    required double size, required double opacity,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Container(
            width: size, height: size,
            decoration: AppDecorations.bubble(
                AppTheme.backgroundColor.withOpacity(opacity)),
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
  late Animation<double>   _scaleAnimation;
  late Animation<double>   _bounceAnimation;

  bool _isResending   = false;
  bool _resentSuccess = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _scaleAnimation = CurvedAnimation(
        parent: _scaleController, curve: Curves.elasticOut);

    _bounceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));

    _floatController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    setState(() { _isResending = true; _resentSuccess = false; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
      if (mounted) setState(() => _resentSuccess = true);
    } catch (_) {
      // silencia
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
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
            decoration: AppDecorations.loginBackground,
            child: Stack(children: [
              ..._buildBubbles(),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: r.contentWidth + r.pagePadH * 2),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: r.pagePadH),
                      child: Column(children: [
                        SizedBox(height: r.gapXL),
                        _buildEmailIcon(r),
                        SizedBox(height: r.gapXL),
                        _buildInstructionsCard(r),
                        SizedBox(height: r.gapM),
                        _buildBackToLoginButton(context, r),
                        SizedBox(height: r.gapM),
                      ]),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  // ── Ícone animado (tela 2 — maior) ────────────────────────────────────────
  Widget _buildEmailIcon(_Responsive r) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: SizedBox(
            width: r.icon2Size, height: r.icon2Size,
            child: Stack(alignment: Alignment.center, children: [
              AnimatedBuilder(
                animation: _floatController,
                builder: (_, __) => Transform.rotate(
                  angle: _floatController.value * 2 * math.pi,
                  child: Container(
                    width: r.icon2RingSize, height: r.icon2RingSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: [
                        AppTheme.kidsCyan,
                        AppTheme.kidsGreen,
                        AppTheme.kidsPurple,
                        AppTheme.kidsPink,
                        AppTheme.kidsCyan,
                      ]),
                    ),
                  ),
                ),
              ),
              Container(
                width: r.icon2InnerSize, height: r.icon2InnerSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.kidsCyan, AppTheme.kidsGreen],
                  ),
                ),
                child: Icon(Icons.mark_email_read_rounded,
                    size: r.icon2IconSize, color: AppTheme.backgroundColor),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Card de instruções ────────────────────────────────────────────────────
  Widget _buildInstructionsCard(_Responsive r) {
    return Container(
      decoration: AppDecorations.loginCard,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Column(children: [
          Container(
            height: 10,
            decoration: AppDecorations.cardRainbowBar,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(r.cardPadH, r.gapL, r.cardPadH, r.gapL),
            child: Column(children: [

              // Cabeçalho
              Container(
                padding: EdgeInsets.all(16 * r.scale),
                decoration: AppDecorations.forgotSuccessHeader,
                child: Column(children: [
                  Text(
                    '📬 Email Enviado!',
                    style: TextStyle(
                      fontSize: r.fontTitle + 6,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.kidsGreen,
                    ),
                  ),
                  SizedBox(height: r.gapXS + 2),
                  Text(
                    'Mandamos o link para:',
                    style: TextStyle(
                      fontSize: r.fontBody,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: r.gapXS),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14 * r.scale, vertical: 8 * r.scale),
                    decoration: AppDecorations.forgotEmailChip,
                    child: Text(
                      widget.email,
                      style: TextStyle(
                        fontSize: r.fontEmail,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.backgroundColor,
                      ),
                    ),
                  ),
                ]),
              ),
              SizedBox(height: r.gapL),

              // Passos
              _buildStep(r,
                  number: '1', emoji: '📧',
                  title: 'Abra seu email',
                  description: 'Acesse a caixa de entrada do email que você cadastrou no app.',
                  color: AppTheme.kidsCyan),
              SizedBox(height: r.gapS + 4),
              _buildStep(r,
                  number: '2', emoji: '🔍',
                  title: 'Verifique o spam também!',
                  description: 'Às vezes o email vai parar na pasta de Spam ou Lixo Eletrônico. Confere lá também! 😊',
                  color: AppTheme.kidsYellow, highlight: true),
              SizedBox(height: r.gapS + 4),
              _buildStep(r,
                  number: '3', emoji: '🔗',
                  title: 'Clique no link',
                  description: 'Dentro do email você vai encontrar um botão azul escrito "Redefinir senha". Clica nele!',
                  color: AppTheme.kidsPurple),
              SizedBox(height: r.gapS + 4),
              _buildStep(r,
                  number: '4', emoji: '🔐',
                  title: 'Crie sua nova senha',
                  description: 'Você será redirecionado para uma página segura para criar uma senha nova. Use pelo menos 6 caracteres.',
                  color: AppTheme.kidsPink),
              SizedBox(height: r.gapS + 4),
              _buildStep(r,
                  number: '5', emoji: '🎉',
                  title: 'Pronto! É só entrar',
                  description: 'Com a nova senha salva, é só voltar pro app e fazer o login normalmente!',
                  color: AppTheme.kidsGreen),
              SizedBox(height: r.gapL),

              // Dica: link expira
              Container(
                padding: EdgeInsets.all(16 * r.scale),
                decoration: AppDecorations.forgotWarningBox,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⏱️',
                        style: TextStyle(fontSize: r.fontLabel + 8)),
                    SizedBox(width: 12 * r.scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'O link expira em 1 hora!',
                            style: TextStyle(
                              fontSize: r.fontStep,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.kidsAmberDark,
                            ),
                          ),
                          SizedBox(height: r.gapXS),
                          Text(
                            'Se passar do prazo, volta aqui e solicita um novo link. Tá bem?',
                            style: TextStyle(
                              fontSize: r.fontStepDesc,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.kidsAmber,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: r.gapM),

              // Reenviar email
              if (_resentSuccess)
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16 * r.scale, vertical: 12 * r.scale),
                  decoration: AppDecorations.forgotResentBanner,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppTheme.kidsGreen, size: 20 * r.scale),
                      SizedBox(width: 8 * r.scale),
                      Text(
                        'Email reenviado com sucesso! ✅',
                        style: TextStyle(
                          fontSize: r.fontBody,
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
                    padding: EdgeInsets.symmetric(
                        horizontal: 20 * r.scale, vertical: 14 * r.scale),
                    decoration: AppDecorations.forgotResendButton,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isResending)
                          SizedBox(
                            width: 18 * r.scale, height: 18 * r.scale,
                            child: const CircularProgressIndicator(
                                strokeWidth: 2.5, color: AppTheme.kidsCyan),
                          )
                        else
                          Text('📤',
                              style: TextStyle(fontSize: r.fontStep + 5)),
                        SizedBox(width: 10 * r.scale),
                        Text(
                          _isResending
                              ? 'Reenviando...'
                              : 'Não recebeu? Reenviar email',
                          style: TextStyle(
                            fontSize: r.fontBody,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.kidsCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Passo ─────────────────────────────────────────────────────────────────
  Widget _buildStep(
    _Responsive r, {
    required String number,
    required String emoji,
    required String title,
    required String description,
    required Color color,
    bool highlight = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16 * r.scale),
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
          // Badge numérico
          Container(
            width: r.stepBadgeSize, height: r.stepBadgeSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(r.stepBadgeR),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: r.stepNumSize,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.backgroundColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 14 * r.scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(emoji,
                      style: TextStyle(fontSize: r.stepIconSize - 2)),
                  SizedBox(width: 6 * r.scale),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: r.fontStep,
                        fontWeight: FontWeight.w900,
                        color: highlight ? color : AppTheme.textDark,
                      ),
                    ),
                  ),
                ]),
                SizedBox(height: r.gapXS),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: r.fontStepDesc,
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

  // ── Botão voltar ao login ──────────────────────────────────────────────────
  Widget _buildBackToLoginButton(BuildContext context, _Responsive r) {
    return GestureDetector(
      onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            horizontal: 24 * r.scale, vertical: 18 * r.scale),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppTheme.kidsGreen, AppTheme.kidsCyan]),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kidsGreen.withOpacity(0.6),
              blurRadius: 25, spreadRadius: 2, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('🎮', style: TextStyle(fontSize: r.fontButton + 9)),
          SizedBox(width: 12 * r.scale),
          Text(
            'VOLTAR PARA O LOGIN',
            style: TextStyle(
              fontSize: r.fontButton,
              fontWeight: FontWeight.w900,
              color: AppTheme.backgroundColor,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(width: 12 * r.scale),
          Text('✨', style: TextStyle(fontSize: r.fontButton + 9)),
        ]),
      ),
    );
  }

  // ── Bubbles ───────────────────────────────────────────────────────────────
  List<Widget> _buildBubbles() {
    return [
      _bubble(top: 60,  left: 20, size: 70, opacity: 0.12),
      _bubble(top: 180, right: 30, size: 90, opacity: 0.10),
      _bubble(bottom: 150, left: 30, size: 80, opacity: 0.08),
    ];
  }

  Widget _bubble({
    double? top, double? bottom, double? left, double? right,
    required double size, required double opacity,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (_, __) {
          final t = Tween<double>(begin: -6, end: 6)
              .animate(CurvedAnimation(
                  parent: _floatController, curve: Curves.easeInOut))
              .value;
          return Transform.translate(
            offset: Offset(0, t),
            child: Container(
              width: size, height: size,
              decoration:
                  AppDecorations.bubble(AppTheme.backgroundColor.withOpacity(opacity)),
            ),
          );
        },
      ),
    );
  }
}
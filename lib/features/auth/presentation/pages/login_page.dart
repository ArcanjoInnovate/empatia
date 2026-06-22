import 'package:empatia/core/navigation/main_navigation.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/auth/controller/auth_controller.dart';
import 'package:empatia/features/auth/presentation/pages/forgout_password_page.dart';
import 'package:empatia/features/auth/presentation/pages/register_page.dart';
import 'package:empatia/features/auth/presentation/pages/sucess_auth_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// ════════════════════════════════════════════════════════════════════════
/// LOGIN PAGE — redesign premium
///
/// REGRA DE OURO DESTE ARQUIVO: nenhuma Color(0x...), gradiente ou
/// BoxShadow literal aqui. Tudo vem de [AppTheme] (cores/gradientes) e
/// [AppDecorations] (BoxDecoration prontas). Se um dia a marca migrar de
/// paleta ou estilo visual, só `app_theme.dart` e `app_decorations.dart`
/// precisam mudar — esta tela não é tocada.
///
/// Sistema de design:
///  • 1 elemento de assinatura animado (anel gradiente do logo) — tudo o
///    resto é calmo, para não competir por atenção.
///  • Apenas 2 AnimationControllers no total (entrada + loop ambiente).
///  • Hierarquia única por seção: Logo → Saudação → Formulário → CTA
///    secundário.
///  • Responsivo de ~320px até tablet via LayoutBuilder, sem alturas fixas.
/// ════════════════════════════════════════════════════════════════════════
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _loginError;

  // Sinalizam progresso/recompensa (ver _ProgressSteps).
  bool get _emailValid =>
      _emailController.text.contains('@') && _emailController.text.contains('.');
  bool get _passwordValid => _passwordController.text.length >= 6;

  final AuthController controller = AuthController();

  // Controller único de entrada (logo + card aparecendo de forma orquestrada).
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  // Controller único de ambiente (anel do logo + bolhas de fundo), em loop.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat(reverse: true);

  late final Animation<double> _logoAnim = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
  );
  late final Animation<double> _cardAnim = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.30, 1.0, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _emailError = null;
      _passwordError = null;
      _loginError = null;
    });

    bool hasError = false;

    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = 'Cadê o email? 📧');
      hasError = true;
    } else if (!_emailValid) {
      setState(() => _emailError = 'Ops! Email tá estranho 🤔');
      hasError = true;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Senha secreta esquecida? 🔐');
      hasError = true;
    } else if (!_passwordValid) {
      setState(() => _passwordError = 'Senha muito curtinha! 💪');
      hasError = true;
    }

    if (hasError) {
      HapticFeedback.mediumImpact();
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    final result = await controller.loginUser(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (result == 'success') {
      final userData = await controller.getUserData();
      if (!mounted) return;
      if (userData != null) {
        HapticFeedback.mediumImpact();
        Navigator.pushReplacement(
          context,
          _premiumRoute(SuccessAnimationPage(message: 'Bem-vindo!', user: userData)),
        );
        return; // mantém _isLoading true durante a transição de saída
      } else {
        setState(() {
          _isLoading = false;
          _loginError = 'Erro ao carregar dados! 😅';
        });
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _isLoading = false;
        _loginError = result ?? 'Algo deu errado! 😅';
      });
    }
  }

  /// Transição suave e consistente (fade + slide sutil) para navegação.
  PageRouteBuilder _premiumRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final r = _Responsive(constraints.maxWidth, mq.size.height);

          return Container(
            decoration: AppDecorations.loginBackground,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _AmbientBubbles(loop: _ambient),
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: r.horizontalPadding,
                      vertical: 16 * r.scale,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: mq.size.height -
                            mq.padding.top -
                            mq.padding.bottom -
                            32 * r.scale,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FadeTransition(
                                opacity: _logoAnim,
                                child: ScaleTransition(
                                  scale: _logoAnim,
                                  child: _Brand(r: r, ring: _ambient),
                                ),
                              ),
                              SizedBox(height: r.gapXL),
                              FadeTransition(
                                opacity: _cardAnim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.06),
                                    end: Offset.zero,
                                  ).animate(_cardAnim),
                                  child: _BrandCard(
                                    r: r,
                                    child: _LoginForm(
                                      r: r,
                                      emailController: _emailController,
                                      passwordController: _passwordController,
                                      emailFocus: _emailFocus,
                                      passwordFocus: _passwordFocus,
                                      emailError: _emailError,
                                      passwordError: _passwordError,
                                      loginError: _loginError,
                                      emailValid: _emailValid,
                                      passwordValid: _passwordValid,
                                      isPasswordVisible: _isPasswordVisible,
                                      isLoading: _isLoading,
                                      onTogglePassword: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                                      },
                                      onEmailChanged: (_) => setState(() => _emailError = null),
                                      onPasswordChanged: (_) =>
                                          setState(() => _passwordError = null),
                                      onForgotPassword: () => Navigator.push(
                                        context,
                                        _premiumRoute(const ForgotPasswordPage()),
                                      ),
                                      onSubmit: _handleLogin,
                                      onCreateAccount: () => Navigator.push(
                                        context,
                                        _premiumRoute(const RegisterPage()),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ─── Sistema responsivo ────────────────────────────────────────────────
/// Decisões puramente estruturais (tamanho/espaçamento) — não envolve
/// cor nem estilo visual, por isso não pertence a app_decorations.dart.
class _Responsive {
  final double width;
  final double height;
  late final bool isTablet = width >= 600;
  late final bool isCompactHeight = height < 700;
  late final bool isTiny = width < 360;

  late final double scale =
      (width / 390).clamp(0.86, 1.0) * (isCompactHeight ? 0.92 : 1.0);

  late final double horizontalPadding = isTablet ? 32 : (isTiny ? 16 : 20);
  late final double maxContentWidth = isTablet ? 440 : double.infinity;

  late final double gapXL = (isCompactHeight ? 20 : 32) * scale;
  late final double gapL = (isCompactHeight ? 14 : 20) * scale;
  late final double gapM = 12 * scale;
  late final double gapS = 8 * scale;

  late final double fontTitle = (isCompactHeight ? 24 : 28) * scale;
  late final double fontSubtitle = (isCompactHeight ? 13.5 : 15) * scale;
  late final double fontLabel = 13.5 * scale;
  late final double fontBody = 15.5 * scale;
  late final double fontButton = (isCompactHeight ? 16 : 17) * scale;

  late final double logoSize = (isCompactHeight ? 100 : 124) * scale;
  late final double fieldHeight = (isCompactHeight ? 52 : 58) * scale;
  late final double buttonHeight = (isCompactHeight ? 52 : 58) * scale;

  _Responsive(this.width, this.height);
}

/// ─── Bolhas de fundo ────────────────────────────────────────────────────
/// Reduzidas de 5 bolhas + 9 sparkles para 3 bolhas grandes e calmas —
/// usa o mesmo builder `AppDecorations.bubble()` do arquivo original,
/// só com menos elementos competindo por atenção. Um único
/// `AnimatedBuilder` para as três, baixo custo de repaint.
class _AmbientBubbles extends StatelessWidget {
  final AnimationController loop;
  const _AmbientBubbles({required this.loop});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final size = MediaQuery.of(context).size;
        final dy = loop.value * 16 - 8;
        return Stack(
          children: [
            Positioned(
              top: size.height * 0.10 + dy,
              right: -size.width * 0.12,
              child: Container(
                width: size.width * 0.55,
                height: size.width * 0.55,
                decoration: AppDecorations.bubble(Colors.white.withOpacity(0.10)),
              ),
            ),
            Positioned(
              bottom: size.height * 0.22 - dy,
              left: -size.width * 0.18,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: AppDecorations.bubble(Colors.white.withOpacity(0.08)),
              ),
            ),
            Positioned(
              top: size.height * 0.45 + dy * 0.5,
              left: size.width * 0.08,
              child: Container(
                width: size.width * 0.22,
                height: size.width * 0.22,
                decoration: AppDecorations.bubble(Colors.white.withOpacity(0.12)),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ─── Logo + nome (identidade da marca) ─────────────────────────────────
/// Único elemento com animação contínua: o anel gradiente girando.
/// Todas as decorations vêm de AppDecorations/AppTheme.
class _Brand extends StatelessWidget {
  final _Responsive r;
  final AnimationController ring;
  const _Brand({required this.r, required this.ring});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: r.logoSize,
          height: r.logoSize,
          child: Container(
            decoration: AppDecorations.loginLogo,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: ring,
                  builder: (_, __) => Transform.rotate(
                    angle: ring.value * 2 * math.pi,
                    child: Container(
                      width: r.logoSize * 0.94,
                      height: r.logoSize * 0.94,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.logoSweep,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: r.logoSize * 0.78,
                  height: r.logoSize * 0.78,
                  decoration: AppDecorations.loginLogoInner,
                  child: Icon(
                    Icons.favorite_rounded,
                    size: r.logoSize * 0.4,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: r.gapM),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20 * r.scale, vertical: 8 * r.scale),
          decoration: AppDecorations.appNameTag,
          child: Text(
            'EMPATIA 💖',
            style: TextStyle(
              fontSize: r.fontTitle,
              fontWeight: FontWeight.w900,
              foreground: AppDecorations.textShader(
                [AppTheme.kidsPink, AppTheme.kidsPurple],
                width: 220,
              ),
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(height: r.gapS * 0.7),
        if (!r.isCompactHeight)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16 * r.scale, vertical: 6 * r.scale),
            decoration: AppDecorations.brandTagBox,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🧸', style: TextStyle(fontSize: 18)),
                SizedBox(width: 6 * r.scale),
                Text(
                  'Pingo Brinquedos',
                  style: TextStyle(
                    fontSize: r.fontLabel,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.kidsPink,
                  ),
                ),
                SizedBox(width: 6 * r.scale),
                const Text('✨', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
      ],
    );
  }
}

/// ─── Card branco (chrome vem 100% de AppDecorations) ───────────────────
class _BrandCard extends StatelessWidget {
  final _Responsive r;
  final Widget child;
  const _BrandCard({required this.r, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.loginCard,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Column(
          children: [
            Container(height: 10, decoration: AppDecorations.cardRainbowBar),
            Padding(
              padding: EdgeInsets.all(r.isCompactHeight ? 20 : 26),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Formulário ─────────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final _Responsive r;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final String? emailError;
  final String? passwordError;
  final String? loginError;
  final bool emailValid;
  final bool passwordValid;
  final bool isPasswordVisible;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onForgotPassword;
  final VoidCallback onSubmit;
  final VoidCallback onCreateAccount;

  const _LoginForm({
    required this.r,
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.emailError,
    required this.passwordError,
    required this.loginError,
    required this.emailValid,
    required this.passwordValid,
    required this.isPasswordVisible,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onForgotPassword,
    required this.onSubmit,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all((r.isCompactHeight ? 12 : 16) * r.scale),
          decoration: AppDecorations.loginTitleBox,
          child: Column(
            children: [
              Text(
                '👋 Oi, amiguinho!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.fontTitle,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.kidsPink,
                ),
              ),
              SizedBox(height: 4 * r.scale),
              Text(
                'Vamos brincar juntos? 🎈',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.fontSubtitle,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.kidsPurple,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: r.gapM),
        _ProgressSteps(r: r, step1Done: emailValid, step2Done: passwordValid),
        SizedBox(height: r.gapL),

        _PremiumField(
          r: r,
          controller: emailController,
          focusNode: emailFocus,
          label: 'Seu email 📧',
          hint: 'exemplo@email.com',
          icon: '📬',
          gradientColors: AppTheme.gradientEmail,
          errorText: emailError,
          isValid: emailValid && emailController.text.isNotEmpty,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: onEmailChanged,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(passwordFocus),
        ),
        SizedBox(height: r.gapM),
        _PremiumField(
          r: r,
          controller: passwordController,
          focusNode: passwordFocus,
          label: 'Senha secreta 🔐',
          hint: '••••••••',
          icon: '🗝️',
          gradientColors: AppTheme.gradientPassword,
          errorText: passwordError,
          isValid: passwordValid,
          obscureText: !isPasswordVisible,
          textInputAction: TextInputAction.done,
          onChanged: onPasswordChanged,
          onSubmitted: (_) => onSubmit(),
          suffix: GestureDetector(
            onTap: onTogglePassword,
            child: Container(
              padding: EdgeInsets.all(8 * r.scale),
              decoration: AppDecorations.passwordTogglePurple,
              child: Text(
                isPasswordVisible ? '🙈' : '👁️',
                style: TextStyle(fontSize: 20 * r.scale),
              ),
            ),
          ),
        ),

        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: onForgotPassword,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14 * r.scale, vertical: 8 * r.scale),
              decoration: AppDecorations.forgotPasswordLink,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔑', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6 * r.scale),
                  Text(
                    'Esqueci a senha',
                    style: TextStyle(
                      fontSize: r.fontLabel,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.kidsPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: loginError == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: EdgeInsets.only(top: r.gapS, bottom: r.gapM),
                  child: _ErrorBanner(r: r, message: loginError!),
                ),
        ),

        SizedBox(height: r.gapS),
        _PrimaryButton(
          r: r,
          label: 'VAMOS LÁ!',
          isLoading: isLoading,
          onTap: onSubmit,
        ),

        SizedBox(height: r.gapL),
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12 * r.scale),
              child: Text(
                '✨ ou ✨',
                style: TextStyle(
                  fontSize: r.fontLabel,
                  fontWeight: FontWeight.w700,
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
        SizedBox(height: r.gapL),
        _SecondaryButton(r: r, label: 'CRIAR CONTA', onTap: onCreateAccount),
      ],
    );
  }
}

/// ─── Indicador de progresso (recompensa leve, não intrusiva) ──────────
class _ProgressSteps extends StatelessWidget {
  final _Responsive r;
  final bool step1Done;
  final bool step2Done;
  const _ProgressSteps({required this.r, required this.step1Done, required this.step2Done});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(step1Done),
        Container(width: 18 * r.scale, height: 2, color: AppTheme.textMuted.withOpacity(0.2)),
        _dot(step2Done),
      ],
    );
  }

  Widget _dot(bool done) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 10 * r.scale,
      height: 10 * r.scale,
      decoration: AppDecorations.progressDot(done: done),
    );
  }
}

/// ─── Campo de texto premium ─────────────────────────────────────────────
/// Usa fieldOuter/fieldInner/fieldIcon centralizados; o único parâmetro
/// novo é `isFocused`, já suportado por AppDecorations.fieldOuter.
class _PremiumField extends StatelessWidget {
  final _Responsive r;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final String icon;
  final List<Color> gradientColors;
  final String? errorText;
  final bool isValid;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  const _PremiumField({
    required this.r,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.gradientColors,
    this.errorText,
    this.isValid = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8, bottom: 10 * r.scale),
          child: Text(
            label,
            style: TextStyle(
              fontSize: r.fontLabel + 2.5,
              fontWeight: FontWeight.w800,
              foreground: AppDecorations.textShader(gradientColors),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: AppDecorations.fieldOuter(
            gradientColors: gradientColors,
            hasError: hasError,
            isFocused: focusNode.hasFocus,
          ),
          child: Container(
            height: r.fieldHeight,
            decoration: AppDecorations.fieldInner(gradientColors),
            child: Row(
              children: [
                SizedBox(width: 16 * r.scale),
                Container(
                  padding: EdgeInsets.all(9 * r.scale),
                  decoration: AppDecorations.fieldIcon(gradientColors),
                  child: Text(icon, style: TextStyle(fontSize: 19 * r.scale)),
                ),
                SizedBox(width: 12 * r.scale),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    style: TextStyle(
                      fontSize: r.fontBody,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: r.fontBody,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: suffix != null
                      ? Padding(
                          key: const ValueKey('suffix'),
                          padding: EdgeInsets.symmetric(horizontal: 8 * r.scale),
                          child: suffix,
                        )
                      : (isValid
                          ? Padding(
                              key: const ValueKey('check'),
                              padding: EdgeInsets.symmetric(horizontal: 16 * r.scale),
                              child: Icon(Icons.check_circle_rounded,
                                  color: AppTheme.kidsGreenDeep, size: 22),
                            )
                          : const SizedBox(key: ValueKey('empty'), width: 16)),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: hasError
              ? Padding(
                  padding: EdgeInsets.only(top: 8 * r.scale),
                  child: _ErrorBanner(r: r, message: errorText!),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

/// ─── Banner de erro (campo ou login geral) — usa errorBubble/errorIcon ──
class _ErrorBanner extends StatelessWidget {
  final _Responsive r;
  final String message;
  const _ErrorBanner({required this.r, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16 * r.scale, vertical: 12 * r.scale),
      decoration: AppDecorations.errorBubble,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(7 * r.scale),
            decoration: AppDecorations.errorIcon,
            child: Text('😅', style: TextStyle(fontSize: 18 * r.scale)),
          ),
          SizedBox(width: 10 * r.scale),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: r.fontLabel,
                color: AppTheme.errorRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Botão primário — usa AppDecorations.loginButton ────────────────────
class _PrimaryButton extends StatefulWidget {
  final _Responsive r;
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.r,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.isLoading) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          height: r.buttonHeight,
          width: double.infinity,
          decoration: AppDecorations.loginButton,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: widget.isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.8, color: Colors.white),
                    )
                  : Row(
                      key: const ValueKey('label'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎮', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 10 * r.scale),
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: r.fontButton,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(width: 10 * r.scale),
                        const Text('✨', style: TextStyle(fontSize: 24)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ─── Botão secundário — usa AppDecorations.createAccountButton ─────────
class _SecondaryButton extends StatefulWidget {
  final _Responsive r;
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.r, required this.label, required this.onTap});

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 24 * r.scale,
            vertical: (r.isCompactHeight ? 12 : 16) * r.scale,
          ),
          decoration: AppDecorations.createAccountButton,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10 * r.scale),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: r.fontButton * 0.92,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(width: 10 * r.scale),
              const Text('🚀', style: TextStyle(fontSize: 22)),
            ],
          ),
        ),
      ),
    );
  }
}
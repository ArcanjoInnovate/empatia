import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/auth/controller/auth_controller.dart';
import 'package:empatia/features/auth/presentation/pages/age_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // ── Flags ─────────────────────────────────────────────────────────────────
  bool get isTablet   => width  >= 600;
  bool get isCompact  => height <  680;   // tela curta (mesmo critério do login)

  // ── Fator base — idêntico ao login ───────────────────────────────────────
  double get scale => (width / 390).clamp(0.86, 1.0) * (isCompact ? 0.92 : 1.0);

  // ── Largura do card ───────────────────────────────────────────────────────
  double get contentWidth => isTablet ? 480.0 : width - 32;

  // ── Tipografia (mesmos nomes do login) ────────────────────────────────────
  double get fontTitle    => 22 * scale;
  double get fontSubtitle => 13 * scale;
  double get fontLabel    => 13 * scale;
  double get fontBody     => 15 * scale;   // texto dentro dos campos
  double get fontButton   => 17 * scale;
  double get fontCaption  => 12 * scale;
  double get fontHint     => 14 * scale;
  double get fontTerms    => 13 * scale;
  double get fontProgress => 10 * scale;

  // ── Espaçamentos (mesmos nomes do login) ──────────────────────────────────
  double get gapXL => (isCompact ? 16.0 : 22.0) * scale;  // entre seções grandes
  double get gapL  => (isCompact ? 12.0 : 18.0) * scale;  // entre seções normais
  double get gapM  => (isCompact ? 10.0 : 14.0) * scale;  // entre campos
  double get gapS  => (isCompact ?  4.0 :  6.0) * scale;  // micro-gaps

  // ── Alturas fixas (mesmos nomes do login) ─────────────────────────────────
  double get fieldHeight  => 54 * scale;
  double get buttonHeight => 56 * scale;

  // ── Padding horizontal ────────────────────────────────────────────────────
  double get pagePadH  => isTablet ? 40.0 : 16.0;
  double get cardPadH  => 20 * scale;

  // ── Logo ──────────────────────────────────────────────────────────────────
  double get logoSize      => 96 * scale;
  double get logoInnerSize => logoSize * 0.72;
  double get logoIconSize  => logoSize * 0.36;

  // ── Campo: prefixo e ícone ────────────────────────────────────────────────
  double get fieldPrefixW   => 52 * scale;
  double get fieldIconPad   => 10 * scale;
  double get fieldIconEmoji => 20 * scale;

  // ── Botão: emoji ──────────────────────────────────────────────────────────
  double get btnEmoji => 24 * scale;

  // ── Indicador de progresso ────────────────────────────────────────────────
  double get dotSize   => 10 * scale;
  double get lineHeight => 2.5;          // não escala — espessura visual é fixa

  // ── Blobs decorativos ─────────────────────────────────────────────────────
  double get blob1 => width * 0.55;
  double get blob2 => width * 0.65;
  double get blob3 => width * 0.45;
}

// ─────────────────────────────────────────────────────────────────────────────
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {

  final _emailTc   = TextEditingController();
  final _passTc    = TextEditingController();
  final _confirmTc = TextEditingController();

  final _emailFn   = FocusNode();
  final _passFn    = FocusNode();
  final _confirmFn = FocusNode();

  bool _showPass       = false;
  bool _showConfirm    = false;
  bool _acceptTerms    = false;
  bool _btnPressed     = false;

  bool _emailValid     = false;
  bool _passValid      = false;
  bool _confirmValid   = false;

  bool _emailFocused   = false;
  bool _passFocused    = false;
  bool _confirmFocused = false;

  String? _emailErr;
  String? _passErr;
  String? _confirmErr;
  String? _termsErr;
  String? _globalErr;

  final _auth = AuthController();

  late AnimationController _entryCtrl;
  late AnimationController _ambientCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _floatAnim;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _ambientCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: _ambientCtrl, curve: Curves.easeInOut));

    _entryCtrl.forward();

    for (final pair in [
      (_emailFn,   (bool v) => setState(() => _emailFocused   = v)),
      (_passFn,    (bool v) => setState(() => _passFocused    = v)),
      (_confirmFn, (bool v) => setState(() => _confirmFocused = v)),
    ]) {
      final fn = pair.$1 as FocusNode;
      final cb = pair.$2 as void Function(bool);
      fn.addListener(() => cb(fn.hasFocus));
    }
  }

  @override
  void dispose() {
    for (final c in [_emailTc, _passTc, _confirmTc]) c.dispose();
    for (final f in [_emailFn, _passFn, _confirmFn]) f.dispose();
    _entryCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  // ── Validação em tempo real ───────────────────────────────────────────────
  void _onEmailChanged(String v) => setState(() {
    _emailErr   = null;
    _emailValid = v.trim().isNotEmpty && v.contains('@') && v.contains('.');
  });

  void _onPassChanged(String v) => setState(() {
    _passErr      = null;
    _passValid    = v.length >= 6;
    _confirmValid = _confirmTc.text.isNotEmpty && _confirmTc.text == v;
  });

  void _onConfirmChanged(String v) => setState(() {
    _confirmErr   = null;
    _confirmValid = v.isNotEmpty && v == _passTc.text;
  });

  // ── Submit ────────────────────────────────────────────────────────────────
  void _submit() {
    HapticFeedback.mediumImpact();
    setState(() {
      _emailErr = _passErr = _confirmErr = _termsErr = _globalErr = null;
    });

    bool err = false;

    if (_emailTc.text.trim().isEmpty ||
        !_emailTc.text.contains('@') ||
        !_emailTc.text.contains('.')) {
      setState(() => _emailErr = 'E-mail inválido. Confere o formato 📧');
      err = true;
    }
    if (_passTc.text.isEmpty || _passTc.text.length < 6) {
      setState(() => _passErr = 'Mínimo 6 caracteres na senha 🔐');
      err = true;
    }
    if (_confirmTc.text != _passTc.text || _confirmTc.text.isEmpty) {
      setState(() => _confirmErr = 'As senhas não conferem 🔑');
      err = true;
    }
    if (!_acceptTerms) {
      setState(() => _termsErr = 'Aceite os termos para continuar');
      err = true;
    }
    if (err) {
      HapticFeedback.heavyImpact();
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => AgeVerificationPage(
          email: _emailTc.text.trim(),
          password: _passTc.text,
          authController: _auth,
        ),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  int get _progress =>
      [_emailValid, _passValid, _confirmValid].where((v) => v).length;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // LayoutBuilder fornece width; MediaQuery fornece height — idêntico ao login
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = _Responsive(
          constraints.maxWidth,
          MediaQuery.of(context).size.height,
        );

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Container(
            decoration: AppDecorations.registerBackground,
            child: Stack(children: [
              _blobs(r),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: r.contentWidth + r.pagePadH * 2),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding:
                              EdgeInsets.symmetric(horizontal: r.pagePadH),
                          child: Column(children: [
                            SizedBox(height: r.gapL),
                            _logo(r),
                            SizedBox(height: r.gapL),
                            _card(r),
                            SizedBox(height: r.gapL),
                          ]),
                        ),
                      ),
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

  // ── Blobs de fundo ────────────────────────────────────────────────────────
  Widget _blobs(_Responsive r) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, __) {
        final h = MediaQuery.of(context).size.height;
        return Stack(children: [
          Positioned(
            top:  h * 0.03 + _floatAnim.value,
            left: -r.blob1 * 0.38,
            child: _blob(r.blob1, 0.12),
          ),
          Positioned(
            top:   h * 0.30 - _floatAnim.value,
            right: -r.blob2 * 0.42,
            child: _blob(r.blob2, 0.09),
          ),
          Positioned(
            bottom: h * 0.08 + _floatAnim.value * 0.6,
            left:  -r.blob3 * 0.28,
            child: _blob(r.blob3, 0.11),
          ),
        ]);
      },
    );
  }

  Widget _blob(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: AppDecorations.blobDecoration(opacity),
      );

  // ── Logo com anel giratório ───────────────────────────────────────────────
  Widget _logo(_Responsive r) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _floatAnim.value * 0.35),
        child: SizedBox(
          width: r.logoSize,
          height: r.logoSize,
          child: Stack(alignment: Alignment.center, children: [
            AnimatedBuilder(
              animation: _ambientCtrl,
              builder: (_, __) => Transform.rotate(
                angle: _ambientCtrl.value * 2 * math.pi,
                child: Container(
                  width: r.logoSize,
                  height: r.logoSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.registerLogoSweep,
                  ),
                ),
              ),
            ),
            Container(
              width: r.logoSize * 0.78,
              height: r.logoSize * 0.78,
              decoration: AppDecorations.registerLogo,
            ),
            Container(
              width: r.logoInnerSize,
              height: r.logoInnerSize,
              decoration: AppDecorations.registerLogoInner,
              child: Icon(Icons.favorite,
                  size: r.logoIconSize, color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Card ──────────────────────────────────────────────────────────────────
  Widget _card(_Responsive r) {
    return Container(
      width: double.infinity,
      decoration: AppDecorations.registerCard,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 8, decoration: AppDecorations.cardRainbowBar),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    r.cardPadH, r.gapXL, r.cardPadH, r.gapXL),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _titleBox(r),
                      SizedBox(height: r.gapL),
                      _progressRow(r),
                      SizedBox(height: r.gapL),

                      // E-mail
                      _field(r,
                          tc: _emailTc,
                          fn: _emailFn,
                          label: 'E-mail',
                          hint: 'seuemail@exemplo.com',
                          icon: '📬',
                          colors: AppTheme.gradientEmail,
                          focused: _emailFocused,
                          valid: _emailValid,
                          error: _emailErr,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: _onEmailChanged),
                      SizedBox(height: r.gapM),

                      // Senha
                      _field(r,
                          tc: _passTc,
                          fn: _passFn,
                          label: 'Senha',
                          hint: 'Mínimo 6 caracteres',
                          icon: '🗝️',
                          colors: AppTheme.gradientPassword,
                          focused: _passFocused,
                          valid: _passValid,
                          error: _passErr,
                          obscure: !_showPass,
                          onChanged: _onPassChanged,
                          suffix: _eyeBtn(
                              '🙈', '👁️', _showPass,
                              () {
                                HapticFeedback.lightImpact();
                                setState(() => _showPass = !_showPass);
                              },
                              AppDecorations.passwordTogglePurple)),
                      SizedBox(height: r.gapM),

                      // Confirmar senha
                      _field(r,
                          tc: _confirmTc,
                          fn: _confirmFn,
                          label: 'Confirmar senha',
                          hint: 'Repete a mesma senha',
                          icon: '🎯',
                          colors: AppTheme.gradientConfirm,
                          focused: _confirmFocused,
                          valid: _confirmValid,
                          error: _confirmErr,
                          obscure: !_showConfirm,
                          onChanged: _onConfirmChanged,
                          suffix: _eyeBtn(
                              '🙈', '👁️', _showConfirm,
                              () {
                                HapticFeedback.lightImpact();
                                setState(() => _showConfirm = !_showConfirm);
                              },
                              AppDecorations.passwordTogglePink)),
                      SizedBox(height: r.gapL),

                      _terms(r),
                      if (_termsErr != null) ...[
                        SizedBox(height: r.gapS + 4),
                        _errBubble(_termsErr!, r),
                      ],
                      if (_globalErr != null) ...[
                        SizedBox(height: r.gapS + 4),
                        _errBubble(_globalErr!, r),
                      ],
                      SizedBox(height: r.gapL),

                      _registerBtn(r),
                      SizedBox(height: r.gapL),

                      _loginLink(r),
                    ]),
              ),
            ]),
      ),
    );
  }

  // ── Título ────────────────────────────────────────────────────────────────
  Widget _titleBox(_Responsive r) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: r.cardPadH * 0.6, vertical: r.gapL * 0.7),
      decoration: AppDecorations.registerTitleBox,
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎉', style: TextStyle(fontSize: r.fontTitle * 1.1)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Vem com a gente!',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: r.fontTitle,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.kidsPink,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('🚀', style: TextStyle(fontSize: r.fontTitle * 1.1)),
          ],
        ),
        SizedBox(height: r.gapS),
        Text(
          'Rápido, fácil e seguro ✨',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: r.fontSubtitle,
            fontWeight: FontWeight.w600,
            color: AppTheme.kidsPurple,
          ),
        ),
      ]),
    );
  }

  // ── Indicador de progresso ────────────────────────────────────────────────
  Widget _progressRow(_Responsive r) {
    const labels = ['E-mail', 'Senha', 'Confirmação'];
    return Row(
      children: List.generate(labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final done = (i ~/ 2) < _progress;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: r.lineHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: done
                    ? AppTheme.kidsGreenDeep
                    : AppTheme.kidsPurple.withOpacity(0.15),
              ),
            ),
          );
        }
        final step = i ~/ 2;
        final done = step < _progress;
        return Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width:  done ? r.dotSize * 1.35 : r.dotSize,
            height: done ? r.dotSize * 1.35 : r.dotSize,
            decoration: AppDecorations.progressDot(done: done),
          ),
          SizedBox(height: r.gapS),
          Text(
            labels[step],
            style: TextStyle(
              fontSize: r.fontProgress,
              fontWeight: FontWeight.w700,
              color: done ? AppTheme.kidsGreenDeep : AppTheme.textMuted,
            ),
          ),
        ]);
      }),
    );
  }

  // ── Campo de texto ────────────────────────────────────────────────────────
  Widget _field(
    _Responsive r, {
    required TextEditingController tc,
    required FocusNode fn,
    required String label,
    required String hint,
    required String icon,
    required List<Color> colors,
    required bool focused,
    required bool valid,
    String? error,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
    required void Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + check
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: r.gapS),
          child: Row(children: [
            Text(
              label,
              style: TextStyle(
                fontSize: r.fontLabel,
                fontWeight: FontWeight.w700,
                foreground: AppDecorations.textShader(colors),
              ),
            ),
            const Spacer(),
            AnimatedOpacity(
              opacity: valid ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Row(children: [
                Icon(Icons.check_circle_rounded,
                    size: r.fontLabel + 1, color: AppTheme.kidsGreenDeep),
                SizedBox(width: r.gapS - 2),
                Text('OK',
                    style: TextStyle(
                      fontSize: r.fontLabel - 1,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.kidsGreenDeep,
                    )),
              ]),
            ),
          ]),
        ),

        // Campo — altura fixa via fieldHeight (mesmo nome do login)
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: r.fieldHeight,
          decoration: AppDecorations.fieldOuter(
            gradientColors: colors,
            hasError: error != null,
            isFocused: focused,
          ),
          child: Container(
            decoration: AppDecorations.fieldInner(colors),
            child: Row(children: [
              SizedBox(
                width: r.fieldPrefixW,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(r.fieldIconPad),
                    decoration: AppDecorations.fieldIcon(colors),
                    child: Text(icon,
                        style: TextStyle(fontSize: r.fieldIconEmoji)),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: tc,
                  focusNode: fn,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  style: TextStyle(
                    fontSize: r.fontBody,
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: r.fontHint,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (suffix != null) ...[suffix, SizedBox(width: 10)],
            ]),
          ),
        ),

        if (error != null) ...[
          SizedBox(height: r.gapS + 2),
          _errBubble(error, r),
        ],
      ],
    );
  }

  Widget _eyeBtn(String hide, String show, bool visible, VoidCallback onTap,
      BoxDecoration deco) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: deco,
        child: Text(visible ? hide : show,
            style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  // ── Termos ────────────────────────────────────────────────────────────────
  Widget _terms(_Responsive r) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _acceptTerms = !_acceptTerms;
          if (_acceptTerms) _termsErr = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(r.gapM),
        decoration: AppDecorations.termsCheckbox(accepted: _acceptTerms),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 28,
            height: 28,
            decoration: AppDecorations.termsCheckboxTick(accepted: _acceptTerms),
            child: _acceptTerms
                ? const Icon(Icons.check_rounded,
                    size: 17, color: Colors.white)
                : null,
          ),
          SizedBox(width: r.gapM),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: r.fontTerms,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSubtle,
                  height: 1.4,
                ),
                children: const [
                  TextSpan(text: 'Li e aceito os '),
                  TextSpan(
                    text: 'Termos de Uso',
                    style: TextStyle(
                      color: AppTheme.kidsPurple,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' e a '),
                  TextSpan(
                    text: 'Política de Privacidade',
                    style: TextStyle(
                      color: AppTheme.kidsPink,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' 🤝'),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Botão registrar ───────────────────────────────────────────────────────
  Widget _registerBtn(_Responsive r) {
    return GestureDetector(
      onTapDown:  (_) { setState(() => _btnPressed = true);  HapticFeedback.lightImpact(); },
      onTapUp:    (_) => setState(() => _btnPressed = false),
      onTapCancel: () => setState(() => _btnPressed = false),
      onTap: _submit,
      child: AnimatedScale(
        scale: _btnPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Container(
          width: double.infinity,
          height: r.buttonHeight,           // ← mesmo nome do login
          decoration: AppDecorations.registerButton,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('🎊', style: TextStyle(fontSize: r.btnEmoji)),
            const SizedBox(width: 10),
            Text(
              'CRIAR CONTA',
              style: TextStyle(
                fontSize: r.fontButton,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.4,
                shadows: const [
                  Shadow(
                      color: AppTheme.shadowDark,
                      blurRadius: 6,
                      offset: Offset(0, 2))
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('✨', style: TextStyle(fontSize: r.btnEmoji)),
          ]),
        ),
      ),
    );
  }

  // ── Link "já tenho conta" ─────────────────────────────────────────────────
  Widget _loginLink(_Responsive r) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(
        'Já tem conta? ',
        style: TextStyle(
          fontSize: r.fontCaption + 1,
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
      GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: AppDecorations.loginLinkButton,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('🎮', style: TextStyle(fontSize: r.fontCaption + 4)),
            const SizedBox(width: 5),
            Text(
              'ENTRAR',
              style: TextStyle(
                fontSize: r.fontCaption + 1,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  // ── Erro bubble ───────────────────────────────────────────────────────────
  Widget _errBubble(String msg, _Responsive r) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppDecorations.errorBubble,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: AppDecorations.errorIcon,
          child: const Text('😅', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            msg,
            style: TextStyle(
              fontSize: r.fontCaption + 1,
              color: AppTheme.errorRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ]),
    );
  }
}
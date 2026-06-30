import 'package:empatia/core/constant/legal_linkgs_constant.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/auth/controller/auth_controller.dart';
import 'package:empatia/features/auth/presentation/pages/age_verification_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────────
// _Responsive — mesma arquitetura do LoginPage.
// ─────────────────────────────────────────────────────────────────────────────
class _Responsive {
  final double width;
  final double height;

  const _Responsive(this.width, this.height);

  bool get isTablet  => width  >= 600;
  bool get isCompact => height <  680;

  double get scale => (width / 390).clamp(0.86, 1.0) * (isCompact ? 0.92 : 1.0);

  double get contentWidth => isTablet ? 480.0 : width - 32;

  double get fontTitle    => 22 * scale;
  double get fontSubtitle => 13 * scale;
  double get fontLabel    => 13 * scale;
  double get fontBody     => 16.5 * scale;
  double get fontButton   => 17 * scale;
  double get fontCaption  => 12 * scale;
  double get fontHint     => 15.5 * scale;
  double get fontTerms    => 13 * scale;
  double get fontProgress => 10 * scale;

  double get gapXL => (isCompact ? 16.0 : 22.0) * scale;
  double get gapL  => (isCompact ? 12.0 : 18.0) * scale;
  double get gapM  => (isCompact ? 10.0 : 14.0) * scale;
  double get gapS  => (isCompact ?  4.0 :  6.0) * scale;

  double get fieldHeight  => 58 * scale;
  double get buttonHeight => 56 * scale;

  double get pagePadH => isTablet ? 40.0 : 16.0;
  double get cardPadH => 20 * scale;

  double get logoSize      => 128 * scale;
  double get logoInnerSize => logoSize * 0.78;
  double get logoIconSize  => logoSize * 0.4;

  double get fieldPrefixW   => 52 * scale;
  double get fieldIconPad   => 10 * scale;
  double get fieldIconEmoji => 20 * scale;

  double get btnEmoji => 24 * scale;

  double get dotSize    => 10 * scale;
  double get lineHeight => 2.5;

  // Toque mínimo acessível (regra: ~44x44)
  double get tapMin => 44.0;

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

  bool _showPass    = false;
  bool _showConfirm = false;
  bool _acceptTerms = false;
  bool _btnPressed  = false;
  bool _isSubmitting = false; // ← novo: estado de loading visível

  bool _emailValid   = false;
  bool _passValid    = false;
  bool _confirmValid = false;

  bool _emailFocused   = false;
  bool _passFocused    = false;
  bool _confirmFocused = false;

  String? _emailErr;
  String? _passErr;
  String? _confirmErr;
  String? _termsErr;
  String? _globalErr; // agora é de fato populado em caso de falha

  final _auth = AuthController();

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  // Apenas para o float ambiente dos blobs/logo (NÃO é mais usado para girar o anel)
  late AnimationController _entryCtrl;
  late AnimationController _ambientCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        HapticFeedback.lightImpact();
        LegalLinks.openTerms();
      };
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        HapticFeedback.lightImpact();
        LegalLinks.openPrivacyPolicy();
      };

    _entryCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    // Float ambiente (oscila ida-e-volta de propósito — é o efeito desejado p/ blobs)
    _ambientCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _ambientCtrl, curve: Curves.easeInOut));

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
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _entryCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  // ── Validação em tempo real ───────────────────────────────────────────────
  static final _emailRegex =
      RegExp(r'^[\w\.\-]+@[\w\-]+\.[A-Za-z]{2,}$');

  void _onEmailChanged(String v) => setState(() {
        _emailErr = null;
        _emailValid = _emailRegex.hasMatch(v.trim());
      });

  void _onPassChanged(String v) => setState(() {
        _passErr = null;
        _passValid = v.length >= 6;
        _confirmValid = _confirmTc.text.isNotEmpty && _confirmTc.text == v;
      });

  void _onConfirmChanged(String v) => setState(() {
        _confirmErr = null;
        _confirmValid = v.isNotEmpty && v == _passTc.text;
      });

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_isSubmitting) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _emailErr = _passErr = _confirmErr = _termsErr = _globalErr = null;
    });

    bool err = false;

    if (!_emailRegex.hasMatch(_emailTc.text.trim())) {
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

    // Não existe checagem assíncrona de e-mail disponível antes desta tela:
    // a conta só é de fato criada em AgeVerificationPage, via
    // AuthController.registerUserWithBirthDate (depois da data de nascimento
    // também ser validada). O erro 'email-already-in-use' é mapeado lá por
    // _mapErrorRegister. Aqui _isSubmitting cobre só a transição de tela,
    // evitando duplo toque, e um pequeno delay garante que o spinner seja
    // perceptível mesmo em devices rápidos.
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _isSubmitting = false);

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = _Responsive(
          constraints.maxWidth,
          MediaQuery.of(context).size.height,
        );

        // Trava a escala de fonte do sistema (acessibilidade do usuário varia
        // por padrão entre fabricantes Android e o iOS, causando diferença de
        // tamanho percebida mesmo com o mesmo fontSize lógico). Clampamos
        // entre 0.9x e 1.15x para ainda respeitar parcialmente preferências
        // de acessibilidade sem deixar a tela visualmente inconsistente.
        final clampedScaler = MediaQuery.textScalerOf(context)
            .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15);

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: clampedScaler),
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: Container(
              decoration: AppDecorations.registerBackground,
              child: Stack(children: [
                _RegisterBackgroundBlobs(r: r, floatAnim: _floatAnim),
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
                              _RegisterLogo(r: r, floatAnim: _floatAnim),
                              SizedBox(height: r.gapL),
                              _buildCard(r),
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
          ),
        );
      },
    );
  }

  // ── Card ──────────────────────────────────────────────────────────────────
  Widget _buildCard(_Responsive r) {
    return Container(
      width: double.infinity,
      decoration: AppDecorations.registerCard,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(height: 8, decoration: AppDecorations.cardRainbowBar),
          Padding(
            padding: EdgeInsets.fromLTRB(r.cardPadH, r.gapXL, r.cardPadH, r.gapXL),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const _RegisterTitle(),
              SizedBox(height: r.gapL),
              _RegisterProgressRow(r: r, progress: _progress),
              SizedBox(height: r.gapL),
              _RegisterField(
                r: r,
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
                onChanged: _onEmailChanged,
              ),
              SizedBox(height: r.gapM),
              _RegisterField(
                r: r,
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
                suffix: _EyeToggle(
                  r: r,
                  visible: _showPass,
                  decoration: AppDecorations.passwordTogglePurple,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showPass = !_showPass);
                  },
                ),
              ),
              SizedBox(height: r.gapM),
              _RegisterField(
                r: r,
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
                suffix: _EyeToggle(
                  r: r,
                  visible: _showConfirm,
                  decoration: AppDecorations.passwordTogglePink,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showConfirm = !_showConfirm);
                  },
                ),
              ),
              SizedBox(height: r.gapL),
              _TermsCheckbox(
                r: r,
                accepted: _acceptTerms,
                termsRecognizer: _termsRecognizer,
                privacyRecognizer: _privacyRecognizer,
                onToggle: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _acceptTerms = !_acceptTerms;
                    if (_acceptTerms) _termsErr = null;
                  });
                },
              ),
              if (_termsErr != null) ...[
                SizedBox(height: r.gapS + 4),
                _ErrorBanner(message: _termsErr!, r: r),
              ],
              if (_globalErr != null) ...[
                SizedBox(height: r.gapS + 4),
                _ErrorBanner(message: _globalErr!, r: r),
              ],
              SizedBox(height: r.gapL),
              _RegisterSubmitButton(
                r: r,
                pressed: _btnPressed,
                loading: _isSubmitting,
                onTapDown: () {
                  setState(() => _btnPressed = true);
                  HapticFeedback.lightImpact();
                },
                onTapUp: () => setState(() => _btnPressed = false),
                onTapCancel: () => setState(() => _btnPressed = false),
                onTap: _submit,
              ),
              SizedBox(height: r.gapL),
              _LoginLink(r: r, onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              }),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Blobs decorativos de fundo — isolados para não rebuildar com cada setState
// de validação de campo (só dependem de floatAnim).
// ─────────────────────────────────────────────────────────────────────────────
class _RegisterBackgroundBlobs extends StatelessWidget {
  final _Responsive r;
  final Animation<double> floatAnim;

  const _RegisterBackgroundBlobs({required this.r, required this.floatAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatAnim,
      builder: (_, __) {
        final h = MediaQuery.of(context).size.height;
        return Stack(children: [
          Positioned(
            top: h * 0.03 + floatAnim.value,
            left: -r.blob1 * 0.38,
            child: _blob(r.blob1, 0.12),
          ),
          Positioned(
            top: h * 0.30 - floatAnim.value,
            right: -r.blob2 * 0.42,
            child: _blob(r.blob2, 0.09),
          ),
          Positioned(
            bottom: h * 0.08 + floatAnim.value * 0.6,
            left: -r.blob3 * 0.28,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo com anel giratório — AGORA com AnimationController PRÓPRIO e contínuo
// (corrige o bug do giro "ida e volta" causado por reaproveitar o ambientCtrl
// que tinha repeat(reverse: true)).
// ─────────────────────────────────────────────────────────────────────────────
class _RegisterLogo extends StatefulWidget {
  final _Responsive r;
  final Animation<double> floatAnim;

  const _RegisterLogo({required this.r, required this.floatAnim});

  @override
  State<_RegisterLogo> createState() => _RegisterLogoState();
}

class _RegisterLogoState extends State<_RegisterLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(); // loop contínuo, sutil — nunca reverte
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    return AnimatedBuilder(
      animation: widget.floatAnim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, widget.floatAnim.value * 0.35),
        child: SizedBox(
          width: r.logoSize,
          height: r.logoSize,
          child: Stack(alignment: Alignment.center, children: [
            AnimatedBuilder(
              animation: _spinCtrl,
              builder: (_, __) => Transform.rotate(
                angle: _spinCtrl.value * 2 * math.pi,
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
                  size: r.logoIconSize, color: AppTheme.backgroundColor),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _RegisterTitle extends StatelessWidget {
  const _RegisterTitle();

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final r = _Responsive(
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height,
      );
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            horizontal: r.cardPadH * 0.6, vertical: r.gapL * 0.7),
        decoration: AppDecorations.registerTitleBox,
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
          ]),
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
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _RegisterProgressRow extends StatelessWidget {
  final _Responsive r;
  final int progress;

  const _RegisterProgressRow({required this.r, required this.progress});

  static const _labels = ['E-mail', 'Senha', 'Confirmação'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final done = (i ~/ 2) < progress;
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
        final done = step < progress;
        return Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: done ? r.dotSize * 1.35 : r.dotSize,
            height: done ? r.dotSize * 1.35 : r.dotSize,
            decoration: AppDecorations.progressDot(done: done),
          ),
          SizedBox(height: r.gapS),
          Text(
            _labels[step],
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
}

// ─────────────────────────────────────────────────────────────────────────────
class _RegisterField extends StatelessWidget {
  final _Responsive r;
  final TextEditingController tc;
  final FocusNode fn;
  final String label;
  final String hint;
  final String icon;
  final List<Color> colors;
  final bool focused;
  final bool valid;
  final String? error;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final void Function(String) onChanged;

  const _RegisterField({
    required this.r,
    required this.tc,
    required this.fn,
    required this.label,
    required this.hint,
    required this.icon,
    required this.colors,
    required this.focused,
    required this.valid,
    required this.onChanged,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  child: Text(icon, style: TextStyle(fontSize: r.fieldIconEmoji)),
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
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: r.fontHint,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (suffix != null) ...[suffix!, const SizedBox(width: 10)],
          ]),
        ),
      ),
      if (error != null) ...[
        SizedBox(height: r.gapS + 2),
        _ErrorBanner(message: error!, r: r),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botão olho — agora com área de toque mínima de 44x44 (regra de acessibilidade)
// ─────────────────────────────────────────────────────────────────────────────
class _EyeToggle extends StatelessWidget {
  final _Responsive r;
  final bool visible;
  final BoxDecoration decoration;
  final VoidCallback onTap;

  const _EyeToggle({
    required this.r,
    required this.visible,
    required this.decoration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Área de toque ampliada para 44x44 (regra de acessibilidade) mantendo
    // o "selo" visual menor centralizado dentro dela, sem alterar
    // AppDecorations.
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: r.tapMin,
        height: r.tapMin,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: decoration,
            child: Text(visible ? '🙈' : '👁️', style: const TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _TermsCheckbox extends StatelessWidget {
  final _Responsive r;
  final bool accepted;
  final TapGestureRecognizer termsRecognizer;
  final TapGestureRecognizer privacyRecognizer;
  final VoidCallback onToggle;

  const _TermsCheckbox({
    required this.r,
    required this.accepted,
    required this.termsRecognizer,
    required this.privacyRecognizer,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(r.gapM),
        decoration: AppDecorations.termsCheckbox(accepted: accepted),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 28,
            height: 28,
            decoration: AppDecorations.termsCheckboxTick(accepted: accepted),
            child: accepted
                ? const Icon(Icons.check_rounded,
                    size: 17, color: AppTheme.backgroundColor)
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
                children: [
                  const TextSpan(text: 'Li e aceito os '),
                  TextSpan(
                    text: 'Termos de Uso',
                    recognizer: termsRecognizer,
                    style: const TextStyle(
                      color: AppTheme.kidsPurple,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' e a '),
                  TextSpan(
                    text: 'Política de Privacidade',
                    recognizer: privacyRecognizer,
                    style: const TextStyle(
                      color: AppTheme.kidsPink,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' 🤝'),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botão "CRIAR CONTA" — agora com estado de loading visível (spinner substitui
// o conteúdo do botão enquanto _isSubmitting é true, e o tap fica desabilitado).
// ─────────────────────────────────────────────────────────────────────────────
class _RegisterSubmitButton extends StatelessWidget {
  final _Responsive r;
  final bool pressed;
  final bool loading;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;
  final VoidCallback onTap;

  const _RegisterSubmitButton({
    required this.r,
    required this.pressed,
    required this.loading,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: loading ? null : (_) => onTapDown(),
      onTapUp: loading ? null : (_) => onTapUp(),
      onTapCancel: loading ? null : onTapCancel,
      onTap: loading ? null : onTap,
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          height: r.buttonHeight,
          decoration: AppDecorations.registerButton,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: loading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: r.btnEmoji,
                    height: r.btnEmoji,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor:
                          AlwaysStoppedAnimation(AppTheme.backgroundColor),
                    ),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🎊', style: TextStyle(fontSize: r.btnEmoji)),
                      const SizedBox(width: 10),
                      Text(
                        'CRIAR CONTA',
                        style: TextStyle(
                          fontSize: r.fontButton,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.backgroundColor,
                          letterSpacing: 1.4,
                          shadows: const [
                            Shadow(
                                color: AppTheme.shadowDark,
                                blurRadius: 6,
                                offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('✨', style: TextStyle(fontSize: r.btnEmoji)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _LoginLink extends StatelessWidget {
  final _Responsive r;
  final VoidCallback onTap;

  const _LoginLink({required this.r, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: r.tapMin),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: AppDecorations.loginLinkButton,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('🎮', style: TextStyle(fontSize: r.fontCaption + 4)),
            const SizedBox(width: 5),
            Text(
              'ENTRAR',
              style: TextStyle(
                fontSize: r.fontCaption + 1,
                fontWeight: FontWeight.w900,
                color: AppTheme.backgroundColor,
                letterSpacing: 0.8,
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final _Responsive r;

  const _ErrorBanner({required this.message, required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            message,
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
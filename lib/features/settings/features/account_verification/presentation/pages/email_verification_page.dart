import 'dart:async';
import 'dart:math' as math;

import 'package:empatia/features/settings/features/account_verification/controller/email_controller.dart';
import 'package:flutter/material.dart';

/// Página de verificação de e-mail exclusiva do fluxo de configurações.
/// Usa [EmailVerificationController] — completamente independente do AuthController.
class SettingsEmailVerificationPage extends StatefulWidget {
  const SettingsEmailVerificationPage({Key? key}) : super(key: key);

  @override
  State<SettingsEmailVerificationPage> createState() =>
      _SettingsEmailVerificationPageState();
}

class _SettingsEmailVerificationPageState
    extends State<SettingsEmailVerificationPage> with TickerProviderStateMixin {
  // ─── CONTROLLER ──────────────────────────────────────────────────────────────

  final _controller = EmailVerificationController();

  // ─── ANIMAÇÕES ───────────────────────────────────────────────────────────────

  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _successScaleController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successScaleAnimation;

  // ─── ESTADO ──────────────────────────────────────────────────────────────────

  bool _isChecking = false;
  bool _isResending = false;
  bool _resentOk = false;
  bool _alreadyVerified = false; // e-mail já estava verificado ao abrir
  String? _errorMessage;

  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  Timer? _autoPopTimer;

  // ─── LIFECYCLE ───────────────────────────────────────────────────────────────

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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _successScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnimation = CurvedAnimation(
      parent: _successScaleController,
      curve: Curves.elasticOut,
    );

    _sendOnOpen();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _successScaleController.dispose();
    _cooldownTimer?.cancel();
    _autoPopTimer?.cancel();
    super.dispose();
  }

  // ─── ACTIONS ─────────────────────────────────────────────────────────────────

  /// Ao abrir: verifica se já está verificado. Se sim, mostra tela de sucesso
  /// e volta automaticamente. Se não, envia o e-mail normalmente.
  Future<void> _sendOnOpen() async {
    final verified = await _controller.checkEmailVerified();

    if (!mounted) return;

    if (verified) {
      _showSuccessAndPop();
    } else {
      await _controller.sendVerificationEmail();
      if (mounted) _startCooldown();
    }
  }

  /// Exibe o estado de sucesso e agenda o pop automático após 2,5s.
  void _showSuccessAndPop() {
    setState(() => _alreadyVerified = true);
    _successScaleController.forward();

    _autoPopTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  /// Verifica se o usuário já clicou no link de confirmação.
  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final verified = await _controller.checkEmailVerified();

      if (!mounted) return;

      if (verified) {
        _showSuccessAndPop();
      } else {
        setState(() {
          _errorMessage =
              'E-mail ainda não verificado. Confira sua caixa de entrada! 📬';
        });
      }
    } on EmailVerificationException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  /// Reenvia o e-mail de verificação (com cooldown de 60s).
  Future<void> _resendEmail() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _resentOk = false;
      _errorMessage = null;
    });

    final error = await _controller.sendVerificationEmail();

    if (!mounted) return;

    setState(() {
      _isResending = false;
      if (error == null) {
        _resentOk = true;
        _startCooldown();
      } else {
        _errorMessage = error;
      }
    });
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) {
          t.cancel();
          _resentOk = false;
        }
      });
    });
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Se já verificado, mostra tela de sucesso em cima do fundo normal
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDF2FF), Color(0xFFFFF0F7), Color(0xFFF0F4FF)],
          ),
        ),
        child: _alreadyVerified ? _buildSuccessOverlay() : _buildNormalContent(),
      ),
    );
  }

  // ─── TELA DE SUCESSO ─────────────────────────────────────────────────────────

  Widget _buildSuccessOverlay() {
    return Stack(
      children: [
        ..._buildBubbles(),
        SafeArea(
          child: Center(
            child: ScaleTransition(
              scale: _successScaleAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 48),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 4,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ícone animado
                      AnimatedBuilder(
                        animation: _floatAnimation,
                        builder: (_, __) => Transform.translate(
                          offset: Offset(0, _floatAnimation.value * 0.5),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF4ADE80),
                                  Color(0xFF22C55E),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E)
                                      .withOpacity(0.45),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mark_email_read_rounded,
                              color: Colors.white,
                              size: 56,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Título
                      const Text(
                        '✅ E-mail verificado!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtítulo
                      Text(
                        'Seu e-mail já foi confirmado.\nVoltando às configurações...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Barra de progresso do auto-pop
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 0.0),
                        duration: const Duration(milliseconds: 2500),
                        builder: (_, value, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor:
                                const Color(0xFF4ADE80).withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF22C55E),
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
    );
  }

  // ─── CONTEÚDO NORMAL ─────────────────────────────────────────────────────────

  Widget _buildNormalContent() {
    final email = _controller.currentEmail ?? '';

    return Stack(
      children: [
        ..._buildBubbles(),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                _buildAnimatedEnvelope(),
                const SizedBox(height: 36),
                _buildCard(email),
                const SizedBox(height: 24),
                _buildBackButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── ENVELOPE ANIMADO ────────────────────────────────────────────────────────

  Widget _buildAnimatedEnvelope() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _floatAnimation.value),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (_, __) => Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF6B9D), Color(0xFFA855F7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withOpacity(0.45),
                    blurRadius: 40,
                    spreadRadius: 4,
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                  ),
                  const Text('✉️', style: TextStyle(fontSize: 60)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── CARD PRINCIPAL ──────────────────────────────────────────────────────────

  Widget _buildCard(String email) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B9D).withOpacity(0.12),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 8,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF6B9D),
                  Color(0xFFA855F7),
                  Color(0xFF6366F1),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
            child: Column(
              children: [
                const Text(
                  '📬 Verifique seu e-mail!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enviamos um link de confirmação para:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      const Color(0xFFFF6B9D).withOpacity(0.08),
                      const Color(0xFFA855F7).withOpacity(0.08),
                    ]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFF6B9D).withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📧', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          email,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFA855F7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _buildStep('1', '📬', 'Abra seu e-mail'),
                const SizedBox(height: 10),
                _buildStep('2', '🔗', 'Clique em "Confirmar meu e-mail"'),
                const SizedBox(height: 10),
                _buildStep('3', '✅', 'Volte aqui e toque no botão abaixo'),
                const SizedBox(height: 28),
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Text('😅', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildCheckButton(),
                const SizedBox(height: 16),
                _buildResendButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP ITEM ───────────────────────────────────────────────────────────────

  Widget _buildStep(String number, String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFA855F7)],
              ),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTÃO CHECAR ─────────────────────────────────────────────────────────────

  Widget _buildCheckButton() {
    return GestureDetector(
      onTap: _isChecking ? null : _checkVerification,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, __) => Transform.scale(
          scale: _isChecking ? 1.0 : _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFA855F7)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B9D).withOpacity(0.45),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: _isChecking
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('✅', style: TextStyle(fontSize: 22)),
                        SizedBox(width: 10),
                        Text(
                          'Já verifiquei meu e-mail',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
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

  // ─── BOTÃO REENVIAR ───────────────────────────────────────────────────────────

  Widget _buildResendButton() {
    final onCooldown = _resendCooldown > 0;

    if (_resentOk) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF4ADE80).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4ADE80).withOpacity(0.4),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                color: Color(0xFF22C55E), size: 20),
            SizedBox(width: 8),
            Text(
              'E-mail reenviado com sucesso! ✅',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF166534),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: (onCooldown || _isResending) ? null : _resendEmail,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: onCooldown
                ? Colors.grey.shade300
                : const Color(0xFFA855F7).withOpacity(0.5),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
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
                  color: Color(0xFFA855F7),
                ),
              )
            else
              Text(
                '📤',
                style: TextStyle(
                  fontSize: 18,
                  color: onCooldown ? Colors.grey : null,
                ),
              ),
            const SizedBox(width: 10),
            Text(
              _isResending
                  ? 'Reenviando...'
                  : onCooldown
                      ? 'Reenviar em ${_resendCooldown}s'
                      : 'Não recebeu? Reenviar e-mail',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: onCooldown
                    ? Colors.grey.shade400
                    : const Color(0xFFA855F7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOTÃO VOLTAR ────────────────────────────────────────────────────────────

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context, false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF6B7280), size: 16),
            SizedBox(width: 8),
            Text(
              'Voltar para configurações',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOLHAS DE FUNDO ──────────────────────────────────────────────────────────

  List<Widget> _buildBubbles() {
    return [
      _bubble(top: 60, left: 20, size: 80, opacity: 0.08),
      _bubble(top: 180, right: 30, size: 100, opacity: 0.06),
      _bubble(bottom: 150, left: 30, size: 120, opacity: 0.07),
      _bubble(bottom: 280, right: 20, size: 90, opacity: 0.06),
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
          offset: Offset(0, _floatAnimation.value * 0.6),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFFF6B9D).withOpacity(opacity),
                const Color(0xFFA855F7).withOpacity(opacity * 0.3),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
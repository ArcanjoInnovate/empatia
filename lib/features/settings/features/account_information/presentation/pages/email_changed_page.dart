import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Tela exibida após o envio do link de troca de e-mail.
/// Redireciona para Login e permite reenviar o link.
class EmailChangedPage extends StatefulWidget {
  final String pendingEmail;

  const EmailChangedPage({Key? key, required this.pendingEmail})
      : super(key: key);

  @override
  State<EmailChangedPage> createState() => _EmailChangedPageState();
}

class _EmailChangedPageState extends State<EmailChangedPage>
    with TickerProviderStateMixin {
  // ─── Animações ────────────────────────────────────────────────────────────
  late final AnimationController _bounceCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _spinCtrl;

  late final Animation<double> _bounce;
  late final Animation<double> _float;
  late final Animation<double> _pulse;
  late final Animation<double> _spin;

  bool _resending = false;
  bool _resentOk  = false;

  @override
  void initState() {
    super.initState();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -14)
        .animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _spin = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  // ─── REENVIAR ─────────────────────────────────────────────────────────────

  Future<void> _resendEmail() async {
    setState(() { _resending = true; _resentOk = false; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.verifyBeforeUpdateEmail(widget.pendingEmail);
        if (mounted) setState(() => _resentOk = true);
      }
    } catch (_) {
      // Silencia — aviso genérico abaixo
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  // ─── IR PARA LOGIN ────────────────────────────────────────────────────────

  Future<void> _goToLogin() async {
    await FirebaseAuth.instance.signOut();
    // O StreamBuilder no MyApp.home já redireciona para LoginPage
    // após o signOut, então basta voltar até a raiz.
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6B9D),
              Color(0xFFFFC837),
              Color(0xFF8B5CF6),
              Color(0xFF06B6D4),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            ..._bubbles(),
            ..._sparkles(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildIcon(),
                    const SizedBox(height: 28),
                    _buildTitle(),
                    const SizedBox(height: 20),
                    _buildEmailBadge(),
                    const SizedBox(height: 20),
                    _buildStepsCard(),
                    const SizedBox(height: 16),
                    _buildWarningCard(),
                    const SizedBox(height: 28),
                    _buildLoginButton(),
                    const SizedBox(height: 14),
                    _buildResendButton(),
                    const SizedBox(height: 24),
                    if (_resentOk) _buildResentBanner(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ÍCONE ANIMADO ────────────────────────────────────────────────────────

  Widget _buildIcon() {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Transform.scale(
            scale: _pulse.value,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withOpacity(0.5),
                    blurRadius: 35,
                    spreadRadius: 6,
                  ),
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.4),
                    blurRadius: 45,
                    spreadRadius: 12,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Anel giratório
                  AnimatedBuilder(
                    animation: _spin,
                    builder: (_, __) => Transform.rotate(
                      angle: _spin.value,
                      child: Container(
                        width: 122,
                        height: 122,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Color(0xFFFF6B9D),
                              Color(0xFFFFC837),
                              Color(0xFF06B6D4),
                              Color(0xFF8B5CF6),
                              Color(0xFFFF6B9D),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Centro
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      color: Colors.white,
                      size: 46,
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

  // ─── TÍTULO ───────────────────────────────────────────────────────────────

  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF9E6)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC837).withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFF8B5CF6)],
            ).createShader(bounds),
            child: const Text(
              'Email de Troca Enviado! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enviamos um link de verificação para:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMAIL BADGE ──────────────────────────────────────────────────────────

  Widget _buildEmailBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alternate_email_rounded,
              color: Color(0xFF2563EB), size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              widget.pendingEmail,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── CARD DE PASSOS ───────────────────────────────────────────────────────

  Widget _buildStepsCard() {
    final steps = [
      _Step('1️⃣', 'Verifique sua caixa de entrada', const Color(0xFF2563EB), false),
      _Step('2️⃣', 'Confira também a caixa de SPAM', const Color(0xFFFF6B9D), true),
      _Step('3️⃣', 'Clique no link de verificação no email', const Color(0xFF8B5CF6), false),
      _Step('4️⃣', 'Faça login com o novo email', const Color(0xFF06B6D4), false),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Próximos Passos:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map((s) => _buildStep(s)).toList(),
        ],
      ),
    );
  }

  Widget _buildStep(_Step s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: s.bold ? FontWeight.w800 : FontWeight.w600,
                color: s.bold ? s.color : const Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CARD AVISO ───────────────────────────────────────────────────────────

  Widget _buildWarningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD34D), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC837).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          const Text(
            'Importante',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Caso não consiga fazer login com o novo email,\ntente usar o email antigo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Se os problemas persistirem, entre em contato\ncom o suporte.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.orange.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTÃO LOGIN ─────────────────────────────────────────────────────────

  Widget _buildLoginButton() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.scale(
        scale: _pulse.value * 0.97,
        child: GestureDetector(
          onTap: _goToLogin,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Ir para Login',
                  style: TextStyle(
                    fontSize: 17,
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
    );
  }

  // ─── BOTÃO REENVIAR ───────────────────────────────────────────────────────

  Widget _buildResendButton() {
    return GestureDetector(
      onTap: _resending ? null : _resendEmail,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _resending
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded,
                        color: Color(0xFF8B5CF6), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Reenviar Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── BANNER REENVIADO ─────────────────────────────────────────────────────

  Widget _buildResentBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6EE7B7), width: 1.5),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: Color(0xFF059669), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Email reenviado! Verifique sua caixa de entrada 📬',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF065F46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOLHAS DE FUNDO ─────────────────────────────────────────────────────

  List<Widget> _bubbles() {
    final positions = [
      [80.0,  null,  30.0, null,  80.0],
      [180.0, null,  null, 40.0,  100.0],
      [null,  200.0, 20.0, null,  120.0],
      [null,  300.0, null, 35.0,  90.0],
      [320.0, null,  50.0, null,  70.0],
    ];
    return positions.map((p) {
      return Positioned(
        top:    p[0],
        bottom: p[1],
        left:   p[2],
        right:  p[3],
        child: AnimatedBuilder(
          animation: _float,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _float.value),
            child: Container(
              width:  p[4],
              height: p[4],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ─── SPARKLES ─────────────────────────────────────────────────────────────

  List<Widget> _sparkles() {
    final items = [
      ['✨', 110.0, null,  15.0, null,  22.0],
      ['⭐', 220.0, null,  null, 25.0,  26.0],
      ['💫', null,  260.0, 30.0, null,  20.0],
      ['🌟', null,  160.0, null, 20.0,  24.0],
      ['🎈', 370.0, null,  null, 55.0,  28.0],
      ['🦄', null,  380.0, null, 50.0,  26.0],
    ];
    return items.map((s) {
      return Positioned(
        top:    s[1] as double?,
        bottom: s[2] as double?,
        left:   s[3] as double?,
        right:  s[4] as double?,
        child: AnimatedBuilder(
          animation: _bounce,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _bounce.value * 0.6),
            child: Text(s[0] as String,
                style: TextStyle(fontSize: s[5] as double)),
          ),
        ),
      );
    }).toList();
  }
}

// ─── HELPER ───────────────────────────────────────────────────────────────────

class _Step {
  final String emoji;
  final String label;
  final Color  color;
  final bool   bold;
  const _Step(this.emoji, this.label, this.color, this.bold);
}
import 'dart:math' as math;

import 'package:empatia/features/settings/features/change_password/controller/change_password_controller.dart';
import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with TickerProviderStateMixin {
  // ─── Controllers de texto ────────────────────────────────────────────────
  final _currentCtrl  = TextEditingController();
  final _newCtrl      = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;

  late final ChangePasswordController _controller;

  // ─── Animações ────────────────────────────────────────────────────────────
  late final AnimationController _bounceCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _spinCtrl;
  late final AnimationController _shakeCtrl;

  late final Animation<double> _bounce;
  late final Animation<double> _float;
  late final Animation<double> _pulse;
  late final Animation<double> _shake;

  // Força da senha
  int get _strength {
    final p = _newCtrl.text;
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[!@#\$&*~%^]').hasMatch(p)) s++;
    return s;
  }

  @override
  void initState() {
    super.initState();

    _controller = ChangePasswordController();
    _controller.addListener(() => setState(() {}));

    _currentCtrl.addListener(_clearErrors);
    _newCtrl.addListener(() { _clearErrors(); setState(() {}); });
    _confirmCtrl.addListener(_clearErrors);

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -12)
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
    _pulse = Tween<double>(begin: 1.0, end: 1.1)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end:  8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin:-8, end:  8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end:  0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

  }

  void _clearErrors() {
    if (_localError != null) setState(() => _localError = null);
    if (_controller.error != null) _controller.clearError();
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _bounceCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _spinCtrl.dispose();
    _shakeCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ─── SUBMIT ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final novo    = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || novo.isEmpty || confirm.isEmpty) {
      _triggerError('Preencha todos os campos! 📝');
      return;
    }
    if (novo != confirm) {
      _triggerError('As senhas não coincidem! 🙈');
      return;
    }
    if (novo.length < 6) {
      _triggerError('Senha muito curta! Mínimo 6 caracteres 🔐');
      return;
    }
    if (novo == current) {
      _triggerError('A nova senha deve ser diferente da atual! 💡');
      return;
    }

    final success = await _controller.updatePassword(
      currentPassword: current,
      newPassword:     novo,
    );

    if (!mounted) return;

    if (success) {
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Text(
                'Senha atualizada com sucesso!',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } else if (_controller.error != null) {
      _triggerError(_controller.error!);
    }
  }

  void _triggerError(String msg) {
    _controller.clearError();
    setState(() {});
    // show error via the existing banner using a local approach
    _showLocalError(msg);
  }

  String? _localError;

  void _showLocalError(String msg) {
    setState(() => _localError = msg);
    _shakeCtrl.forward(from: 0);
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
              Color(0xFF8B5CF6),
              Color(0xFFFF6B9D),
              Color(0xFFFFC837),
              Color(0xFF06B6D4),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            ..._bubbles(),
            ..._sparkles(),
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    child: Column(
                      children: [
                        _buildIcon(),
                        const SizedBox(height: 20),
                        _buildTitleBadge(),
                        const SizedBox(height: 20),
                        _buildFormCard(),
                        const SizedBox(height: 16),
                        if (_newCtrl.text.isNotEmpty) _buildStrengthCard(),
                        const SizedBox(height: 16),
                        _buildTipsCard(),
                        const SizedBox(height: 24),
                        _buildButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.25),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'TROCAR SENHA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
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
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withOpacity(0.35),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _spinCtrl,
                    builder: (_, __) => Transform.rotate(
                      angle: _spinCtrl.value * 2 * math.pi,
                      child: Container(
                        width: 102,
                        height: 102,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Color(0xFF8B5CF6),
                              Color(0xFFFF6B9D),
                              Color(0xFFFFC837),
                              Color(0xFF06B6D4),
                              Color(0xFF8B5CF6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFFF6B9D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 38),
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
  Widget _buildTitleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF9E6)]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC837).withOpacity(0.4),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFFF6B9D)],
            ).createShader(b),
            child: const Text(
              'Nova Senha 🔐✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Crie uma senha forte e segura!',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── CARD DO FORMULÁRIO ───────────────────────────────────────────────────
  Widget _buildFormCard() {
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) => Transform.translate(
        offset: Offset((_localError != null || _controller.error != null) ? _shake.value : 0, 0),
        child: child,
      ),
      child: Container(
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
            _fieldLabel('🔑', 'Senha atual'),
            const SizedBox(height: 8),
            _passwordField(
              controller:  _currentCtrl,
              hint:        '••••••••',
              obscure:     _obscureCurrent,
              accentColor: const Color(0xFF8B5CF6),
              onToggle: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
            ),

            const SizedBox(height: 18),
            _fieldLabel('🆕', 'Nova senha'),
            const SizedBox(height: 8),
            _passwordField(
              controller:  _newCtrl,
              hint:        '••••••••',
              obscure:     _obscureNew,
              accentColor: const Color(0xFFFF6B9D),
              onToggle: () =>
                  setState(() => _obscureNew = !_obscureNew),
            ),

            const SizedBox(height: 18),
            _fieldLabel('✅', 'Confirmar nova senha'),
            const SizedBox(height: 8),
            _passwordField(
              controller:  _confirmCtrl,
              hint:        '••••••••',
              obscure:     _obscureConfirm,
              accentColor: const Color(0xFF06B6D4),
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),

            if (_localError != null || _controller.error != null) ...[
              const SizedBox(height: 14),
              _buildErrorBanner(_localError ?? _controller.error!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String emoji, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required Color accentColor,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.grey.shade400, fontWeight: FontWeight.w500),
          prefixIcon: Icon(Icons.lock_outline_rounded,
              color: accentColor, size: 20),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Text('😬', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CARD FORÇA DA SENHA ──────────────────────────────────────────────────
  Widget _buildStrengthCard() {
    final labels  = ['Fraquinha 😬', 'Tá indo! 😅', 'Boa! 😄', 'Forte! 💪', 'Incrível! 🚀'];
    final colors  = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.yellow.shade700,
      const Color(0xFF4ADE80),
      const Color(0xFF06B6D4),
    ];
    final s = _strength.clamp(0, 4);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💪', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Força da senha: ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                labels[s],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors[s],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                  height: 8,
                  decoration: BoxDecoration(
                    color: i < _strength ? colors[s] : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── CARD DE DICAS ────────────────────────────────────────────────────────
  Widget _buildTipsCard() {
    final tips = [
      ('8️⃣', 'Mínimo 8 caracteres',           _newCtrl.text.length >= 8),
      ('🔡', 'Uma letra maiúscula (A-Z)',       RegExp(r'[A-Z]').hasMatch(_newCtrl.text)),
      ('🔢', 'Um número (0-9)',                 RegExp(r'[0-9]').hasMatch(_newCtrl.text)),
      ('⚡', 'Um símbolo (!@#\$&*)',            RegExp(r'[!@#\$&*~%^]').hasMatch(_newCtrl.text)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFFF6B9D)],
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.tips_and_updates_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Dicas para uma senha forte',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: t.$3
                        ? const Color(0xFF4ADE80).withOpacity(0.15)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: t.$3
                        ? const Icon(Icons.check_rounded,
                            color: Color(0xFF16A34A), size: 15)
                        : Text(t.$1,
                            style: const TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  t.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.$3
                        ? const Color(0xFF16A34A)
                        : Colors.grey.shade600,
                    decoration:
                        t.$3 ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ─── BOTÃO ────────────────────────────────────────────────────────────────
  Widget _buildButton() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.scale(
        scale: _pulse.value * 0.97,
        child: GestureDetector(
          onTap: _controller.loading ? null : _submit,
          child: Container(
            width: double.infinity,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFFF6B9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.5),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: _controller.loading
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_reset_rounded,
                            color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Salvar nova senha 🚀',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.4,
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

  // ─── BOLHAS DE FUNDO ─────────────────────────────────────────────────────
  List<Widget> _bubbles() {
    final items = [
      [90.0,  null,  25.0, null,  85.0],
      [200.0, null,  null, 35.0,  100.0],
      [null,  220.0, 20.0, null,  115.0],
      [null,  310.0, null, 30.0,  75.0],
      [350.0, null,  55.0, null,  65.0],
    ];
    return items.map((p) => Positioned(
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
              color: Colors.white.withOpacity(0.09),
            ),
          ),
        ),
      ),
    )).toList();
  }

  // ─── SPARKLES ─────────────────────────────────────────────────────────────
  List<Widget> _sparkles() {
    final items = [
      ['✨', 115.0, null,  12.0, null,  22.0],
      ['⭐', 230.0, null,  null, 22.0,  24.0],
      ['💫', null,  250.0, 28.0, null,  20.0],
      ['🌟', null,  150.0, null, 18.0,  22.0],
      ['🎈', 380.0, null,  null, 50.0,  26.0],
      ['🔮', null,  370.0, null, 48.0,  24.0],
      ['💎', 160.0, null,  null, 60.0,  20.0],
    ];
    return items.map((s) => Positioned(
      top:    s[1] as double?,
      bottom: s[2] as double?,
      left:   s[3] as double?,
      right:  s[4] as double?,
      child: AnimatedBuilder(
        animation: _bounce,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _bounce.value * 0.55),
          child: Text(s[0] as String,
              style: TextStyle(fontSize: s[5] as double)),
        ),
      ),
    )).toList();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationPage({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 600; // 10 minutos
  Timer? _timer;
  bool _canResend = false;
  bool _isVerifying = false;
  String? _errorMsg;
  late AnimationController _shakeController;
  late AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Auto-focus primeiro campo
    Future.delayed(
      const Duration(milliseconds: 300),
      () => _focusNodes[0].requestFocus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var ctrl in _controllers) {
      ctrl.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _shakeController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 600;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  String get _timerText {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Verifica se todos os campos estão preenchidos
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      _verifyCode(code);
    }
  }

  void _onBackspace(int index) {
    if (index > 0 && _controllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyCode(String code) async {
    setState(() {
      _isVerifying = true;
      _errorMsg = null;
    });

    // Simula verificação
    await Future.delayed(const Duration(milliseconds: 1500));

    // Simula sucesso (você pode adicionar lógica de verificação real aqui)
    if (code == '123456') {
      _successController.forward();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        // Aqui você pode navegar para a tela de sucesso ou home
      }
    } else {
      // Código inválido
      _shakeController.forward().then((_) => _shakeController.reset());
      setState(() {
        _errorMsg = 'Código inválido. Tente novamente.';
        _isVerifying = false;
      });
      // Limpa os campos
      for (var ctrl in _controllers) {
        ctrl.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  void _resendCode() {
    if (!_canResend) return;
    
    setState(() {
      _errorMsg = null;
      for (var ctrl in _controllers) {
        ctrl.clear();
      }
    });
    _startTimer();
    _focusNodes[0].requestFocus();

    // Mostra feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Código reenviado com sucesso!',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 32,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Column(
                children: [
                  _buildTopIllustration(),
                  const SizedBox(height: 32),
                  _buildOtpCard(),
                  const SizedBox(height: 20),
                  _buildResendSection(),
                  const SizedBox(height: 24),
                  _buildInfoTip(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        ),
      ),
      child: SafeArea(
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
                'VERIFICAR CÓDIGO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ILUSTRAÇÃO ────────────────────────────────────────────────────────────
  Widget _buildTopIllustration() {
    return AnimatedBuilder(
      animation: _successController,
      builder: (context, child) {
        final isSuccess = _successController.value > 0;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSuccess
                      ? [const Color(0xFF4ADE80), const Color(0xFF22C55E)]
                      : [const Color(0xFF2563EB), const Color(0xFF7C3AED)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isSuccess
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF2563EB))
                        .withOpacity(0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                isSuccess ? Icons.check_rounded : Icons.sms_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSuccess ? 'Verificado!' : 'Digite o código',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSuccess
                  ? 'Seu número foi verificado com sucesso!'
                  : 'Enviamos um SMS com 6 dígitos para',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
            if (!isSuccess) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_rounded,
                        color: Color(0xFF2563EB), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      widget.phoneNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ── CARD OTP ──────────────────────────────────────────────────────────────
  Widget _buildOtpCard() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shake = _shakeController.value;
        final offset = shake < 0.5
            ? shake * 20
            : (1 - shake) * 20;
        
        return Transform.translate(
          offset: Offset(offset * (shake < 0.5 ? 1 : -1), 0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: _errorMsg != null
                  ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: _errorMsg != null
                      ? Colors.red.withOpacity(0.15)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Timer
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _secondsRemaining < 60
                          ? [Colors.red.shade400, Colors.red.shade600]
                          : [
                              const Color(0xFF2563EB).withOpacity(0.1),
                              const Color(0xFF7C3AED).withOpacity(0.1)
                            ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _secondsRemaining < 60
                          ? Colors.red.withOpacity(0.3)
                          : const Color(0xFF2563EB).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: _secondsRemaining < 60
                            ? Colors.white
                            : const Color(0xFF2563EB),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timerText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _secondsRemaining < 60
                              ? Colors.white
                              : const Color(0xFF1E3A8A),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Campos OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) => _buildOtpField(index)),
                ),

                // Erro
                if (_errorMsg != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Loading
                if (_isVerifying) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF2563EB)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Verificando código...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 48,
      height: 58,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        enabled: !_isVerifying,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => _onDigitChanged(index, value),
        onTap: () {
          _controllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[index].text.length,
          );
        },
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1E3A8A),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF8F8FF),
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _controllers[index].text.isNotEmpty
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFF2563EB).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF2563EB),
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ── REENVIAR ──────────────────────────────────────────────────────────────
  Widget _buildResendSection() {
    return GestureDetector(
      onTap: _canResend ? _resendCode : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _canResend
              ? const Color(0xFF2563EB).withOpacity(0.06)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _canResend
                ? const Color(0xFF2563EB).withOpacity(0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh_rounded,
              color: _canResend ? const Color(0xFF2563EB) : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              _canResend ? 'Reenviar código SMS' : 'Aguarde para reenviar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color:
                    _canResend ? const Color(0xFF2563EB) : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DICA ──────────────────────────────────────────────────────────────────
  Widget _buildInfoTip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Não recebeu o código? Verifique se o número está correto e se há sinal de celular.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
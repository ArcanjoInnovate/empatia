import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/auth/controller/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:empatia/features/auth/presentation/pages/sucess_auth_page.dart';
import 'package:empatia/features/auth/controller/birth_controller.dart';
import 'package:empatia/features/auth/data/repositories/birth_repository.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class AgeVerificationPage extends StatefulWidget {
  /// Quando vindo do cadastro, recebe as credenciais para fazer o registro
  /// completo só após a idade ser validada.
  /// Quando acessada de outras telas (ex: configurações), esses campos são
  /// nulos e o comportamento é apenas salvar a data para o usuário logado.
  final String? email;
  final String? password;
  final AuthController? authController;

  const AgeVerificationPage({
    Key? key,
    this.email,
    this.password,
    this.authController,
  }) : super(key: key);

  bool get isRegistrationFlow => email != null && password != null;

  @override
  State<AgeVerificationPage> createState() => _AgeVerificationPageState();
}

class _AgeVerificationPageState extends State<AgeVerificationPage>
    with SingleTickerProviderStateMixin {
  late final BirthController _controller;
  late final AnimationController _successAnim;

  final _dayCtrl   = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _yearCtrl  = TextEditingController();

  final _dayFocus   = FocusNode();
  final _monthFocus = FocusNode();
  final _yearFocus  = FocusNode();

  String? _submitError;
  bool _isSubmitting = false;

  // ─── LIFECYCLE ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _controller = BirthController(repository: BirthDateRepository());
    _successAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _successAnim.dispose();
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    _dayFocus.dispose();
    _monthFocus.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  void _onFieldChanged() {
    final day   = int.tryParse(_dayCtrl.text.trim());
    final month = int.tryParse(_monthCtrl.text.trim());
    final year  = int.tryParse(_yearCtrl.text.trim());

    if (day == null || month == null || year == null ||
        _yearCtrl.text.trim().length < 4) {
      _controller.clearSelectedDate();
      return;
    }

    try {
      final date = DateTime(year, month, day);
      _controller.onDateSelected(date);
    } catch (_) {
      _controller.clearSelectedDate();
    }
  }

  Future<void> _pickFromCalendar() async {
    final now     = DateTime.now();
    final initial = _controller.selectedDate ??
        DateTime(now.year - 25, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate:   DateTime(now.year - 120),
      lastDate:    now,
      locale: const Locale('pt', 'BR'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   AppTheme.kidsPink,
            onPrimary: Colors.white,
            surface:   Colors.white,
            onSurface: AppTheme.textDark,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      _controller.onDateSelected(picked);
      _dayCtrl.text   = picked.day.toString().padLeft(2, '0');
      _monthCtrl.text = picked.month.toString().padLeft(2, '0');
      _yearCtrl.text  = picked.year.toString();
    }
  }

  Future<void> _submit() async {
    final date = _controller.selectedDate;
    if (date == null || _isSubmitting) return;

    setState(() {
      _submitError = null;
      _isSubmitting = true;
    });

    try {
      if (widget.isRegistrationFlow) {
        // ── FLUXO DE CADASTRO ──────────────────────────────────────────────
        // Só agora criamos a conta no Firebase Auth + RTDB, com tudo validado.
        final result = await widget.authController!.registerUserWithBirthDate(
          email:     widget.email!,
          password:  widget.password!,
          birthDate: date,
        );

        if (!mounted) return;

        if (result == 'success') {
          _successAnim.forward();
          await Future.delayed(const Duration(milliseconds: 900));
          if (!mounted) return;

          final userData = await widget.authController!.getUserData();
          if (!mounted) return;

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
          setState(() => _submitError = result ?? 'Algo deu errado! 😅');
        }
      } else {
        // ── FLUXO DE ATUALIZAÇÃO (usuário já logado) ───────────────────────
        // Usa o BirthController para salvar apenas a data de nascimento.
        final uid = _getCurrentUid();
        if (uid == null) {
          setState(() => _submitError = 'Usuário não autenticado. Faça login novamente.');
          return;
        }

        final success = await _controller.saveBirthDate(
          userId: uid, birthDate: date,
        );

        if (!mounted) return;
        if (success) {
          _successAnim.forward();
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted) Navigator.pop(context, true);
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _getCurrentUid() {
    // No fluxo de atualização (usuário já logado), pega o uid do Firebase Auth.
    return widget.authController?.getCurrentUid()
        ?? FirebaseAuth.instance.currentUser?.uid;
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20, right: 20, top: 32,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildIllustration(),
                      const SizedBox(height: 32),
                      _buildInputCard(),
                      const SizedBox(height: 20),
                      _buildPrivacyNote(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: AppDecorations.ageVerificationHeader,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(
                widget.isRegistrationFlow
                    ? 'VERIFICAR IDADE'
                    : 'ATUALIZAR IDADE',
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ILLUSTRATION ────────────────────────────────────────────────────────────

  Widget _buildIllustration() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _controller.isSuccess
          ? _buildSuccessBadge()
          : _buildInfoBadge(),
    );
  }

  Widget _buildInfoBadge() {
    return Container(
      key: const ValueKey('info'),
      padding: const EdgeInsets.all(28),
      decoration: AppDecorations.ageVerificationInfoBadge,
      child: Column(
        children: [
          const Text('🎂', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            'Qual é a sua data\nde nascimento?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900,
              color: Colors.white, height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Precisamos confirmar que você tem\npelo menos 18 anos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBadge() {
    return Container(
      key: const ValueKey('success'),
      padding: const EdgeInsets.all(28),
      decoration: AppDecorations.ageVerificationSuccessBadge,
      child: const Column(
        children: [
          Text('🎉', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text('Tudo certo!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          SizedBox(height: 8),
          Text('Criando sua conta...',
              style: TextStyle(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }

  // ─── INPUT CARD ──────────────────────────────────────────────────────────────

  Widget _buildInputCard() {
    final validation = _controller.liveValidation;
    final hasDate    = _controller.selectedDate != null;
    final canSubmit  = hasDate && (validation?.isValid ?? false);

    return Container(
      decoration: AppDecorations.ageVerificationCard,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: AppDecorations.ageVerificationCalendarIcon,
                  child: const Icon(Icons.calendar_month_rounded,
                      color: AppTheme.kidsPink, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Data de nascimento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                      color: AppTheme.textDark),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                _buildSegmentField(
                  controller: _dayCtrl, focusNode: _dayFocus,
                  nextFocus: _monthFocus, hint: 'DD', maxLength: 2, label: 'Dia',
                ),
                _buildSeparator(),
                _buildSegmentField(
                  controller: _monthCtrl, focusNode: _monthFocus,
                  nextFocus: _yearFocus, hint: 'MM', maxLength: 2, label: 'Mês',
                ),
                _buildSeparator(),
                Expanded(
                  flex: 3,
                  child: _buildSegmentField(
                    controller: _yearCtrl, focusNode: _yearFocus,
                    nextFocus: null, hint: 'AAAA', maxLength: 4,
                    label: 'Ano', expanded: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickFromCalendar,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: AppDecorations.ageVerificationCalendarButton,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.date_range_rounded,
                        color: AppTheme.kidsPink, size: 18),
                    SizedBox(width: 8),
                    Text('Escolher pelo calendário',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppTheme.kidsPink)),
                  ],
                ),
              ),
            ),

            if (hasDate) ...[
              const SizedBox(height: 16),
              _buildValidationFeedback(validation),
            ],

            // Erro de cadastro (email já em uso, etc.)
            if (_submitError != null) ...[
              const SizedBox(height: 16),
              _buildErrorBanner(_submitError!),
            ],

            if (_controller.hasError && _controller.errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorBanner(_controller.errorMessage!),
            ],

            const SizedBox(height: 24),
            _buildSubmitButton(canSubmit),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode? nextFocus,
    required String hint,
    required int maxLength,
    required String label,
    bool expanded = false,
  }) {
    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.grey.shade500, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: maxLength,
          onChanged: (v) {
            if (v.length == maxLength && nextFocus != null) {
              nextFocus.requestFocus();
            }
            _onFieldChanged();
          },
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
              color: AppTheme.textDark),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: TextStyle(fontSize: 16, color: Colors.grey.shade300,
                fontWeight: FontWeight.w700),
            filled: true,
            fillColor: AppTheme.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: controller.text.isNotEmpty
                    ? AppTheme.kidsPink.withOpacity(0.5)
                    : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.kidsPink, width: 2),
            ),
          ),
        ),
      ],
    );

    return expanded ? inner : Expanded(flex: 2, child: inner);
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.only(top: 22, left: 8, right: 8),
      child: Text('/',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
              color: Colors.grey.shade300)),
    );
  }

  Widget _buildValidationFeedback(BirthDateValidation? validation) {
    if (validation == null) return const SizedBox.shrink();

    if (validation.isValid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: AppDecorations.ageVerificationFeedbackValid,
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.kidsGreenDeep, size: 18),
            const SizedBox(width: 10),
            Text(
              'Tudo certo! Você tem ${validation.age} anos.',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppTheme.kidsGreenDeep),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppDecorations.ageVerificationFeedbackError,
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              validation.errorMessage ?? 'Data inválida.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.ageVerificationErrorBanner,
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppTheme.errorRed)),
          ),
          GestureDetector(
            onTap: () => setState(() => _submitError = null),
            child: Icon(Icons.close_rounded, color: AppTheme.errorRed, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool canSubmit) {
    return GestureDetector(
      onTap: (_isSubmitting || _controller.isLoading || !canSubmit) ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: canSubmit
            ? AppDecorations.ageVerificationSubmitActive
            : AppDecorations.ageVerificationSubmitDisabled,
        child: (_isSubmitting || _controller.isLoading)
            ? const Center(
                child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded,
                      color: canSubmit ? Colors.white : AppTheme.textMuted,
                      size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.isRegistrationFlow
                        ? 'Confirmar e criar conta'
                        : 'Confirmar data de nascimento',
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: canSubmit ? Colors.white : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── PRIVACY NOTE ────────────────────────────────────────────────────────────

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecorations.ageVerificationPrivacyNote,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔒', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sua data de nascimento é armazenada com segurança e usada apenas para verificar sua maioridade. Ela não é exibida publicamente.',
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: AppTheme.kidsPinkDeep, height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
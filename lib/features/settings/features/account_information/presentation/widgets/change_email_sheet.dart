import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/settings/features/account_information/presentation/pages/email_changed_page.dart';
import 'package:empatia/features/settings/features/account_information/presentation/widgets/sheet_components.dart';
import 'package:flutter/material.dart';

class ChangeEmailSheet extends StatefulWidget {
  final Future<bool> Function({
    required String newEmail,
    required String password,
  }) onConfirm;

  final String? errorMessage;

  const ChangeEmailSheet({
    Key? key,
    required this.onConfirm,
    this.errorMessage,
  }) : super(key: key);

  @override
  State<ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<ChangeEmailSheet> {
  final _emailCtrl    = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool    _obscurePass = true;
  bool    _loading     = false;
  String? _localError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _confirmCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? get _error => _localError ?? widget.errorMessage;

  Future<void> _submit() async {
    final newEmail = _emailCtrl.text.trim();
    final confirm  = _confirmCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (newEmail.isEmpty || confirm.isEmpty || password.isEmpty) {
      setState(() => _localError = 'Preencha todos os campos.');
      return;
    }
    if (newEmail != confirm) {
      setState(() => _localError = 'Os e-mails não coincidem.');
      return;
    }

    setState(() {
      _loading    = true;
      _localError = null;
    });

    final success = await widget.onConfirm(
      newEmail: newEmail,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      // Fecha o sheet e abre a tela de confirmação
      Navigator.of(context).pop();
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) =>
              EmailChangedPage(pendingEmail: newEmail),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end:   Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      setState(() => _loading = false);
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 24),
            const SheetTitle(
              emoji:          '✉️',
              label:          'Alterar e-mail',
              gradientColors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            ),
            const SizedBox(height: 24),

            const SheetLabel(text: 'Novo e-mail'),
            const SizedBox(height: 8),
            SheetField(
              controller:   _emailCtrl,
              hint:         'novo@email.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon:   Icons.alternate_email_rounded,
              accentColor:  const Color(0xFF2563EB),
            ),
            const SizedBox(height: 14),

            const SheetLabel(text: 'Confirmar novo e-mail'),
            const SizedBox(height: 8),
            SheetField(
              controller:   _confirmCtrl,
              hint:         'novo@email.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon:   Icons.alternate_email_rounded,
              accentColor:  const Color(0xFF2563EB),
            ),
            const SizedBox(height: 14),

            const SheetLabel(text: 'Senha atual'),
            const SizedBox(height: 8),
            SheetField(
              controller:  _passwordCtrl,
              hint:        '••••••••',
              prefixIcon:  Icons.lock_outline_rounded,
              accentColor: const Color(0xFF2563EB),
              obscureText: _obscurePass,
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePass = !_obscurePass),
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              SheetErrorBanner(message: _error!),
            ],

            const SizedBox(height: 24),
            SheetButton(
              label:          'Confirmar alteração',
              gradientColors: const [Color(0xFF2563EB), Color(0xFF7C3AED)],
              glowColor:      const Color(0xFF2563EB),
              loading:        _loading,
              onTap:          _submit,
            ),
          ],
        ),
      ),
    );
  }
}
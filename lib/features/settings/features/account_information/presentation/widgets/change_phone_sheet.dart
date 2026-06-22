import 'package:empatia/features/settings/features/account_information/presentation/widgets/sheet_components.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChangePhoneSheet extends StatefulWidget {
  final Future<bool> Function(String newPhone) onConfirm;
  final String? errorMessage;

  const ChangePhoneSheet({
    Key? key,
    required this.onConfirm,
    this.errorMessage,
  }) : super(key: key);

  @override
  State<ChangePhoneSheet> createState() => _ChangePhoneSheetState();
}

class _ChangePhoneSheetState extends State<ChangePhoneSheet> {
  final _phoneCtrl = TextEditingController();
  bool   _loading  = false;
  String? _localError;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? get _error => _localError ?? widget.errorMessage;

  Future<void> _submit() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _localError = 'Informe o número de telefone.');
      return;
    }

    // Adiciona o +55 antes de enviar
    final fullPhone = '+55$phone';

    setState(() { _loading = true; _localError = null; });

    final success = await widget.onConfirm(fullPhone);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        _successSnackBar('Número atualizado. Lembre-se de verificá-lo.'),
      );
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
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
              emoji:         '📱',
              label:         'Alterar telefone',
              gradientColors: [Color(0xFFFF6B9D), Color(0xFFFFC837)],
            ),
            const SizedBox(height: 8),
            Text(
              'O número será salvo, mas precisará ser verificado novamente '
              'em Configurações da Conta.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            const SheetLabel(text: 'Número de telefone'),
            const SizedBox(height: 8),
            
            // Campo com +55 fixo
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prefix +55 fixo
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: Center(
                    child: Row(
                      children: [
                        Icon(Icons.phone_rounded, 
                            color: const Color(0xFFFF6B9D), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '+55',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                
                // Campo do número
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11), // DDD + 9 dígitos
                        _PhoneNumberFormatter(),
                      ],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      decoration: InputDecoration(
                        hintText: '(11) 99999-9999',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              SheetErrorBanner(message: _error!),
            ],

            const SizedBox(height: 24),
            SheetButton(
              label:         'Salvar número',
              gradientColors: const [Color(0xFFFF6B9D), Color(0xFFFFC837)],
              glowColor:     const Color(0xFFFF6B9D),
              loading:       _loading,
              onTap:         _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// Formatter para formatar automaticamente (XX) XXXXX-XXXX
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    if (text.isEmpty) return newValue.copyWith(text: '');

    final buffer = StringBuffer();
    
    // DDD
    if (text.length >= 1) {
      buffer.write('(');
      buffer.write(text.substring(0, text.length >= 2 ? 2 : text.length));
      if (text.length >= 2) buffer.write(') ');
    }
    
    // Primeiros 5 dígitos
    if (text.length >= 3) {
      final endIndex = text.length >= 7 ? 7 : text.length;
      buffer.write(text.substring(2, endIndex));
      if (text.length >= 7) buffer.write('-');
    }
    
    // Últimos 4 dígitos
    if (text.length >= 8) {
      buffer.write(text.substring(7, text.length >= 11 ? 11 : text.length));
    }

    final formatted = buffer.toString();
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

SnackBar _successSnackBar(String message) => SnackBar(
  content: Row(
    children: [
      const Icon(Icons.check_circle_rounded,
          color: Colors.white, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Text(message,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  ),
  backgroundColor: const Color(0xFF22C55E),
  behavior:        SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  margin:          const EdgeInsets.all(16),
  duration:        const Duration(seconds: 3),
);
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'otp_verification_page.dart';

// ─── MODELO DE PAÍS ────────────────────────────────────────────────────────
class Country {
  final String name;
  final String flag;
  final String dialCode;
  final String isoCode;
  final int digitCount; // quantidade de dígitos do número local (sem código)
  final String mask;    // máscara de exibição

  const Country({
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.isoCode,
    required this.digitCount,
    required this.mask,
  });
}

const List<Country> kCountries = [
  Country(name: 'Brasil',           flag: '🇧🇷', dialCode: '+55',  isoCode: 'BR', digitCount: 11, mask: '(##) #####-####'),
  Country(name: 'Portugal',         flag: '🇵🇹', dialCode: '+351', isoCode: 'PT', digitCount: 9,  mask: '## ### ####'),
  Country(name: 'Estados Unidos',   flag: '🇺🇸', dialCode: '+1',   isoCode: 'US', digitCount: 10, mask: '(###) ###-####'),
  Country(name: 'Argentina',        flag: '🇦🇷', dialCode: '+54',  isoCode: 'AR', digitCount: 10, mask: '## ####-####'),
  Country(name: 'Chile',            flag: '🇨🇱', dialCode: '+56',  isoCode: 'CL', digitCount: 9,  mask: '# ####-####'),
  Country(name: 'Colômbia',         flag: '🇨🇴', dialCode: '+57',  isoCode: 'CO', digitCount: 10, mask: '### ###-####'),
  Country(name: 'México',           flag: '🇲🇽', dialCode: '+52',  isoCode: 'MX', digitCount: 10, mask: '## ####-####'),
  Country(name: 'Uruguai',          flag: '🇺🇾', dialCode: '+598', isoCode: 'UY', digitCount: 8,  mask: '## ### ###'),
  Country(name: 'Paraguai',         flag: '🇵🇾', dialCode: '+595', isoCode: 'PY', digitCount: 9,  mask: '## #### ###'),
  Country(name: 'Peru',             flag: '🇵🇪', dialCode: '+51',  isoCode: 'PE', digitCount: 9,  mask: '### ### ###'),
  Country(name: 'Bolívia',          flag: '🇧🇴', dialCode: '+591', isoCode: 'BO', digitCount: 8,  mask: '## ## ####'),
  Country(name: 'Venezuela',        flag: '🇻🇪', dialCode: '+58',  isoCode: 'VE', digitCount: 10, mask: '###-###-####'),
  Country(name: 'Equador',          flag: '🇪🇨', dialCode: '+593', isoCode: 'EC', digitCount: 9,  mask: '## ### ####'),
  Country(name: 'Espanha',          flag: '🇪🇸', dialCode: '+34',  isoCode: 'ES', digitCount: 9,  mask: '### ## ## ##'),
  Country(name: 'França',           flag: '🇫🇷', dialCode: '+33',  isoCode: 'FR', digitCount: 9,  mask: '# ## ## ## ##'),
  Country(name: 'Alemanha',         flag: '🇩🇪', dialCode: '+49',  isoCode: 'DE', digitCount: 10, mask: '#### ######'),
  Country(name: 'Itália',           flag: '🇮🇹', dialCode: '+39',  isoCode: 'IT', digitCount: 10, mask: '### ### ####'),
  Country(name: 'Reino Unido',      flag: '🇬🇧', dialCode: '+44',  isoCode: 'GB', digitCount: 10, mask: '#### ######'),
  Country(name: 'Japão',            flag: '🇯🇵', dialCode: '+81',  isoCode: 'JP', digitCount: 10, mask: '##-####-####'),
  Country(name: 'Austrália',        flag: '🇦🇺', dialCode: '+61',  isoCode: 'AU', digitCount: 9,  mask: '### ### ###'),
  Country(name: 'Canadá',           flag: '🇨🇦', dialCode: '+1',   isoCode: 'CA', digitCount: 10, mask: '(###) ###-####'),
  Country(name: 'Angola',           flag: '🇦🇴', dialCode: '+244', isoCode: 'AO', digitCount: 9,  mask: '### ### ###'),
  Country(name: 'Moçambique',       flag: '🇲🇿', dialCode: '+258', isoCode: 'MZ', digitCount: 9,  mask: '## ### ####'),
];

// ─── FORMATTER DE MÁSCARA ──────────────────────────────────────────────────
class PhoneMaskFormatter extends TextInputFormatter {
  final String mask; // usa '#' como placeholder de dígito

  PhoneMaskFormatter(this.mask);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final maxDigits = mask.replaceAll(RegExp(r'[^#]'), '').length;
    final limited = digits.length > maxDigits ? digits.substring(0, maxDigits) : digits;

    final buffer = StringBuffer();
    int digitIndex = 0;
    for (int i = 0; i < mask.length && digitIndex < limited.length; i++) {
      if (mask[i] == '#') {
        buffer.write(limited[digitIndex++]);
      } else {
        buffer.write(mask[i]);
      }
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ─── TELA PRINCIPAL ────────────────────────────────────────────────────────
class PhoneVerificationPage extends StatefulWidget {
  const PhoneVerificationPage({Key? key}) : super(key: key);

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  Country _selected = kCountries.first; // Brasil por padrão
  final _phoneCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _isValid = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_validate);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validate() {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _isValid = digits.length == _selected.digitCount;
      _errorMsg = null;
    });
  }

  void _onCountryChanged(Country c) {
    setState(() {
      _selected = c;
      _phoneCtrl.clear();
      _isValid = false;
      _errorMsg = null;
    });
    Future.delayed(const Duration(milliseconds: 100), () => _focusNode.requestFocus());
  }

  void _submit() {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != _selected.digitCount) {
      setState(() => _errorMsg =
          'Número inválido. ${_selected.name} requer ${_selected.digitCount} dígitos.');
      return;
    }

    final fullNumber = '${_selected.dialCode} ${_phoneCtrl.text}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationPage(phoneNumber: fullNumber),
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
                  _buildPhoneCard(),
                  const SizedBox(height: 20),
                  _buildInfoTip(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
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
                'VERIFICAR TELEFONE',
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
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.35),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.phone_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          'Seu número de celular',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Escolha seu país e digite o número.\nVamos enviar um SMS de confirmação.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── CARD DO FORMULÁRIO ────────────────────────────────────────────────────
  Widget _buildPhoneCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label país
          _buildLabel('País / Região'),
          const SizedBox(height: 8),
          _buildCountrySelector(),
          const SizedBox(height: 20),

          // Label número
          _buildLabel('Número de celular'),
          const SizedBox(height: 8),
          _buildPhoneField(),

          // Erro
          if (_errorMsg != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.red, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Número completo preview
          if (_isValid) ...[
            const SizedBox(height: 14),
            _buildPreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }

  // ── SELETOR DE PAÍS ───────────────────────────────────────────────────────
  Widget _buildCountrySelector() {
    return GestureDetector(
      onTap: _showCountryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF2563EB).withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(_selected.flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selected.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  Text(
                    '${_selected.dialCode} · ${_selected.digitCount} dígitos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CAMPO DE TELEFONE ─────────────────────────────────────────────────────
  Widget _buildPhoneField() {
    return TextField(
      controller: _phoneCtrl,
      focusNode: _focusNode,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        PhoneMaskFormatter(_selected.mask),
      ],
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E3A8A),
        letterSpacing: 1,
      ),
      decoration: InputDecoration(
        hintText: _selected.mask.replaceAll('#', '0'),
        hintStyle: TextStyle(
          color: Colors.grey.shade300,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
        prefixText: '${_selected.dialCode}  ',
        prefixStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
        ),
        suffixIcon: _isValid
            ? const Icon(Icons.check_circle_rounded,
                color: Color(0xFF4ADE80), size: 24)
            : null,
        filled: true,
        fillColor: const Color(0xFFF8F8FF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _errorMsg != null
                ? Colors.red.withOpacity(0.5)
                : _isValid
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFF2563EB).withOpacity(0.2),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _errorMsg != null
                ? Colors.red
                : _isValid
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFF2563EB),
            width: 2,
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ── PREVIEW NÚMERO COMPLETO ───────────────────────────────────────────────
  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2563EB).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF4ADE80), size: 18),
          const SizedBox(width: 10),
          Text(
            'Número: ${_selected.dialCode} ${_phoneCtrl.text}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  // ── DICA INFERIOR ─────────────────────────────────────────────────────────
  Widget _buildInfoTip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Certifique-se de usar um número que você tenha acesso. O código SMS expira em 10 minutos.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTÃO ENVIAR ──────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isValid ? _submit : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _isValid
              ? const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                )
              : null,
          color: _isValid ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isValid
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_rounded,
              color: _isValid ? Colors.white : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Enviar código SMS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _isValid ? Colors.white : Colors.grey.shade400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BOTTOM SHEET PAÍS ─────────────────────────────────────────────────────
  void _showCountryPicker() {
    final searchCtrl = TextEditingController();
    List<Country> filtered = List.from(kCountries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),

              // Título
              const Text(
                'Selecionar país',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 16),

              // Busca
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: (q) {
                    setSheet(() {
                      filtered = kCountries
                          .where((c) =>
                              c.name
                                  .toLowerCase()
                                  .contains(q.toLowerCase()) ||
                              c.dialCode.contains(q))
                          .toList();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar país ou código...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF2563EB)),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Lista
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final isSelected = c.isoCode == _selected.isoCode;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _onCountryChanged(c);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2563EB).withOpacity(0.07)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF2563EB)
                                      .withOpacity(0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text(c.flag,
                                style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                c.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                            Text(
                              c.dialCode,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : Colors.grey.shade500,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check_rounded,
                                  color: Color(0xFF2563EB), size: 18),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
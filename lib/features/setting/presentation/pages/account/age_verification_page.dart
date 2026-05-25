import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class AgeVerificationPage extends StatefulWidget {
  const AgeVerificationPage({Key? key}) : super(key: key);

  @override
  State<AgeVerificationPage> createState() => _AgeVerificationPageState();
}

class _AgeVerificationPageState extends State<AgeVerificationPage> {
  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;
  bool _isValid = false;
  bool _acceptedTerms = false;
  String? _errorMsg;

  final List<String> _months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
  }

  void _validate() {
    setState(() {
      _errorMsg = null;
      _isValid = _selectedDay != null &&
          _selectedMonth != null &&
          _selectedYear != null;

      if (_isValid) {
        // Valida se a data é válida
        try {
          final date = DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);
          
          // Verifica se a data não é futura
          if (date.isAfter(DateTime.now())) {
            _errorMsg = 'A data não pode ser no futuro.';
            _isValid = false;
            return;
          }

          // Verifica idade mínima (agora 18 anos)
          final age = _calcAge(date);
          if (age < 18) {
            _errorMsg = 'Você precisa ter pelo menos 18 anos.';
            _isValid = false;
            return;
          }

          // Verifica idade máxima razoável (exemplo: 120 anos)
          if (age > 120) {
            _errorMsg = 'Por favor, verifique a data inserida.';
            _isValid = false;
            return;
          }
        } catch (e) {
          _errorMsg = 'Data inválida. Verifique o dia selecionado.';
          _isValid = false;
        }
      }
    });
  }

  int _calcAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  int _getDaysInMonth(int month, int year) {
    if (month == 2) {
      // Fevereiro - verifica ano bissexto
      if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
        return 29;
      }
      return 28;
    }
    if ([4, 6, 9, 11].contains(month)) {
      return 30;
    }
    return 31;
  }

  void _submit() {
    if (!_isValid || !_acceptedTerms) return;

    // Retorna true para a tela anterior
    Navigator.pop(context, true);
  }

  void _openTerms() {
    // Implemente a navegação para os termos de uso
    // Navigator.push(context, MaterialPageRoute(builder: (_) => TermsPage()));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Termos de Uso'),
        content: const SingleChildScrollView(
          child: Text('Aqui ficarão os termos de uso da plataforma...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy() {
    // Implemente a navegação para a política de privacidade
    // Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyPolicyPage()));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Política de Privacidade'),
        content: const SingleChildScrollView(
          child: Text('Aqui ficará a política de privacidade da plataforma...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
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
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
              child: Column(
                children: [
                  _buildTopIllustration(),
                  const SizedBox(height: 32),
                  _buildDateCard(),
                  const SizedBox(height: 20),
                  if (_isValid && _errorMsg == null) _buildAgePreview(),
                  if (_errorMsg != null) _buildErrorCard(),
                  const SizedBox(height: 20),
                  _buildTermsCheckbox(),
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
          colors: [Color(0xFFFF6B9D), Color(0xFFFFC837), Color(0xFF8B5CF6)],
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
                'VERIFICAR IDADE',
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
              colors: [Color(0xFFFF6B9D), Color(0xFFFFC837)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B9D).withOpacity(0.35),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.cake_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          'Sua data de nascimento',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Precisamos confirmar sua idade para\npersonalizar sua experiência.',
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

  // ── CARD DE DATA ──────────────────────────────────────────────────────────
  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          _buildLabel('Selecione sua data de nascimento'),
          const SizedBox(height: 16),
          Row(
            children: [
              // Dia
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  value: _selectedDay,
                  hint: 'Dia',
                  items: List.generate(31, (i) => i + 1),
                  onChanged: (val) {
                    setState(() => _selectedDay = val);
                    _validate();
                  },
                  displayText: (val) => val.toString().padLeft(2, '0'),
                ),
              ),
              const SizedBox(width: 12),
              // Mês
              Expanded(
                flex: 3,
                child: _buildDropdown(
                  value: _selectedMonth,
                  hint: 'Mês',
                  items: List.generate(12, (i) => i + 1),
                  onChanged: (val) {
                    setState(() {
                      _selectedMonth = val;
                      // Ajusta o dia se necessário
                      if (_selectedDay != null && _selectedYear != null) {
                        final maxDays = _getDaysInMonth(val!, _selectedYear!);
                        if (_selectedDay! > maxDays) {
                          _selectedDay = maxDays;
                        }
                      }
                    });
                    _validate();
                  },
                  displayText: (val) => _months[val! - 1],
                ),
              ),
              const SizedBox(width: 12),
              // Ano
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  value: _selectedYear,
                  hint: 'Ano',
                  items: List.generate(
                    120,
                    (i) => DateTime.now().year - i,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _selectedYear = val;
                      // Ajusta o dia se necessário
                      if (_selectedDay != null && _selectedMonth != null) {
                        final maxDays =
                            _getDaysInMonth(_selectedMonth!, val!);
                        if (_selectedDay! > maxDays) {
                          _selectedDay = maxDays;
                        }
                      }
                    });
                    _validate();
                  },
                  displayText: (val) => val.toString(),
                ),
              ),
            ],
          ),
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

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T?) displayText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value != null
              ? const Color(0xFFFF6B9D).withOpacity(0.4)
              : const Color(0xFFFF6B9D).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: value != null
                ? const Color(0xFFFF6B9D)
                : Colors.grey.shade400,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          borderRadius: BorderRadius.circular(14),
          dropdownColor: Colors.white,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E3A8A),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(displayText(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── PREVIEW DE IDADE ──────────────────────────────────────────────────────
  Widget _buildAgePreview() {
    if (_selectedDay == null ||
        _selectedMonth == null ||
        _selectedYear == null) {
      return const SizedBox.shrink();
    }

    final birthDate =
        DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);
    final age = _calcAge(birthDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFFFC837)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B9D).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎂', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sua idade',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$age anos',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Válido',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CARD DE ERRO ──────────────────────────────────────────────────────────
  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMsg!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CHECKBOX TERMOS ───────────────────────────────────────────────────────
  Widget _buildTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _acceptedTerms
              ? const Color(0xFF8B5CF6).withOpacity(0.3)
              : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _acceptedTerms,
              onChanged: (value) {
                setState(() {
                  _acceptedTerms = value ?? false;
                });
              },
              activeColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              side: BorderSide(
                color: _acceptedTerms
                    ? const Color(0xFF8B5CF6)
                    : Colors.grey.shade400,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Declaro ser maior de 18 anos e aceito os ',
                    ),
                    TextSpan(
                      text: 'Termos de Uso',
                      style: const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF8B5CF6),
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _openTerms,
                    ),
                    const TextSpan(text: ' e '),
                    TextSpan(
                      text: 'Política de Privacidade',
                      style: const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF8B5CF6),
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _openPrivacyPolicy,
                    ),
                    const TextSpan(
                      text: ', comprometendo-me a seguir as diretrizes da plataforma.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DICA ──────────────────────────────────────────────────────────────────
  Widget _buildInfoTip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          const Text('🔒', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Suas informações são privadas e seguras. Usamos apenas para personalizar sua experiência.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.purple.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTÃO CONFIRMAR ───────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    final bool canSubmit = _isValid && _acceptedTerms;
    
    return GestureDetector(
      onTap: canSubmit ? _submit : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: canSubmit
              ? const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFFC837)],
                )
              : null,
          color: canSubmit ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: canSubmit
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withOpacity(0.4),
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
              Icons.verified_rounded,
              color: canSubmit ? Colors.white : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Confirmar data de nascimento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: canSubmit ? Colors.white : Colors.grey.shade400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
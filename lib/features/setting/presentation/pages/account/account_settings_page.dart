import 'package:empatia/features/setting/presentation/pages/account/age_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'phone_verification_page.dart'; // Adicione este import

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _phoneVerified = false;
  bool _ageVerified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 20),
                  _buildVerifyPhoneCard(),
                  const SizedBox(height: 16),
                  _buildVerifyAgeCard(),
                  const SizedBox(height: 24),
                  if (_phoneVerified && _ageVerified) _buildAllDoneCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────
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
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'CONFIGURAÇÕES DA CONTA',
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
      ),
    );
  }

  // ─── HERO ──────────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    final total = 2;
    final done = (_phoneVerified ? 1 : 0) + (_ageVerified ? 1 : 0);
    final progress = done / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B9D), Color(0xFFFFC837), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B9D).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('🛡️', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verifique sua conta',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Perfis verificados transmitem\nmais confiança para a comunidade.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progresso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$done de $total verificações concluídas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ─── CARD VERIFICAR TELEFONE ───────────────────────────────────────────────
  Widget _buildVerifyPhoneCard() {
    return _buildVerifyCard(
      verified: _phoneVerified,
      emoji: '📱',
      gradientColors: [const Color(0xFF2563EB), const Color(0xFF7C3AED)],
      glowColor: const Color(0xFF2563EB),
      title: 'Verificar telefone',
      description:
          'Confirme seu número de celular via SMS. Leva menos de 1 minuto.',
      tag: 'SMS',
      tagColor: const Color(0xFF2563EB),
      benefits: [
        'Recuperação de conta mais fácil',
        'Camada extra de segurança',
        'Alertas importantes por SMS',
      ],
      buttonLabel: 'Verificar por SMS',
      buttonIcon: Icons.sms_rounded,
      onTap: () => _navigateToPhoneVerification(),
    );
  }

  // ─── CARD VERIFICAR IDADE ──────────────────────────────────────────────────
  Widget _buildVerifyAgeCard() {
    return _buildVerifyCard(
      verified: _ageVerified,
      emoji: '🎂',
      gradientColors: [const Color(0xFFFF6B9D), const Color(0xFFFFC837)],
      glowColor: const Color(0xFFFF6B9D),
      title: 'Verificar idade',
      description:
          'Confirme sua data de nascimento para acessar conteúdos exclusivos.',
      tag: 'Rápido',
      tagColor: const Color(0xFFFF6B9D),
      benefits: [
        'Acesso a conteúdos por faixa etária',
        'Personalização do app',
        'Maior confiança na comunidade',
      ],
      buttonLabel: 'Confirmar data de nascimento',
      buttonIcon: Icons.cake_rounded,
      onTap: () => _navigateToAgeVerification(),
    );
  }

  Widget _buildVerifyCard({
    required bool verified,
    required String emoji,
    required List<Color> gradientColors,
    required Color glowColor,
    required String title,
    required String description,
    required String tag,
    required Color tagColor,
    required List<String> benefits,
    required String buttonLabel,
    required IconData buttonIcon,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: verified
              ? const Color(0xFF4ADE80).withOpacity(0.5)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: verified
                ? const Color(0xFF4ADE80).withOpacity(0.15)
                : Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topo colorido
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: verified
                  ? const LinearGradient(
                      colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                    )
                  : LinearGradient(colors: gradientColors),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    verified ? '✅' : emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verified ? 'Verificado!' : title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        verified
                            ? 'Esta etapa foi concluída com sucesso.'
                            : description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    verified ? '✓ OK' : tag,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Benefícios
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Text(
              'Por que verificar?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade500,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              children: benefits
                  .map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: verified
                                  ? const Color(0xFF4ADE80).withOpacity(0.15)
                                  : tagColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: verified
                                  ? const Color(0xFF22C55E)
                                  : tagColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            b,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: verified
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4ADE80).withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF22C55E),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Verificação concluída',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: onTap,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(buttonIcon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            buttonLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
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

  // ─── CARD TUDO PRONTO ──────────────────────────────────────────────────────
  Widget _buildAllDoneCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ADE80).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conta verificada!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Seu perfil agora tem o selo de verificação. Parabéns!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── NAVEGAÇÃO PARA VERIFICAÇÃO DE TELEFONE ────────────────────────────────
  Future<void> _navigateToPhoneVerification() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PhoneVerificationPage()),
    );

    // Se a verificação foi bem-sucedida, atualiza o estado
    if (result == true && mounted) {
      setState(() => _phoneVerified = true);

      // Mostra feedback visual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Telefone verificado com sucesso!',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ─── NAVEGAÇÃO PARA VERIFICAÇÃO DE IDADE ────────────────────────────────
  Future<void> _navigateToAgeVerification() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AgeVerificationPage()),
    );

    // Se a verificação foi bem-sucedida, atualiza o estado
    if (result == true && mounted) {
      setState(() => _ageVerified = true);

      // Mostra feedback visual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.cake_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Idade verificada com sucesso!',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF6B9D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

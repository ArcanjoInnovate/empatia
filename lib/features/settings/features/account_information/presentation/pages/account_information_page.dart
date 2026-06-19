import 'package:empatia/features/settings/features/account_information/controller/account_info_controller.dart';
import 'package:empatia/features/settings/features/account_information/presentation/widgets/change_email_sheet.dart';
import 'package:empatia/features/settings/features/account_information/presentation/widgets/info_card.dart';
import 'package:flutter/material.dart';

class AccountInformationPage extends StatefulWidget {
  const AccountInformationPage({Key? key}) : super(key: key);

  @override
  State<AccountInformationPage> createState() => _AccountInformationPageState();
}

class _AccountInformationPageState extends State<AccountInformationPage> {
  late final AccountInfoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AccountInfoController();
    _controller.loadUserInfo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (_, __) {
                if (_controller.loadingPage) return _buildSkeleton();
                return _buildContent();
              },
            ),
          ),
        ],
      ),
    );
  }

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
                'INFORMAÇÕES PESSOAIS',
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

  Widget _buildContent() {
    final model = _controller.model;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        children: [
          InfoCard(
            emoji:          '✉️',
            gradientColors: const [Color(0xFF2563EB), Color(0xFF7C3AED)],
            glowColor:      const Color(0xFF2563EB),
            title:          'E-mail',
            currentLabel:   'Endereço atual',
            currentValue:   model?.displayEmail ?? '—',
            buttonLabel:    'Alterar e-mail',
            onTap:          _openEmailSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: _skeletonBox(height: 160),
    );
  }

  Widget _skeletonBox({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
        ),
      ),
    );
  }

  void _openEmailSheet() {
    _controller.clearEmailError();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ListenableBuilder(
        listenable: _controller,
        builder: (_, __) => ChangeEmailSheet(
          errorMessage: _controller.emailError,
          onConfirm: ({required newEmail, required password}) =>
              _controller.updateEmail(
                  newEmail: newEmail, password: password),
        ),
      ),
    );
  }
}
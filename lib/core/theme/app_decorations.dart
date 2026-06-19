import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Centraliza todas as BoxDecoration, sombras e estilos visuais
/// reutilizados nas telas. Nenhuma cor literal deve ficar nas páginas —
/// use sempre as constantes de [AppTheme] e os builders deste arquivo.
class AppDecorations {
  AppDecorations._();

  // ─── Fundos de tela ──────────────────────────────────────────────────────────

  static const BoxDecoration loginBackground = BoxDecoration(
    gradient: AppTheme.loginBackground,
  );

  static const BoxDecoration registerBackground = BoxDecoration(
    gradient: AppTheme.registerBackground,
  );

  static const BoxDecoration successBackground = BoxDecoration(
    gradient: AppTheme.successBackground,
  );

  // ─── Cards ───────────────────────────────────────────────────────────────────

  /// Card branco com sombra rosa + roxa (Login)
  static BoxDecoration loginCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(40),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withOpacity(0.3),
        blurRadius: 40,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: AppTheme.kidsPurple.withOpacity(0.2),
        blurRadius: 50,
        spreadRadius: 5,
        offset: const Offset(0, 15),
      ),
    ],
  );

  /// Card branco com sombra amarela + rosa (Register)
  static BoxDecoration registerCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(40),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsYellow.withOpacity(0.4),
        blurRadius: 40,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: AppTheme.kidsPink.withOpacity(0.3),
        blurRadius: 50,
        spreadRadius: 5,
        offset: const Offset(0, 15),
      ),
    ],
  );

  // ─── Barra arco-íris no topo do card ────────────────────────────────────────

  static const BoxDecoration cardRainbowBar = BoxDecoration(
    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
    gradient: AppTheme.kidsRainbow,
  );

  // ─── Fundo dos títulos dentro do card ────────────────────────────────────────

  static BoxDecoration loginTitleBox = BoxDecoration(
    gradient: AppTheme.loginTitleBackground,
    borderRadius: BorderRadius.circular(25),
  );

  static BoxDecoration registerTitleBox = BoxDecoration(
    gradient: AppTheme.registerTitleBackground,
    borderRadius: BorderRadius.circular(30),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsYellow.withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 5),
      ),
    ],
  );

  // ─── Logo circular ───────────────────────────────────────────────────────────

  /// Círculo branco externo do logo (LoginPage — tamanho 130)
  static BoxDecoration loginLogo = BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withOpacity(0.4),
        blurRadius: 30,
        spreadRadius: 5,
      ),
      BoxShadow(
        color: AppTheme.kidsPurple.withOpacity(0.3),
        blurRadius: 40,
        spreadRadius: 10,
      ),
    ],
  );

  /// Círculo branco externo do logo (RegisterPage — tamanho 85)
  static BoxDecoration registerLogo = BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsYellow.withOpacity(0.5),
        blurRadius: 30,
        spreadRadius: 5,
      ),
      BoxShadow(
        color: AppTheme.kidsPink.withOpacity(0.4),
        blurRadius: 40,
        spreadRadius: 10,
      ),
    ],
  );

  /// Círculo interno (coração) do logo da LoginPage — gradiente rosa
  static const BoxDecoration loginLogoInner = BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppTheme.kidsPink, AppTheme.kidsPinkDeep],
    ),
  );

  /// Círculo interno (coração) do logo da RegisterPage — gradiente amarelo
  static const BoxDecoration registerLogoInner = BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppTheme.kidsYellow, AppTheme.kidsYellowGold],
    ),
  );

  // ─── Sucesso / ícone de check ────────────────────────────────────────────────

  /// Círculo branco externo do ícone de sucesso (SuccessPage — 180)
  static BoxDecoration successIcon = BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsGreen.withOpacity(0.6),
        blurRadius: 50,
        spreadRadius: 10,
      ),
      BoxShadow(
        color: AppTheme.kidsCyan.withOpacity(0.4),
        blurRadius: 60,
        spreadRadius: 20,
      ),
    ],
  );

  /// Círculo interno do ícone de sucesso (check verde)
  static const BoxDecoration successIconInner = BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppTheme.kidsGreen, AppTheme.kidsGreenDeep],
    ),
  );

  // ─── Mensagem de sucesso ─────────────────────────────────────────────────────

  static BoxDecoration successMessageBox = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(30),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 30,
        spreadRadius: 5,
      ),
    ],
  );

  static BoxDecoration successSubMessageBox = BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFFE6FFF0), Color(0xFFE6F7FF)],
    ),
    borderRadius: BorderRadius.circular(25),
    border: Border.all(color: AppTheme.kidsGreen, width: 3),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsGreen.withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration successLoadingBox = BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPurple.withOpacity(0.4),
        blurRadius: 30,
        spreadRadius: 5,
      ),
    ],
  );

  // ─── Campos (MagicField) ─────────────────────────────────────────────────────

  /// Borda externa do campo (normal)
  static BoxDecoration fieldOuter({
    required List<Color> gradientColors,
    bool hasError = false,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: hasError
            ? [const Color(0xFFFFE6E6), const Color(0xFFFFF0F0)]
            : [Colors.white, Colors.white],
      ),
      borderRadius: BorderRadius.circular(25),
      border: hasError
          ? Border.all(width: 3, color: AppTheme.errorRed)
          : Border.all(width: 3, color: Colors.transparent),
      boxShadow: [
        BoxShadow(
          color: hasError
              ? AppTheme.errorRed.withOpacity(0.3)
              : gradientColors[0].withOpacity(0.2),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  /// Fundo interno do campo (tint da cor do gradiente)
  static BoxDecoration fieldInner(List<Color> gradientColors) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        colors: [
          gradientColors[0].withOpacity(0.1),
          gradientColors[1].withOpacity(0.05),
        ],
      ),
    );
  }

  /// Ícone do campo
  static BoxDecoration fieldIcon(List<Color> gradientColors) {
    return BoxDecoration(
      gradient: LinearGradient(colors: gradientColors),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: gradientColors[0].withOpacity(0.4),
          blurRadius: 8,
        ),
      ],
    );
  }

  // ─── Erros ───────────────────────────────────────────────────────────────────

  static BoxDecoration errorBubble = BoxDecoration(
    gradient: AppTheme.errorGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppTheme.errorRed, width: 2),
    boxShadow: [
      BoxShadow(
        color: AppTheme.errorRed.withOpacity(0.3),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration errorIcon = BoxDecoration(
    color: AppTheme.errorRed,
    borderRadius: BorderRadius.circular(12),
  );

  // ─── Botões ───────────────────────────────────────────────────────────────────

  static BoxDecoration loginButton = BoxDecoration(
    gradient: AppTheme.loginButtonGradient,
    borderRadius: BorderRadius.circular(32),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withOpacity(0.6),
        blurRadius: 25,
        spreadRadius: 2,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: AppTheme.kidsPinkDeep.withOpacity(0.4),
        blurRadius: 35,
        spreadRadius: 5,
        offset: const Offset(0, 12),
      ),
    ],
  );

  static BoxDecoration registerButton = BoxDecoration(
    gradient: AppTheme.registerButtonGradient,
    borderRadius: BorderRadius.circular(34),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsYellow.withOpacity(0.7),
        blurRadius: 30,
        spreadRadius: 3,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: AppTheme.kidsYellowGold.withOpacity(0.5),
        blurRadius: 40,
        spreadRadius: 8,
        offset: const Offset(0, 15),
      ),
    ],
  );

  static BoxDecoration createAccountButton = BoxDecoration(
    gradient: AppTheme.createAccountGradient,
    borderRadius: BorderRadius.circular(30),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsYellow.withOpacity(0.5),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration loginLinkButton = BoxDecoration(
    gradient: AppTheme.loginLinkGradient,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsCyan.withOpacity(0.4),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );

  // ─── Checkbox de termos ───────────────────────────────────────────────────────

  static BoxDecoration termsCheckbox({required bool accepted}) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: accepted
            ? [const Color(0xFFE6FFF0), const Color(0xFFF0FFF4)]
            : [const Color(0xFFFFFBE6), const Color(0xFFFFF9E6)],
      ),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(
        color: accepted ? AppTheme.kidsGreen : AppTheme.kidsYellow,
        width: 3,
      ),
      boxShadow: [
        BoxShadow(
          color: (accepted ? AppTheme.kidsGreen : AppTheme.kidsYellow)
              .withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  static BoxDecoration termsCheckboxTick({required bool accepted}) {
    return BoxDecoration(
      gradient: accepted
          ? const LinearGradient(
              colors: [AppTheme.kidsGreen, AppTheme.kidsGreenDeep],
            )
          : null,
      color: accepted ? null : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: accepted ? AppTheme.kidsGreen : AppTheme.kidsYellow,
        width: 3,
      ),
      boxShadow: accepted
          ? [
              BoxShadow(
                color: AppTheme.kidsGreen.withOpacity(0.5),
                blurRadius: 10,
              ),
            ]
          : null,
    );
  }

  // ─── Tag do app name (LoginPage) ─────────────────────────────────────────────

  static BoxDecoration appNameTag = BoxDecoration(
    gradient: const LinearGradient(
      colors: [Colors.white, Color(0xFFFFF9E6)],
    ),
    borderRadius: BorderRadius.circular(30),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsYellow.withOpacity(0.5),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );

  static BoxDecoration brandTagBox = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
      ),
    ],
  );

  // ─── AgeVerificationPage ─────────────────────────────────────────────────────

  /// Header da AgeVerificationPage
  static const BoxDecoration ageVerificationHeader = BoxDecoration(
    gradient: AppTheme.ageVerificationHeaderGradient,
  );

  /// Badge informativo (antes de selecionar data)
  static BoxDecoration ageVerificationInfoBadge = BoxDecoration(
    gradient: AppTheme.ageVerificationInfoBadgeGradient,
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withOpacity(0.35),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );

  /// Badge de sucesso (após validar a data)
  static BoxDecoration ageVerificationSuccessBadge = BoxDecoration(
    gradient: AppTheme.ageVerificationSuccessBadgeGradient,
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsGreen.withOpacity(0.40),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );

  /// Card branco principal da AgeVerificationPage
  static BoxDecoration ageVerificationCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ],
  );

  /// Ícone de calendário dentro do card
  static BoxDecoration ageVerificationCalendarIcon = BoxDecoration(
    color: AppTheme.kidsPink.withOpacity(0.10),
    borderRadius: BorderRadius.circular(10),
  );

  /// Botão de calendário (escolher pelo calendário)
  static BoxDecoration ageVerificationCalendarButton = BoxDecoration(
    color: AppTheme.kidsPink.withOpacity(0.06),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.kidsPink.withOpacity(0.25)),
  );

  /// Feedback de validação — data válida (verde)
  static BoxDecoration ageVerificationFeedbackValid = BoxDecoration(
    color: AppTheme.kidsGreen.withOpacity(0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.kidsGreen.withOpacity(0.35)),
  );

  /// Feedback de validação — data inválida (vermelho)
  static BoxDecoration ageVerificationFeedbackError = BoxDecoration(
    color: AppTheme.errorRed.withOpacity(0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.errorRed.withOpacity(0.35)),
  );

  /// Banner de erro de submit
  static BoxDecoration ageVerificationErrorBanner = BoxDecoration(
    color: AppTheme.errorRed.withOpacity(0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.errorRed.withOpacity(0.35)),
  );

  /// Botão de submit ativo
  static BoxDecoration ageVerificationSubmitActive = BoxDecoration(
    gradient: AppTheme.ageVerificationSubmitButtonGradient,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withOpacity(0.40),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  /// Botão de submit inativo (disabled)
  static BoxDecoration ageVerificationSubmitDisabled = BoxDecoration(
    color: const Color(0xFFE0E0E0),
    borderRadius: BorderRadius.circular(18),
  );

  /// Nota de privacidade no rodapé
  static BoxDecoration ageVerificationPrivacyNote = BoxDecoration(
    color: AppTheme.kidsPink.withOpacity(0.06),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppTheme.kidsPink.withOpacity(0.20)),
  );

  // ─── ForgotPasswordPage ───────────────────────────────────────────────────────

  /// Ícone circular do ForgotPasswordPage (branco externo)
  static BoxDecoration forgotPasswordIcon = BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withOpacity(0.5),
        blurRadius: 40,
        spreadRadius: 8,
      ),
    ],
  );

  /// Círculo interno do ícone (gradiente rosa→roxo)
  static const BoxDecoration forgotPasswordIconInner = BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppTheme.kidsPink, AppTheme.kidsPurple],
    ),
  );

  /// Caixa de dica/explicação dentro do card (fundo lilás)
  static BoxDecoration forgotPasswordHintBox = BoxDecoration(
    color: const Color(0xFFF3E8FF),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: AppTheme.kidsPurple.withOpacity(0.3),
      width: 2,
    ),
  );

  /// Botão "Enviar email"
  static BoxDecoration forgotSendButton = BoxDecoration(
    gradient: AppTheme.forgotSendButtonGradient,
    borderRadius: BorderRadius.circular(32),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withOpacity(0.6),
        blurRadius: 25,
        spreadRadius: 2,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // ─── ForgotPasswordInstructionsPage ──────────────────────────────────────────

  /// Fundo da tela de instruções
  static const BoxDecoration forgotInstructionsBackground = BoxDecoration(
    gradient: AppTheme.forgotInstructionsBackground,
  );

  /// Ícone de email enviado (branco externo — 140)
  static BoxDecoration forgotEmailIcon = BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsCyan.withOpacity(0.6),
        blurRadius: 50,
        spreadRadius: 10,
      ),
      BoxShadow(
        color: AppTheme.kidsGreen.withOpacity(0.4),
        blurRadius: 60,
        spreadRadius: 20,
      ),
    ],
  );

  /// Círculo interno do ícone de email enviado
  static const BoxDecoration forgotEmailIconInner = BoxDecoration(
    shape: BoxShape.circle,
    gradient: AppTheme.forgotEmailIconGradient,
  );

  /// Card branco de instruções
  static BoxDecoration forgotInstructionsCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(40),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsCyan.withOpacity(0.3),
        blurRadius: 40,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: AppTheme.kidsGreen.withOpacity(0.2),
        blurRadius: 50,
        spreadRadius: 5,
        offset: const Offset(0, 15),
      ),
    ],
  );

  /// Cabeçalho verde do card de instruções ("Email Enviado!")
  static const BoxDecoration forgotInstructionsCardHeader = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFFE6FFF0), Color(0xFFE6F7FF)],
    ),
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
      bottomLeft: Radius.circular(24),
      bottomRight: Radius.circular(24),
    ),
  );

  /// Badge com o email do usuário (gradiente cyan→green)
  static BoxDecoration forgotEmailBadge = BoxDecoration(
    gradient: AppTheme.forgotEmailBadgeGradient,
    borderRadius: BorderRadius.circular(20),
  );

  /// Caixa de aviso de expiração do link (amarela)
  static BoxDecoration forgotExpiryWarning = BoxDecoration(
    color: const Color(0xFFFFFBE6),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: AppTheme.kidsYellow.withOpacity(0.6),
      width: 2,
    ),
  );

  /// Caixa de confirmação "email reenviado"
  static BoxDecoration forgotResentSuccess = BoxDecoration(
    color: const Color(0xFFE6FFF0),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppTheme.kidsGreen.withOpacity(0.5)),
  );

  /// Botão "Reenviar email" (borda apenas)
  static BoxDecoration forgotResendButton = BoxDecoration(
    border: Border.all(
      color: AppTheme.kidsCyan.withOpacity(0.5),
      width: 2,
    ),
    borderRadius: BorderRadius.circular(20),
  );

  /// Botão "Voltar para o login"
  static BoxDecoration forgotBackButton = BoxDecoration(
    gradient: AppTheme.forgotBackButtonGradient,
    borderRadius: BorderRadius.circular(32),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsGreen.withOpacity(0.6),
        blurRadius: 25,
        spreadRadius: 2,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // ─── Toggle de visibilidade de senha (login / register) ───────────────────────

  /// Fundo do botão olho de senha na LoginPage (lilás claro)
  static BoxDecoration passwordTogglePurple = BoxDecoration(
    color: const Color(0xFFF3E8FF),
    borderRadius: BorderRadius.circular(12),
  );

  /// Fundo do botão olho de senha no campo "Confirmar senha" (rosa claro)
  static BoxDecoration passwordTogglePink = BoxDecoration(
    color: const Color(0xFFFFE6F0),
    borderRadius: BorderRadius.circular(12),
  );

  /// Fundo do link "Esqueci a senha" (lilás claro)
  static BoxDecoration forgotPasswordLink = BoxDecoration(
    color: const Color(0xFFF3E8FF),
    borderRadius: BorderRadius.circular(20),
  );

  // ─── Bolhas / círculos de fundo ───────────────────────────────────────────────

  static BoxDecoration bubble(Color color) {
    return BoxDecoration(shape: BoxShape.circle, color: color);
  }

  // ─── Estilos de texto reutilizáveis ──────────────────────────────────────────

  /// Shader de gradiente para texto (ex: título "EMPATIA")
  static Paint textShader(List<Color> colors, {double width = 300}) {
    return Paint()
      ..shader = LinearGradient(colors: colors)
          .createShader(Rect.fromLTWH(0, 0, width, 70));
  }
}
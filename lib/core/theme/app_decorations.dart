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

  // ─── Perfil ──────────────────────────────────────────────────────────────────

  /// Container body da ProfilePage (arredondamento superior + cor de fundo)
  static const BoxDecoration profileBody = BoxDecoration(
    color: AppTheme.profileBackground,
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  );

  /// Card de contador de atividade (_SummaryCard) — branco com borda sutil
  static BoxDecoration profileSummaryCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppTheme.dividerColor, width: 1.5),
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
  // IMPORTANTE: sempre use dentro de ClipRRect(borderRadius: 40) para que
  // as pontas da barra respeitem o arredondamento do card pai.
  static const BoxDecoration cardRainbowBar = BoxDecoration(
    gradient: AppTheme.kidsRainbow,
  );

  // ─── Fundo dos títulos dentro do card ────────────────────────────────────────

  static BoxDecoration loginTitleBox = BoxDecoration(
    gradient: AppTheme.loginTitleBackground,
    borderRadius: BorderRadius.circular(25),
  );

  static BoxDecoration registerTitleBox = BoxDecoration(
    gradient: AppTheme.registerTitleBackground,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsYellow.withOpacity(0.2),
        blurRadius: 12,
        offset: const Offset(0, 4),
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

  /// Círculo branco externo do logo (RegisterPage)
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

  static BoxDecoration fieldOuter({
    required List<Color> gradientColors,
    bool hasError = false,
    bool isFocused = false,
  }) {
    final Color glowColor = hasError
        ? AppTheme.errorRed
        : (isFocused ? AppTheme.kidsPurple : gradientColors[0]);

    return BoxDecoration(
      gradient: LinearGradient(
        colors: hasError
            ? [const Color(0xFFFFE6E6), const Color(0xFFFFF0F0)]
            : [Colors.white, Colors.white],
      ),
      borderRadius: BorderRadius.circular(25),
      border: hasError
          ? Border.all(width: 3, color: AppTheme.errorRed)
          : Border.all(
              width: 3,
              color: isFocused ? AppTheme.kidsPurple : Colors.transparent,
            ),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(hasError || isFocused ? 0.30 : 0.2),
          blurRadius: (isFocused && !hasError) ? 18 : 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

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

  /// Botão CRIAR CONTA — sombra calibrada: visível mas não exagerada.
  /// blurRadius 18 (era 30/40), spreadRadius 0 (era 3/8), opacidade 0.45/0.25.
  static BoxDecoration registerButton = BoxDecoration(
    gradient: AppTheme.registerButtonGradient,
    borderRadius: BorderRadius.circular(34),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsYellow.withOpacity(0.45),
        blurRadius: 18,
        spreadRadius: 0,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: AppTheme.kidsYellowGold.withOpacity(0.25),
        blurRadius: 28,
        spreadRadius: 2,
        offset: const Offset(0, 10),
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

  static const BoxDecoration ageVerificationHeader = BoxDecoration(
    gradient: AppTheme.ageVerificationHeaderGradient,
  );

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

  static BoxDecoration ageVerificationCalendarIcon = BoxDecoration(
    color: AppTheme.kidsPink.withOpacity(0.10),
    borderRadius: BorderRadius.circular(10),
  );

  static BoxDecoration ageVerificationCalendarButton = BoxDecoration(
    color: AppTheme.kidsPink.withOpacity(0.06),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.kidsPink.withOpacity(0.25)),
  );

  static BoxDecoration ageVerificationFeedbackValid = BoxDecoration(
    color: AppTheme.kidsGreen.withOpacity(0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.kidsGreen.withOpacity(0.35)),
  );

  static BoxDecoration ageVerificationFeedbackError = BoxDecoration(
    color: AppTheme.errorRed.withOpacity(0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.errorRed.withOpacity(0.35)),
  );

  static BoxDecoration ageVerificationErrorBanner = BoxDecoration(
    color: AppTheme.errorRed.withOpacity(0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.errorRed.withOpacity(0.35)),
  );

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

  static BoxDecoration ageVerificationSubmitDisabled = BoxDecoration(
    color: const Color(0xFFE0E0E0),
    borderRadius: BorderRadius.circular(18),
  );

  static BoxDecoration ageVerificationPrivacyNote = BoxDecoration(
    color: AppTheme.kidsPink.withOpacity(0.06),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppTheme.kidsPink.withOpacity(0.20)),
  );

  // ─── ForgotPasswordPage ───────────────────────────────────────────────────────

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

  static const BoxDecoration forgotPasswordIconInner = BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppTheme.kidsPink, AppTheme.kidsPurple],
    ),
  );

  static BoxDecoration forgotPasswordHintBox = BoxDecoration(
    color: const Color(0xFFF3E8FF),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: AppTheme.kidsPurple.withOpacity(0.3),
      width: 2,
    ),
  );

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

  static const BoxDecoration forgotInstructionsBackground = BoxDecoration(
    gradient: AppTheme.forgotInstructionsBackground,
  );

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

  static const BoxDecoration forgotEmailIconInner = BoxDecoration(
    shape: BoxShape.circle,
    gradient: AppTheme.forgotEmailIconGradient,
  );

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

  static BoxDecoration forgotEmailBadge = BoxDecoration(
    gradient: AppTheme.forgotEmailBadgeGradient,
    borderRadius: BorderRadius.circular(20),
  );

  static BoxDecoration forgotExpiryWarning = BoxDecoration(
    color: const Color(0xFFFFFBE6),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: AppTheme.kidsYellow.withOpacity(0.6),
      width: 2,
    ),
  );

  static BoxDecoration forgotResentSuccess = BoxDecoration(
    color: const Color(0xFFE6FFF0),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppTheme.kidsGreen.withOpacity(0.5)),
  );

  static BoxDecoration forgotResendButton = BoxDecoration(
    border: Border.all(
      color: AppTheme.kidsCyan.withOpacity(0.5),
      width: 2,
    ),
    borderRadius: BorderRadius.circular(20),
  );

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

  // ─── Toggle de visibilidade de senha ───────────────────────────────────────────

  static BoxDecoration passwordTogglePurple = BoxDecoration(
    color: const Color(0xFFF3E8FF),
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration passwordTogglePink = BoxDecoration(
    color: const Color(0xFFFFE6F0),
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration forgotPasswordLink = BoxDecoration(
    color: const Color(0xFFF3E8FF),
    borderRadius: BorderRadius.circular(20),
  );

  // ─── Bolhas / círculos de fundo ───────────────────────────────────────────────

  static BoxDecoration bubble(Color color) {
    return BoxDecoration(shape: BoxShape.circle, color: color);
  }

  // ─── Indicador de progresso ──────────────────────────────────────────────────

  static BoxDecoration progressDot({required bool done}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: done ? AppTheme.kidsGreenDeep : AppTheme.textMuted.withOpacity(0.25),
    );
  }

  // ─── DreamPage ────────────────────────────────────────────────────────────────

  /// Fundo do SliverAppBar da DreamPage
  static const BoxDecoration dreamHeaderBackground = BoxDecoration(
    gradient: AppTheme.dreamHeaderGradient,
  );

  /// Ícone de seção (emoji dentro do círculo colorido em _SectionWrapper)
  static BoxDecoration dreamSectionIcon(Color color) => BoxDecoration(
    gradient: LinearGradient(
      colors: [color.withOpacity(0.22), color.withOpacity(0.08)],
    ),
    shape: BoxShape.circle,
  );

  /// Bolha de estatística no header — estado normal
  static BoxDecoration dreamStatBubble = BoxDecoration(
    color: Colors.white.withOpacity(0.15),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
  );

  /// Bolha de estatística no header — estado ativo (glow colorido)
  static BoxDecoration dreamStatBubbleActive(Color color) => BoxDecoration(
    color: color.withOpacity(0.25),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: color.withOpacity(0.6), width: 1.5),
    boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10)],
  );

  /// Card de doação recebida
  static BoxDecoration dreamReceivedCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3), width: 2),
    boxShadow: [
      BoxShadow(
        color: AppTheme.accentGreen.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Ícone (emoji) dentro do card de doação recebida
  static BoxDecoration dreamReceivedCardIcon = BoxDecoration(
    gradient: LinearGradient(colors: [
      AppTheme.accentGreen.withOpacity(0.18),
      AppTheme.accentTeal.withOpacity(0.18),
    ]),
    borderRadius: BorderRadius.circular(16),
  );

  /// Badge "Atendido!" dentro do card de doação recebida
  static BoxDecoration dreamFulfilledBadge = BoxDecoration(
    color: AppTheme.accentGreen.withOpacity(0.12),
    borderRadius: BorderRadius.circular(20),
  );

  /// Botão "+ Adicionar" dentro do cabeçalho de seção
  static BoxDecoration dreamAddButton(Color color) => BoxDecoration(
    gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
    ],
  );

  /// Container do estado vazio de seção (_EmptyState)
  static BoxDecoration dreamEmptyState(Color borderColor) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: borderColor.withOpacity(0.4), width: 2),
    boxShadow: [
      BoxShadow(
        color: borderColor.withOpacity(0.1),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ─── Estilos de texto reutilizáveis ──────────────────────────────────────────

  static Paint textShader(List<Color> colors, {double width = 300}) {
    return Paint()
      ..shader = LinearGradient(colors: colors)
          .createShader(Rect.fromLTWH(0, 0, width, 70));
  }
}
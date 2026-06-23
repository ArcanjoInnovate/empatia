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

  /// Card branco com sombra rosa + roxa (Login / ForgotPassword instruções)
  static BoxDecoration loginCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(40),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withValues(alpha: 0.3),
        blurRadius: 40,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: AppTheme.kidsPurple.withValues(alpha: 0.2),
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
        color: AppTheme.kidsYellow.withValues(alpha: 0.4),
        blurRadius: 40,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: AppTheme.kidsPink.withValues(alpha: 0.3),
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
        color: AppTheme.kidsYellow.withValues(alpha: 0.2),
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
        color: AppTheme.kidsPink.withValues(alpha: 0.4),
        blurRadius: 30,
        spreadRadius: 5,
      ),
      BoxShadow(
        color: AppTheme.kidsPurple.withValues(alpha: 0.3),
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
        color: AppTheme.kidsYellow.withValues(alpha: 0.5),
        blurRadius: 30,
        spreadRadius: 5,
      ),
      BoxShadow(
        color: AppTheme.kidsPink.withValues(alpha: 0.4),
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
        color: AppTheme.kidsGreen.withValues(alpha: 0.6),
        blurRadius: 50,
        spreadRadius: 10,
      ),
      BoxShadow(
        color: AppTheme.kidsCyan.withValues(alpha: 0.4),
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
        color: Colors.black.withValues(alpha: 0.1),
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
        color: AppTheme.kidsGreen.withValues(alpha: 0.3),
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
        color: AppTheme.kidsPurple.withValues(alpha: 0.4),
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
          gradientColors[0].withValues(alpha: 0.1),
          gradientColors[1].withValues(alpha: 0.05),
        ],
      ),
    );
  }

  static BoxDecoration fieldIcon(List<Color> gradientColors) {
    return BoxDecoration(
      gradient: LinearGradient(colors: gradientColors),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(color: gradientColors[0].withValues(alpha: 0.4), blurRadius: 8),
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
        color: AppTheme.errorRed.withValues(alpha: 0.3),
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
        color: AppTheme.kidsPink.withValues(alpha: 0.6),
        blurRadius: 25,
        spreadRadius: 2,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: AppTheme.kidsPinkDeep.withValues(alpha: 0.4),
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
        color: AppTheme.kidsYellow.withValues(alpha: 0.45),
        blurRadius: 18,
        spreadRadius: 0,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: AppTheme.kidsYellowGold.withValues(alpha: 0.25),
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
        color: AppTheme.kidsYellow.withValues(alpha: 0.5),
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
        color: AppTheme.kidsCyan.withValues(alpha: 0.4),
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
              .withValues(alpha: 0.3),
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
                color: AppTheme.kidsGreen.withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ]
          : null,
    );
  }

  // ─── Tag do app name (LoginPage) ─────────────────────────────────────────────

  static BoxDecoration appNameTag = BoxDecoration(
    gradient: const LinearGradient(colors: [Colors.white, Color(0xFFFFF9E6)]),
    borderRadius: BorderRadius.circular(30),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsYellow.withValues(alpha: 0.5),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );

  static BoxDecoration brandTagBox = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
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
        color: AppTheme.kidsPink.withValues(alpha: 0.35),
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
        color: AppTheme.kidsGreen.withValues(alpha: 0.40),
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
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration ageVerificationCalendarIcon = BoxDecoration(
    color: AppTheme.kidsPink.withValues(alpha: 0.10),
    borderRadius: BorderRadius.circular(10),
  );

  static BoxDecoration ageVerificationCalendarButton = BoxDecoration(
    color: AppTheme.kidsPink.withValues(alpha: 0.06),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.kidsPink.withValues(alpha: 0.25)),
  );

  static BoxDecoration ageVerificationFeedbackValid = BoxDecoration(
    color: AppTheme.kidsGreen.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.kidsGreen.withValues(alpha: 0.35)),
  );

  static BoxDecoration ageVerificationFeedbackError = BoxDecoration(
    color: AppTheme.errorRed.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.35)),
  );

  static BoxDecoration ageVerificationErrorBanner = BoxDecoration(
    color: AppTheme.errorRed.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.35)),
  );

  static BoxDecoration ageVerificationSubmitActive = BoxDecoration(
    gradient: AppTheme.ageVerificationSubmitButtonGradient,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withValues(alpha: 0.40),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration ageVerificationSubmitDisabled = BoxDecoration(
    color: const Color(0xFFE0E0E0),
    borderRadius: BorderRadius.circular(18),
  );

  /// Nota de privacidade no rodapé da AgeVerificationPage (_buildPrivacyNote)
  static BoxDecoration ageVerificationPrivacyNote = BoxDecoration(
    color: AppTheme.kidsPink.withValues(alpha: 0.06),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppTheme.kidsPink.withValues(alpha: 0.20)),
  );

  // ─── Blobs decorativos de fundo ──────────────────────────────────────────────

  /// Blob circular com RadialGradient branco — usado como elemento decorativo
  /// de fundo na RegisterPage (e outras telas com blobs). [opacity] controla
  /// a opacidade do branco central.
  static BoxDecoration blobDecoration(double opacity) {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          Colors.white.withOpacity(opacity),
          Colors.white.withValues(alpha: 0),
        ],
      ),
    );
  }

  // ─── ForgotPasswordPage ───────────────────────────────────────────────────────

  static BoxDecoration forgotPasswordIcon = BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withValues(alpha: 0.5),
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

  /// Caixa explicativa/informativa roxa (ex.: "como funciona a recuperação")
  static BoxDecoration forgotInfoBox = BoxDecoration(
    color: const Color(0xFFF3E8FF),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppTheme.kidsPurple.withValues(alpha: 0.3), width: 2),
  );

  /// Alias mantido para retrocompatibilidade — prefira [forgotInfoBox].
  static BoxDecoration get forgotPasswordHintBox => forgotInfoBox;

  static BoxDecoration forgotSendButton = BoxDecoration(
    gradient: AppTheme.forgotSendButtonGradient,
    borderRadius: BorderRadius.circular(32),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withValues(alpha: 0.6),
        blurRadius: 25,
        spreadRadius: 2,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Botão "Voltar para o login" — gradiente green→cyan com glow verde
  static BoxDecoration forgotBackButton = BoxDecoration(
    gradient: AppTheme.forgotBackButtonGradient,
    borderRadius: BorderRadius.circular(32),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsGreen.withValues(alpha: 0.6),
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
        color: AppTheme.kidsCyan.withValues(alpha: 0.6),
        blurRadius: 50,
        spreadRadius: 10,
      ),
      BoxShadow(
        color: AppTheme.kidsGreen.withValues(alpha: 0.4),
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
        color: AppTheme.kidsCyan.withValues(alpha: 0.3),
        blurRadius: 40,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: AppTheme.kidsGreen.withValues(alpha: 0.2),
        blurRadius: 50,
        spreadRadius: 5,
        offset: const Offset(0, 15),
      ),
    ],
  );

  /// Cabeçalho do card "Email Enviado!" — gradiente verde-água suave
  static const BoxDecoration forgotSuccessHeader = BoxDecoration(
    gradient: LinearGradient(colors: [Color(0xFFE6FFF0), Color(0xFFE6F7FF)]),
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );

  /// Alias mantido para retrocompatibilidade — prefira [forgotSuccessHeader].
  static BoxDecoration get forgotInstructionsCardHeader =>
      forgotSuccessHeader as BoxDecoration;

  /// Chip com o endereço de email do destinatário — gradiente cyan→green
  static BoxDecoration forgotEmailChip = BoxDecoration(
    gradient: AppTheme.forgotEmailChipGradient,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsCyan.withValues(alpha: 0.3),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static BoxDecoration forgotEmailBadge = BoxDecoration(
    gradient: AppTheme.forgotEmailBadgeGradient,
    borderRadius: BorderRadius.circular(20),
  );

  /// Caixa de aviso "link expira em X minutos" — fundo âmbar claro
  /// Use [AppTheme.kidsAmberDark] para o título e [AppTheme.kidsAmber]
  /// para o texto secundário desta caixa.
  static BoxDecoration forgotWarningBox = BoxDecoration(
    color: const Color(0xFFFFFBE6),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppTheme.kidsYellow.withValues(alpha: 0.6), width: 2),
  );

  /// Alias mantido para retrocompatibilidade — prefira [forgotWarningBox].
  static BoxDecoration get forgotExpiryWarning => forgotWarningBox;

  /// Banner de confirmação de reenvio de email ("Email reenviado com sucesso!")
  static BoxDecoration forgotResentBanner = BoxDecoration(
    color: const Color(0xFFE6FFF0),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppTheme.kidsGreen.withValues(alpha: 0.5)),
  );

  /// Alias mantido para retrocompatibilidade — prefira [forgotResentBanner].
  static BoxDecoration get forgotResentSuccess => forgotResentBanner;

  /// Botão de reenviar email — apenas borda cyan, sem preenchimento
  static BoxDecoration forgotResendButton = BoxDecoration(
    border: Border.all(color: AppTheme.kidsCyan.withValues(alpha: 0.5), width: 2),
    borderRadius: BorderRadius.circular(20),
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

  // ─── DonationItemFormSheet ────────────────────────────────────────────────────
  // Cole este bloco dentro de AppDecorations, antes do fechamento da classe.

  /// Handle bar do bottom sheet (drag indicator)
  static BoxDecoration donationFormHandle = BoxDecoration(
    color: AppTheme.dividerColor,
    borderRadius: BorderRadius.circular(4),
  );

  /// Botão "Publicar na vitrine" / "Salvar alterações" — estado ativo
  static BoxDecoration donationSubmitActive = BoxDecoration(
    gradient: const LinearGradient(
      colors: [AppTheme.kidsPink, AppTheme.kidsPurple],
    ),
    borderRadius: BorderRadius.circular(18),
  );

  /// Botão submit — estado de loading (spinner visível, gradiente removido)
  static BoxDecoration donationSubmitLoading = BoxDecoration(
    color: AppTheme.dividerColor,
    borderRadius: BorderRadius.circular(18),
  );

  /// Container do PhotoPicker — varia conforme estado de erro e presença de foto
  static BoxDecoration donationPhotoPicker({
    required bool hasError,
    required bool hasPhoto,
  }) {
    return BoxDecoration(
      color: hasError
          ? AppTheme.errorRed.withValues(alpha: 0.06)
          : const Color(
              0xFFF8F8FF,
            ), // surfaceLight levemente azulado, padrão do sheet
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: hasError
            ? AppTheme.errorRed
            : hasPhoto
            ? AppTheme.kidsPink.withValues(alpha: 0.4)
            : AppTheme.dividerColor,
        width: hasError ? 2 : 1.5,
      ),
    );
  }
  // ─── Indicador de progresso ──────────────────────────────────────────────────

  static BoxDecoration progressDot({required bool done}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: done
          ? AppTheme.kidsGreenDeep
          : AppTheme.textMuted.withValues(alpha: 0.25),
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
      colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.08)],
    ),
    shape: BoxShape.circle,
  );

  /// Bolha de estatística no header — estado normal
  static BoxDecoration dreamStatBubble = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
  );

  /// Bolha de estatística no header — estado ativo (glow colorido)
  static BoxDecoration dreamStatBubbleActive(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.25),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10)],
  );

  /// Card de doação recebida
  static BoxDecoration dreamReceivedCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3), width: 2),
    boxShadow: [
      BoxShadow(
        color: AppTheme.accentGreen.withValues(alpha: 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Ícone (emoji) dentro do card de doação recebida
  static BoxDecoration dreamReceivedCardIcon = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppTheme.accentGreen.withValues(alpha: 0.18),
        AppTheme.accentTeal.withValues(alpha: 0.18),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
  );

  /// Badge "Atendido!" dentro do card de doação recebida
  static BoxDecoration dreamFulfilledBadge = BoxDecoration(
    color: AppTheme.accentGreen.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(20),
  );

  /// Botão "+ Adicionar" dentro do cabeçalho de seção
  static BoxDecoration dreamAddButton(Color color) => BoxDecoration(
    gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.75)]),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: 0.3),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );

  /// Container do estado vazio de seção (_EmptyState)
  static BoxDecoration dreamEmptyState(Color borderColor) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: borderColor.withValues(alpha: 0.4), width: 2),
    boxShadow: [
      BoxShadow(
        color: borderColor.withValues(alpha: 0.1),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════════
  // ADIÇÕES AO app_decorations.dart
  // Cole estes membros dentro da classe AppDecorations, antes do fechamento.
  // ═══════════════════════════════════════════════════════════════════════════════

  // ─── DonationCardWidget ───────────────────────────────────────────────────────

  /// Card de doação no grid (borda rosa sutil + sombra pink)
  static BoxDecoration donationCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppTheme.donationCardBorder, width: 1.5),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withValues(alpha: 0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Badge de status da doação (fundo sólido com cor dinâmica)
  static BoxDecoration donationStatusBadge = BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    // cor aplicada via `color:` no Container em runtime
  );

  /// Menu de edição flutuante sobre a imagem da doação (branco + sombra suave)
  static BoxDecoration donationEditMenuContainer = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  /// Painel inferior do fullscreen de doação (fundo escuro semitransparente)
  static const BoxDecoration donationFullscreenPanel = BoxDecoration(
    color: Color(0x99000000), // Colors.black.withValues(alpha: 0.6) — const
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  );

  /// Botão "Editar" dentro do fullscreen de doação
  static BoxDecoration donationFullscreenEditButton = BoxDecoration(
    gradient: AppTheme.donationEditButtonGradient,
    borderRadius: BorderRadius.circular(14),
  );

  /// Placeholder (sem imagem) do card de doação
  static BoxDecoration donationPlaceholder = BoxDecoration(
    color: AppTheme.donationPlaceholderBg,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
  );

  // ─── DreamFormSheet ───────────────────────────────────────────────────────────

  /// Handle bar do DreamFormSheet (igual ao donationFormHandle, criado para
  /// clareza semântica — ambos podem ser unificados se preferir)
  static BoxDecoration dreamFormHandle = BoxDecoration(
    color: AppTheme.dividerColor,
    borderRadius: BorderRadius.circular(4),
  );

  /// Container do ImagePicker do DreamFormSheet — estado sem imagem
  static BoxDecoration dreamImagePickerEmpty = BoxDecoration(
    color: AppTheme.dreamImagePickerBg,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppTheme.kidsPurple.withValues(alpha: 0.3), width: 1.5),
  );

  /// Container do ImagePicker do DreamFormSheet — estado com imagem
  /// (mantém mesmas bordas, sem fill colorido para não cobrir a foto)
  static BoxDecoration dreamImagePickerFilled = BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppTheme.kidsPurple.withValues(alpha: 0.3), width: 1.5),
  );

  /// Badge de edição sobre a imagem do picker (lápis escuro semitransparente)
  static BoxDecoration dreamImageEditBadge = BoxDecoration(
    color: Color(0x8C000000), // Colors.black.withValues(alpha: 0.55) — const-friendly
    borderRadius: BorderRadius.circular(10),
  );

  /// Placeholder quando a imagem de URL falha no picker
  static BoxDecoration dreamImagePickerPlaceholder = BoxDecoration(
    color: AppTheme.dreamImagePickerBg,
    borderRadius: BorderRadius.circular(17),
  );

  /// Emoji selecionado no picker de emojis do DreamFormSheet
  static BoxDecoration dreamEmojiSelected = BoxDecoration(
    color: AppTheme.kidsPurple.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.kidsPurple, width: 2),
  );

  /// Emoji não-selecionado no picker de emojis do DreamFormSheet
  static const BoxDecoration dreamEmojiUnselected = BoxDecoration(
    color: Color(0xFFF5F5F5),
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  /// Campo de texto do DreamFormSheet — borda habilitada (usando kidsPurple)
  static BoxDecoration dreamFieldEnabled = BoxDecoration(
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppTheme.kidsPurple, width: 1),
  );

  /// Botão salvar/publicar do DreamFormSheet — estado ativo
  static BoxDecoration dreamSaveButtonActive = BoxDecoration(
    gradient: AppTheme.dreamSaveButtonGradient,
    borderRadius: BorderRadius.circular(18),
  );

  // ═══════════════════════════════════════════════════════════════════════════════
  // ADIÇÕES AO app_decorations.dart — bloco "Perfil / Edit Profile / Children / Location"
  // Cole estes membros dentro da classe AppDecorations, antes do fechamento.
  // ═══════════════════════════════════════════════════════════════════════════════

  // ─── EditProfilePage ──────────────────────────────────────────────────────────

  /// Header com gradiente rosa→amarelo→roxo (EditProfilePage._buildHeader)
  static const BoxDecoration editProfileHeader = BoxDecoration(
    gradient: AppTheme.editProfileHeaderGradient,
  );

  /// Botão "voltar" circular semitransparente sobre o header
  static BoxDecoration editProfileBackButton = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.25),
    borderRadius: BorderRadius.circular(12),
  );

  /// Card branco de cada seção da tela de edição (Perfil / Filhos)
  static BoxDecoration editProfileSectionCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ],
  );

  /// Ícone (emoji) do cabeçalho de cada seção — gradiente pink→purple
  static BoxDecoration editProfileSectionIcon = BoxDecoration(
    gradient: AppTheme.pinkPurpleGradient,
    borderRadius: BorderRadius.circular(14),
  );

  /// Chip de seleção de sexo — estado selecionado/não selecionado
  static BoxDecoration editProfileSexoChip({required bool selected}) {
    return BoxDecoration(
      gradient: selected ? AppTheme.pinkPurpleGradient : null,
      color: selected ? null : AppTheme.surfaceNeutral,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: selected
            ? Colors.transparent
            : AppTheme.kidsPink.withValues(alpha: 0.2),
        width: 1.5,
      ),
    );
  }

  /// TextFormField de campo simples (nome, status) — borda habilitada/focada
  /// aplicada via InputDecoration; ver helper [editProfileFieldBorder].
  static OutlineInputBorder editProfileFieldBorder({required bool focused}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: focused
          ? const BorderSide(color: AppTheme.kidsPink, width: 2)
          : BorderSide(color: AppTheme.kidsPink.withValues(alpha: 0.2), width: 1.5),
    );
  }

  /// Botão "SALVAR ALTERAÇÕES" — estado ativo/loading
  static BoxDecoration editProfileSaveButton({required bool loading}) {
    return BoxDecoration(
      gradient: loading
          ? null
          : const LinearGradient(
              colors: [
                AppTheme.kidsPink,
                AppTheme.kidsYellow,
                AppTheme.kidsPurple,
              ],
            ),
      color: loading ? Colors.grey.shade400 : null,
      borderRadius: BorderRadius.circular(22),
      boxShadow: loading
          ? []
          : [
              BoxShadow(
                color: AppTheme.kidsPink.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
    );
  }

  // ─── ChildrenSection (edit) ───────────────────────────────────────────────────

  /// Card de filho na lista de edição — gradiente azul claro → amarelo claro
  static BoxDecoration childEditCard = BoxDecoration(
    gradient: AppTheme.childCardGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: AppTheme.childCardAccent.withValues(alpha: 0.15),
      width: 2,
    ),
  );

  /// Avatar/emoji do filho dentro do card de edição
  static BoxDecoration childEditAvatar = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: AppTheme.childCardAccent.withValues(alpha: 0.2),
      width: 2,
    ),
  );

  /// Botão "Adicionar filho"
  static BoxDecoration addChildButton = BoxDecoration(
    color: AppTheme.surfaceNeutral,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppTheme.kidsPink.withValues(alpha: 0.3), width: 2),
  );

  /// Emoji picker do formulário de filho — estado selecionado/não selecionado
  static BoxDecoration childEmojiOption({required bool selected}) {
    return BoxDecoration(
      color: selected
          ? AppTheme.kidsPink.withValues(alpha: 0.15)
          : AppTheme.surfaceNeutral,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: selected ? AppTheme.kidsPink : Colors.transparent,
        width: 2,
      ),
    );
  }

  /// Input de nome/idade no formulário de filho — com/sem erro
  static BoxDecoration childFormInput({required bool hasError}) {
    return BoxDecoration(
      color: hasError ? Colors.red.shade50 : AppTheme.surfaceBlueTint,
      borderRadius: BorderRadius.circular(14),
    );
  }

  /// Botão confirmar (Adicionar/Salvar) do formulário de filho
  static BoxDecoration childFormSubmitButton({required bool loading}) {
    return BoxDecoration(
      gradient: loading ? null : AppTheme.pinkPurpleGradient,
      color: loading ? Colors.grey.shade200 : null,
      borderRadius: BorderRadius.circular(18),
    );
  }

  /// Banner de erro de faixa etária inválida ("deve ter entre 0 e 17 anos")
  static BoxDecoration childAgeErrorBanner = BoxDecoration(
    color: Colors.red.shade50,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.red.shade200, width: 1.5),
  );

  static BoxDecoration childAgeErrorIcon = BoxDecoration(
    color: Colors.red.shade100,
    borderRadius: BorderRadius.circular(10),
  );

  // ─── LocationSection ──────────────────────────────────────────────────────────

  /// Container dos 3 dropdowns (Estado / Cidade / Bairro)
  static BoxDecoration locationFieldsBox = BoxDecoration(
    color: AppTheme.surfaceBlueTint,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppTheme.kidsPink.withValues(alpha: 0.2), width: 1.5),
  );

  /// Aviso âmbar "selecione o bairro na lista"
  static BoxDecoration locationNeighborhoodWarning = BoxDecoration(
    color: AppTheme.kidsYellow.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppTheme.kidsYellow.withValues(alpha: 0.5), width: 1.5),
  );

  /// Lista de sugestões de bairro (dropdown flutuante)
  static BoxDecoration locationSuggestionsBox = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppTheme.kidsPink.withValues(alpha: 0.2), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Preview do endereço confirmado (bairro, cidade, estado)
  static BoxDecoration locationAddressPreview = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppTheme.kidsPink.withValues(alpha: 0.08),
        AppTheme.kidsPurple.withValues(alpha: 0.08),
      ],
    ),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppTheme.kidsPink.withValues(alpha: 0.2)),
  );

  // ─── ProfilePhotoSection ──────────────────────────────────────────────────────

  /// Chip "Foto" / "Emoji" — estado selecionado/não selecionado
  static BoxDecoration photoModeChip({required bool selected}) {
    return BoxDecoration(
      gradient: selected ? AppTheme.pinkPurpleGradient : null,
      color: selected ? null : AppTheme.surfaceNeutral,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: selected
            ? Colors.transparent
            : AppTheme.kidsPink.withValues(alpha: 0.2),
        width: 1.5,
      ),
    );
  }

  /// Círculo de preview de foto/emoji de perfil (avatar grande no editor)
  static BoxDecoration photoPreviewCircle = BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.white,
    border: Border.all(color: AppTheme.kidsPink.withValues(alpha: 0.3), width: 3),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withValues(alpha: 0.2),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Badge da câmera sobre o avatar (canto inferior direito)
  static BoxDecoration photoCameraBadge = BoxDecoration(
    gradient: AppTheme.pinkPurpleGradient,
    shape: BoxShape.circle,
    border: Border.all(color: Colors.white, width: 3),
  );

  /// Placeholder de avatar sem foto (ícone de pessoa cinza)
  static BoxDecoration photoEmptyPlaceholder = BoxDecoration(
    color: AppTheme.surfaceBlueTint,
  );

  /// Opção dentro do bottom sheet "Escolher foto" (câmera / galeria / remover)
  static BoxDecoration photoSourceOption({Color? accentColor}) {
    final color = accentColor ?? AppTheme.kidsPink;
    return BoxDecoration(
      color: AppTheme.surfaceNeutral,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
    );
  }

  // ─── ProfileHeaderWidget ──────────────────────────────────────────────────────

  /// Fundo do header da ProfilePage (gradiente pink → magenta → purple)
  static const BoxDecoration profileHeaderBackground = BoxDecoration(
    gradient: AppTheme.profileHeaderGradient,
  );

  /// Botão de ícone (editar / configurações) no topo do header
  static BoxDecoration profileHeaderIconButton = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.2),
  );

  /// Avatar do header — borda dourada se totalmente verificado
  static BoxDecoration profileAvatarRing({required bool verified}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      border: Border.all(
        color: verified ? AppTheme.kidsYellow : Colors.white,
        width: verified ? 3.5 : 3,
      ),
      boxShadow: [
        BoxShadow(
          color: verified
              ? AppTheme.kidsYellow.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.2),
          blurRadius: verified ? 20 : 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  /// Chip de verificação (verde se verificado, translúcido se não)
  static BoxDecoration verificationChip({required bool verified}) {
    return BoxDecoration(
      color: verified
          ? AppTheme.kidsGreen.withValues(alpha: 0.2)
          : Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: verified ? AppTheme.kidsGreen : Colors.white38,
        width: 1.5,
      ),
    );
  }

  /// Badge "Verificar" dentro do chip de verificação
  static BoxDecoration verificationBadge = BoxDecoration(
    color: AppTheme.kidsYellow,
    borderRadius: BorderRadius.circular(6),
  );

  /// Container da linha de meta-informações (idade, gênero, localização)
  static BoxDecoration profileMetaRow = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(16),
  );

  /// Banner de status (frase pessoal do usuário) no header
  static BoxDecoration profileStatusBanner = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ─── VerificationSheetWidget ──────────────────────────────────────────────────

  /// Ícone circular principal do sheet de verificação
  static BoxDecoration verificationSheetIcon({required bool verified}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: verified
          ? AppTheme.verifiedStepGradient
          : AppTheme.pinkPurpleGradient,
    );
  }

  /// Card de cada etapa (e-mail / perfil completo) — concluída ou pendente
  static BoxDecoration verificationStepCard({required bool done}) {
    return BoxDecoration(
      color: done ? AppTheme.kidsGreen.withValues(alpha: 0.05) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: done
            ? AppTheme.kidsGreen.withValues(alpha: 0.4)
            : AppTheme.dividerColor,
        width: 1.5,
      ),
    );
  }

  /// Ícone de cada etapa dentro do card (gradiente verde se concluída)
  static BoxDecoration verificationStepIcon({required bool done}) {
    return BoxDecoration(
      gradient: done
          ? AppTheme.verifiedStepGradient
          : AppTheme.pinkPurpleGradient,
      borderRadius: BorderRadius.circular(12),
    );
  }

  /// Banner "Você é um membro verificado!" no final do sheet
  static BoxDecoration verifiedMemberBanner = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppTheme.kidsGreen.withValues(alpha: 0.15),
        AppTheme.kidsYellow.withValues(alpha: 0.1),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppTheme.kidsGreen.withValues(alpha: 0.4), width: 1.5),
  );

  // ─── Handles de bottom sheet (genérico) ──────────────────────────────────────
  // Reaproveita o padrão já usado em donationFormHandle/dreamFormHandle/
  // imageSourceHandle — ver alias abaixo para os novos usos.

  /// Alias semântico para o handle do sheet de filho e do sheet de foto.
  /// Reaproveita a mesma decoração de [donationFormHandle].
  static BoxDecoration get sheetHandle => donationFormHandle;
  // ─── DreamFormSheet / verificação ────────────────────────────────────────────

  /// Decoração do handle do mini bottom sheet de seleção de fonte de imagem
  static BoxDecoration imageSourceHandle = BoxDecoration(
    color: AppTheme.dividerColor,
    borderRadius: BorderRadius.circular(4),
  );

  // ─── DreamPage — _DreamHeader ─────────────────────────────────────────────────

  /// Container do ícone de título do header (fundo branco semitransparente)
  static BoxDecoration dreamHeaderIconBox = BoxDecoration(
    color: Color(0x33FFFFFF), // Colors.white.withValues(alpha: 0.2) — const-friendly
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );

  // ─── DreamPage — _SectionWrapper ─────────────────────────────────────────────

  /// Chip de contagem de itens em _SectionWrapper (cor dinâmica)
  /// Use assim:  dreamSectionCountChip(color)
  static BoxDecoration dreamSectionCountChip(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(20),
  );
  // ─── Estilos de texto reutilizáveis ──────────────────────────────────────────

  static Paint textShader(List<Color> colors, {double width = 300}) {
    return Paint()
      ..shader = LinearGradient(
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, width, 70));
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // ADIÇÕES — HomePage, SettingsPage, AccountInformation, EmailVerification,
  //           VerificationBlockDialog, ChangePassword
  // ═══════════════════════════════════════════════════════════════════════════════

  // ─── HomePage ─────────────────────────────────────────────────────────────────

  /// Header azul da HomePage (EMPATIA + saudação)
  static const BoxDecoration homeHeader = BoxDecoration(
    gradient: AppTheme.homeHeaderGradient,
  );

  /// Container do indicador de notificação no header da HomePage
  static BoxDecoration homeNotificationBadge = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.2),
    borderRadius: BorderRadius.circular(12),
  );

  /// Card de ad do carrossel da HomePage (cor dinâmica via parâmetro)
  static BoxDecoration homeAdCard(List<Color> colors) => BoxDecoration(
    gradient: LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: colors[0].withValues(alpha: 0.3),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Indicador de página ativo do carrossel
  static BoxDecoration homePageIndicatorActive = BoxDecoration(
    color: AppTheme.primaryBlueMid,
    borderRadius: BorderRadius.circular(4),
  );

  /// Card de sonho na HomePage (branco com sombra suave)
  static BoxDecoration homeDreamCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Avatar do sonho na HomePage (gradiente pink → deep pink)
  static const BoxDecoration homeDreamAvatar = BoxDecoration(
    gradient: AppTheme.homeDreamAvatarGradient,
    borderRadius: BorderRadius.all(Radius.circular(15)),
  );

  /// Área de imagem/emoji do sonho na HomePage
  static BoxDecoration homeDreamImageArea = BoxDecoration(
    gradient: LinearGradient(
      colors: [AppTheme.childCardBg, const Color(0xFFFFF9E6)],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: AppTheme.primaryBlueMid.withValues(alpha: 0.2),
      width: 2,
    ),
  );

  /// Badge de progresso do sonho (cor dinâmica por nível)
  static BoxDecoration homeDreamProgressBadge(List<Color> colors) =>
      BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(15),
      );

  /// Botão "Salvar" na HomePage
  static BoxDecoration homeSaveButton = BoxDecoration(
    gradient: AppTheme.homeSaveButtonGradient,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsYellow.withValues(alpha: 0.3),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ─── SettingsPage ─────────────────────────────────────────────────────────────

  /// Header da SettingsPage (pink → yellow → purple)
  static const BoxDecoration settingsHeader = BoxDecoration(
    gradient: AppTheme.settingsHeaderGradient,
  );

  /// Card genérico de seção na SettingsPage (branco com sombra)
  static BoxDecoration settingsSectionCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Botão de logout (outline vermelho)
  static BoxDecoration settingsLogoutButton = BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.red.shade200, width: 1.5),
  );

  /// Card de conta estilo Instagram (gradiente kids rainbow)
  static const BoxDecoration settingsAccountCard = BoxDecoration(
    gradient: AppTheme.settingsHeaderGradient,
  );

  // ─── AccountInformationPage / ChangeEmailSheet ────────────────────────────────

  /// Header azul-violeta das telas de informações de conta
  static const BoxDecoration accountInfoHeader = BoxDecoration(
    gradient: AppTheme.infoHeaderGradient,
  );

  /// Indicador de loading (circular) nas telas de informações de conta
  static BoxDecoration accountInfoSkeleton = BoxDecoration(
    color: Colors.grey.shade200,
    borderRadius: BorderRadius.circular(24),
  );

  // ─── EmailChangedPage ─────────────────────────────────────────────────────────

  /// Card do banner "Email enviado!" — branco com sombra cyan
  static BoxDecoration emailChangedCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(40),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsCyan.withValues(alpha: 0.3),
        blurRadius: 40,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: AppTheme.kidsGreen.withValues(alpha: 0.2),
        blurRadius: 50,
        spreadRadius: 5,
        offset: const Offset(0, 15),
      ),
    ],
  );

  /// Header do card "Email enviado!" (gradiente verde-água suave)
  static const BoxDecoration emailChangedCardHeader = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFFE6FFF0), Color(0xFFE6F7FF)],
    ),
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );

  /// Chip de e-mail de destino (gradiente blue → violet)
  static BoxDecoration emailChangedChip = BoxDecoration(
    gradient: AppTheme.accountButtonGradient,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppTheme.primaryBlueMid.withValues(alpha: 0.3),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  /// Container de cada step de instrução (borda azul suave)
  static BoxDecoration emailChangedStepBox = BoxDecoration(
    color: AppTheme.primaryBlueMid.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(
      color: AppTheme.primaryBlueMid.withValues(alpha: 0.3),
      width: 2,
    ),
  );

  /// Caixa de alerta âmbar (email_changed — "link expira")
  static BoxDecoration emailChangedAmberAlert = BoxDecoration(
    color: AppTheme.alertAmberBg,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppTheme.alertAmberBorder, width: 2),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsYellow.withValues(alpha: 0.25),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Banner "Email reenviado com sucesso!" (verde claro)
  static BoxDecoration emailChangedResentBanner = BoxDecoration(
    color: AppTheme.verifiedEmailBg,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppTheme.verifiedEmailBorder, width: 1.5),
  );

  // ─── EmailVerificationPage ────────────────────────────────────────────────────

  /// Fundo da EmailVerificationPage (pastel triplo)
  static const BoxDecoration emailVerifBackground = BoxDecoration(
    gradient: LinearGradient(
      colors: [AppTheme.bgPastelPurple, AppTheme.bgPastelPink, AppTheme.bgPastelBlue],
    ),
  );

  /// Card de dica/hint lavanda
  static BoxDecoration emailVerifHintCard = BoxDecoration(
    color: AppTheme.bgPastelLavender,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppTheme.borderLavender, width: 1.5),
  );

  /// Botão principal da EmailVerificationPage (pink → roxo médio)
  static BoxDecoration emailVerifButton = BoxDecoration(
    gradient: AppTheme.pinkPurpleMidGradient,
    borderRadius: BorderRadius.circular(32),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withValues(alpha: 0.45),
        blurRadius: 25,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Badge de sucesso de verificação (verde claro circular)
  static BoxDecoration emailVerifSuccessBadge = BoxDecoration(
    color: AppTheme.kidsGreen.withValues(alpha: 0.1),
    shape: BoxShape.circle,
    border: Border.all(color: AppTheme.kidsGreen.withValues(alpha: 0.4)),
  );

  // ─── AccountSettingsPage (verificação de conta) ───────────────────────────────

  /// Header da AccountSettingsPage (pink → yellow → purple — mesmo do settings)
  static const BoxDecoration accountSettingsHeader = BoxDecoration(
    gradient: AppTheme.settingsHeaderGradient,
  );

  /// Card "hero" de verificação (gradiente settings)
  static const BoxDecoration accountSettingsHeroCard = BoxDecoration(
    gradient: AppTheme.settingsHeaderGradient,
  );

  /// Badge de status de verificação de e-mail (activo/inativo)
  static BoxDecoration accountSettingsStatusBadge({required bool verified}) {
    return BoxDecoration(
      color: verified
          ? AppTheme.kidsGreenDeep.withValues(alpha: 0.1)
          : AppTheme.kidsPink.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    );
  }

  // ─── ChangePasswordPage ───────────────────────────────────────────────────────

  /// Fundo do ícone principal de troca de senha (branco + brilho roxo/pink)
  static BoxDecoration changePasswordIcon = BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPurple.withValues(alpha: 0.5),
        blurRadius: 40,
        spreadRadius: 8,
      ),
      BoxShadow(
        color: AppTheme.kidsPink.withValues(alpha: 0.35),
        blurRadius: 50,
        spreadRadius: 12,
      ),
    ],
  );

  /// Ícone interno de cadeado (gradiente roxo → pink)
  static const BoxDecoration changePasswordIconInner = BoxDecoration(
    shape: BoxShape.circle,
    gradient: AppTheme.changePasswordHeaderGradient,
  );

  /// Card branco de conteúdo (troca de senha)
  static BoxDecoration changePasswordCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(40),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPurple.withValues(alpha: 0.3),
        blurRadius: 40,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: AppTheme.kidsPink.withValues(alpha: 0.2),
        blurRadius: 50,
        spreadRadius: 5,
        offset: const Offset(0, 15),
      ),
    ],
  );

  /// Campo de senha (troca) com acent dinâmico
  static BoxDecoration changePasswordField({required Color accentColor}) {
    return BoxDecoration(
      color: accentColor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
    );
  }

  /// Botão "Alterar senha" ativo (roxo → pink)
  static BoxDecoration changePasswordButton = BoxDecoration(
    gradient: AppTheme.changePasswordHeaderGradient,
    borderRadius: BorderRadius.circular(32),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPurple.withValues(alpha: 0.5),
        blurRadius: 25,
        spreadRadius: 2,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Caixa de erro (sheet_components / change_password)
  static BoxDecoration sheetErrorBox = BoxDecoration(
    color: AppTheme.errorRedBg,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppTheme.errorRedBorder, width: 1),
  );

  // ─── VerificationBlockDialog ──────────────────────────────────────────────────

  /// Dialog de verificação obrigatória (branco + sombra pink/purple)
  static BoxDecoration verificationBlockDialog = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: AppTheme.kidsPink.withValues(alpha: 0.18),
        blurRadius: 40,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: AppTheme.kidsPurple.withValues(alpha: 0.10),
        blurRadius: 60,
        offset: const Offset(0, 24),
      ),
    ],
  );

  /// Banner gradiente do topo do VerificationBlockDialog
  static const BoxDecoration verificationBlockBanner = BoxDecoration(
    gradient: AppTheme.pinkPurpleGradient,
  );

  /// Ícone emoji em badge no VerificationBlockDialog (_InfoRow)
  static BoxDecoration verificationBlockInfoBadge = BoxDecoration(
    color: AppTheme.kidsPink.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(10),
  );

  /// Botão principal do VerificationBlockDialog
  static const BoxDecoration verificationBlockButton = BoxDecoration(
    gradient: AppTheme.pinkPurpleGradient,
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
}
  
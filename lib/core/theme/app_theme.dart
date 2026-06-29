import 'package:flutter/material.dart';

class AppTheme {
  // ─── Cores principais ────────────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color primaryBlueMid = Color(0xFF2563EB);   // <<NOVO>> azul médio (headers, gradientes)
  static const Color primaryBlueLight = Color(0xFF3B82F6); // <<NOVO>> azul claro (gradientes)
  static const Color accentTeal = Color(0xFF4DB8C4);
  static const Color accentYellow = Color(0xFFFBD346);
  static const Color accentPink = Color(0xFFE91E63);
  static const Color accentOrange = Color(0xFFFFA726);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentGreen = Color(0xFF4CAF50);

  // ─── Paleta "kids" (usada nas telas de auth e success) ───────────────────────
  static const Color kidsPink = Color(0xFFFF6B9D);
  static const Color kidsPinkDeep = Color(0xFFFF1493);
  static const Color kidsPinkMagenta = Color(0xFFE040A0); // <<NOVO>> magenta usado em profileHeaderGradient
  static const Color kidsYellow = Color(0xFFFFC837);      // <<NOVO>> amarelo padrão kids (era FFC837)
  static const Color kidsYellowGold = Color(0xFFFFD700);
  static const Color kidsPurple = Color(0xFF8B5CF6);
  static const Color kidsPurpleLight = Color(0xFFA78BFA);
  static const Color kidsPurpleMid = Color(0xFFA855F7);   // <<NOVO>> roxo médio (email_verification, change_password)
  static const Color kidsPurpleViolet = Color(0xFF7C3AED); // <<NOVO>> violeta profundo (account_information, email_changed)
  static const Color kidsPurpleIndigo = Color(0xFF6366F1); // <<NOVO>> índigo (email_verification sweep)
  static const Color kidsCyan = Color(0xFF06B6D4);
  static const Color kidsCyanLight = Color(0xFF0EA5E9);
  static const Color kidsGreen = Color(0xFF4ADE80);
  static const Color kidsGreenDeep = Color(0xFF22C55E);
  static const Color kidsGreenDark = Color(0xFF16A34A);    // <<NOVO>> verde escuro de sucesso (change_password snackbar)

  /// Usado em avisos/warnings (texto + ícone de "link expira")
  static const Color kidsAmber = Color(0xFFB45309);

  /// Usado em cabeçalhos de avisos (título da caixa "link expira")
  static const Color kidsAmberDark = Color(0xFF92400E);

  // ─── Cores de erro ───────────────────────────────────────────────────────────
  static const Color errorRed = Color(0xFFFF6B6B);
  static const Color errorRedDeep = Color(0xFFFF4444);
  static const Color errorRedStrong = Color(0xFFDC2626);   // <<NOVO>> vermelho forte (sheet_components, change_password)
  static const Color errorRedBg = Color(0xFFFEE2E2);       // <<NOVO>> fundo de erro (sheet_components)
  static const Color errorRedBorder = Color(0xFFFECACA);   // <<NOVO>> borda de erro (sheet_components)

  // ─── Cores de status/medalha ─────────────────────────────────────────────────
  static const Color bronzeMedal = Color(0xFFCD7F32);
  static const Color goldMedal = Color(0xFFFFD700);
  static const Color diamondLevel = Color(0xFF1E3A8A);

  // ─── Cores neutras ───────────────────────────────────────────────────────────
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textNavy = Color(0xFF1E293B);          // <<NOVO>> navy escuro (email_changed, change_password)
  static const Color textSlate = Color(0xFF334155);          // <<NOVO>> slate (email_changed secundário)
  static const Color textCharcoal = Color(0xFF374151);       // <<NOVO>> carvão (verification_block_dialog, email_verif)
  static const Color textGrayMid = Color(0xFF6B7280);        // <<NOVO>> cinza médio (email_verification)
  static const Color textDarkGray = Color(0xFF1F2937);       // <<NOVO>> quase-preto (sheet_components, change_phone)
  static const Color textAmberWarn = Color(0xFFD97706);      // <<NOVO>> texto âmbar de aviso (email_changed)
  static const Color textMuted = Color(0xFF888888);
  static const Color textSubtle = Color(0xFF555555);

  /// Fundo claro de campos de input (fillColor)
  static const Color surfaceLight = Color(0xFFFAFAFA);

  /// Branco puro para superfícies e containers
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  /// Fundo levemente azulado de inputs e pickers
  static const Color surfaceBlueTint = Color(0xFFF8F8FF);

  /// Fundo neutro cinza-claro de chips/botões não selecionados
  static const Color surfaceNeutral = Color(0xFFF5F5F5);

  /// Placeholder de avatar sem foto
  static const Color placeholderIcon = Color(0xFFD1D5DB);

  // ─── Sombras ─────────────────────────────────────────────────────────────────

  /// Sombra genérica semitransparente
  static const Color shadowDark = Color(0x55000000);

  /// Sombra suave (cards e containers)
  static const Color shadowColor = Color(0x1A000000);

  // ─── Cores de perfil ─────────────────────────────────────────────────────────
  /// Fundo da ProfilePage
  static const Color profileBackground = Color(0xFFF7F8FC);

  /// Linha divisória entre seções do perfil
  static const Color dividerColor = Color(0xFFEEEEEE);

  /// Verde escuro usado em textos de "etapa concluída" / "membro verificado"
  static const Color verifiedTextDark = Color(0xFF166534);

  // ─── Cores de localização / filhos ───────────────────────────────────────────
  /// Azul usado nos cards de filhos e ícones de localização confirmada
  static const Color childCardAccent = Color(0xFF2563EB);

  /// Fundo azul claro do avatar/emoji de filho
  static const Color childCardBg = Color(0xFFE0F2FE);

  // ─── Cores da DreamPage ───────────────────────────────────────────────────────
  /// Fundo do Scaffold da DreamPage
  static const Color dreamBackground = Color(0xFFF0F8FF);

  // ─── Cores de status de doação ────────────────────────────────────────────────
  /// Cor do badge "reservado" em DonationCardWidget
  static const Color donationReservedColor = Color(0xFFF59E0B);

  /// Fundo do placeholder/picker de imagem de doação e sonho
  static const Color dreamImagePickerBg = Color(0xFFF5F0FF);

  /// Borda sutil rosa usada no card de doação
  static const Color donationCardBorder = Color(0xFFFCE7F3);

  /// Fundo do card de doação no placeholder
  static const Color donationPlaceholderBg = Color(0xFFFCE7F3);

  // ─── Cores de verificação / account_settings ─────────────────────────────────
  /// Fundo do card de e-mail verificado (verde bem claro)
  static const Color verifiedEmailBg = Color(0xFFD1FAE5);   // <<NOVO>>

  /// Borda do card de e-mail verificado (verde água)
  static const Color verifiedEmailBorder = Color(0xFF6EE7B7); // <<NOVO>>

  /// Texto de sucesso da verificação de e-mail
  static const Color verifiedEmailText = Color(0xFF059669);  // <<NOVO>>

  /// Texto escuro de instruções de verificação
  static const Color verifiedEmailTextDark = Color(0xFF065F46); // <<NOVO>>

  // ─── Cores de email_verification / fundo pastel ──────────────────────────────
  /// Fundo lilás/roxo muito claro (email_verification background)
  static const Color bgPastelPurple = Color(0xFFFDF2FF);    // <<NOVO>>

  /// Fundo rosa muito claro
  static const Color bgPastelPink = Color(0xFFFFF0F7);      // <<NOVO>>

  /// Fundo azul muito claro
  static const Color bgPastelBlue = Color(0xFFF0F4FF);      // <<NOVO>>

  /// Fundo lilás leve (card de dica/hint em email_verification)
  static const Color bgPastelLavender = Color(0xFFFDF4FF);  // <<NOVO>>

  /// Borda lilás clara de dicas
  static const Color borderLavender = Color(0xFFE9D5FF);    // <<NOVO>>

  // ─── Cores de âmbar / alerta ─────────────────────────────────────────────────
  /// Fundo âmbar claro para alertas suaves
  static const Color alertAmberBg = Color(0xFFFFFBEB);      // <<NOVO>>

  /// Borda âmbar de alertas
  static const Color alertAmberBorder = Color(0xFFFCD34D);  // <<NOVO>>

  // ─── Cores da Home ────────────────────────────────────────────────────────────
  /// Borda azul sutil do card de sonho na HomePage
  static const Color homeDreamCardBorderBg = Color(0xFFE0F2FE); // <<NOVO>> (já existe como childCardBg — alias semântico)

  // ─── Gradientes da DreamPage ──────────────────────────────────────────────────
  /// Gradiente do header da DreamPage (SliverAppBar background)
  static const LinearGradient dreamHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, accentTeal, accentPurple],
    stops: [0.0, 0.55, 1.0],
  );

  /// Gradiente do divisor decorativo entre seções (_FunDivider)
  static const List<Color> dreamDividerColors = [accentTeal, accentGreen];

  // ─── Pares de gradiente (campo email, senha, etc.) ───────────────────────────
  static const List<Color> gradientEmail = [kidsCyan, kidsCyanLight];
  static const List<Color> gradientPassword = [kidsPurple, kidsPurpleLight];
  static const List<Color> gradientConfirm = [kidsPink, kidsPinkDeep];

  // ─── Gradientes reutilizáveis ────────────────────────────────────────────────
  static const LinearGradient rainbowGradient = LinearGradient(
    colors: [
      Color(0xFFE91E63),
      Color(0xFFFBD346),
      Color(0xFF4CAF50),
      Color(0xFF4DB8C4),
      Color(0xFF9C27B0),
      Color(0xFFFFA726),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Arco-íris kids — usado na barra do topo dos cards e em outros detalhes
  static const LinearGradient kidsRainbow = LinearGradient(
    colors: [kidsPink, kidsYellow, kidsGreen, kidsCyan, kidsPurple, kidsPink],
  );

  /// Fundo da LoginPage
  static const LinearGradient loginBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsPink, kidsYellow, kidsPurple, kidsCyan],
    stops: [0.0, 0.3, 0.6, 1.0],
  );

  /// Fundo da RegisterPage
  static const LinearGradient registerBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsYellow, kidsPink, kidsPurple, kidsGreen],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  /// Fundo da SuccessPage
  static const LinearGradient successBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsGreen, kidsCyan, kidsPurple, kidsYellow],
    stops: [0.0, 0.3, 0.6, 1.0],
  );

  /// Gradiente do botão principal de login
  static const LinearGradient loginButtonGradient = LinearGradient(
    colors: [kidsPink, kidsPinkDeep, kidsPink],
  );

  /// Gradiente do botão principal de registro
  static const LinearGradient registerButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsYellow, kidsYellowGold, Color(0xFFFFAA00), kidsYellow],
  );

  /// Gradiente do botão "Criar conta nova" (dentro da LoginPage)
  static const LinearGradient createAccountGradient = LinearGradient(
    colors: [kidsYellow, kidsYellowGold],
  );

  /// Gradiente do botão "Entrar" (dentro da RegisterPage)
  static const LinearGradient loginLinkGradient = LinearGradient(
    colors: [kidsCyan, kidsCyanLight],
  );

  /// Fundo do título "Oi, amiguinho!" na LoginPage
  static const LinearGradient loginTitleBackground = LinearGradient(
    colors: [Color(0xFFFFF9E6), Color(0xFFFFE6F0)],
  );

  /// Fundo do título "Vem com a gente!" na RegisterPage
  static const LinearGradient registerTitleBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFBE6), Color(0xFFFFE6F0), Color(0xFFF3E8FF)],
  );

  // ─── Gradientes de erro ──────────────────────────────────────────────────────
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFFFE6E6), Color(0xFFFFF0F0)],
  );

  // ─── Gradientes do ícone sweep (anel girando) ────────────────────────────────
  static const SweepGradient logoSweep = SweepGradient(
    colors: [kidsPink, kidsYellow, kidsGreen, kidsCyan, kidsPurple, kidsPink],
  );

  static const SweepGradient registerLogoSweep = SweepGradient(
    colors: [kidsYellow, kidsPink, kidsPurple, kidsGreen, kidsCyan, kidsYellow],
  );

  static const SweepGradient successIconSweep = SweepGradient(
    colors: [
      kidsGreen,
      kidsCyan,
      kidsPurple,
      kidsYellow,
      Color(0xFFFF6B9D),
      kidsGreen,
    ],
  );

  // ─── Gradientes da ForgotPasswordPage ───────────────────────────────────────
  static const LinearGradient forgotInstructionsBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsCyan, kidsGreen, kidsPurple, kidsPink],
    stops: [0.0, 0.3, 0.65, 1.0],
  );

  static const LinearGradient forgotSendButtonGradient = LinearGradient(
    colors: [kidsPink, kidsPurple],
  );

  static const LinearGradient forgotBackButtonGradient = LinearGradient(
    colors: [kidsGreen, kidsCyan],
  );

  static const LinearGradient forgotEmailChipGradient = LinearGradient(
    colors: [kidsCyan, kidsGreen],
  );

  // ─── Gradientes da AgeVerificationPage ───────────────────────────────────────
  static const LinearGradient ageVerificationHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsPink, kidsYellow],
  );

  static const LinearGradient ageVerificationInfoBadgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsPink, kidsYellow],
  );

  static const LinearGradient ageVerificationSuccessBadgeGradient =
      LinearGradient(colors: [kidsGreen, kidsGreenDeep]);

  static const LinearGradient ageVerificationSubmitButtonGradient =
      LinearGradient(colors: [kidsPink, kidsYellow]);

  static const SweepGradient forgotInstructionsSweep = SweepGradient(
    colors: [kidsCyan, kidsGreen, kidsPurple, kidsPink, kidsCyan],
  );

  static const LinearGradient forgotEmailIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsCyan, kidsGreen],
  );

  static const LinearGradient forgotEmailBadgeGradient = LinearGradient(
    colors: [kidsCyan, kidsGreen],
  );

  // ─── Gradientes da HomePage ───────────────────────────────────────────────────
  /// Header azul da HomePage (EMPATIA + saudação)
  static const LinearGradient homeHeaderGradient = LinearGradient(      // <<NOVO>>
    colors: [primaryBlue, primaryBlueMid],
  );

  /// Gradiente para ad card azul (carrossel)
  static const List<Color> homeAdBlue = [primaryBlue, primaryBlueLight]; // <<NOVO>>

  /// Gradiente para ad card rosa/pink (carrossel)
  static const List<Color> homeAdPink = [kidsPink, kidsPinkDeep];        // <<NOVO>>

  /// Gradiente para ad card roxo (carrossel)
  static const List<Color> homeAdPurple = [kidsPurple, kidsPurpleLight]; // <<NOVO>>

  /// Gradiente do avatar do sonho na HomePage
  static const LinearGradient homeDreamAvatarGradient = LinearGradient(  // <<NOVO>>
    colors: [kidsPink, kidsPinkDeep],
  );

  /// Gradiente do botão "Salvar" na HomePage
  static const LinearGradient homeSaveButtonGradient = LinearGradient(   // <<NOVO>>
    colors: [kidsYellow, kidsYellowGold],
  );

  /// Cores de progresso (alta / média / baixa)
  static const List<Color> progressHigh = [kidsGreen, kidsGreenDeep];   // <<NOVO>>
  static const List<Color> progressMid = [kidsYellow, kidsYellowGold];  // <<NOVO>>
  static const List<Color> progressLow = [kidsPink, kidsPinkDeep];      // <<NOVO>>

  // ─── Gradientes de Settings ────────────────────────────────────────────────
  /// Header da SettingsPage (pink → yellow → purple)
  static const LinearGradient settingsHeaderGradient = LinearGradient(   // <<NOVO>>
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsPink, kidsYellow, kidsPurple],
  );

  // ─── Gradientes de AccountInformation / EmailChanged ──────────────────────
  /// Header azul-violeta (AccountInformationPage, ChangeEmailSheet)
  static const LinearGradient infoHeaderGradient = LinearGradient(       // <<NOVO>>
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlueMid, kidsPurpleViolet],
  );

  /// Gradiente de botão/ícone de conta (azul → violeta)
  static const LinearGradient accountButtonGradient = LinearGradient(    // <<NOVO>>
    colors: [primaryBlueMid, kidsPurpleViolet],
  );

  // ─── Gradientes de EmailVerification / AccountSettings ────────────────────
  /// Gradiente pink → roxo médio (usado em email_verification e account_settings)
  static const LinearGradient pinkPurpleMidGradient = LinearGradient(    // <<NOVO>>
    colors: [kidsPink, kidsPurpleMid],
  );

  /// Sweep de verificação de e-mail (pink → purple → indigo)
  static const SweepGradient emailVerifSweep = SweepGradient(            // <<NOVO>>
    colors: [kidsPink, kidsPurpleMid, kidsPurpleIndigo, kidsPink],
  );

  // ─── Gradientes de ChangePassword ─────────────────────────────────────────
  /// Sweep de troca de senha (purple → pink → yellow → cyan)
  static const SweepGradient changePasswordSweep = SweepGradient(        // <<NOVO>>
    colors: [kidsPurple, kidsPink, kidsYellow, kidsCyan, kidsPurple],
  );

  /// Gradiente do header de troca de senha (roxo → pink)
  static const LinearGradient changePasswordHeaderGradient = LinearGradient( // <<NOVO>>
    colors: [kidsPurple, kidsPink],
  );

  // ─── Gradientes de doação ─────────────────────────────────────────────────
  static const LinearGradient donationEditButtonGradient = LinearGradient(
    colors: [kidsPink, Color(0xFFFF8FB3)],
  );

  static const LinearGradient dreamSaveButtonGradient = LinearGradient(
    colors: [kidsPurple, Color(0xFFBB86FC)],
  );

  // ─── Gradientes de perfil ─────────────────────────────────────────────────
  static const LinearGradient profileHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsPink, kidsPinkMagenta, kidsPurple],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient editProfileHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsPink, kidsYellow, kidsPurple],
  );

  static const LinearGradient pinkPurpleGradient = LinearGradient(
    colors: [kidsPink, kidsPurple],
  );

  static const LinearGradient childCardGradient = LinearGradient(
    colors: [childCardBg, Color(0x80FFF9E6)],
  );

  static const LinearGradient verifiedStepGradient = LinearGradient(
    colors: [kidsGreen, kidsGreenDeep],
  );

  // ─── Emojis da DreamPage / DreamFormSheet ────────────────────────────────────
  static const List<String> dreamEmojiOptions = [
    '💭', '🌟', '🏠', '🚗', '✈️', '📚', '💪', '🎓',
    '❤️', '🌱', '🎯', '💼', '🎨', '🏋️', '🧘', '🌈',
  ];

  // ─── ThemeData ───────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        secondary: accentYellow,
        surface: cardBackground,
        background: backgroundColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentYellow,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: accentTeal, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
      ),
    );
  }
  // ════════════════════════════════════════════════════════════════════════════
// SUBSTITUA o bloco "─── Cores do Ranking ───" e "─── Gradientes do Ranking ───"
// dentro de class AppTheme { ... } pelo conteúdo abaixo.
// Remova também as constantes rankingNavy, rankingNavyMid, rankingPurple,
// rankingNavyBlue, rankingBronzeDark, rankingBronzeMid que ficavam lá.
// ════════════════════════════════════════════════════════════════════════════

  // ─── Cores do Ranking ────────────────────────────────────────────────────────

  /// Prata (medalha 2°)
  static const Color silverMedal = Color(0xFFB0BEC5);

  /// Fundo branco suave do Scaffold da RankingPage
  static const Color rankingBackground = Color(0xFFFDF4FF); // bgPastelPurple

  /// Cor do spinner e pill de countdown na RankingPage
  static const Color rankingAccent = kidsPurple;

  /// Cor do RefreshIndicator da RankingPage
  static const Color rankingRefreshColor = kidsYellowGold;

  // ─── Gradientes do Ranking ───────────────────────────────────────────────────

  /// Header da RankingPage — pink → amarelo → roxo (mesmo padrão do app)
  static const LinearGradient rankingHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsPink, kidsYellow, kidsPurple],
    stops: [0.0, 0.50, 1.0],
  );

  /// Slide 1° lugar — pink quente → laranja → dourado
  static const LinearGradient rankingSlide1Gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsPink, accentOrange, kidsYellowGold],
    stops: [0.0, 0.55, 1.0],
  );

  /// Slide 2° lugar — roxo → pink
  static const LinearGradient rankingSlide2Gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsPurple, kidsPink],
  );

  /// Slide 3° lugar — ciano → azul
  static const LinearGradient rankingSlide3Gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsCyan, kidsCyanLight],
  );

  /// Banner motivacional do usuário logado (UserPositionBanner)
  static const LinearGradient rankingUserBannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsPurple, kidsPink],
  );

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Gradiente correto por posição no carrossel.
  /// Uso: AppTheme.rankingSlideGradient(position)
  static LinearGradient rankingSlideGradient(int pos) {
    if (pos == 1) return rankingSlide1Gradient;
    if (pos == 2) return rankingSlide2Gradient;
    return rankingSlide3Gradient;
  }

  /// Cor de medalha por posição.
  /// Uso: AppTheme.rankingMedalColor(position)
  static Color rankingMedalColor(int pos) {
    if (pos == 1) return kidsYellowGold; // dourado
    if (pos == 2) return silverMedal;    // prata
    return bronzeMedal;                  // bronze
  }

  /// Cor de texto sobre medalha por posição (contraste garantido).
  /// Uso: AppTheme.rankingMedalTextColor(position)
  static Color rankingMedalTextColor(int pos) {
    if (pos == 1) return kidsAmber;      // âmbar escuro sobre dourado
    if (pos == 2) return textNavy;       // navy sobre prata
    return accentOrange;                 // laranja sobre bronze
  }

}
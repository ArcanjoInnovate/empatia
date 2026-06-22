import 'package:flutter/material.dart';

class AppTheme {
  // ─── Cores principais ────────────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color accentTeal = Color(0xFF4DB8C4);
  static const Color accentYellow = Color(0xFFFBD346);
  static const Color accentPink = Color(0xFFE91E63);
  static const Color accentOrange = Color(0xFFFFA726);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentGreen = Color(0xFF4CAF50);

  // ─── Paleta "kids" (usada nas telas de auth e success) ───────────────────────
  static const Color kidsPink = Color(0xFFFF6B9D);
  static const Color kidsPinkDeep = Color(0xFFFF1493);
  static const Color kidsYellow = Color(0xFFFFC837);
  static const Color kidsYellowGold = Color(0xFFFFD700);
  static const Color kidsPurple = Color(0xFF8B5CF6);
  static const Color kidsPurpleLight = Color(0xFFA78BFA);
  static const Color kidsCyan = Color(0xFF06B6D4);
  static const Color kidsCyanLight = Color(0xFF0EA5E9);
  static const Color kidsGreen = Color(0xFF4ADE80);
  static const Color kidsGreenDeep = Color(0xFF22C55E);

  /// Usado em avisos/warnings (texto + ícone de "link expira")
  static const Color kidsAmber = Color(0xFFB45309);

  /// Usado em cabeçalhos de avisos (título da caixa "link expira")
  static const Color kidsAmberDark = Color(0xFF92400E);

  // ─── Cores de erro ───────────────────────────────────────────────────────────
  static const Color errorRed = Color(0xFFFF6B6B);
  static const Color errorRedDeep = Color(0xFFFF4444);

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
  static const Color textMuted = Color(0xFF888888);
  static const Color textSubtle = Color(0xFF555555);

  /// Fundo claro de campos de input (fillColor)
  static const Color surfaceLight = Color(0xFFFAFAFA);

  /// Branco puro para superfícies e containers
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // ─── Sombras ─────────────────────────────────────────────────────────────────

  /// Sombra genérica semitransparente (ex.: Shadow no botão CRIAR CONTA)
  static const Color shadowDark = Color(0x55000000);

  /// Sombra suave (ex.: cards e containers)
  static const Color shadowColor = Color(0x1A000000);

  // ─── Cores de perfil ─────────────────────────────────────────────────────────
  /// Fundo da ProfilePage (Scaffold + _ProfileBody)
  static const Color profileBackground = Color(0xFFF7F8FC);

  /// Linha divisória entre seções do perfil
  static const Color dividerColor = Color(0xFFEEEEEE);

  // ─── Cores da DreamPage ───────────────────────────────────────────────────────
  /// Fundo do Scaffold da DreamPage
  static const Color dreamBackground = Color(0xFFF0F8FF);

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

  /// Fundo da ForgotPasswordInstructionsPage (tela de instruções pós-envio)
  static const LinearGradient forgotInstructionsBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsCyan, kidsGreen, kidsPurple, kidsPink],
    stops: [0.0, 0.3, 0.65, 1.0],
  );

  /// Gradiente do botão "Enviar email" da ForgotPasswordPage
  static const LinearGradient forgotSendButtonGradient = LinearGradient(
    colors: [kidsPink, kidsPurple],
  );

  /// Gradiente do botão "Voltar para o login"
  static const LinearGradient forgotBackButtonGradient = LinearGradient(
    colors: [kidsGreen, kidsCyan],
  );

  /// Gradiente do chip de email (cyan → green) nas instruções de recuperação
  static const LinearGradient forgotEmailChipGradient = LinearGradient(
    colors: [kidsCyan, kidsGreen],
  );

  // ─── Gradientes da AgeVerificationPage ───────────────────────────────────────

  /// Fundo do cabeçalho (header) da AgeVerificationPage
  static const LinearGradient ageVerificationHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsPink, kidsYellow],
  );

  /// Gradiente do badge informativo da AgeVerificationPage
  static const LinearGradient ageVerificationInfoBadgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsPink, kidsYellow],
  );

  /// Gradiente do badge de sucesso da AgeVerificationPage
  static const LinearGradient ageVerificationSuccessBadgeGradient =
      LinearGradient(colors: [kidsGreen, kidsGreenDeep]);

  /// Gradiente do botão de submit da AgeVerificationPage (quando ativo)
  static const LinearGradient ageVerificationSubmitButtonGradient =
      LinearGradient(colors: [kidsPink, kidsYellow]);

  /// SweepGradient do anel giratório da ForgotPasswordInstructionsPage
  static const SweepGradient forgotInstructionsSweep = SweepGradient(
    colors: [kidsCyan, kidsGreen, kidsPurple, kidsPink, kidsCyan],
  );

  /// Gradiente interno do ícone de email da ForgotPasswordInstructionsPage
  static const LinearGradient forgotEmailIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsCyan, kidsGreen],
  );

  /// Gradiente do badge de email enviado (dentro do card de instruções)
  static const LinearGradient forgotEmailBadgeGradient = LinearGradient(
    colors: [kidsCyan, kidsGreen],
  );

  // ═══════════════════════════════════════════════════════════════════════════════
  // ADIÇÕES AO app_theme.dart
  // Cole estes membros dentro da classe AppTheme, nos grupos indicados.
  // ═══════════════════════════════════════════════════════════════════════════════

  // ─── Cores de status de doação ────────────────────────────────────────────────
  // (Cole junto ao grupo "Cores de status/medalha")

  /// Cor do badge "reservado" em DonationCardWidget
  static const Color donationReservedColor = Color(0xFFF59E0B);

  /// Fundo do placeholder/picker de imagem de doação e sonho (lilás muito claro)
  static const Color dreamImagePickerBg = Color(0xFFF5F0FF);

  /// Borda sutil rosa usada no card de doação (FCE7F3)
  static const Color donationCardBorder = Color(0xFFFCE7F3);

  /// Fundo do card de doação no placeholder (mesma cor da borda)
  static const Color donationPlaceholderBg = Color(0xFFFCE7F3);

  // ─── Gradientes da DonationCardWidget / DreamFormSheet ────────────────────────
  // (Cole junto ao grupo "Gradientes reutilizáveis")

  /// Gradiente do botão "Editar" no fullscreen de doação (pink → pink claro)
  static const LinearGradient donationEditButtonGradient = LinearGradient(
    colors: [kidsPink, Color(0xFFFF8FB3)],
  );

  /// Gradiente do botão salvar/publicar no DreamFormSheet (purple → lilás)
  static const LinearGradient dreamSaveButtonGradient = LinearGradient(
    colors: [kidsPurple, Color(0xFFBB86FC)],
  );

  // ─── Emojis da DreamPage / DreamFormSheet ────────────────────────────────────
  // (Cole como lista estática — pode ficar em AppTheme ou em um arquivo de
  //  constantes próprio. Aqui fica centralizado para facilitar a manutenção.)

  /// Lista de emojis disponíveis no picker de sonhos (DreamFormSheet)
  static const List<String> dreamEmojiOptions = [
    '💭',
    '🌟',
    '🏠',
    '🚗',
    '✈️',
    '📚',
    '💪',
    '🎓',
    '❤️',
    '🌱',
    '🎯',
    '💼',
    '🎨',
    '🏋️',
    '🧘',
    '🌈',
  ];
  // ═══════════════════════════════════════════════════════════════════════════════
  // ADIÇÕES AO app_theme.dart — bloco "Perfil / Edit Profile / Children / Location"
  // Cole estes membros dentro da classe AppTheme, antes do fechamento.
  // Fonte: edit_profile.dart, children_section.dart, location_section.dart,
  //        profile_photo_section.dart, profile_header_widget.dart, profile_page.dart,
  //        profile_children_widget.dart, profile_donor_widget.dart,
  //        profile_dreams_widget.dart, profile_shared_widgets.dart
  // ═══════════════════════════════════════════════════════════════════════════════

  // ─── Cores neutras / superfícies adicionais ──────────────────────────────────
  // (Cole junto ao grupo "Cores neutras")

  /// Fundo levemente azulado de inputs e pickers (era 0xFFF8F8FF, espalhado em
  /// edit_profile, children_section, profile_photo_section)
  static const Color surfaceBlueTint = Color(0xFFF8F8FF);

  /// Fundo neutro cinza-claro de chips/botões não selecionados (era 0xFFF5F5F5,
  /// espalhado em edit_profile, children_section, profile_photo_section)
  static const Color surfaceNeutral = Color(0xFFF5F5F5);

  /// Placeholder de avatar sem foto (era 0xFFD1D5DB em profile_photo_section)
  static const Color placeholderIcon = Color(0xFFD1D5DB);

  // ─── Cores de status/verificação ─────────────────────────────────────────────
  // (Cole junto ao grupo "Cores de status/medalha")

  /// Verde escuro usado em textos de "etapa concluída" / "membro verificado"
  /// (era 0xFF166534 em profile_header_widget)
  static const Color verifiedTextDark = Color(0xFF166534);

  /// Verde "deep" usado em gradientes de sucesso/verificação (era 0xFF22C55E,
  /// duplicava kidsGreenDeep em profile_header_widget — usar kidsGreenDeep)

  // ─── Cores de localização / mapa ─────────────────────────────────────────────
  // (Cole junto ao grupo "Cores de perfil")

  /// Azul usado nos cards de filhos e ícones de localização confirmada
  /// (era 0xFF2563EB em children_section / profile_children_widget)
  static const Color childCardAccent = Color(0xFF2563EB);

  /// Fundo azul claro do avatar/emoji de filho (era 0xFFE0F2FE em
  /// children_section / profile_children_widget)
  static const Color childCardBg = Color(0xFFE0F2FE);

  // ─── Gradientes de perfil ─────────────────────────────────────────────────────
  // (Cole junto ao grupo "Gradientes reutilizáveis")

  /// Gradiente do header da ProfilePage / EditProfilePage (era inline:
  /// [kidsPink, Color(0xFFE040A0), kidsPurple] em profile_header_widget, e
  /// [kidsPink, kidsYellow, kidsPurple] em edit_profile._buildHeader)
  static const LinearGradient profileHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsPink, Color(0xFFE040A0), kidsPurple],
    stops: [0.0, 0.55, 1.0],
  );

  /// Gradiente do header da tela de edição de perfil (rosa → amarelo → roxo)
  static const LinearGradient editProfileHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kidsPink, kidsYellow, kidsPurple],
  );

  /// Gradiente pink → purple usado em chips selecionados, botões de ação e
  /// ícones de seção (repetido em edit_profile, children_section,
  /// profile_photo_section, profile_header_widget)
  static const LinearGradient pinkPurpleGradient = LinearGradient(
    colors: [kidsPink, kidsPurple],
  );

  /// Gradiente do card de filho (azul claro → amarelo claro translúcido)
  /// (era inline em children_section._ChildCard)
  static const LinearGradient childCardGradient = LinearGradient(
    colors: [childCardBg, Color(0x80FFF9E6)], // FFF9E6 com opacity 0.5
  );

  /// Gradiente verde de "etapa concluída" (era [_green, Color(0xFF22C55E)] em
  /// profile_header_widget — equivalente a [kidsGreen, kidsGreenDeep])
  static const LinearGradient verifiedStepGradient = LinearGradient(
    colors: [kidsGreen, kidsGreenDeep],
  );

  // ─── Ícones reutilizáveis ─────────────────────────────────────────────────────
  // Centraliza os IconData usados nas telas de perfil para evitar repetição de
  // `Icons.xxx` direto nos widgets. Use AppIcons.xxx no lugar de Icons.xxx.

  // (criar classe auxiliar abaixo, fora de AppTheme — ver bloco 2)
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
        foregroundColor: Colors.white,
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
        fillColor: Colors.white,
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
}

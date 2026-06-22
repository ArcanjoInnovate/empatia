import 'package:flutter/material.dart';

class AppTheme {
  // ─── Cores principais ────────────────────────────────────────────────────────
  static const Color primaryBlue   = Color(0xFF1E3A8A);
  static const Color accentTeal    = Color(0xFF4DB8C4);
  static const Color accentYellow  = Color(0xFFFBD346);
  static const Color accentPink    = Color(0xFFE91E63);
  static const Color accentOrange  = Color(0xFFFFA726);
  static const Color accentPurple  = Color(0xFF9C27B0);
  static const Color accentGreen   = Color(0xFF4CAF50);

  // ─── Paleta "kids" (usada nas telas de auth e success) ───────────────────────
  static const Color kidsPink      = Color(0xFFFF6B9D);
  static const Color kidsPinkDeep  = Color(0xFFFF1493);
  static const Color kidsYellow    = Color(0xFFFFC837);
  static const Color kidsYellowGold= Color(0xFFFFD700);
  static const Color kidsPurple    = Color(0xFF8B5CF6);
  static const Color kidsPurpleLight= Color(0xFFA78BFA);
  static const Color kidsCyan      = Color(0xFF06B6D4);
  static const Color kidsCyanLight = Color(0xFF0EA5E9);
  static const Color kidsGreen     = Color(0xFF4ADE80);
  static const Color kidsGreenDeep = Color(0xFF22C55E);

  // ─── Cores de erro ───────────────────────────────────────────────────────────
  static const Color errorRed      = Color(0xFFFF6B6B);
  static const Color errorRedDeep  = Color(0xFFFF4444);

  // ─── Cores de status/medalha ─────────────────────────────────────────────────
  static const Color bronzeMedal   = Color(0xFFCD7F32);
  static const Color goldMedal     = Color(0xFFFFD700);
  static const Color diamondLevel  = Color(0xFF1E3A8A);

  // ─── Cores neutras ───────────────────────────────────────────────────────────
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardBackground  = Color(0xFFFFFFFF);
  static const Color textPrimary     = Color(0xFF212121);
  static const Color textSecondary   = Color(0xFF757575);
  static const Color textDark        = Color(0xFF1a1a2e);
  static const Color textMuted       = Color(0xFF888888);
  static const Color textSubtle      = Color(0xFF555555);

  // ─── Cores de perfil ─────────────────────────────────────────────────────────
  /// Fundo da ProfilePage (Scaffold + _ProfileBody)
  static const Color profileBackground = Color(0xFFF7F8FC);
  /// Linha divisória entre seções do perfil
  static const Color dividerColor      = Color(0xFFEEEEEE);

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
  static const List<Color> gradientEmail    = [kidsCyan,    kidsCyanLight];
  static const List<Color> gradientPassword = [kidsPurple,  kidsPurpleLight];
  static const List<Color> gradientConfirm  = [kidsPink,    kidsPinkDeep];

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
    colors: [
      kidsPink,
      kidsYellow,
      kidsGreen,
      kidsCyan,
      kidsPurple,
      kidsPink,
    ],
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
    colors: [kidsGreen, kidsCyan, kidsPurple, kidsYellow, Color(0xFFFF6B9D), kidsGreen],
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
  static const LinearGradient ageVerificationSuccessBadgeGradient = LinearGradient(
    colors: [kidsGreen, kidsGreenDeep],
  );

  /// Gradiente do botão de submit da AgeVerificationPage (quando ativo)
  static const LinearGradient ageVerificationSubmitButtonGradient = LinearGradient(
    colors: [kidsPink, kidsYellow],
  );

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
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
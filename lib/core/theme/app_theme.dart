import 'package:flutter/material.dart';

class AppTheme {
  // Cores principais baseadas no app Pingo Brinquedos
  static const Color primaryBlue = Color(0xFF1E3A8A); // Azul escuro do header
  static const Color accentTeal = Color(0xFF4DB8C4); // Azul turquesa claro
  static const Color accentYellow = Color(0xFFFBD346); // Amarelo dos botões
  static const Color accentPink = Color(0xFFE91E63); // Rosa dos likes
  static const Color accentOrange = Color(0xFFFFA726); // Laranja
  static const Color accentPurple = Color(0xFF9C27B0); // Roxo
  static const Color accentGreen = Color(0xFF4CAF50); // Verde
  
  // Cores de status
  static const Color bronzeMedal = Color(0xFFCD7F32);
  static const Color goldMedal = Color(0xFFFFD700);
  static const Color diamondLevel = Color(0xFF1E3A8A);
  
  // Cores neutras
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  
  // Gradientes coloridos (inspirado nas barras coloridas do app)
  static const LinearGradient rainbowGradient = LinearGradient(
    colors: [
      Color(0xFFE91E63), // Rosa
      Color(0xFFFBD346), // Amarelo
      Color(0xFF4CAF50), // Verde
      Color(0xFF4DB8C4), // Turquesa
      Color(0xFF9C27B0), // Roxo
      Color(0xFFFFA726), // Laranja
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  // Theme Data
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
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
    );
  }
}
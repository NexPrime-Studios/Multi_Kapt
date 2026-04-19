import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A1A1A); // Preto suave
  static const Color secondaryColor = Color(0xFF00D2FF); // Azul neon vibrante
  static const Color accentColor =
      Color(0xFFFF4B4B); // Vermelho vibrante para destaques
  static const Color scaffoldBg =
      Color(0xFFF8F9FA); // Cinza claríssimo para o fundo

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
        error: accentColor,
      ),

      // Fontes: Use uma fonte moderna se possível (como Inter ou Roboto)
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
            fontWeight: FontWeight.w900,
            color: primaryColor,
            letterSpacing: -0.5),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
      ),

      // AppBars limpas e minimalistas
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        centerTitle: false, // Títulos à esquerda são mais modernos
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      // Botões com cantos arredondados e sombras suaves
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      // Inputs (TextFields) com bordas suaves
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: secondaryColor, width: 2),
        ),
      ),
    );
  }
}

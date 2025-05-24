import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Для красивых шрифтов

// --- Основные цвета для оранжево-желтой гаммы ---
// Для Светлой Темы
const Color _lightPrimarySeedColor = Colors.orange; // Яркий оранжевый
const Color _lightSecondarySeedColor = Colors.amber;   // Теплый желтый/янтарный

// Для Темной Темы
const Color _darkPrimarySeedColor = Color(0xFFD84315); // Глубокий оранжевый (чуть темнее и насыщеннее)
const Color _darkSecondarySeedColor = Colors.amberAccent; // Яркий желтый акцент

class AppThemes {
  AppThemes._(); // Приватный конструктор

  // --- Светлая тема (Оранжево-Желтая) ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.montserrat().fontFamily,

    colorScheme: ColorScheme.fromSeed(
      seedColor: _lightPrimarySeedColor,
      secondary: _lightSecondarySeedColor,
      brightness: Brightness.light,
      // Переопределяем для лучшего контроля, если fromSeed не идеален
      background: const Color(0xFFFFF8E1), // Очень светлый кремово-желтый фон
      surface: Colors.white,              // Белые поверхности (карточки, диалоги)
      onPrimary: Colors.white,            // Текст на основном оранжевом цвете (кнопки)
      onSecondary: Colors.black87,        // Текст на вторичном желтом цвете
      onError: Colors.white,
    ),

    scaffoldBackgroundColor: const Color(0xFFFFF8E1), // Фон экрана

    appBarTheme: AppBarTheme(
      elevation: 2,
      centerTitle: true,
      backgroundColor: _lightPrimarySeedColor, // Оранжевый AppBar
      foregroundColor: Colors.white,          // Белый текст и иконки
      titleTextStyle: GoogleFonts.lato(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimarySeedColor, // Оранжевый
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        textStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 3,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _lightPrimarySeedColor, // Оранжевый текст и рамка
        side: BorderSide(color: _lightPrimarySeedColor, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        textStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    ),

    cardTheme: CardTheme(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: Colors.white, // Белые карточки
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.orange.shade50.withOpacity(0.7), // Очень светлый оранжевый оттенок
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.orange.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: _lightPrimarySeedColor, width: 2.0),
      ),
      hintStyle: GoogleFonts.roboto(color: Colors.orange.shade700.withOpacity(0.7)),
      labelStyle: GoogleFonts.roboto(color: _lightPrimarySeedColor),
    ),

    textTheme: TextTheme(
      displayLarge: GoogleFonts.raleway(fontSize: 52, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
      displayMedium: GoogleFonts.raleway(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
      headlineMedium: GoogleFonts.raleway(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
      titleLarge: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
      bodyLarge: GoogleFonts.roboto(fontSize: 16, color: Colors.black87),
      bodyMedium: GoogleFonts.roboto(fontSize: 14, color: Colors.black54),
      labelLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white), // Для ElevatedButton
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: _lightPrimarySeedColor,
      unselectedItemColor: Colors.orange.shade300,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500),
      unselectedLabelStyle: GoogleFonts.roboto(),
    ),
  );

  // --- Темная тема (Оранжево-Желтая) ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.montserrat().fontFamily,

    colorScheme: ColorScheme.fromSeed(
      seedColor: _darkPrimarySeedColor, // Глубокий оранжевый
      secondary: _darkSecondarySeedColor, // Яркий желтый акцент
      brightness: Brightness.dark,
      background: const Color(0xFF211205), // Очень темный коричнево-оранжевый фон
      surface: const Color(0xFF38200A),   // Темный оранжево-коричневый для поверхностей
      onPrimary: Colors.white, // Текст на кнопках с _darkPrimarySeedColor
      onSecondary: Colors.black, // Текст на кнопках с _darkSecondarySeedColor
      onError: Colors.black,
    ),

    scaffoldBackgroundColor: const Color(0xFF211205), // Фон экрана

    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: const Color(0xFF38200A), // Цвет поверхности
      foregroundColor: Colors.orange.shade100,      // Светлый текст
      titleTextStyle: GoogleFonts.lato(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.orange.shade100,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimarySeedColor, // Глубокий оранжевый
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        textStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 2,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkSecondarySeedColor, // Яркий желтый акцент
        side: BorderSide(color: _darkSecondarySeedColor, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        textStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    ),

    cardTheme: CardTheme(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: const Color(0xFF38200A), // Цвет карточек (цвет поверхности)
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF4A2D10), // Еще темнее оранжево-коричневый
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.orange.shade800.withOpacity(0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: _darkSecondarySeedColor, width: 2.0),
      ),
      hintStyle: GoogleFonts.roboto(color: Colors.orange.shade200.withOpacity(0.6)),
      labelStyle: GoogleFonts.roboto(color: _darkSecondarySeedColor),
    ),

    textTheme: TextTheme(
      displayLarge: GoogleFonts.raleway(fontSize: 52, fontWeight: FontWeight.bold, color: Colors.orange.shade100),
      displayMedium: GoogleFonts.raleway(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.orange.shade100),
      headlineMedium: GoogleFonts.raleway(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.orange.shade200),
      titleLarge: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange.shade100),
      bodyLarge: GoogleFonts.roboto(fontSize: 16, color: Colors.orange.shade100.withOpacity(0.87)),
      bodyMedium: GoogleFonts.roboto(fontSize: 14, color: Colors.orange.shade100.withOpacity(0.70)),
      labelLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white), // Для ElevatedButton
    ),

     bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF38200A), // Цвет поверхности
      selectedItemColor: _darkSecondarySeedColor, // Яркий желтый
      unselectedItemColor: Colors.orange.shade400,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500),
      unselectedLabelStyle: GoogleFonts.roboto(),
    ),
  );
}
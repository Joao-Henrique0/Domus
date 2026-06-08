import 'package:flutter/material.dart';

const Color brandPrimary = Color(0xFF0E6F73);
const Color brandPrimaryDark = Color(0xFF053B3F);
const Color brandAccent = Color(0xFF35C2A1);
const Color lightSurface = Color(0xFFFFFFFF);
const Color lightBackground = Color(0xFFF4F7F6);
const Color darkBackground = Color(0xFF101415);
const Color darkSurface = Color(0xFF1A2224);
const Color darkAccent = Color(0xFF62D6B3);

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  scaffoldBackgroundColor: lightBackground,
  colorScheme: ColorScheme.fromSeed(
    seedColor: brandPrimary,
    brightness: Brightness.light,
    primary: brandPrimary,
    onPrimary: Colors.white,
    secondary: brandAccent,
    onSecondary: const Color(0xFF082624),
    tertiary: lightSurface,
    surface: lightSurface,
    onSurface: const Color(0xFF172426),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    backgroundColor: brandPrimary,
    foregroundColor: Colors.white,
    elevation: 2,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 21,
      fontWeight: FontWeight.w700,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  cardTheme: CardThemeData(
    color: lightSurface,
    elevation: 2,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: brandPrimary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: brandPrimary,
      foregroundColor: Colors.white,
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: brandPrimary,
    foregroundColor: Colors.white,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: brandPrimary,
    selectedItemColor: Colors.white,
    unselectedItemColor: Color(0xFFCDE4E2),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF172426), fontSize: 15),
    bodyMedium: TextStyle(color: Color(0xFF617174), fontSize: 14),
    displayLarge: TextStyle(
      color: brandPrimary,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      color: brandPrimaryDark,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: darkBackground,
  colorScheme: const ColorScheme.dark(
    primary: darkAccent,
    onPrimary: Color(0xFF082624),
    secondary: Color(0xFF8CE8D0),
    onSecondary: Color(0xFF082624),
    tertiary: darkSurface,
    surface: darkSurface,
    onSurface: Color(0xFFE7F0EF),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    backgroundColor: Color(0xFF132022),
    foregroundColor: Color(0xFFE7F0EF),
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Color(0xFFE7F0EF),
      fontSize: 21,
      fontWeight: FontWeight.w700,
    ),
    iconTheme: IconThemeData(color: Color(0xFFE7F0EF)),
  ),
  cardTheme: CardThemeData(
    color: darkSurface,
    elevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkAccent,
      foregroundColor: const Color(0xFF082624),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: darkAccent,
      foregroundColor: const Color(0xFF082624),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: darkAccent,
    foregroundColor: Color(0xFF082624),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF132022),
    selectedItemColor: darkAccent,
    unselectedItemColor: Color(0xFF7F9295),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFE7F0EF), fontSize: 15),
    bodyMedium: TextStyle(color: Color(0xFFB4C3C5), fontSize: 14),
    displayLarge: TextStyle(
      color: darkAccent,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      color: Color(0xFFE7F0EF),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
);

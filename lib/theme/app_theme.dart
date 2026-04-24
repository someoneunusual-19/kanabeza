import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF6366F1); // Indigo
  static const background = Color(0xFF09090B); // Shadcn Dark
  static const surface = Color(0xFF18181B);
  
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    cardColor: surface,
    appBarTheme: const AppBarTheme(backgroundColor: background, elevation: 0),
  );
}
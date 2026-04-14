import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kanabeza/models/product.dart';
import 'package:kanabeza/models/purchase.dart';
import 'package:kanabeza/models/sale.dart';
import 'package:kanabeza/screens/splash_screen.dart';
import 'package:kanabeza/services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(PurchaseAdapter());
  Hive.registerAdapter(SaleAdapter());

  await HiveService.initBoxes();

  runApp(const KanabezaApp());
}

class KanabezaApp extends StatelessWidget {
  const KanabezaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanabeza',
      debugShowCheckedModeBanner: false,

      // Light Theme
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.lightBlue,
        primaryColor: const Color(0xFF81D4FA),
        scaffoldBackgroundColor: const Color(0xFFF0F9FF),
        brightness: Brightness.light,

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF81D4FA),
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF81D4FA),
        ),

        // ✅ FIXED: Use CardThemeData instead of CardTheme
        cardTheme: const CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.lightBlue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A192F),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0277BD),
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF81D4FA),
        ),

        // ✅ FIXED: Use CardThemeData
        cardTheme: const CardThemeData(
          elevation: 6,
          color: Color(0xFF1E3A5F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),

      themeMode: ThemeMode.system, // Follows system light/dark mode
      home: const SplashScreen(),
    );
  }
}
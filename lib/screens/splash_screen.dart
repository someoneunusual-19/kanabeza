// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kanabeza/models/app_user.dart';
import 'main_wrapper.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(seconds: 2)); // Branding time
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    // Fetch Role & Navigate
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    final appUser = AppUser(
      uid: user.uid,
      email: user.email!,
      storeId: data?['storeId'] ?? '',
      role: data?['role'] == 'manager' ? UserRole.manager : UserRole.seller,
    );

    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainWrapper(user: appUser)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 80, color: Color(0xFF6366F1)),
            const SizedBox(height: 16),
            const Text("KANABEZA", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4)),
            const SizedBox(height: 8),
            SizedBox(width: 40, child: LinearProgressIndicator(color: Colors.indigoAccent, backgroundColor: Colors.white10)),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kanabeza/models/app_user.dart';

// Import your internal files
import 'screens/login_screen.dart';
import 'screens/main_wrapper.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 2. Pass the options to initializeApp
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const KanabezaApp());
}

class KanabezaApp extends StatelessWidget {
  const KanabezaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanabeza Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Uses your Shadcn-inspired dark theme
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to the Firebase Auth session
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        
        // 1. If not logged in, show the Login Screen
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        // 2. If logged in, fetch the user profile from Firestore
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(authSnapshot.data!.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.indigoAccent)),
              );
            }

            // 3. Handle cases where the User exists in Auth but not in Firestore
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const LoginScreen(); 
            }

            // 4. Map Firestore data to our local AppUser model
            final userData = AppUser.fromFirestore(
              userSnapshot.data!.data() as Map<String, dynamic>,
              userSnapshot.data!.id,
            );

            // 5. Success! Pass the user data to the Main UI Wrapper
            return MainWrapper(user: userData);
          },
        );
      },
    );
  }
}
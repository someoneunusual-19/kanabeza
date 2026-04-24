import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
 

  // Handle Account Creation with Role Assignment
  Future<void> signUp({
    required String email, 
    required String password, 
    required String role,
    String? storeName,
  }) async {
    // 1. Create the Auth credentials
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(), 
      password: password.trim()
    );

    // 2. Define StoreID (Managers create new, Sellers are pending)
    String storeId = role == 'manager' 
        ? "STR-${DateTime.now().millisecondsSinceEpoch}" 
        : "PENDING";

    // 3. Save the profile to Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'email': email.trim(),
      'role': role,
      'storeId': storeId,
      'storeName': storeName ?? "N/A",
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Handle Standard Login
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(), 
      password: password.trim()
    );
  }

  // Handle Biometric Hardware Check
  Future<bool> authenticateBiometrics() async {
    try {
      bool canCheck = await _localAuth.canCheckBiometrics;
      bool isSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheck || !isSupported) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock the Kanabeza terminal',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async => await _auth.signOut();


Future<void> signInWithGoogle() async {
  try {
    // Check if platform supports authenticate
    if (GoogleSignIn.instance.supportsAuthenticate()) {
      await GoogleSignIn.instance.authenticate(scopeHint: ['email']);
    } else {
      // Handle web platform differently
      print('This platform requires platform-specific sign-in UI');
    }
  } catch (e) {
    print('Sign-in error: $e');
  }
}

}
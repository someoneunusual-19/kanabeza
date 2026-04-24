import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signup_screen.dart';
import '../services/security_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final SecurityService _security = SecurityService();
  bool _isLoading = false;
  GoogleSignInAccount? user;

  Future<void> _initializeGoogleSignIn() async {
    // Initialize and listen to authentication events
    await GoogleSignIn.instance.initialize();
    
    GoogleSignIn.instance.authenticationEvents.listen(
      (event) {
        setState(() {
          user = switch (event) {
            GoogleSignInAuthenticationEventSignIn() => event.user,
            GoogleSignInAuthenticationEventSignOut() => null,
          };
        });
      },
    );
  }


  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await _security.signIn(_emailController.text, _passwordController.text);
      // The AuthGate in main.dart will detect the state change and navigate
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login Failed: ${e.toString()}"), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

   Future<void> _signInGoogle() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Branding
              const Icon(Icons.bolt_rounded, size: 80, color: AppTheme.primary),
              const SizedBox(height: 16),
              const Text(
                "Kanabeza Pro", 
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)
              ),
              const Text("Secure Store Terminal", style: TextStyle(color: Colors.grey)),
              
              const SizedBox(height: 48),

              // Inputs
              _buildTextField("Business Email", _emailController, Icons.email_outlined),
              const SizedBox(height: 16),
              _buildTextField("Password", _passwordController, Icons.lock_outline, isPassword: true),
              
              const SizedBox(height: 32),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("SIGN IN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed:_signInGoogle ,
                child: Text('Sign in with Google'),
              ),

              // Biometric Access
              IconButton(
                icon: const Icon(Icons.fingerprint, size: 48, color: AppTheme.primary),
                onPressed: () async {
                  bool success = await _security.authenticateBiometrics();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Biometrics Verified. Check session..."))
                    );
                  }
                },
              ),
              const Text("Quick Unlock", style: TextStyle(color: Colors.white24, fontSize: 12)),

              const SizedBox(height: 40),

              // Navigation to Signup
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const SignupScreen())
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: "Sign Up",
                        style: TextStyle(
                          color: AppTheme.primary, 
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.white24, size: 20),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: BorderSide.none
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
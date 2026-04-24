import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _security = SecurityService();
  
  String _selectedRole = 'seller'; 
  bool _isLoading = false;

  void _handleSignup() async {
    setState(() => _isLoading = true);
    try {
      await _security.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
        storeName: _selectedRole == 'manager' ? _storeNameController.text : null,
      );
      if (mounted) Navigator.pop(context); // Return to login after success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup Failed: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Create Account", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const Text("Register your terminal", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            // Role Toggle
            _buildRoleToggle(),
            const SizedBox(height: 24),

            _buildField("Email", _emailController, Icons.email_outlined),
            const SizedBox(height: 16),
            
            if (_selectedRole == 'manager') ...[
              _buildField("Store Name", _storeNameController, Icons.storefront),
              const SizedBox(height: 16),
            ],

            _buildField("Password", _passwordController, Icons.lock_outline, isPass: true),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                onPressed: _isLoading ? null : _handleSignup,
                child: _isLoading ? const CircularProgressIndicator() : const Text("GET STARTED"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: ['seller', 'manager'].map((role) {
          bool isSelected = _selectedRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white24),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
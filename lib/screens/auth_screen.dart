import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:kanabeza/services/hive_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  bool _isFirstLaunch = true;
  String? _storedPin;
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunchAndBiometrics();
  }

  Future<void> _checkFirstLaunchAndBiometrics() async {
    _isFirstLaunch = await HiveService.isFirstLaunch();
    _storedPin = await HiveService.getStoredPin();

    final canCheckBiometrics = await auth.canCheckBiometrics;
    final isDeviceSupported = await auth.isDeviceSupported();
    _biometricsAvailable = canCheckBiometrics && isDeviceSupported;

    if (_isFirstLaunch) {
      // Stay on set PIN flow
    } else if (_biometricsAvailable) {
      _authenticateWithBiometrics();
    }
    setState(() {});
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint or face to unlock Kanabeza',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (authenticated && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      // Biometrics failed - fall back to PIN
    }
  }

  Future<void> _setPin() async {
    final pin = _pinController.text.trim();
    if (pin.length == 4 && int.tryParse(pin) != null) {
      await HiveService.setPin(pin);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be 4 digits')),
      );
    }
  }

  Future<void> _verifyPin() async {
    if (_pinController.text == _storedPin) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN')),
      );
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2, size: 100, color: Color(0xFF81D4FA)),
            const SizedBox(height: 20),
            Text(
              _isFirstLaunch ? 'Welcome to Kanabeza' : 'Unlock Kanabeza',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            if (_isFirstLaunch) ...[
              const Text('Set your 4-digit security PIN', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '••••',
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _setPin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: const Color(0xFF81D4FA),
                ),
                child: const Text('SET PIN & CONTINUE', style: TextStyle(fontSize: 18)),
              ),
            ] else ...[
              if (_biometricsAvailable)
                ElevatedButton.icon(
                  onPressed: _authenticateWithBiometrics,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Unlock with Biometrics'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: const Color(0xFF81D4FA),
                  ),
                ),
              const SizedBox(height: 20),
              const Text('or enter PIN'),
              const SizedBox(height: 20),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '••••',
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _verifyPin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: const Color(0xFF81D4FA),
                ),
                child: const Text('VERIFY PIN', style: TextStyle(fontSize: 18)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/hive_service.dart';
import '../widgets/custom_modals.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _biometricsAvailable = false;
  bool _biometricsEnabled = false;
  String? _currentPin;
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currentPin = await HiveService.getStoredPin();
    _biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;

    final canCheck = await auth.canCheckBiometrics;
    final isSupported = await auth.isDeviceSupported();
    _biometricsAvailable = canCheck && isSupported;

    setState(() {});
  }

  Future<void> _changePin() async {
    if (_oldPinController.text != _currentPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Old PIN is incorrect')),
      );
      return;
    }

    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (newPin.length != 4 || confirmPin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be 4 digits')),
      );
      return;
    }

    if (newPin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PIN and confirmation do not match')),
      );
      return;
    }

    await HiveService.setPin(newPin);
    _currentPin = newPin;

    _oldPinController.clear();
    _newPinController.clear();
    _confirmPinController.clear();

    CustomModals.showSuccessModal(context, 'PIN changed successfully!');
    setState(() {});
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value && !_biometricsAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometrics not available on this device')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometrics_enabled', value);

    setState(() => _biometricsEnabled = value);

    CustomModals.showSuccessModal(
      context,
      value ? 'Biometrics enabled successfully' : 'Biometrics disabled',
    );
  }

  void _showChangePinModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Security PIN'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Current PIN',
                  border: OutlineInputBorder(),
                  hintText: '••••',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'New PIN',
                  border: OutlineInputBorder(),
                  hintText: '••••',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Confirm New PIN',
                  border: OutlineInputBorder(),
                  hintText: '••••',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _changePin();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81D4FA)),
            child: const Text('Change PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),

          // Security Section
          const Text('Security', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock, color: Color(0xFF81D4FA)),
                  title: const Text('Change PIN'),
                  subtitle: const Text('Update your 4-digit security PIN'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showChangePinModal,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Biometric Authentication'),
                  subtitle: Text(_biometricsAvailable
                      ? 'Use fingerprint or face ID'
                      : 'Biometrics not available'),
                  value: _biometricsEnabled,
                  onChanged: _biometricsAvailable ? _toggleBiometrics : null,
                  secondary: const Icon(Icons.fingerprint, color: Color(0xFF81D4FA)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // App Info
          const Text('About Kanabeza', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.inventory_2, color: Color(0xFF81D4FA)),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info, color: Color(0xFF81D4FA)),
                  title: const Text('Description'),
                  subtitle: const Text('Personal Stock, Sales & Accounting Ledger'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.person, color: Color(0xFF81D4FA)),
                  title: Text('Single User Mode'),
                  subtitle: Text('Fully offline with Hive'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}
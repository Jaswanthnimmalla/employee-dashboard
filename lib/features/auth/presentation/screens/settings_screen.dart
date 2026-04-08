import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return false;

      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<String> authenticateUser() async {
    try {
      final isAuthenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return isAuthenticated ? 'success' : 'failed';
    } catch (e) {
      return 'error';
    }
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthenticationService _authService = AuthenticationService();
  bool biometricEnabled = false;
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      biometricEnabled = prefs.getBool('biometricEnabled') ?? false;
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final isAvailable = await _authService.isBiometricAvailable();

      if (!isAvailable) {
        _showDialog(
          'Biometric Not Available',
          'No fingerprint or face recognition found on this device.\n\nPlease enroll biometrics in device settings first.',
          Icons.fingerprint,
        );
        return;
      }

      final result = await _authService.authenticateUser();

      if (result == 'success') {
        await prefs.setBool('biometricEnabled', value);
        setState(() {
          biometricEnabled = value;
        });
        _showSnackBar('Biometric lock enabled successfully!', Colors.green);
      } else if (result == 'failed') {
        _showSnackBar('Authentication failed. Please try again.', Colors.red);
      } else {
        _showSnackBar('Authentication error. Please try again.', Colors.red);
      }
    } else {
      await prefs.setBool('biometricEnabled', value);
      setState(() {
        biometricEnabled = value;
      });
      _showSnackBar('Biometric lock disabled', Colors.orange);
    }
  }

  void _showDialog(String title, String message, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: Colors.orange),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    setState(() {
      notificationsEnabled = value;
    });
    _showSnackBar(value ? 'Notifications enabled' : 'Notifications disabled',
        Colors.blue);
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkModeEnabled', value);
    setState(() {
      darkModeEnabled = value;
    });
    _showSnackBar(
        value ? 'Dark mode enabled' : 'Dark mode disabled', Colors.blue);
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 6,
        centerTitle: true,
        backgroundColor: const Color(0xFF6C5CE7),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(size.width < 600 ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Security Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                _buildToggleTile(
                  title: 'Biometric Lock',
                  subtitle: 'Ask fingerprint or face when app opens',
                  icon: Icons.fingerprint,
                  value: biometricEnabled,
                  onChanged: _toggleBiometric,
                  color: const Color(0xFF6C5CE7),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                _buildToggleTile(
                  title: 'Notifications',
                  subtitle: 'Receive alerts and updates',
                  icon: Icons.notifications_active,
                  value: notificationsEnabled,
                  onChanged: _toggleNotifications,
                  color: const Color(0xFF27AE60),
                ),
                _buildToggleTile(
                  title: 'Dark Mode',
                  subtitle: 'Switch to dark theme',
                  icon: Icons.dark_mode,
                  value: darkModeEnabled,
                  onChanged: _toggleDarkMode,
                  color: const Color(0xFF2C3E50),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.5),
                      width: 1.4,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'When biometric lock is enabled, the app will require authentication every time it opens.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

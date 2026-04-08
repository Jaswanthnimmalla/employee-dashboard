import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4361EE);
  static const Color primaryDark = Color(0xFF3A56D4);
  static const Color primaryLight = Color(0xFF6C8AFF);
  static const Color secondary = Color(0xFFF72585);
  static const Color secondaryLight = Color(0xFFFF4D8C);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF2B2D42);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textHint = Color(0xFFADB5BD);
  static const Color success = Color(0xFF06D6A0);
  static const Color error = Color(0xFFEF476F);
  static const Color warning = Color(0xFFF9C74F);
  static const Color info = Color(0xFF4895EF);
  static const Color border = Color(0xFFE9ECEF);
  static const Color divider = Color(0xFFDEE2E6);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

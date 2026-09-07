import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primaryPurple = Color(0xFF6C5294);
  static const Color deepPurple = Color(0xFF422B74);
  static const Color lightPurple = Color(0xFF947CB8);
  static const Color palePurple = Color(0xFFF0ECF6);

  // Background & Surfaces
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F6FA);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFEBEBF0);

  // Financial Accents
  static const Color incomeGreen = Color(0xFF2E7D32);
  static const Color incomeLightGreen = Color(0xFFE8F5E9);
  static const Color expenseRed = Color(0xFFE53935);
  static const Color expenseLightRed = Color(0xFFFFEBEE);

  // Additional Accent Colors
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color accentTeal = Color(0xFF00897B);

  // Text Colors
  static const Color textPrimary = Color(0xFF1D1B20);
  static const Color textSecondary = Color(0xFF75747A);
  static const Color textLight = Color(0xFFADABB2);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Card Gradient
  static const LinearGradient balanceCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF422B74),
      Color(0xFF6C5294),
    ],
  );

  static const LinearGradient purpleButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF422B74),
      Color(0xFF6C5294),
    ],
  );
}

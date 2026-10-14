import 'package:flutter/material.dart';

class AppColors {
  static const pesoSymbol = '₱';
  static const orange = Color(0xFFFF7900);
  static const orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF922F),
      Color(0xFFFF8423),
      Color(0xFFF87818),
    ],
    stops: [0, 0.45, 1],
  );
  static const orangeLight = Color(0xFFFFB37A);
  static const orangeTint = Color(0xFFFFF1E6);
  static const pageBackground = Color(0xFFF5F5F5);
  static const surface = Color(0xFFF5F5F5);
  static const inputFill = Color(0xFFF3F3F3);
  static const inputBorder = Color(0xFFE0E0E0);
  static const textMuted = Color(0xFF666666);
  static const iconMuted = Color(0xFF4A4A4A);
}

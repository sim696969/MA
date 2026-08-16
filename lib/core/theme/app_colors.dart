import 'package:flutter/material.dart';

class AppColors {
  // Elegant Romance palette
  static const Color warmCream = Color(0xFFFDFBF7);
  static const Color navy = Color(0xFF161B22);
  static const Color blush = Color(0xFFE5989B);
  static const Color sage = Color(0xFF81B29A);
  static const Color charcoal = Color(0xFF2B2B2B);

  static const Color pureBlack = charcoal;
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Slate / Zinc Tones (Shadcn)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // Accent Tones
  static const Color accentBlack = Color(0xFF000000);
  static const Color accentLight = Color(0xFFF4F4F5);
  static const Color accentBorder = Color(0xFFE4E4E7);

  // Legacy names retained so existing feature screens inherit the palette.
  static const Color pinkPrimary = blush;
  static const Color pinkLight = Color(0xFFFBE7E7);
  static const Color pinkBorder = Color(0xFFF1C7C9);
  static const Color pinkGradientStart = Color(0xFFF2B8B5);
  static const Color pinkGradientEnd = blush;

  // Backgrounds
  static const Color backgroundLight = warmCream;
  static const Color backgroundDark = navy;

  // Primary
  static const Color primary = blush;
  static const Color onPrimary = Colors.white;

  // Borders
  static const Color borderLight = Color(0xFFE9E1DC);
  static const Color borderDark = Color(0xFF334155);
}

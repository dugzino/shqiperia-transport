import 'package:flutter/material.dart';

/// Brand palette for Kosova Transit — deep transit blue with warm accent.
abstract final class AppColors {
  static const Color primary = Color(0xFF0B3D91);
  static const Color primaryLight = Color(0xFF1E5BB8);
  static const Color secondary = Color(0xFFE85D04);
  static const Color secondarySoft = Color(0xFFFFF0E6);

  static const Color surface = Color(0xFFF7F8FA);
  static const Color surfaceDark = Color(0xFF121417);
  static const Color card = Colors.white;
  static const Color cardDark = Color(0xFF1C1F24);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnPrimary = Colors.white;

  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);

  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF2A2F36);

  /// Line badge colors for variety in the sample network.
  static const List<Color> linePalette = [
    Color(0xFF0B3D91),
    Color(0xFFE85D04),
    Color(0xFF059669),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
    Color(0xFF0891B2),
    Color(0xFFCA8A04),
    Color(0xFFDB2777),
  ];
}

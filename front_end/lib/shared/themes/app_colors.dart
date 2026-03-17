import 'package:flutter/material.dart';

/// Paleta principal de l'aplicació.
///
/// Criteri visual:
/// - base neutra i elegant
/// - blau grisós com a color principal
/// - accent discret per interaccions i highlights
/// - colors d'estat clars i professionals
class AppColors {
  AppColors._();

  // Brand / primaris
  static const Color primary = Color(0xFF234A67);
  static const Color primaryLight = Color(0xFF35627F);
  static const Color primaryDark = Color(0xFF18364D);

  static const Color secondary = Color(0xFF5E7486);
  static const Color accent = Color(0xFF3C7A89);

  // Fons i superfícies
  static const Color background = Color(0xFFF4F6F8);
  static const Color surface = Colors.white;
  static const Color surfaceSoft = Color(0xFFF8FAFB);
  static const Color surfaceMuted = Color(0xFFEEF2F5);

  // Text
  static const Color textPrimary = Color(0xFF1F2933);
  static const Color textSecondary = Color(0xFF52606D);
  static const Color textMuted = Color(0xFF7B8794);
  static const Color textOnDark = Colors.white;

  // Borders / divisors
  static const Color border = Color(0xFFD9E2EC);
  static const Color divider = Color(0xFFE5EAF0);

  // Estats
  static const Color success = Color(0xFF2F855A);
  static const Color successSoft = Color(0xFFE6F4EC);

  static const Color warning = Color(0xFFB7791F);
  static const Color warningSoft = Color(0xFFFBF1DE);

  static const Color error = Color(0xFFC53030);
  static const Color errorSoft = Color(0xFFFCE8E8);

  static const Color info = Color(0xFF2B6CB0);
  static const Color infoSoft = Color(0xFFE7F0FA);

  // Altres
  static const Color disabled = Color(0xFFBCC7D1);
  static const Color overlay = Color(0x66000000);

  /// ColorScheme base per al tema clar.
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: textOnDark,
    secondary: secondary,
    onSecondary: textOnDark,
    error: error,
    onError: textOnDark,
    surface: surface,
    onSurface: textPrimary,
  );
}
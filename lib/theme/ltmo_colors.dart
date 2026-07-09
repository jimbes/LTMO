import 'package:flutter/material.dart';

/// Palette couleurs LTMO — Direction « Cocon »
class LtmoColors {
  LtmoColors._();

  /// #34302A — fond sombre, texte principal
  static const Color encre = Color(0xFF34302A);

  /// #7E9C89 — sauge, couleur d'action principale
  static const Color sauge = Color(0xFF7E9C89);

  /// #C39A82 — argile, couleur d'accent secondaire
  static const Color argile = Color(0xFFC39A82);

  /// #ECE1CF — sable, fond icône clair
  static const Color sable = Color(0xFFECE1CF);

  /// #F5F1EA — crème, fond app principal
  static const Color creme = Color(0xFFF5F1EA);

  /// Thème clair
  static ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.light(
      primary: sauge,
      secondary: argile,
      surface: creme,
      onPrimary: Colors.white,
      onSurface: encre,
    ),
    scaffoldBackgroundColor: creme,
  );

  /// Thème sombre
  static ThemeData get darkTheme => ThemeData(
    colorScheme: ColorScheme.dark(
      primary: sauge,
      secondary: argile,
      surface: encre,
      onPrimary: creme,
      onSurface: creme,
    ),
    scaffoldBackgroundColor: encre,
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Display & Large Titles — Newsreader (serif)
  static TextStyle get displayLarge => GoogleFonts.newsreader(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        height: 1.12,
      );

  static TextStyle get displayMedium => GoogleFonts.newsreader(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        height: 1.16,
      );

  static TextStyle get displaySmall => GoogleFonts.newsreader(
        fontSize: 36,
        fontWeight: FontWeight.w500,
        height: 1.22,
      );

  // Headlines — Newsreader
  static TextStyle get headline1 => GoogleFonts.newsreader(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.25,
      );

  static TextStyle get headline2 => GoogleFonts.newsreader(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        height: 1.29,
      );

  static TextStyle get headline3 => GoogleFonts.newsreader(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.33,
      );

  // Titles — Mulish (sans-serif)
  static TextStyle get titleLarge => GoogleFonts.mulish(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.27,
      );

  static TextStyle get titleMedium => GoogleFonts.mulish(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  static TextStyle get titleSmall => GoogleFonts.mulish(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
      );

  // Body — Mulish
  static TextStyle get bodyLarge => GoogleFonts.mulish(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.mulish(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
      );

  static TextStyle get bodySmall => GoogleFonts.mulish(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
      );

  // Labels — Mulish, heavier weight
  static TextStyle get labelLarge => GoogleFonts.mulish(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.43,
      );

  static TextStyle get labelMedium => GoogleFonts.mulish(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.33,
      );

  static TextStyle get labelSmall => GoogleFonts.mulish(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        height: 1.45,
        letterSpacing: 0.5,
      );
}

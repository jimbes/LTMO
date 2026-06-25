import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Colors
      colorScheme: ColorScheme.light(
        primary: AppColors.sage,
        primaryContainer: AppColors.sageBgLight,
        secondary: AppColors.clay,
        secondaryContainer: AppColors.clayBgLight,
        tertiary: AppColors.clay,
        tertiaryContainer: AppColors.clayBgLight,
        surface: AppColors.cream,
        surfaceContainerHighest: AppColors.white,
        error: AppColors.error,
        outline: AppColors.border1,
      ),
      scaffoldBackgroundColor: AppColors.cream,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.sage,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: AppColors.border1,
            width: 1,
          ),
        ),
        shadowColor: AppColors.shadowColor,
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border1,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border1,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.sage,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.inkSecondary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.inkDisabled,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sage,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
          shadowColor: AppColors.sage.withOpacity(0.4),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sage,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(
            color: AppColors.sage,
            width: 2,
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.sage,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.sage,
        foregroundColor: AppColors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.cream,
        selectedItemColor: AppColors.sage,
        unselectedItemColor: AppColors.inkTertiary,
        showUnselectedLabels: true,
        selectedLabelStyle: AppTypography.labelSmall,
        unselectedLabelStyle: AppTypography.labelSmall,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Switches & Toggles
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.sage;
          }
          return AppColors.border1;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.sageBgLight;
          }
          return AppColors.border2;
        }),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.sage,
        disabledColor: AppColors.inkDisabled,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: AppColors.border1,
          ),
        ),
        labelStyle: AppTypography.bodyMedium,
        secondaryLabelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.white,
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTypography.headline3.copyWith(
          color: AppColors.ink,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.inkSecondary,
        ),
      ),

      // Text themes
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.ink,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.ink,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.ink,
        ),
        headlineLarge: AppTypography.headline1.copyWith(
          color: AppColors.ink,
        ),
        headlineMedium: AppTypography.headline2.copyWith(
          color: AppColors.ink,
        ),
        headlineSmall: AppTypography.headline3.copyWith(
          color: AppColors.ink,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.ink,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.ink,
        ),
        titleSmall: AppTypography.titleSmall.copyWith(
          color: AppColors.ink,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.ink,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.inkSecondary,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.inkTertiary,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.ink,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.ink,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.inkSecondary,
        ),
      ),
    );
  }
}

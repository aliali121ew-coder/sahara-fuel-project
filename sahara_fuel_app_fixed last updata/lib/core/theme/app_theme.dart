import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_schemes.dart';
import 'app_dimensions.dart';

/// Centralized theme factory for the Sahara Fuel app.
/// Provides both light and dark ThemeData with proper Material 3 support.
class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF00D9A3);

  // ===== Dark Theme =====
  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF0D1B2A),
      surfaceContainerHighest: const Color(0xFF252D3D),
      primary: const Color(0xFF00D9A3),
      onPrimary: Colors.white,
      secondary: const Color(0xFFF4A261),
      onSecondary: Colors.white,
      error: const Color(0xFFEF5350),
      onError: Colors.white,
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFFB0B0B0),
      outline: const Color(0xFF424242),
      outlineVariant: const Color(0xFF2D3748),
    );

    return _buildTheme(colorScheme, Brightness.dark, SaharaColors.dark);
  }

  // ===== Light Theme =====
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFF8FAFB),
      surfaceContainerHighest: const Color(0xFFF5F6F8),
      primary: const Color(0xFF009D78),
      onPrimary: Colors.white,
      secondary: const Color(0xFFD87A2A),
      onSecondary: Colors.white,
      error: const Color(0xFFD32F2F),
      onError: Colors.white,
      onSurface: const Color(0xFF0F1419),
      onSurfaceVariant: const Color(0xFF4B5563),
      outline: const Color(0xFFE2E4E8),
      outlineVariant: const Color(0xFFD0D5DD),
    );

    return _buildTheme(colorScheme, Brightness.light, SaharaColors.light);
  }

  // ===== Shared Theme Builder =====
  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    Brightness brightness,
    SaharaColors saharaColors,
  ) {
    final isDark = brightness == Brightness.dark;
    final textTheme = GoogleFonts.cairoTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        elevation: isDark ? AppDimensions.elevationLow : AppDimensions.elevationMedium,
        shadowColor: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.grey.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLg,
          side: isDark
              ? BorderSide.none
              : BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: AppDimensions.elevationLow,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMd,
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMd,
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: saharaColors.inputBg,
        hintStyle: GoogleFonts.cairo(
          color: saharaColors.hintText,
          fontSize: 14,
        ),
        contentPadding: AppDimensions.paddingInput,
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF0F2438) : const Color(0xFFFBFCFE),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLg,
        ),
        elevation: AppDimensions.elevationHigh,
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: saharaColors.inputBg,
        labelStyle: GoogleFonts.cairo(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusSm,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1A1F2E) : const Color(0xFF323232),
        contentTextStyle: GoogleFonts.cairo(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMd,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // DataTable
      dataTableTheme: DataTableThemeData(
        headingTextStyle: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: colorScheme.onSurface,
        ),
        dataTextStyle: GoogleFonts.cairo(
          fontSize: 13,
          color: colorScheme.onSurface,
        ),
        headingRowColor: WidgetStateProperty.all(saharaColors.tableHeader),
        decoration: BoxDecoration(
          borderRadius: AppDimensions.borderRadiusMd,
        ),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        textStyle: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: 12,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFF323232),
          borderRadius: AppDimensions.borderRadiusSm,
        ),
      ),

      // Extensions
      extensions: [saharaColors],
    );
  }
}

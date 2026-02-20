import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_schemes.dart';
import 'app_dimensions.dart';

/// Centralized theme factory for the Sahara Fuel app.
///
/// Architecture:
///   Seed Color → ColorScheme.fromSeed() → Tonal Palette
///   → Light: ZERO overrides — pure M3 harmony
///   → Dark:  surface overrides only (branded navy)
///   → SaharaColors.fromScheme() derives custom tokens from palette
///   → ThemeData uses scheme semantics (NO hardcoded colors)
class AppTheme {
  AppTheme._();

  /// Brand seed color — the single source of truth for the entire palette.
  static const _seedColor = Color(0xFF00D9A3);

  // ===== Dark Theme =====
  // Override surface system to branded navy tones; everything else from seed.
  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      // Branded navy surface elevation system
      surface:                    const Color(0xFF0D1B2A),
      surfaceDim:                 const Color(0xFF081420),
      surfaceBright:              const Color(0xFF1A3654),
      surfaceContainerLowest:     const Color(0xFF060F1A),
      surfaceContainerLow:        const Color(0xFF0F2438),
      surfaceContainer:           const Color(0xFF142D45),
      surfaceContainerHigh:       const Color(0xFF1A3654),
      surfaceContainerHighest:    const Color(0xFF213F5E),
      onSurface:                  Colors.white,
      onSurfaceVariant:           const Color(0xFFB0BEC5),
      outline:                    const Color(0xFF546E7A),
      outlineVariant:             const Color(0xFF37474F),
    );

    return _buildTheme(
      colorScheme,
      Brightness.dark,
      SaharaColors.fromScheme(colorScheme, isDark: true),
    );
  }

  // ===== Light Theme =====
  // Pure ColorScheme.fromSeed() — ZERO overrides. M3 generates everything.
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    return _buildTheme(
      colorScheme,
      Brightness.light,
      SaharaColors.fromScheme(colorScheme, isDark: false),
    );
  }

  // ===== Shared Theme Builder =====
  // Uses ONLY ColorScheme tokens — no hardcoded Color() values.
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

      // AppBar — uses scheme surface
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: colorScheme.surfaceTint,
        shadowColor: colorScheme.shadow,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),

      // Cards — uses scheme surfaceContainerLow (M3 elevation level)
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: isDark ? 1 : 2,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLg,
          side: isDark
              ? BorderSide.none
              : BorderSide(color: colorScheme.outlineVariant),
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

      // Input Fields — uses scheme tokens
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        hintStyle: GoogleFonts.cairo(
          color: colorScheme.onSurfaceVariant,
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

      // Dialogs — uses scheme surfaceContainerHigh
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLg,
        ),
        elevation: 6,
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        labelStyle: GoogleFonts.cairo(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusSm,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.cairo(
          color: colorScheme.onInverseSurface,
        ),
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
        headingRowColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHighest,
        ),
        decoration: BoxDecoration(
          borderRadius: AppDimensions.borderRadiusMd,
        ),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        textStyle: GoogleFonts.cairo(
          color: colorScheme.onInverseSurface,
          fontSize: 12,
        ),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: AppDimensions.borderRadiusSm,
        ),
      ),

      // Extensions
      extensions: [saharaColors],
    );
  }
}

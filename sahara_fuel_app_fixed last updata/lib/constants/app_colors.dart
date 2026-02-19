import 'package:flutter/material.dart';
import '../core/theme/color_schemes.dart';

/// Legacy color accessor — delegates to ThemeData when a BuildContext is available.
/// Static getters (no context) remain for backward compatibility during migration.
/// Prefer using `Theme.of(context).colorScheme` and `context.sahara` in new code.
class AppColors {
  static bool isDark = true;

  // ─── Static getters (backward-compat, used where no context is available) ───

  static Color get primary =>
      isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF8FAFB);
  static Color get accent =>
      isDark ? const Color(0xFF00D9A3) : const Color(0xFF009D78);
  static Color get orange =>
      isDark ? const Color(0xFFF4A261) : const Color(0xFFD87A2A);
  static Color get cardBg =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);

  static List<Color> get pageGradient => isDark
      ? [const Color(0xFF0D1B2A), const Color(0xFF0F2438), const Color(0xFF0F2847)]
      : [const Color(0xFFF5F7FA), const Color(0xFFE8ECF1), const Color(0xFFF0F2F5)];

  static Color get gradientStart =>
      isDark ? const Color(0xFF1F4D6D) : const Color(0xFFB3D9F2);
  static Color get gradientMiddle =>
      isDark ? const Color(0xFF0D2847) : const Color(0xFF7CB8DD);
  static Color get gradientEnd =>
      isDark ? const Color(0xFF1A3A52) : const Color(0xFFD4E7F7);

  static Color get cardGreen =>
      isDark ? const Color(0xFF00D9A3) : const Color(0xFF009D78);
  static Color get cardOrange =>
      isDark ? const Color(0xFFFFA726) : const Color(0xFFD87A2A);
  static Color get cardPurple =>
      isDark ? const Color(0xFFAB47BC) : const Color(0xFF7C3B8F);

  static Color get textPrimary =>
      isDark ? Colors.white : const Color(0xFF0F1419);
  static Color get textSecondary =>
      isDark ? const Color(0xFFB0B0B0) : const Color(0xFF4B5563);

  static Color get success =>
      isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  static Color get warning =>
      isDark ? const Color(0xFFFFA726) : const Color(0xFFD87A2A);
  static Color get error =>
      isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
  static Color get info =>
      isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);

  static Color get scaffold =>
      isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF8FAFB);
  static Color get surface =>
      isDark ? const Color(0xFF1A1F2E) : const Color(0xFFFFFFFF);
  static Color get surfaceVariant =>
      isDark ? const Color(0xFF252D3D) : const Color(0xFFF5F6F8);
  static Color get sidebar =>
      isDark ? const Color(0xFF1A1F2E) : const Color(0xFFFFFFFF);
  static Color get sidebarBorder =>
      isDark ? Colors.grey[800]! : const Color(0xFFE2E4E8);
  static Color get divider =>
      isDark ? Colors.grey[800]! : const Color(0xFFE2E4E8);
  static Color get inputBg =>
      isDark ? const Color(0xFF252D3D) : const Color(0xFFF5F6F8);
  static Color get dialogBg =>
      isDark ? const Color(0xFF0F2438) : const Color(0xFFFBFCFE);
  static Color get tableHeader =>
      isDark ? const Color(0xFF0F2438) : const Color(0xFFF2F4F8);
  static Color get hintText =>
      isDark ? Colors.grey[600]! : const Color(0xFF8A92A0);
  static Color get subtleText =>
      isDark ? Colors.grey[500]! : const Color(0xFF9CA5B3);
  static Color get cardShadow =>
      isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.08);
  static Color get iconDefault =>
      isDark ? Colors.grey[500]! : Colors.grey[600]!;

  static Color get badgeBg => isDark ? const Color(0xFF1A1F2E) : Colors.white;
  static Color get badgeBorder =>
      isDark ? accent.withOpacity(0.2) : const Color(0xFFD0D5DD);

  static Color get chartBlue =>
      isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
  static Color get chartGreen =>
      isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  static Color get chartOrange =>
      isDark ? const Color(0xFFFFA726) : const Color(0xFFD87A2A);
  static Color get chartRed =>
      isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
  static Color get chartPurple =>
      isDark ? const Color(0xFF8B5CF6) : const Color(0xFF6A1B9A);

  static Color get statBg =>
      isDark ? const Color(0xFF1A1F2E) : const Color(0xFFF5F7FA);
  static Color get statBorder =>
      isDark ? const Color(0xFF2D3748) : const Color(0xFFD0D5DD);

  static Color get tableRowEven => isDark
      ? const Color(0xFF1E2127).withOpacity(0.3)
      : const Color(0xFFF5F7FA);
  static Color get tableRowOdd =>
      isDark ? Colors.transparent : const Color(0xFFFFFFFF);
  static Color get dialogHeader =>
      isDark ? const Color(0xFF1E2127) : const Color(0xFFEFF1F5);

  // ─── Context-aware accessors (delegate to ThemeData) ───

  static Color getPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color getAccent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color getOrange(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color getCardBg(BuildContext context) =>
      Theme.of(context).cardTheme.color ?? surface;

  static List<Color> getPageGradient(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.pageGradient;
  static Color getGradientStart(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.gradientStart;
  static Color getGradientMiddle(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.gradientMiddle;
  static Color getGradientEnd(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.gradientEnd;

  static Color getCardGreen(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.cardGreen;
  static Color getCardOrange(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.cardOrange;
  static Color getCardPurple(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.cardPurple;

  static Color getTextPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color getTextSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color getSuccess(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.chartGreen;
  static Color getWarning(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.chartOrange;
  static Color getError(BuildContext context) =>
      Theme.of(context).colorScheme.error;
  static Color getInfo(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.chartBlue;

  static Color getScaffold(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color getSurface(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.sidebar;
  static Color getSurfaceVariant(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color getSidebar(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.sidebar;
  static Color getSidebarBorder(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.sidebarBorder;
  static Color getDivider(BuildContext context) =>
      Theme.of(context).colorScheme.outline;
  static Color getInputBg(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.inputBg;
  static Color getDialogBg(BuildContext context) =>
      Theme.of(context).dialogTheme.backgroundColor ?? dialogBg;
  static Color getTableHeader(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.tableHeader;
  static Color getHintText(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.hintText;
  static Color getSubtleText(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.subtleText;
  static Color getCardShadow(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.grey.withOpacity(0.08);
  }
  static Color getIconDefault(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.grey[500]! : Colors.grey[600]!;
  }

  static Color getBadgeBg(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.badgeBg;
  static Color getBadgeBorder(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.badgeBorder;

  static Color getChartBlue(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.chartBlue;
  static Color getChartGreen(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.chartGreen;
  static Color getChartOrange(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.chartOrange;
  static Color getChartRed(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.chartRed;
  static Color getChartPurple(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.chartPurple;

  static Color getStatBg(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.statBg;
  static Color getStatBorder(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.statBorder;

  static Color getTableRowEven(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.tableRowEven;
  static Color getTableRowOdd(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.tableRowOdd;
  static Color getDialogHeader(BuildContext context) =>
      Theme.of(context).extension<SaharaColors>()!.dialogHeader;

  static bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

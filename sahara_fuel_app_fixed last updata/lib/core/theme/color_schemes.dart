import 'package:flutter/material.dart';

/// Custom theme extension for Sahara-specific colors not covered by ColorScheme.
///
/// Architecture (Material 3 compliant):
///   Seed Color → ColorScheme.fromSeed() → Tonal Palette
///   → SaharaColors.fromScheme() derives surface/semantic tokens from palette
///   → Only brand-specific colors (charts, gradients, sidebar) are manual constants
class SaharaColors extends ThemeExtension<SaharaColors> {
  final Color cardGreen;
  final Color cardOrange;
  final Color cardPurple;
  final Color chartBlue;
  final Color chartGreen;
  final Color chartOrange;
  final Color chartRed;
  final Color chartPurple;
  final Color sidebar;
  final Color sidebarBorder;
  final Color tableHeader;
  final Color tableRowEven;
  final Color tableRowOdd;
  final Color dialogHeader;
  final Color inputBg;
  final Color hintText;
  final Color subtleText;
  final Color badgeBg;
  final Color badgeBorder;
  final Color statBg;
  final Color statBorder;
  final Color accent;
  final Color gradientStart;
  final Color gradientMiddle;
  final Color gradientEnd;
  final List<Color> pageGradient;
  final Color sidebarText;
  final Color sidebarSubtle;
  final Color sidebarIconBg;
  final Color sidebarHoverBg;

  const SaharaColors({
    required this.cardGreen,
    required this.cardOrange,
    required this.cardPurple,
    required this.chartBlue,
    required this.chartGreen,
    required this.chartOrange,
    required this.chartRed,
    required this.chartPurple,
    required this.sidebar,
    required this.sidebarBorder,
    required this.tableHeader,
    required this.tableRowEven,
    required this.tableRowOdd,
    required this.dialogHeader,
    required this.inputBg,
    required this.hintText,
    required this.subtleText,
    required this.badgeBg,
    required this.badgeBorder,
    required this.statBg,
    required this.statBorder,
    required this.accent,
    required this.gradientStart,
    required this.gradientMiddle,
    required this.gradientEnd,
    required this.pageGradient,
    required this.sidebarText,
    required this.sidebarSubtle,
    required this.sidebarIconBg,
    required this.sidebarHoverBg,
  });

  // ═══════════════════════════════════════════════════════════════════
  // Factory: derives colors from the M3 ColorScheme tonal palette.
  // Surface/semantic colors come FROM the palette → guaranteed harmony.
  // Only brand-specific colors (charts, sidebar, gradients) are manual.
  // ═══════════════════════════════════════════════════════════════════
  static SaharaColors fromScheme(ColorScheme cs, {required bool isDark}) {
    return SaharaColors(
      // ── Dashboard card accent colors (brand constants) ──
      cardGreen:   isDark ? const Color(0xFF00D9A3) : const Color(0xFF0A8A6A),
      cardOrange:  isDark ? const Color(0xFFFFA726) : const Color(0xFFD4772B),
      cardPurple:  isDark ? const Color(0xFFAB47BC) : const Color(0xFF6B3FA0),

      // ── Chart colors (brand constants) ──
      chartBlue:   isDark ? const Color(0xFF42A5F5) : const Color(0xFF2B6CB0),
      chartGreen:  isDark ? const Color(0xFF10B981) : const Color(0xFF0D9668),
      chartOrange: isDark ? const Color(0xFFFFA726) : const Color(0xFFDD8B39),
      chartRed:    isDark ? const Color(0xFFEF5350) : const Color(0xFFC53030),
      chartPurple: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF6B46C1),

      // ── Sidebar (dark navy in both modes — pro ERP design) ──
      sidebar:      isDark ? const Color(0xFF1A1F2E) : const Color(0xFF1B2A3D),
      sidebarBorder: isDark ? cs.outlineVariant : const Color(0xFF2D4052),
      sidebarText:   const Color(0xFFECEFF4),
      sidebarSubtle: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF8899AA),
      sidebarIconBg: isDark ? const Color(0xFF252D3D) : const Color(0xFF243447),
      sidebarHoverBg: const Color(0x1AFFFFFF),

      // ── Surfaces → derived from M3 tonal palette ──
      tableHeader:  cs.surfaceContainerHighest,
      tableRowEven: cs.surfaceContainerLow,
      tableRowOdd:  cs.surface,
      dialogHeader: cs.surfaceContainerHigh,
      inputBg:      cs.surfaceContainerLow,

      // ── Text → derived from M3 semantic tokens ──
      hintText:   cs.onSurfaceVariant,
      subtleText: cs.outline,

      // ── Badges & Stats → derived from M3 elevation surfaces ──
      badgeBg:     cs.surfaceContainerLowest,
      badgeBorder: cs.outlineVariant,
      statBg:      cs.surfaceContainerLow,
      statBorder:  cs.outlineVariant,

      // ── Accent = primary from scheme ──
      accent: cs.primary,

      // ── Gradients (brand — sidebar-matching for headers) ──
      gradientStart:  isDark ? const Color(0xFF1F4D6D) : const Color(0xFF1B2A3D),
      gradientMiddle: isDark ? const Color(0xFF0D2847) : const Color(0xFF2A4A5E),
      gradientEnd:    isDark ? const Color(0xFF1A3A52) : const Color(0xFF1D3A50),

      // ── Page gradient → derived from M3 surface tones ──
      pageGradient: isDark
          ? [cs.surface, cs.surfaceContainerLow, cs.surfaceContainer]
          : [cs.surfaceContainerLowest, cs.surfaceContainerLow, cs.surface],
    );
  }

  @override
  SaharaColors copyWith({
    Color? cardGreen,
    Color? cardOrange,
    Color? cardPurple,
    Color? chartBlue,
    Color? chartGreen,
    Color? chartOrange,
    Color? chartRed,
    Color? chartPurple,
    Color? sidebar,
    Color? sidebarBorder,
    Color? tableHeader,
    Color? tableRowEven,
    Color? tableRowOdd,
    Color? dialogHeader,
    Color? inputBg,
    Color? hintText,
    Color? subtleText,
    Color? badgeBg,
    Color? badgeBorder,
    Color? statBg,
    Color? statBorder,
    Color? accent,
    Color? gradientStart,
    Color? gradientMiddle,
    Color? gradientEnd,
    List<Color>? pageGradient,
    Color? sidebarText,
    Color? sidebarSubtle,
    Color? sidebarIconBg,
    Color? sidebarHoverBg,
  }) {
    return SaharaColors(
      cardGreen: cardGreen ?? this.cardGreen,
      cardOrange: cardOrange ?? this.cardOrange,
      cardPurple: cardPurple ?? this.cardPurple,
      chartBlue: chartBlue ?? this.chartBlue,
      chartGreen: chartGreen ?? this.chartGreen,
      chartOrange: chartOrange ?? this.chartOrange,
      chartRed: chartRed ?? this.chartRed,
      chartPurple: chartPurple ?? this.chartPurple,
      sidebar: sidebar ?? this.sidebar,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      tableHeader: tableHeader ?? this.tableHeader,
      tableRowEven: tableRowEven ?? this.tableRowEven,
      tableRowOdd: tableRowOdd ?? this.tableRowOdd,
      dialogHeader: dialogHeader ?? this.dialogHeader,
      inputBg: inputBg ?? this.inputBg,
      hintText: hintText ?? this.hintText,
      subtleText: subtleText ?? this.subtleText,
      badgeBg: badgeBg ?? this.badgeBg,
      badgeBorder: badgeBorder ?? this.badgeBorder,
      statBg: statBg ?? this.statBg,
      statBorder: statBorder ?? this.statBorder,
      accent: accent ?? this.accent,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientMiddle: gradientMiddle ?? this.gradientMiddle,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      pageGradient: pageGradient ?? this.pageGradient,
      sidebarText: sidebarText ?? this.sidebarText,
      sidebarSubtle: sidebarSubtle ?? this.sidebarSubtle,
      sidebarIconBg: sidebarIconBg ?? this.sidebarIconBg,
      sidebarHoverBg: sidebarHoverBg ?? this.sidebarHoverBg,
    );
  }

  @override
  SaharaColors lerp(ThemeExtension<SaharaColors>? other, double t) {
    if (other is! SaharaColors) return this;
    return SaharaColors(
      cardGreen: Color.lerp(cardGreen, other.cardGreen, t)!,
      cardOrange: Color.lerp(cardOrange, other.cardOrange, t)!,
      cardPurple: Color.lerp(cardPurple, other.cardPurple, t)!,
      chartBlue: Color.lerp(chartBlue, other.chartBlue, t)!,
      chartGreen: Color.lerp(chartGreen, other.chartGreen, t)!,
      chartOrange: Color.lerp(chartOrange, other.chartOrange, t)!,
      chartRed: Color.lerp(chartRed, other.chartRed, t)!,
      chartPurple: Color.lerp(chartPurple, other.chartPurple, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      sidebarBorder: Color.lerp(sidebarBorder, other.sidebarBorder, t)!,
      tableHeader: Color.lerp(tableHeader, other.tableHeader, t)!,
      tableRowEven: Color.lerp(tableRowEven, other.tableRowEven, t)!,
      tableRowOdd: Color.lerp(tableRowOdd, other.tableRowOdd, t)!,
      dialogHeader: Color.lerp(dialogHeader, other.dialogHeader, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      hintText: Color.lerp(hintText, other.hintText, t)!,
      subtleText: Color.lerp(subtleText, other.subtleText, t)!,
      badgeBg: Color.lerp(badgeBg, other.badgeBg, t)!,
      badgeBorder: Color.lerp(badgeBorder, other.badgeBorder, t)!,
      statBg: Color.lerp(statBg, other.statBg, t)!,
      statBorder: Color.lerp(statBorder, other.statBorder, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientMiddle: Color.lerp(gradientMiddle, other.gradientMiddle, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      pageGradient: [
        Color.lerp(pageGradient[0], other.pageGradient[0], t)!,
        Color.lerp(pageGradient[1], other.pageGradient[1], t)!,
        Color.lerp(pageGradient[2], other.pageGradient[2], t)!,
      ],
      sidebarText: Color.lerp(sidebarText, other.sidebarText, t)!,
      sidebarSubtle: Color.lerp(sidebarSubtle, other.sidebarSubtle, t)!,
      sidebarIconBg: Color.lerp(sidebarIconBg, other.sidebarIconBg, t)!,
      sidebarHoverBg: Color.lerp(sidebarHoverBg, other.sidebarHoverBg, t)!,
    );
  }
}

/// Helper extension to easily access SaharaColors from BuildContext.
extension SaharaColorsExtension on BuildContext {
  SaharaColors get sahara => Theme.of(this).extension<SaharaColors>()!;
}

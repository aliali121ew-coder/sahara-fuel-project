import 'package:flutter/material.dart';

/// Custom theme extension for Sahara-specific colors not covered by ColorScheme.
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
  });

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
    );
  }

  // ===== Dark Theme Colors =====
  static const dark = SaharaColors(
    cardGreen: Color(0xFF00D9A3),
    cardOrange: Color(0xFFFFA726),
    cardPurple: Color(0xFFAB47BC),
    chartBlue: Color(0xFF42A5F5),
    chartGreen: Color(0xFF10B981),
    chartOrange: Color(0xFFFFA726),
    chartRed: Color(0xFFEF5350),
    chartPurple: Color(0xFF8B5CF6),
    sidebar: Color(0xFF1A1F2E),
    sidebarBorder: Color(0xFF424242),
    tableHeader: Color(0xFF0F2438),
    tableRowEven: Color(0x4D1E2127),
    tableRowOdd: Colors.transparent,
    dialogHeader: Color(0xFF1E2127),
    inputBg: Color(0xFF252D3D),
    hintText: Color(0xFF757575),
    subtleText: Color(0xFF9E9E9E),
    badgeBg: Color(0xFF1A1F2E),
    badgeBorder: Color(0x3300D9A3),
    statBg: Color(0xFF1A1F2E),
    statBorder: Color(0xFF2D3748),
    accent: Color(0xFF00D9A3),
    gradientStart: Color(0xFF1F4D6D),
    gradientMiddle: Color(0xFF0D2847),
    gradientEnd: Color(0xFF1A3A52),
    pageGradient: [Color(0xFF0D1B2A), Color(0xFF0F2438), Color(0xFF0F2847)],
  );

  // ===== Light Theme Colors =====
  static const light = SaharaColors(
    cardGreen: Color(0xFF009D78),
    cardOrange: Color(0xFFD87A2A),
    cardPurple: Color(0xFF7C3B8F),
    chartBlue: Color(0xFF1976D2),
    chartGreen: Color(0xFF059669),
    chartOrange: Color(0xFFD87A2A),
    chartRed: Color(0xFFD32F2F),
    chartPurple: Color(0xFF6A1B9A),
    sidebar: Color(0xFFFFFFFF),
    sidebarBorder: Color(0xFFE2E4E8),
    tableHeader: Color(0xFFF2F4F8),
    tableRowEven: Color(0xFFF5F7FA),
    tableRowOdd: Color(0xFFFFFFFF),
    dialogHeader: Color(0xFFEFF1F5),
    inputBg: Color(0xFFF5F6F8),
    hintText: Color(0xFF8A92A0),
    subtleText: Color(0xFF9CA5B3),
    badgeBg: Color(0xFFFFFFFF),
    badgeBorder: Color(0xFFD0D5DD),
    statBg: Color(0xFFF5F7FA),
    statBorder: Color(0xFFD0D5DD),
    accent: Color(0xFF009D78),
    gradientStart: Color(0xFFB3D9F2),
    gradientMiddle: Color(0xFF7CB8DD),
    gradientEnd: Color(0xFFD4E7F7),
    pageGradient: [Color(0xFFF5F7FA), Color(0xFFE8ECF1), Color(0xFFF0F2F5)],
  );
}

/// Helper extension to easily access SaharaColors from BuildContext.
extension SaharaColorsExtension on BuildContext {
  SaharaColors get sahara => Theme.of(this).extension<SaharaColors>()!;
}

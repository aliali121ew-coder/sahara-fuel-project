import 'package:flutter/material.dart';

/// Centralized spacing, radius, and elevation constants for the entire app.
class AppDimensions {
  AppDimensions._();

  // ===== Spacing =====
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // ===== Padding =====
  static const EdgeInsets paddingPage = EdgeInsets.all(24);
  static const EdgeInsets paddingCard = EdgeInsets.all(16);
  static const EdgeInsets paddingCardLarge = EdgeInsets.all(20);
  static const EdgeInsets paddingSection = EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  static const EdgeInsets paddingInput = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  // ===== Border Radius =====
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusRound = 100;

  static BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static BorderRadius borderRadiusRound = BorderRadius.circular(radiusRound);

  // ===== Elevation =====
  static const double elevationNone = 0;
  static const double elevationLow = 1;
  static const double elevationMedium = 4;
  static const double elevationHigh = 8;

  // ===== Sidebar =====
  static const double sidebarExpandedWidth = 260;
  static const double sidebarCollapsedWidth = 68;
  static const Duration sidebarAnimationDuration = Duration(milliseconds: 250);

  // ===== Breakpoints =====
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1200;
}

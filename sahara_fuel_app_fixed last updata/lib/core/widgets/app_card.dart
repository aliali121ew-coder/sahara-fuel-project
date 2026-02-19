import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';
import '../theme/color_schemes.dart';

/// Unified card widget for the entire app.
/// Replaces BalanceCard, DashboardCard, and ad-hoc Card usage.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Color? gradientColor;
  final VoidCallback? onTap;
  final double? elevation;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.gradientColor,
    this.onTap,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sahara = context.sahara;
    final radius = borderRadius ?? AppDimensions.borderRadiusXl;

    Widget content = Container(
      decoration: gradientColor != null
          ? BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                colors: [
                  gradientColor!.withOpacity(0.2),
                  gradientColor!.withOpacity(0.05),
                ],
              ),
            )
          : null,
      padding: padding ?? AppDimensions.paddingCardLarge,
      child: child,
    );

    final card = Card(
      color: color ?? theme.cardTheme.color ?? sahara.sidebar,
      elevation: elevation ?? AppDimensions.elevationMedium,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// Stat card variant — icon, value, title, change badge.
class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? change;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.change,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      gradientColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 36),
              if (change != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: AppDimensions.borderRadiusRound,
                  ),
                  child: Text(
                    change!,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

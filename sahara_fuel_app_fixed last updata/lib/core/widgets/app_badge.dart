import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';

enum AppBadgeType { info, success, warning, error }

/// Colored status badge / chip.
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeType type;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.type = AppBadgeType.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (type) {
      AppBadgeType.info => (
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
        ),
      AppBadgeType.success => (
          const Color(0xFF10B981).withOpacity(0.15),
          const Color(0xFF059669),
        ),
      AppBadgeType.warning => (
          const Color(0xFFFFA726).withOpacity(0.15),
          const Color(0xFFD87A2A),
        ),
      AppBadgeType.error => (
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppDimensions.borderRadiusRound,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

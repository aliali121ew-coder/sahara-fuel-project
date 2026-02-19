import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';

enum AppButtonVariant { primary, secondary, outlined, danger, ghost }

enum AppButtonSize { small, medium, large }

/// Unified button widget with loading state, icon support, and variants.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveOnPressed = isLoading ? null : onPressed;

    final double height;
    final double fontSize;
    final EdgeInsets padding;
    switch (size) {
      case AppButtonSize.small:
        height = 36;
        fontSize = 13;
        padding = const EdgeInsets.symmetric(horizontal: 12);
      case AppButtonSize.medium:
        height = 44;
        fontSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: 20);
      case AppButtonSize.large:
        height = 52;
        fontSize = 16;
        padding = const EdgeInsets.symmetric(horizontal: 28);
    }

    final Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _foregroundColor(colorScheme),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 4),
                const SizedBox(width: AppDimensions.spacingSm),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    final ButtonStyle style;
    switch (variant) {
      case AppButtonVariant.primary:
        style = ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: Size(expand ? double.infinity : 0, height),
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMd,
          ),
          elevation: AppDimensions.elevationLow,
        );
        return ElevatedButton(
            onPressed: effectiveOnPressed, style: style, child: child);

      case AppButtonVariant.secondary:
        style = ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          minimumSize: Size(expand ? double.infinity : 0, height),
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMd,
          ),
          elevation: AppDimensions.elevationNone,
        );
        return ElevatedButton(
            onPressed: effectiveOnPressed, style: style, child: child);

      case AppButtonVariant.outlined:
        style = OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: Size(expand ? double.infinity : 0, height),
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMd,
          ),
          side: BorderSide(color: colorScheme.outline),
        );
        return OutlinedButton(
            onPressed: effectiveOnPressed, style: style, child: child);

      case AppButtonVariant.danger:
        style = ElevatedButton.styleFrom(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          minimumSize: Size(expand ? double.infinity : 0, height),
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMd,
          ),
          elevation: AppDimensions.elevationLow,
        );
        return ElevatedButton(
            onPressed: effectiveOnPressed, style: style, child: child);

      case AppButtonVariant.ghost:
        style = TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: Size(expand ? double.infinity : 0, height),
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMd,
          ),
        );
        return TextButton(
            onPressed: effectiveOnPressed, style: style, child: child);
    }
  }

  Color _foregroundColor(ColorScheme cs) {
    switch (variant) {
      case AppButtonVariant.primary:
        return cs.onPrimary;
      case AppButtonVariant.secondary:
        return cs.onSecondaryContainer;
      case AppButtonVariant.outlined:
      case AppButtonVariant.ghost:
        return cs.primary;
      case AppButtonVariant.danger:
        return cs.onError;
    }
  }
}

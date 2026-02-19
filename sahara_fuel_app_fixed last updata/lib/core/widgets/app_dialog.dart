import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';
import '../theme/color_schemes.dart';
import 'app_button.dart';

/// Standardized confirmation dialog with consistent styling.
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final AppButtonVariant confirmVariant;
  final IconData? icon;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'تأكيد',
    this.cancelLabel = 'إلغاء',
    this.confirmVariant = AppButtonVariant.primary,
    this.icon,
  });

  /// Show the dialog and return true if confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'تأكيد',
    String cancelLabel = 'إلغاء',
    AppButtonVariant confirmVariant = AppButtonVariant.primary,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmVariant: confirmVariant,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = context.sahara;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.borderRadiusLg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: AppDimensions.paddingCard,
              decoration: BoxDecoration(
                color: sahara.dialogHeader,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusLg),
                  topRight: Radius.circular(AppDimensions.radiusLg),
                ),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: colorScheme.onSurface, size: 22),
                    const SizedBox(width: AppDimensions.spacingSm),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: AppDimensions.paddingCardLarge,
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.small,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  AppButton(
                    label: confirmLabel,
                    variant: confirmVariant,
                    size: AppButtonSize.small,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

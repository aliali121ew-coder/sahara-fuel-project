import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';
import '../theme/color_schemes.dart';

/// Unified page scaffold with gradient background, page title, and optional actions.
/// Replaces the repeated gradient-background + padding + title pattern across pages.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final EdgeInsets? padding;
  final bool useGradient;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.padding,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = context.sahara;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: useGradient
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: sahara.pageGradient,
                ),
              )
            : null,
        child: SafeArea(
          child: Padding(
            padding: padding ?? AppDimensions.paddingPage,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (actions != null) ...actions!,
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                // Page body
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

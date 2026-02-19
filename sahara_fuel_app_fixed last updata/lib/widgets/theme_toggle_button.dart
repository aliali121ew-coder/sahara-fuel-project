import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool useSmallSize;

  const ThemeToggleButton({
    super.key,
    this.useSmallSize = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return IconButton(
          onPressed: () => themeProvider.toggleTheme(),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
              key: ValueKey(themeProvider.isDark),
              size: useSmallSize ? 20 : 24,
            ),
          ),
          color: colorScheme.onSurface,
          tooltip: themeProvider.isDark ? 'الوضع النهاري' : 'الوضع الليلي',
        );
      },
    );
  }
}

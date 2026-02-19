import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';
import '../theme/color_schemes.dart';

/// Debounced search bar with consistent styling.
class AppSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final Duration debounceDuration;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    this.hint = 'بحث...',
    required this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 400),
    this.controller,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sahara = context.sahara;
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      onChanged: _onTextChanged,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: sahara.hintText, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: sahara.hintText, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (_, value, __) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(Icons.close, color: sahara.hintText, size: 18),
              onPressed: () {
                _controller.clear();
                widget.onChanged('');
              },
            );
          },
        ),
        filled: true,
        fillColor: sahara.inputBg,
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        contentPadding: AppDimensions.paddingInput,
      ),
    );
  }
}

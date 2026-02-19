import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// زر بحالة تحميل مدمجة مع معالجة أخطاء
class LoadingButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressed;
  final IconData? icon;
  final LoadingButtonVariant variant;
  final bool expand;
  final double height;
  final String? successMessage;
  final String? errorMessage;

  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = LoadingButtonVariant.primary,
    this.expand = false,
    this.height = 44,
    this.successMessage,
    this.errorMessage,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

enum LoadingButtonVariant { primary, danger, outlined, success }

enum _ButtonState { idle, loading, success, error }

class _LoadingButtonState extends State<LoadingButton>
    with SingleTickerProviderStateMixin {
  _ButtonState _state = _ButtonState.idle;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _bgColor(ColorScheme cs) {
    switch (widget.variant) {
      case LoadingButtonVariant.primary:
        return cs.primary;
      case LoadingButtonVariant.danger:
        return cs.error;
      case LoadingButtonVariant.outlined:
        return Colors.transparent;
      case LoadingButtonVariant.success:
        return const Color(0xFF10B981);
    }
  }

  Color _fgColor(ColorScheme cs) {
    switch (widget.variant) {
      case LoadingButtonVariant.primary:
        return cs.onPrimary;
      case LoadingButtonVariant.danger:
        return cs.onError;
      case LoadingButtonVariant.outlined:
        return cs.primary;
      case LoadingButtonVariant.success:
        return Colors.white;
    }
  }

  Future<void> _handlePress() async {
    if (_state == _ButtonState.loading) return;
    setState(() => _state = _ButtonState.loading);

    try {
      await widget.onPressed();
      if (!mounted) return;
      setState(() => _state = _ButtonState.success);

      if (widget.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.successMessage!,
                style: GoogleFonts.cairo(color: Colors.white)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _state = _ButtonState.idle);
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = _ButtonState.error);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.errorMessage ?? 'حدث خطأ: ${e.toString().substring(0, 80)}',
              style: GoogleFonts.cairo(color: Colors.white)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _state = _ButtonState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLoading = _state == _ButtonState.loading;
    final isSuccess = _state == _ButtonState.success;
    final isError = _state == _ButtonState.error;

    Color bg = _bgColor(cs);
    Color fg = _fgColor(cs);

    if (isSuccess) {
      bg = const Color(0xFF10B981);
      fg = Colors.white;
    } else if (isError) {
      bg = cs.error;
      fg = cs.onError;
    }

    Widget child;
    if (isLoading) {
      child = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: fg,
        ),
      );
    } else if (isSuccess) {
      child = Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, size: 18, color: fg),
        const SizedBox(width: 6),
        Text('تم بنجاح', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: fg)),
      ]);
    } else if (isError) {
      child = Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded, size: 18, color: fg),
        const SizedBox(width: 6),
        Text('فشل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: fg)),
      ]);
    } else {
      child = Row(mainAxisSize: MainAxisSize.min, children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Text(widget.label,
            style: GoogleFonts.cairo(
                fontSize: 13, fontWeight: FontWeight.bold, color: fg)),
      ]);
    }

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: widget.variant == LoadingButtonVariant.outlined
            ? Border.all(color: cs.primary)
            : null,
        boxShadow: isLoading
            ? null
            : [
                BoxShadow(
                    color: bg.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _handlePress,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: child),
        ),
      ),
    );

    if (widget.expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return IntrinsicWidth(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: button,
    ));
  }
}

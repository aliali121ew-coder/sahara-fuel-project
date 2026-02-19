import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// مركز الإشعارات داخل التطبيق
class AppNotifications {
  AppNotifications._();

  /// إشعار نجاح
  static void success(BuildContext context, String message) {
    _show(context, message, const Color(0xFF10B981), Icons.check_circle_rounded);
  }

  /// إشعار خطأ
  static void error(BuildContext context, String message) {
    _show(context, message, const Color(0xFFEF4444), Icons.error_rounded);
  }

  /// إشعار تحذير
  static void warning(BuildContext context, String message) {
    _show(context, message, const Color(0xFFF59E0B), Icons.warning_rounded);
  }

  /// إشعار معلومة
  static void info(BuildContext context, String message) {
    _show(context, message, const Color(0xFF3B82F6), Icons.info_rounded);
  }

  /// إشعار تأكيد قبل حذف
  static Future<bool> confirmDelete(BuildContext context, {String? itemName}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              Icon(Icons.warning_amber_rounded, color: colorScheme.error),
              const SizedBox(width: 10),
              Text('تأكيد الحذف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ]),
            content: Text(
              itemName != null
                  ? 'هل تريد حذف "$itemName"؟\nهذا الإجراء لا يمكن التراجع عنه.'
                  : 'هل أنت متأكد من الحذف؟\nهذا الإجراء لا يمكن التراجع عنه.',
              style: GoogleFonts.cairo(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('حذف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13)),
          ),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

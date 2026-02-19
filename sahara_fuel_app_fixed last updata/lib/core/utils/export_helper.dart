import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// مساعد تصدير البيانات (CSV / JSON)
/// يمكن إضافة PDF و Excel عند إضافة المكتبات المناسبة
class ExportHelper {
  ExportHelper._();

  /// تصدير بيانات إلى CSV كنص
  static String toCsv({
    required List<String> headers,
    required List<List<dynamic>> rows,
    String separator = ',',
  }) {
    final buffer = StringBuffer();

    // BOM for UTF-8 Excel compatibility
    buffer.write('\uFEFF');

    // Headers
    buffer.writeln(headers.map((h) => '"$h"').join(separator));

    // Rows
    for (final row in rows) {
      buffer.writeln(row.map((cell) {
        final str = cell?.toString() ?? '';
        return '"${str.replaceAll('"', '""')}"';
      }).join(separator));
    }

    return buffer.toString();
  }

  /// تصدير بيانات إلى JSON
  static String toJson({
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    final list = rows.map((row) {
      final map = <String, dynamic>{};
      for (int i = 0; i < headers.length && i < row.length; i++) {
        map[headers[i]] = row[i];
      }
      return map;
    }).toList();

    return const JsonEncoder.withIndent('  ').convert(list);
  }

  /// نسخ بيانات CSV إلى الحافظة
  static Future<void> copyToClipboard(String data, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: data));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ البيانات إلى الحافظة',
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// تنسيق الأرقام عربي
  static String formatNumber(double value) {
    return NumberFormat('#,###', 'ar').format(value);
  }

  /// تنسيق التاريخ عربي
  static String formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd', 'ar').format(date);
  }

  /// تنسيق العملة
  static String formatCurrency(double value) {
    return '${NumberFormat('#,###', 'ar').format(value)} د.ع';
  }
}

/// قائمة خيارات التصدير المنبثقة
class ExportMenu extends StatelessWidget {
  final VoidCallback? onExportCsv;
  final VoidCallback? onExportJson;
  final VoidCallback? onPrint;

  const ExportMenu({
    super.key,
    this.onExportCsv,
    this.onExportJson,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: Icon(Icons.file_download_outlined,
          color: colorScheme.primary, size: 20),
      tooltip: 'تصدير',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'csv':
            onExportCsv?.call();
            break;
          case 'json':
            onExportJson?.call();
            break;
          case 'print':
            onPrint?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'csv',
          child: Row(children: [
            Icon(Icons.table_chart_outlined, size: 18, color: colorScheme.onSurface),
            const SizedBox(width: 10),
            const Text('تصدير CSV', style: TextStyle(fontFamily: 'Cairo')),
          ]),
        ),
        PopupMenuItem(
          value: 'json',
          child: Row(children: [
            Icon(Icons.code_outlined, size: 18, color: colorScheme.onSurface),
            const SizedBox(width: 10),
            const Text('تصدير JSON', style: TextStyle(fontFamily: 'Cairo')),
          ]),
        ),
        if (onPrint != null)
          PopupMenuItem(
            value: 'print',
            child: Row(children: [
              Icon(Icons.print_outlined, size: 18, color: colorScheme.onSurface),
              const SizedBox(width: 10),
              const Text('طباعة', style: TextStyle(fontFamily: 'Cairo')),
            ]),
          ),
      ],
    );
  }
}

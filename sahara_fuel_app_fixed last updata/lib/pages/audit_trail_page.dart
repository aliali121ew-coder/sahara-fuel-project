import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../constants/app_colors.dart';
import '../core/theme/color_schemes.dart';
import '../providers/theme_provider.dart';

/// صفحة سجل العمليات (Audit Trail)
class AuditTrailPage extends StatefulWidget {
  const AuditTrailPage({super.key});

  @override
  State<AuditTrailPage> createState() => _AuditTrailPageState();
}

class _AuditTrailPageState extends State<AuditTrailPage> {
  String selectedFilter = 'الكل';
  DateTime? startDate;
  DateTime? endDate;

  // بيانات سجل العمليات (Mock Data)
  static final List<Map<String, dynamic>> auditLogs = [
    {
      'action': 'إضافة وارد',
      'user': 'أحمد محمد',
      'details': 'إضافة 50,000 لتر ديزل - خزان المحطة الرئيسية',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'type': 'add',
    },
    {
      'action': 'تحويل وقود',
      'user': 'علي حسن',
      'details': 'تحويل 20,000 لتر من محطة البوادي إلى محطة البياض',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'type': 'transfer',
    },
    {
      'action': 'تعديل رصيد',
      'user': 'مدير النظام',
      'details': 'تعديل رصيد مزرعة تسمين 5 - تصحيح خطأ إدخال',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'type': 'edit',
    },
    {
      'action': 'تسجيل دخول',
      'user': 'أحمد محمد',
      'details': 'تسجيل دخول ناجح من جهاز Windows',
      'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
      'type': 'login',
    },
    {
      'action': 'إنشاء تقرير',
      'user': 'سارة خالد',
      'details': 'إنشاء تقرير استهلاك شهري - يناير 2026',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'type': 'report',
    },
    {
      'action': 'حذف سجل',
      'user': 'مدير النظام',
      'details': 'حذف سجل مكرر - مزرعة أجداد 3',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'type': 'delete',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سجل العمليات',
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'تتبع جميع العمليات والتغييرات في النظام',
                style: GoogleFonts.cairo(
                    fontSize: 14, color: Theme.of(context).extension<SaharaColors>()!.subtleText),
              ),
              const SizedBox(height: 30),

              // شريط البحث والفلاتر
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      style: GoogleFonts.cairo(
                          color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'بحث في السجلات...',
                        hintStyle: GoogleFonts.cairo(
                            color: Theme.of(context).extension<SaharaColors>()!.subtleText),
                        prefixIcon: Icon(Icons.search,
                            color: Theme.of(context).extension<SaharaColors>()!.subtleText),
                        filled: true,
                        fillColor: Theme.of(context).extension<SaharaColors>()!.sidebar,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _filterDropdown(context),
                  const SizedBox(width: 16),
                  _dateRangeButton(context),
                ],
              ),
              const SizedBox(height: 30),

              // جدول السجلات
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).extension<SaharaColors>()!.sidebar,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // رأس الجدول
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          _headerCell('العملية', flex: 2, context: context),
                          _headerCell('المستخدم', flex: 2, context: context),
                          _headerCell('التفاصيل', flex: 4, context: context),
                          _headerCell('الوقت', flex: 2, context: context),
                        ],
                      ),
                    ),
                    // صفوف البيانات
                    ...auditLogs.map((log) => _logRow(log, context)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<SaharaColors>()!.sidebar,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: selectedFilter,
        dropdownColor: Theme.of(context).extension<SaharaColors>()!.sidebar,
        style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface),
        underline: const SizedBox(),
        items: ['الكل', 'إضافة', 'تحويل', 'تعديل', 'حذف', 'تقارير']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (val) => setState(() => selectedFilter = val!),
      ),
    );
  }

  Widget _dateRangeButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            startDate = picked.start;
            endDate = picked.end;
          });
        }
      },
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text('تحديد الفترة', style: GoogleFonts.cairo()),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).extension<SaharaColors>()!.sidebar,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1, required BuildContext context}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _logRow(Map<String, dynamic> log, BuildContext context) {
    final color = _getTypeColor(log['type'], context);
    final icon = _getTypeIcon(log['type']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  log['action'],
                  style: GoogleFonts.cairo(
                      color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log['user'],
              style: GoogleFonts.cairo(
                  color: Theme.of(context).extension<SaharaColors>()!.subtleText, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              log['details'],
              style: GoogleFonts.cairo(
                  color: Theme.of(context).extension<SaharaColors>()!.subtleText, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatTime(log['timestamp']),
              style: GoogleFonts.cairo(
                  color: Theme.of(context).extension<SaharaColors>()!.subtleText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return DateFormat('d/M/yyyy').format(time);
  }

  Color _getTypeColor(String type, BuildContext context) {
    switch (type) {
      case 'add':
        return Theme.of(context).extension<SaharaColors>()!.chartGreen;
      case 'edit':
        return Theme.of(context).extension<SaharaColors>()!.chartOrange;
      case 'delete':
        return Theme.of(context).colorScheme.error;
      case 'transfer':
        return Theme.of(context).extension<SaharaColors>()!.chartBlue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'add':
        return Icons.add_circle;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'transfer':
        return Icons.swap_horiz;
      case 'login':
        return Icons.login;
      case 'report':
        return Icons.description;
      default:
        return Icons.info;
    }
  }
}

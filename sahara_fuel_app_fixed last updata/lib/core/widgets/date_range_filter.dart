import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../theme/color_schemes.dart';

/// فلتر نطاق التاريخ مع أزرار سريعة
class DateRangeFilter extends StatefulWidget {
  final DateTimeRange? initialRange;
  final ValueChanged<DateTimeRange?> onChanged;
  final bool showQuickButtons;

  const DateRangeFilter({
    super.key,
    this.initialRange,
    required this.onChanged,
    this.showQuickButtons = true,
  });

  @override
  State<DateRangeFilter> createState() => _DateRangeFilterState();
}

class _DateRangeFilterState extends State<DateRangeFilter> {
  DateTimeRange? _range;
  String _activeQuick = 'هذا الشهر';

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
  }

  void _setQuick(String label, DateTimeRange range) {
    setState(() {
      _activeQuick = label;
      _range = range;
    });
    widget.onChanged(range);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = Theme.of(context).extension<SaharaColors>()!;
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: sahara.sidebar,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sahara.statBorder),
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Quick buttons
            if (widget.showQuickButtons) ...[
              _quickBtn('اليوم', DateTimeRange(
                start: DateTime.now(),
                end: DateTime.now(),
              ), colorScheme, sahara),
              _quickBtn('هذا الأسبوع', DateTimeRange(
                start: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
                end: DateTime.now(),
              ), colorScheme, sahara),
              _quickBtn('هذا الشهر', DateTimeRange(
                start: DateTime(DateTime.now().year, DateTime.now().month, 1),
                end: DateTime.now(),
              ), colorScheme, sahara),
              _quickBtn('آخر 3 أشهر', DateTimeRange(
                start: DateTime(DateTime.now().year, DateTime.now().month - 2, 1),
                end: DateTime.now(),
              ), colorScheme, sahara),
              _quickBtn('هذا العام', DateTimeRange(
                start: DateTime(DateTime.now().year, 1, 1),
                end: DateTime.now(),
              ), colorScheme, sahara),
            ],

            // Divider
            if (widget.showQuickButtons)
              Container(width: 1, height: 28, color: sahara.statBorder),

            // Custom range picker
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  initialDateRange: _range,
                  locale: const Locale('ar'),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: colorScheme,
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _range = picked;
                    _activeQuick = 'مخصص';
                  });
                  widget.onChanged(picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _activeQuick == 'مخصص'
                      ? colorScheme.primary.withOpacity(0.12)
                      : sahara.inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _activeQuick == 'مخصص'
                        ? colorScheme.primary.withOpacity(0.4)
                        : Colors.transparent,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.date_range_rounded,
                      size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    _range != null
                        ? '${dateFormat.format(_range!.start)} - ${dateFormat.format(_range!.end)}'
                        : 'اختر نطاق تاريخ',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: colorScheme.onSurface),
                  ),
                ]),
              ),
            ),

            // Clear button
            if (_range != null)
              IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 16, color: colorScheme.onSurfaceVariant),
                onPressed: () {
                  setState(() {
                    _range = null;
                    _activeQuick = '';
                  });
                  widget.onChanged(null);
                },
                tooltip: 'مسح الفلتر',
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  Widget _quickBtn(
      String label, DateTimeRange range, ColorScheme colorScheme, SaharaColors sahara) {
    final isActive = _activeQuick == label;
    return GestureDetector(
      onTap: () => _setQuick(label, range),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : sahara.inputBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: GoogleFonts.cairo(
                fontSize: 11,
                color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

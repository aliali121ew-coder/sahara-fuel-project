import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../core/theme/color_schemes.dart';
import '../providers/fuel_provider.dart';
import '../providers/theme_provider.dart';

/// صفحة تقرير الوارد - تصميم احترافي متطور
class IncomingReportPage extends StatefulWidget {
  const IncomingReportPage({super.key});

  @override
  State<IncomingReportPage> createState() => _IncomingReportPageState();
}

class _IncomingReportPageState extends State<IncomingReportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FuelProvider>(context, listen: false).syncWithApi().then((_) {
        if (mounted) setState(() {});
      });
    });
  }

  String _searchQuery = '';
  String _sortColumn = '';
  bool _sortAscending = true;
  final Map<String, String> _columnFilters = {};
  String _selectedDate = ''; // سيتم تعيينه تلقائياً لآخر تاريخ

  // بيانات قاعدة البيانات - متغيرات للفلترة
  final Map<String, String> _dbColumnFilters = {};
  bool _isDatabaseDialogVisible = false;

  // البيانات المفلترة بالتاريخ للداشبورد
  List<Map<String, dynamic>> get _dashboardData {
    return _incomingData
        .where((item) => item['date'] == _selectedDate)
        .toList();
  }

  // الحصول على آخر تاريخ تحديث من البيانات
  String get _lastUpdateDate {
    if (_incomingData.isEmpty) return '';

    // تحويل التواريخ إلى DateTime للمقارنة
    DateTime? latestDate;
    for (var item in _incomingData) {
      try {
        List<String> dateParts = (item['date'] as String).split('/');
        if (dateParts.length == 3) {
          DateTime date = DateTime(
            int.parse(dateParts[2]), // year
            int.parse(dateParts[0]), // month
            int.parse(dateParts[1]), // day
          );
          if (latestDate == null || date.isAfter(latestDate)) {
            latestDate = date;
          }
        }
      } catch (e) {
        continue;
      }
    }

    if (latestDate == null) return '';
    return '\${latestDate.month}/\${latestDate.day}/\${latestDate.year}';
  }

  // البيانات المفلترة للجدول الرئيسي - تظهر آخر تحديث فقط
  List<Map<String, dynamic>> get _mainTableData {
    String lastDate = _lastUpdateDate;
    if (lastDate.isEmpty) return [];

    // إذا لم يتم تحديد تاريخ، استخدم آخر تاريخ
    if (_selectedDate.isEmpty) {
      // Side-effect bad practice in getter, but for UI state init it works in Flutter build cycle often
      // Better handled in build()
      return _incomingData.where((item) => item['date'] == lastDate).toList();
    }

    return _incomingData.where((item) => item['date'] == lastDate).toList();
  }

  // البيانات المفلترة لقاعدة البيانات - تشمل كل البيانات
  List<Map<String, dynamic>> get _databaseFilteredData {
    List<Map<String, dynamic>> dataSource = List.from(_incomingData);

    // تطبيق فلاتر قاعدة البيانات
    if (_dbColumnFilters.isNotEmpty) {
      dataSource = dataSource.where((item) {
        return _dbColumnFilters.entries.every((filter) {
          final value = item[filter.key]?.toString().toLowerCase() ?? '';
          return value.contains(filter.value.toLowerCase());
        });
      }).toList();
    }

    return dataSource;
  }

  List<Map<String, dynamic>> get _incomingData {
    final provider = Provider.of<FuelProvider>(context);
    return provider.incomingShipments.map((e) {
      return {
        'supplier': e.supplier,
        'company': e.fuelType,
        'quantity': e.quantity.toInt(),
        'density': e.density,
        'color': e.color,
        'voucher': e.id.length > 6 ? e.id.substring(0, 6) : e.id,
        'price': e.unitPrice.toInt(),
        'cost': e.totalCost.toInt(),
        'driver': e.driverName,
        'vehicleNo': e.truckNumber,
        'date': '${e.date.month}/${e.date.day}/${e.date.year}',
      };
    }).toList();
  }

  final List<Map<String, String>> _columns = [
    {'key': 'supplier', 'label': 'اسم المجهز'},
    {'key': 'company', 'label': 'الشركة المجهزة'},
    {'key': 'quantity', 'label': 'الكمية المستلمة'},
    {'key': 'density', 'label': 'كثافة المنتج'},
    {'key': 'color', 'label': 'لون المنتج'},
    {'key': 'voucher', 'label': 'رقم الفوچر'},
    {'key': 'price', 'label': 'سعر المنتج'},
    {'key': 'cost', 'label': 'تكلفة المنتج'},
    {'key': 'driver', 'label': 'اسم السائق'},
    {'key': 'vehicleNo', 'label': 'رقم السيارة'},
    {'key': 'date', 'label': 'تاريخ الاستلام'},
  ];

  List<Map<String, dynamic>> get _filteredData {
    // استخدام _mainTableData للجدول الرئيسي (آخر تحديث فقط)
    var data = _mainTableData.where((item) {
      // Global search
      if (_searchQuery.isNotEmpty) {
        final match =
            item.values.any((v) => v.toString().contains(_searchQuery));
        if (!match) return false;
      }
      // Column filters
      for (var entry in _columnFilters.entries) {
        if (entry.value.isNotEmpty &&
            item[entry.key].toString() != entry.value) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sorting
    if (_sortColumn.isNotEmpty) {
      data.sort((a, b) {
        var aVal = a[_sortColumn];
        var bVal = b[_sortColumn];
        int cmp;
        if (aVal is int && bVal is int) {
          cmp = aVal.compareTo(bVal);
        } else {
          cmp = aVal.toString().compareTo(bVal.toString());
        }
        return _sortAscending ? cmp : -cmp;
      });
    }
    return data;
  }

  Set<String> _getUniqueValues(String key) {
    return _incomingData
        .map((e) => e[key]?.toString().trim() ?? '')
        .where((v) => v.isNotEmpty)
        .toSet();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // تعيين التاريخ تلقائياً لأحدث تاريخ عند فتح الصفحة
        if (_selectedDate.isEmpty && _incomingData.isNotEmpty) {
          Future.microtask(
              () => setState(() => _selectedDate = _lastUpdateDate));
        } else if (_selectedDate.isNotEmpty &&
            _incomingData.isNotEmpty &&
            !_incomingData.any((d) => d['date'] == _selectedDate)) {
          // إذا كان التاريخ المختار غير موجود، ننتقل لأحدث تاريخ
          Future.microtask(
              () => setState(() => _selectedDate = _lastUpdateDate));
        }

        final totalQuantity = _filteredData.fold<int>(0, (sum, item) {
          final v = item['quantity'];
          return sum + (v is num ? v.toInt() : 0);
        });
        final totalCost = _filteredData.fold<int>(0, (sum, item) {
          final v = item['cost'];
          return sum + (v is num ? v.toInt() : 0);
        });

        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تقرير الوارد',
                            style: GoogleFonts.cairo(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface)),
                        SizedBox(height: 4),
                        Text('إدارة ومتابعة شحنات الوقود الواردة',
                            style: GoogleFonts.cairo(
                                fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    Row(
                      children: [
                        // Date Picker
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).extension<SaharaColors>()!.inputBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                          ),
                          child: InkWell(
                            onTap: () => _showDatePicker(),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: Theme.of(context).colorScheme.primary, size: 18),
                                SizedBox(width: 8),
                                Text(_selectedDate,
                                    style: GoogleFonts.cairo(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(width: 6),
                                Icon(Icons.keyboard_arrow_down,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
                              ],
                            ),
                          ),
                        ),
                        // زر قاعدة البيانات
                        InkWell(
                          onTap: () => _showDatabaseLoginDialog(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.sahara.chartPurple,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.storage,
                                    color: Theme.of(context).colorScheme.surface, size: 18),
                                SizedBox(width: 8),
                                Text('قاعدة البيانات',
                                    style: GoogleFonts.cairo(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: context.sahara.statBorder,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                          child: PopupMenuButton<String>(
                            offset: Offset(0, 45),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: context.sahara.statBorder,
                            elevation: 4,
                            onSelected: (value) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                          value == 'PDF'
                                              ? Icons.picture_as_pdf
                                              : Icons.table_chart,
                                          color: Theme.of(context).colorScheme.surface,
                                          size: 20),
                                      const SizedBox(width: 10),
                                      Text('جاري التصدير كـ $value...',
                                          style: GoogleFonts.cairo()),
                                    ],
                                  ),
                                  backgroundColor: context.sahara.inputBg,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'PDF',
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                          color: context.sahara.chartRed
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Icon(Icons.picture_as_pdf,
                                          color: context.sahara.chartRed, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('ملف PDF',
                                        style: GoogleFonts.cairo(
                                            fontSize: 14, color: Theme.of(context).colorScheme.surface)),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(height: 1),
                              PopupMenuItem(
                                value: 'Excel',
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                          color: context.sahara.chartGreen
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Icon(Icons.table_chart,
                                          color: context.sahara.chartGreen, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('ملف Excel',
                                        style: GoogleFonts.cairo(
                                            fontSize: 14, color: Theme.of(context).colorScheme.surface)),
                                  ],
                                ),
                              ),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(Icons.download,
                                      color: Theme.of(context).colorScheme.onSurface, size: 18),
                                  SizedBox(width: 8),
                                  Text('تصدير التقرير',
                                      style: GoogleFonts.cairo(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(width: 6),
                                  Icon(Icons.keyboard_arrow_down,
                                      color: context.sahara.subtleText, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Stats Cards - Using Dashboard Data (filtered by date)
                Builder(builder: (context) {
                  final dashData = _dashboardData;
                  final dashTotalQty = dashData.fold<int>(0, (sum, item) {
                    final v = item['quantity'];
                    return sum + (v is num ? v.toInt() : 0);
                  });
                  final dashTotalCost = dashData.fold<int>(0, (sum, item) {
                    final v = item['cost'];
                    return sum + (v is num ? v.toInt() : 0);
                  });
                  final dashSuppliers =
                      dashData.map((e) => e['supplier']).toSet().length;
                  return Row(
                    children: [
                      _statCard('عدد الشحنات', '${dashData.length}',
                          Icons.local_shipping, context.sahara.chartBlue, ''),
                      const SizedBox(width: 16),
                      _statCard(
                          'إجمالي الكمية',
                          '${_formatNumber(dashTotalQty)} لتر',
                          Icons.water_drop,
                          Theme.of(context).colorScheme.primary,
                          ''),
                      const SizedBox(width: 16),
                      _statCard(
                          'إجمالي التكلفة',
                          '${_formatNumber(dashTotalCost)} د.ع',
                          Icons.payments,
                          context.sahara.chartOrange,
                          ''),
                      SizedBox(width: 16),
                      _statCard('عدد الموردين', '$dashSuppliers',
                          Icons.business, context.sahara.chartPurple, ''),
                    ],
                  );
                }),
                const SizedBox(height: 28),

                // Charts Row - Like Reference Image
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line Chart - Main Chart
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 340,
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: context.sahara.dialogHeader,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.sahara.statBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('الشحنات الواردة',
                                    style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface)),
                                Row(
                                  children: [
                                    _legendItem('الكمية', Theme.of(context).colorScheme.primary),
                                    SizedBox(width: 16),
                                    _legendItem(
                                        'التكلفة', context.sahara.chartRed),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(child: _buildLineChart()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Pie Chart + Top Suppliers
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          // Pie Chart with full names
                          Container(
                            height: 200,
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: context.sahara.dialogHeader,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: context.sahara.statBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('توزيع الموردين',
                                        style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface)),
                                    Text('انقر للتفاصيل',
                                        style: GoogleFonts.cairo(
                                            fontSize: 10,
                                            color: context.sahara.hintText)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(child: _buildPieChart()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Top Suppliers Today - Replaces Bar Chart
                          Container(
                            height: 124,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.sahara.dialogHeader,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: context.sahara.statBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('الموردين الأكثر اليوم',
                                    style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface)),
                                const SizedBox(height: 10),
                                Expanded(child: _buildTopSuppliersList()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Advanced Table
                Container(
                  decoration: BoxDecoration(
                    color: context.sahara.dialogHeader,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.sahara.statBorder),
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                    color: context.sahara.statBorder,
                                    borderRadius: BorderRadius.circular(10)),
                                child: TextField(
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                  style: GoogleFonts.cairo(
                                      color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'بحث في جميع الأعمدة...',
                                    hintStyle: GoogleFonts.cairo(
                                        color: context.sahara.hintText, fontSize: 14),
                                    prefixIcon: Icon(Icons.search,
                                        color: context.sahara.hintText, size: 22),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Refresh button
                            InkWell(
                              onTap: () {
                                setState(() => _selectedDate =
                                    ''); // Reset date to force update
                                Provider.of<FuelProvider>(context,
                                        listen: false)
                                    .syncWithApi();
                              },
                              child: Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                    color: context.sahara.statBorder,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.refresh,
                                    color: Theme.of(context).colorScheme.onSurface, size: 22),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Global filter dropdown
                            Container(
                              height: 48,
                              padding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                  color: context.sahara.statBorder,
                                  borderRadius: BorderRadius.circular(10)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _columnFilters['supplier']?.isEmpty ??
                                          true
                                      ? null
                                      : _columnFilters['supplier'],
                                  hint: Row(
                                    children: [
                                      Icon(Icons.filter_list,
                                          color: context.sahara.hintText, size: 18),
                                      SizedBox(width: 8),
                                      Text('فلتر المورد',
                                          style: GoogleFonts.cairo(
                                              color: context.sahara.hintText,
                                              fontSize: 13)),
                                    ],
                                  ),
                                  dropdownColor: context.sahara.statBorder,
                                  style: GoogleFonts.cairo(
                                      color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                                  icon: Icon(Icons.keyboard_arrow_down,
                                      color: context.sahara.hintText),
                                  items: [
                                    DropdownMenuItem(
                                        value: '',
                                        child: Text('جميع الموردين',
                                            style: GoogleFonts.cairo(
                                                fontSize: 13))),
                                    ..._getUniqueValues('supplier').map((v) =>
                                        DropdownMenuItem(
                                            value: v,
                                            child: Text(v,
                                                style: GoogleFonts.cairo(
                                                    fontSize: 13)))),
                                  ],
                                  onChanged: (v) => setState(() =>
                                      _columnFilters['supplier'] = v ?? ''),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Add Data Button
                            InkWell(
                              onTap: () {/* TODO: Add data dialog */},
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.add,
                                        color: Theme.of(context).colorScheme.surface, size: 18),
                                    SizedBox(width: 6),
                                    Text('إضافة بيانات',
                                        style: GoogleFonts.cairo(
                                            color: Theme.of(context).colorScheme.onSurface,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (_columnFilters.values.any((v) => v.isNotEmpty))
                              InkWell(
                                onTap: () =>
                                    setState(() => _columnFilters.clear()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    children: [
                                      Icon(Icons.clear,
                                          color: Colors.red[400], size: 16),
                                      const SizedBox(width: 6),
                                      Text('مسح',
                                          style: GoogleFonts.cairo(
                                              color: Colors.red[400],
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Professional Table with Modern Design
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
                        decoration: BoxDecoration(
                          color: context.sahara.inputBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.sahara.statBorder),
                        ),
                        child: Column(
                          children: [
                            // Table Header Row
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 8),
                              decoration: BoxDecoration(
                                color: context.sahara.dialogHeader,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              child: Row(
                                children: _columns
                                    .map((col) => Expanded(
                                        child: _buildProHeaderCell(
                                            col['key']!, col['label']!)))
                                    .toList(),
                              ),
                            ),
                            // Table Body - with isolated scroll
                            Listener(
                              onPointerSignal: (pointerSignal) {
                                // This prevents scroll events from bubbling up to parent
                              },
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxHeight: 400),
                                child: ScrollConfiguration(
                                  behavior: ScrollConfiguration.of(context)
                                      .copyWith(scrollbars: true),
                                  child: SingleChildScrollView(
                                    physics: const ClampingScrollPhysics(),
                                    child: Column(
                                      children: _filteredData
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final d = entry.value;
                                        final isOdd = entry.key % 2 == 1;
                                        return Container(
                                          width: double.infinity,
                                          color: isOdd
                                              ? context.sahara.dialogHeader
                                              : context.sahara.inputBg,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 8),
                                          child: Row(
                                            children: _columns
                                                .map((col) => Expanded(
                                                    child: _buildProDataCell(
                                                        d, col['key']!)))
                                                .toList(),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Footer
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                                child: Text(
                                    'إجمالي: ${_filteredData.length} سجل',
                                    style: GoogleFonts.cairo(
                                        color: context.sahara.hintText,
                                        fontSize: 13))),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('الكمية: ',
                                      style: GoogleFonts.cairo(
                                          color: context.sahara.hintText,
                                          fontSize: 12)),
                                  Text('${_formatNumber(totalQuantity)} لتر',
                                      style: GoogleFonts.cairo(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCell(String key, String label) {
    final isActive = _sortColumn == key;
    final uniqueValues = _getUniqueValues(key);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minWidth: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column title with sort
          InkWell(
            onTap: () {
              setState(() {
                if (_sortColumn == key) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortColumn = key;
                  _sortAscending = true;
                }
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: GoogleFonts.cairo(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(width: 6),
                Icon(
                  isActive
                      ? (_sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward)
                      : Icons.unfold_more,
                  color: isActive ? Theme.of(context).colorScheme.primary : context.sahara.hintText,
                  size: 16,
                ),
              ],
            ),
          ),
          // Filter dropdown
          if (uniqueValues.isNotEmpty && uniqueValues.length < 10) ...[
            const SizedBox(height: 8),
            Container(
              height: 32,
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                  color: context.sahara.statBorder,
                  borderRadius: BorderRadius.circular(6)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _columnFilters[key]?.isEmpty ?? true
                      ? null
                      : _columnFilters[key],
                  hint: Text('الكل',
                      style: GoogleFonts.cairo(
                          color: context.sahara.hintText, fontSize: 11)),
                  isExpanded: true,
                  dropdownColor: context.sahara.statBorder,
                  style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface, fontSize: 11),
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: context.sahara.hintText, size: 16),
                  items: [
                    DropdownMenuItem(
                        value: '',
                        child: Text('الكل',
                            style: GoogleFonts.cairo(fontSize: 11))),
                    ...uniqueValues.map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v,
                            style: GoogleFonts.cairo(fontSize: 11),
                            overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) =>
                      setState(() => _columnFilters[key] = v ?? ''),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataCell(Map<String, dynamic> data, String key) {
    final value = data[key];
    String displayValue;
    Color textColor = context.sahara.subtleText!;
    FontWeight fontWeight = FontWeight.normal;

    if (value is int) {
      if (key == 'quantity') {
        displayValue = _formatNumber(value);
        textColor = Theme.of(context).colorScheme.primary;
        fontWeight = FontWeight.bold;
      } else if (key == 'cost') {
        displayValue = value > 0 ? _formatNumber(value) : '-';
        textColor = value > 0 ? context.sahara.chartOrange : context.sahara.hintText!;
        fontWeight = value > 0 ? FontWeight.bold : FontWeight.normal;
      } else if (key == 'price') {
        displayValue = value > 0 ? '$value' : '-';
      } else {
        displayValue = value.toString();
      }
    } else {
      displayValue = value.toString().isNotEmpty ? value.toString() : '-';
      if (displayValue == '-') textColor = context.sahara.hintText!;
    }

    // Special styling for color column
    if (key == 'color' && displayValue != '-') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        constraints: const BoxConstraints(minWidth: 120),
        child: _colorBadge(displayValue),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      constraints: const BoxConstraints(minWidth: 120),
      child: Text(displayValue,
          style: GoogleFonts.cairo(
              color: textColor, fontSize: 13, fontWeight: fontWeight)),
    );
  }

  Widget _buildProHeaderCell(String key, String label) {
    final isActive = _sortColumn == key;
    final uniqueValues = _getUniqueValues(key);
    // Show filter for all columns except 'cost'
    final hasFilter = key != 'cost' && uniqueValues.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sort header - fixed height
          SizedBox(
            height: 36,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (_sortColumn == key) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortColumn = key;
                    _sortAscending = true;
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(label,
                          style: GoogleFonts.cairo(
                            color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      isActive
                          ? (_sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward)
                          : Icons.sort,
                      color: isActive ? Theme.of(context).colorScheme.primary : context.sahara.hintText,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Filter dropdown - fixed height for all
          SizedBox(
            height: hasFilter ? 30 : 30,
            child: hasFilter
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: context.sahara.statBorder,
                      borderRadius: BorderRadius.circular(6),
                      border: _columnFilters[key]?.isNotEmpty == true
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                              width: 1)
                          : null,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _columnFilters[key]?.isEmpty ?? true
                            ? null
                            : _columnFilters[key],
                        hint: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_alt_outlined,
                                color: context.sahara.hintText, size: 11),
                            SizedBox(width: 3),
                            Text('الكل',
                                style: GoogleFonts.cairo(
                                    color: context.sahara.hintText, fontSize: 10)),
                          ],
                        ),
                        isExpanded: true,
                        dropdownColor: context.sahara.statBorder,
                        style: GoogleFonts.cairo(
                            color: Theme.of(context).colorScheme.onSurface, fontSize: 10),
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: context.sahara.hintText, size: 12),
                        items: [
                          DropdownMenuItem(
                              value: '',
                              child: Row(
                                children: [
                                  Icon(Icons.clear_all,
                                      color: context.sahara.hintText, size: 12),
                                  SizedBox(width: 6),
                                  Text('إظهار الكل',
                                      style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          color: context.sahara.subtleText)),
                                ],
                              )),
                          ...uniqueValues.map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v,
                                    style: GoogleFonts.cairo(fontSize: 10),
                                    overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) =>
                            setState(() => _columnFilters[key] = v ?? ''),
                      ),
                    ),
                  )
                : Center(
                    child: Text('-',
                        style: GoogleFonts.cairo(
                            color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProDataCell(Map<String, dynamic> data, String key) {
    final value = data[key];
    String displayValue;
    Color textColor = context.sahara.subtleText!;
    FontWeight fontWeight = FontWeight.normal;

    if (value is int) {
      if (key == 'quantity') {
        displayValue = '${_formatNumber(value)} لتر';
        textColor = Theme.of(context).colorScheme.primary;
        fontWeight = FontWeight.bold;
      } else if (key == 'cost') {
        displayValue = value > 0 ? '${_formatNumber(value)} د.ع' : '-';
        textColor = value > 0 ? context.sahara.chartOrange : context.sahara.hintText!;
        fontWeight = value > 0 ? FontWeight.bold : FontWeight.normal;
      } else if (key == 'price') {
        displayValue = value > 0 ? '$value' : '-';
        textColor = value > 0 ? context.sahara.chartBlue : context.sahara.hintText!;
      } else {
        displayValue = value.toString();
      }
    } else {
      displayValue = value?.toString() ?? '-';
      if (displayValue.isEmpty) displayValue = '-';
      if (displayValue == '-') textColor = context.sahara.hintText!;
    }

    // Special styling for color column
    if (key == 'color' && displayValue != '-') {
      return Center(child: _colorBadge(displayValue));
    }

    return Center(
      child: Text(displayValue,
          style: GoogleFonts.cairo(
              color: textColor, fontSize: 13, fontWeight: fontWeight),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis),
    );
  }

  Widget _headerButton(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 18),
          SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.cairo(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showDatePicker() {
    // Get unique dates from data
    final uniqueDates =
        _incomingData.map((e) => e['date'] as String).toSet().toList();
    final searchController = TextEditingController();
    List<String> filteredDates = List.from(uniqueDates);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: context.sahara.dialogHeader,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 320,
            height: 450,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('اختر التاريخ',
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface)),
                    IconButton(
                        icon: Icon(Icons.close,
                            color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                SizedBox(height: 12),
                // Manual date search field
                Container(
                  decoration: BoxDecoration(
                    color: context.sahara.inputBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.sahara.statBorder),
                  ),
                  child: TextField(
                    controller: searchController,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن تاريخ (مثال: 1/24/2026)',
                      hintStyle: GoogleFonts.cairo(
                          color: context.sahara.hintText, fontSize: 12),
                      prefixIcon: Icon(Icons.search,
                          color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value.isEmpty) {
                          filteredDates = List.from(uniqueDates);
                        } else {
                          filteredDates = uniqueDates
                              .where((d) => d.contains(value))
                              .toList();
                        }
                      });
                    },
                    onSubmitted: (value) {
                      // Allow manual date entry
                      if (value.isNotEmpty && uniqueDates.contains(value)) {
                        setState(() => _selectedDate = value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Scrollable date list (max 6 visible)
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredDates.length,
                    itemBuilder: (context, index) {
                      final date = filteredDates[index];
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedDate = date);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: _selectedDate == date
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                                : context.sahara.inputBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _selectedDate == date
                                    ? Theme.of(context).colorScheme.primary
                                    : context.sahara.statBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(date,
                                  style: GoogleFonts.cairo(
                                      color: _selectedDate == date
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              if (_selectedDate == date)
                                Icon(Icons.check_circle,
                                    color: Theme.of(context).colorScheme.primary, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color, String change) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.sahara.dialogHeader,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.sahara.statBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (change.isNotEmpty)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: context.sahara.chartGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        Icon(Icons.trending_up,
                            color: context.sahara.chartGreen, size: 12),
                        SizedBox(width: 4),
                        Text(change,
                            style: GoogleFonts.cairo(
                                color: context.sahara.chartGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(value,
                style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 4),
            Text(title,
                style:
                    GoogleFonts.cairo(fontSize: 12, color: context.sahara.hintText)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final Map<String, int> totals = {};
    final Map<String, int> counts = {};
    for (var item in _incomingData) {
      final supplier = item['supplier'] as String;
      totals[supplier] = (totals[supplier] ?? 0) + (item['quantity'] as int);
      counts[supplier] = (counts[supplier] ?? 0) + 1;
    }

    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = [
      Theme.of(context).colorScheme.primary,
      context.sahara.chartOrange,
      context.sahara.chartPurple,
      context.sahara.chartBlue,
      context.sahara.chartRed
    ];
    final maxValue = sortedEntries.first.value.toDouble();

    return Column(
      children: [
        // Chart bars with full names
        ...sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final supplier = entry.value.key;
          final quantity = entry.value.value;
          final percentage = (quantity / maxValue * 100).round();
          final color = colors[index % colors.length];
          final shipments = counts[supplier] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3)),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(supplier,
                                style: GoogleFonts.cairo(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('$shipments شحنة',
                              style: GoogleFonts.cairo(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(width: 12),
                        Text(_formatNumber(quantity),
                            style: GoogleFonts.cairo(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        Text(' لتر',
                            style: GoogleFonts.cairo(
                                color: context.sahara.hintText, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: context.sahara.statBorder,
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.6)]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                          widthFactor: percentage / 100,
                          alignment: Alignment.centerRight),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: percentage / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                color,
                                color.withValues(alpha: 0.7)
                              ]),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        // Summary row
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.sahara.inputBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _chartStat(
                  'إجمالي الكمية',
                  '${_formatNumber(totals.values.reduce((a, b) => a + b))} لتر',
                  Icons.water_drop),
              Container(width: 1, height: 30, color: context.sahara.statBorder),
              _chartStat('عدد الموردين', '${totals.length}', Icons.business),
              Container(width: 1, height: 30, color: context.sahara.statBorder),
              _chartStat('عدد الشحنات', '${_incomingData.length}',
                  Icons.local_shipping),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chartStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: context.sahara.hintText, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.cairo(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style:
                    GoogleFonts.cairo(color: context.sahara.hintText, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.cairo(color: context.sahara.subtleText, fontSize: 11)),
      ],
    );
  }

  Widget _buildLineChart() {
    // Build chart data from filtered dashboard data
    final data = _dashboardData;
    if (data.isEmpty) {
      return Center(
          child: Text('لا توجد بيانات لهذا التاريخ',
              style: GoogleFonts.cairo(color: context.sahara.hintText, fontSize: 14)));
    }

    // Group by supplier and calculate totals
    final Map<String, int> quantityBySupplier = {};
    final Map<String, int> costBySupplier = {};
    for (var item in data) {
      final supplier = item['supplier'] as String;
      final qty = item['quantity'];
      final cst = item['cost'];
      quantityBySupplier[supplier] =
          (quantityBySupplier[supplier] ?? 0) + (qty is num ? qty.toInt() : 0);
      costBySupplier[supplier] =
          (costBySupplier[supplier] ?? 0) + (cst is num ? cst.toInt() : 0);
    }

    final suppliers = quantityBySupplier.keys.toList();
    final maxQuantity =
        quantityBySupplier.values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxCost = costBySupplier.values.fold<int>(0, (a, b) => a > b ? a : b);

    // Normalize cost to same scale as quantity for display
    final scaleFactor =
        maxQuantity > 0 && maxCost > 0 ? maxQuantity / maxCost : 1.0;

    final quantitySpots = suppliers
        .asMap()
        .entries
        .map((e) =>
            FlSpot(e.key.toDouble(), quantityBySupplier[e.value]!.toDouble()))
        .toList();

    final costSpots = suppliers
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(),
            (costBySupplier[e.value]! * scaleFactor).toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxQuantity > 0 ? maxQuantity / 4 : 1000,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: context.sahara.statBorder, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) {
                final index = v.toInt();
                if (index >= 0 && index < suppliers.length) {
                  // Shorten supplier name for display
                  String name = suppliers[index];
                  if (name.length > 8) name = '${name.substring(0, 8)}...';
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(name,
                        style: GoogleFonts.cairo(
                            color: context.sahara.hintText, fontSize: 9),
                        textAlign: TextAlign.center),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxQuantity * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: quantitySpots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 5,
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 2,
                strokeColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: costSpots,
            isCurved: true,
            color: context.sahara.chartRed,
            barWidth: 2,
            dashArray: [5, 5],
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            maxContentWidth: 200,
            getTooltipColor: (touchedSpot) => context.sahara.inputBg,
            tooltipRoundedRadius: 12,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.toInt();
                final supplierName =
                    index < suppliers.length ? suppliers[index] : '';
                final isQuantity = spot.barIndex == 0;
                final value = isQuantity
                    ? quantityBySupplier[supplierName] ?? 0
                    : costBySupplier[supplierName] ?? 0;
                return LineTooltipItem(
                  '$supplierName\n${isQuantity ? 'الكمية' : 'التكلفة'}: ${_formatNumber(value)} ${isQuantity ? 'لتر' : 'د.ع'}',
                  GoogleFonts.cairo(
                      color: spot.bar.color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
      duration: const Duration(milliseconds: 800),
    );
  }

  Widget _buildPieChart() {
    final Map<String, int> totals = {};
    for (var item in _dashboardData) {
      final qty = item['quantity'];
      totals[item['supplier'] as String] =
          (totals[item['supplier']] ?? 0) + (qty is num ? qty.toInt() : 0);
    }

    if (totals.isEmpty) {
      return Center(
          child: Text('لا توجد بيانات',
              style: GoogleFonts.cairo(color: context.sahara.hintText, fontSize: 12)));
    }

    final colors = [
      Theme.of(context).colorScheme.primary,
      context.sahara.chartOrange,
      context.sahara.chartPurple,
      context.sahara.chartBlue
    ];
    final total = totals.values.fold<int>(0, (a, b) => a + b);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (event is FlTapUpEvent &&
                      pieTouchResponse?.touchedSection != null) {
                    final index =
                        pieTouchResponse!.touchedSection!.touchedSectionIndex;
                    if (index >= 0) {
                      final supplierName = totals.keys.toList()[index];
                      _showSupplierDetailsDialog(supplierName);
                    }
                  }
                },
              ),
              sectionsSpace: 3,
              centerSpaceRadius: 28,
              sections: totals.entries.toList().asMap().entries.map((entry) {
                final percent = (entry.value.value / total * 100).round();
                return PieChartSectionData(
                  color: colors[entry.key % colors.length],
                  value: entry.value.value.toDouble(),
                  title: '$percent%',
                  radius: 25,
                  titleStyle: GoogleFonts.cairo(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
            swapAnimationDuration: const Duration(milliseconds: 800),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: totals.entries.toList().asMap().entries.map((entry) {
              final percent = (entry.value.value / total * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  onTap: () => _showSupplierDetailsDialog(entry.value.key),
                  child: Row(
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: colors[entry.key % colors.length],
                              shape: BoxShape.circle)),
                      SizedBox(width: 6),
                      Expanded(
                          child: Text(entry.value.key,
                              style: GoogleFonts.cairo(
                                  color: context.sahara.subtleText, fontSize: 10),
                              overflow: TextOverflow.ellipsis)),
                      Text('$percent%',
                          style: GoogleFonts.cairo(
                              color: colors[entry.key % colors.length],
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showSupplierDetailsDialog(String supplierName) {
    final supplierData = _incomingData
        .where((item) => item['supplier'] == supplierName)
        .toList();
    final totalQty = supplierData.fold<int>(0, (sum, item) {
      final v = item['quantity'];
      return sum + (v is num ? v.toInt() : 0);
    });
    final totalCost = supplierData.fold<int>(0, (sum, item) {
      final q = item['quantity'];
      final p = item['price'];
      return sum + ((q is num ? q.toInt() : 0) * (p is num ? p.toInt() : 0));
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: context.sahara.dialogHeader,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      context.sahara.dialogHeader
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.business,
                          color: Theme.of(context).colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(supplierName,
                              style: GoogleFonts.cairo(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface)),
                          Text('تفاصيل الشحنات الواردة',
                              style: GoogleFonts.cairo(
                                  fontSize: 12, color: context.sahara.subtleText)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface, shape: BoxShape.circle),
                        child: Icon(Icons.close,
                            color: Theme.of(context).colorScheme.onSurface, size: 18),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Stats Row
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildStatCard('عدد الشحنات', '${supplierData.length}',
                        Icons.local_shipping, Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'إجمالي الكمية',
                        '${_formatNumber(totalQty)} لتر',
                        Icons.water_drop,
                        context.sahara.chartBlue),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'إجمالي التكلفة',
                        '${_formatNumber(totalCost)} د.ع',
                        Icons.payments,
                        context.sahara.chartOrange),
                  ],
                ),
              ),

              // Table Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.table_chart,
                            color: context.sahara.hintText, size: 18),
                        const SizedBox(width: 8),
                        Text('جدول الشحنات',
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      constraints: BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: context.sahara.inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.sahara.statBorder),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SingleChildScrollView(
                          child: Table(
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                  color: context.sahara.statBorder
                                      .withValues(alpha: 0.5),
                                  width: 0.5),
                            ),
                            children: [
                              TableRow(
                                decoration:
                                    BoxDecoration(color: context.sahara.dialogHeader),
                                children: [
                                  'التاريخ',
                                  'الكمية',
                                  'السعر',
                                  'الكثافة'
                                ]
                                    .map((h) => Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          child: Text(h,
                                              style: GoogleFonts.cairo(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center),
                                        ))
                                    .toList(),
                              ),
                              ...supplierData.asMap().entries.map((entry) {
                                final d = entry.value;
                                final isOdd = entry.key % 2 == 1;
                                return TableRow(
                                  decoration: BoxDecoration(
                                      color: isOdd
                                          ? context.sahara.dialogHeader
                                          : context.sahara.inputBg),
                                  children: [
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Text(d['date'],
                                            style: GoogleFonts.cairo(
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontSize: 12),
                                            textAlign: TextAlign.center)),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Text(
                                            '${_formatNumber(d['quantity'])} لتر',
                                            style: GoogleFonts.cairo(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center)),
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Text('${d['price']}',
                                            style: GoogleFonts.cairo(
                                                color: context.sahara.chartOrange,
                                                fontSize: 12),
                                            textAlign: TextAlign.center)),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Text(
                                            d['density']?.toString() ?? '-',
                                            style: GoogleFonts.cairo(
                                                color: context.sahara.subtleText,
                                                fontSize: 12),
                                            textAlign: TextAlign.center)),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.cairo(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style:
                    GoogleFonts.cairo(color: context.sahara.hintText, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _dialogStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.cairo(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: GoogleFonts.cairo(color: context.sahara.hintText, fontSize: 10)),
      ],
    );
  }

  Widget _buildTopSuppliersList() {
    final Map<String, int> counts = {};
    for (var item in _dashboardData) {
      counts[item['supplier'] as String] = (counts[item['supplier']] ?? 0) + 1;
    }
    final sortedSuppliers = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = [
      Theme.of(context).colorScheme.primary,
      context.sahara.chartOrange,
      context.sahara.chartPurple,
      context.sahara.chartBlue
    ];

    return Row(
      children: sortedSuppliers.take(4).toList().asMap().entries.map((entry) {
        final color = colors[entry.key % colors.length];
        final name = entry.value.key;
        final count = entry.value.value;
        return Expanded(
          child: InkWell(
            onTap: () => _showSupplierDetailsDialog(name),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(name,
                        style: GoogleFonts.cairo(
                            color: Theme.of(context).colorScheme.surface,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$count شحنة',
                        style: GoogleFonts.cairo(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarChart() {
    final Map<String, int> counts = {};
    for (var item in _incomingData) {
      counts[item['supplier'] as String] = (counts[item['supplier']] ?? 0) + 1;
    }
    final colors = [
      Theme.of(context).colorScheme.primary,
      context.sahara.chartOrange,
      context.sahara.chartPurple,
      context.sahara.chartBlue
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: counts.values.reduce((a, b) => a > b ? a : b).toDouble() * 1.3,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barGroups: counts.entries.toList().asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value.toDouble(),
                gradient: LinearGradient(colors: [
                  colors[e.key % colors.length],
                  colors[e.key % colors.length].withValues(alpha: 0.6)
                ], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                width: 18,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
      swapAnimationDuration: const Duration(milliseconds: 800),
    );
  }

  Widget _colorBadge(String c) {
    Color bg = c == 'عسلي'
        ? context.sahara.chartOrange
        : c == 'نفط ابيض'
            ? Colors.blueGrey
            : Theme.of(context).extension<SaharaColors>()!.chartBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8)),
      child: Text(c,
          style: GoogleFonts.cairo(
              color: bg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _formatNumber(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  // دالة لإظهار نافذة تسجيل الدخول لقاعدة البيانات
  void _showDatabaseLoginDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.sahara.dialogHeader,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.sahara.chartPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.lock, color: context.sahara.chartPurple, size: 24),
              ),
              const SizedBox(width: 12),
              Text('صلاحية الدخول',
                  style: GoogleFonts.cairo(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'اسم المستخدم',
                    labelStyle: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                    prefixIcon:
                        Icon(Icons.person, color: context.sahara.chartPurple),
                    filled: true,
                    fillColor: context.sahara.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.sahara.chartPurple, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.surface),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    labelStyle: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                    prefixIcon:
                        Icon(Icons.vpn_key, color: context.sahara.chartPurple),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: context.sahara.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.sahara.chartPurple, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء',
                  style:
                      GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                if (usernameController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _showDatabaseDialog(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('الرجاء إدخال اسم المستخدم وكلمة المرور',
                          style: GoogleFonts.cairo()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.sahara.chartPurple,
                foregroundColor: Theme.of(context).colorScheme.surface,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('دخول',
                  style: GoogleFonts.cairo(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // دالة لإظهار نافذة قاعدة البيانات مع الفلاتر
  void _showDatabaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: context.sahara.dialogHeader,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.sahara.chartPurple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.storage,
                          color: context.sahara.chartPurple, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('قاعدة البيانات الكاملة',
                          style: GoogleFonts.cairo(
                              color: Theme.of(context).colorScheme.surface,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildDatabaseTable(setDialogState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // بناء جدول قاعدة البيانات مع الفلاتر
  Widget _buildDatabaseTable(StateSetter setDialogState) {
    final columns = [
      {'key': 'date', 'label': 'التاريخ', 'width': 100.0},
      {'key': 'supplier', 'label': 'المورد', 'width': 180.0},
      {'key': 'company', 'label': 'الشركة', 'width': 180.0},
      {'key': 'quantity', 'label': 'الكمية', 'width': 100.0},
      {'key': 'density', 'label': 'الكثافة', 'width': 80.0},
      {'key': 'color', 'label': 'اللون', 'width': 100.0},
      {'key': 'voucher', 'label': 'رقم الوصل', 'width': 120.0},
      {'key': 'price', 'label': 'السعر', 'width': 100.0},
      {'key': 'cost', 'label': 'الكلفة', 'width': 120.0},
      {'key': 'driver', 'label': 'السائق', 'width': 150.0},
      {'key': 'vehicleNo', 'label': 'رقم المركبة', 'width': 120.0},
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.sahara.inputBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.sahara.dialogHeader,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_alt,
                    color: context.sahara.chartPurple, size: 20),
                const SizedBox(width: 8),
                Text('الفلاتر',
                    style: GoogleFonts.cairo(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_dbColumnFilters.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setDialogState(() {
                        _dbColumnFilters.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all,
                        size: 18, color: Colors.red),
                    label: Text('مسح الفلاتر',
                        style:
                            GoogleFonts.cairo(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  headingRowHeight: 100,
                  dataRowHeight: 55,
                  headingRowColor: WidgetStateProperty.all(
                      context.sahara.chartPurple.withValues(alpha: 0.15)),
                  columns: columns.map((col) {
                    return DataColumn(
                      label: SizedBox(
                        width: col['width'] as double,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              col['label'] as String,
                              style: GoogleFonts.cairo(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 35,
                              child: TextField(
                                onChanged: (value) {
                                  setDialogState(() {
                                    if (value.isEmpty) {
                                      _dbColumnFilters.remove(col['key']);
                                    } else {
                                      _dbColumnFilters[col['key'] as String] =
                                          value;
                                    }
                                  });
                                },
                                style: GoogleFonts.cairo(
                                    color: Theme.of(context).colorScheme.onSurface, fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'بحث...',
                                  hintStyle: GoogleFonts.cairo(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 11),
                                  filled: true,
                                  fillColor: context.sahara.inputBg,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(Icons.search,
                                      size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  rows: _databaseFilteredData.map((item) {
                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color>((states) {
                        if (_databaseFilteredData.indexOf(item) % 2 == 0) {
                          return Theme.of(context).colorScheme.surface.withValues(alpha: 0.03);
                        }
                        return Colors.transparent;
                      }),
                      cells: columns.map((col) {
                        final key = col['key'] as String;
                        final value = item[key];
                        String displayValue = '';

                        if (value is int || value is double) {
                          if (value != 0) {
                            displayValue = _formatNumber(
                                value is int ? value : value.toInt());
                          }
                        } else {
                          displayValue = value.toString();
                        }

                        return DataCell(
                          SizedBox(
                            width: col['width'] as double,
                            child: Text(
                              displayValue,
                              style: GoogleFonts.cairo(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة لإظهار نافذة إضافة البيانات
  void _showAddDataDialog(BuildContext context) {
    final supplierController = TextEditingController();
    final companyController = TextEditingController();
    final quantityController = TextEditingController();
    final densityController = TextEditingController();
    final colorController = TextEditingController();
    final voucherController = TextEditingController();
    final priceController = TextEditingController();
    final costController = TextEditingController();
    final driverController = TextEditingController();
    final vehicleNoController = TextEditingController();
    final dateController = TextEditingController(text: _lastUpdateDate);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: context.sahara.dialogHeader,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(Icons.add_box, color: Theme.of(context).colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('إضافة بيانات جديدة',
                        style: GoogleFonts.cairo(
                            color: Theme.of(context).colorScheme.surface,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.sahara.inputBg,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: _buildInputField('المورد',
                                        supplierController, Icons.business)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: _buildInputField('الشركة',
                                        companyController, Icons.factory)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildInputField('الكمية',
                                        quantityController, Icons.water_drop,
                                        isNumber: true)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: _buildInputField('الكثافة',
                                        densityController, Icons.compress,
                                        isNumber: true)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: _buildInputField('اللون',
                                        colorController, Icons.palette)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildInputField('رقم الوصل',
                                        voucherController, Icons.receipt)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: _buildInputField('السعر',
                                        priceController, Icons.attach_money,
                                        isNumber: true)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: _buildInputField('الكلفة',
                                        costController, Icons.monetization_on,
                                        isNumber: true)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildInputField('السائق',
                                        driverController, Icons.person)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: _buildInputField(
                                        'رقم المركبة',
                                        vehicleNoController,
                                        Icons.directions_car)),
                                const SizedBox(width: 15),
                                Expanded(
                                    child: _buildInputField('التاريخ',
                                        dateController, Icons.calendar_today)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _incomingData.add({
                                    'supplier': supplierController.text,
                                    'company': companyController.text,
                                    'quantity':
                                        int.tryParse(quantityController.text) ??
                                            0,
                                    'density': densityController.text.isEmpty
                                        ? ''
                                        : int.tryParse(
                                                densityController.text) ??
                                            0,
                                    'color': colorController.text,
                                    'voucher': voucherController.text,
                                    'price':
                                        int.tryParse(priceController.text) ?? 0,
                                    'cost':
                                        int.tryParse(costController.text) ?? 0,
                                    'driver': driverController.text,
                                    'vehicleNo': vehicleNoController.text,
                                    'date': dateController.text,
                                  });
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم إضافة البيانات بنجاح',
                                        style: GoogleFonts.cairo()),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check, size: 20),
                              label: Text('حفظ البيانات',
                                  style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.surface,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: context.sahara.inputBg,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(15),
                              child: Row(
                                children: [
                                  Icon(Icons.preview,
                                      color: Theme.of(context).colorScheme.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Text('معاينة البيانات المضافة',
                                      style: GoogleFonts.cairo(
                                          color: Theme.of(context).colorScheme.surface,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            _buildPreviewTable(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label, TextEditingController controller, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        filled: true,
        fillColor: context.sahara.dialogHeader,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildPreviewTable() {
    final columns = [
      {'key': 'date', 'label': 'التاريخ', 'width': 100.0},
      {'key': 'supplier', 'label': 'المورد', 'width': 180.0},
      {'key': 'company', 'label': 'الشركة', 'width': 180.0},
      {'key': 'quantity', 'label': 'الكمية', 'width': 100.0},
      {'key': 'density', 'label': 'الكثافة', 'width': 80.0},
      {'key': 'color', 'label': 'اللون', 'width': 100.0},
      {'key': 'voucher', 'label': 'رقم الوصل', 'width': 120.0},
      {'key': 'price', 'label': 'السعر', 'width': 100.0},
      {'key': 'cost', 'label': 'الكلفة', 'width': 120.0},
      {'key': 'driver', 'label': 'السائق', 'width': 150.0},
      {'key': 'vehicleNo', 'label': 'رقم المركبة', 'width': 120.0},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowHeight: 55,
        dataRowHeight: 50,
        headingRowColor:
            WidgetStateProperty.all(Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
        columns: columns.map((col) {
          return DataColumn(
            label: SizedBox(
              width: col['width'] as double,
              child: Text(
                col['label'] as String,
                style: GoogleFonts.cairo(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }).toList(),
        rows: _mainTableData.map((item) {
          return DataRow(
            color: WidgetStateProperty.resolveWith<Color>((states) {
              if (_mainTableData.indexOf(item) % 2 == 0) {
                return Theme.of(context).colorScheme.surface.withValues(alpha: 0.03);
              }
              return Colors.transparent;
            }),
            cells: columns.map((col) {
              final key = col['key'] as String;
              final value = item[key];
              String displayValue = '';

              if (value is int || value is double) {
                if (value != 0) {
                  displayValue =
                      _formatNumber(value is int ? value : value.toInt());
                }
              } else {
                displayValue = value.toString();
              }

              return DataCell(
                SizedBox(
                  width: col['width'] as double,
                  child: Text(
                    displayValue,
                    style: GoogleFonts.cairo(
                        color: Theme.of(context).colorScheme.onSurface, fontSize: 12),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

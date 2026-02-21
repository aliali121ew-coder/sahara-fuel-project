import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:math';
import '../constants/app_colors.dart';
import '../core/theme/color_schemes.dart';
import '../providers/fuel_provider.dart';
import '../providers/theme_provider.dart';

/// Phase 5 - صفحة التقارير المتقدمة
class AdvancedReportsPage extends StatefulWidget {
  const AdvancedReportsPage({super.key});
  @override
  State<AdvancedReportsPage> createState() => _AdvancedReportsPageState();
}

class _AdvancedReportsPageState extends State<AdvancedReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTimeRange _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now());
  String _compareMode = 'لا شيء'; // لا شيء, الشهر السابق, العام السابق
  String _chartType = 'خطي'; // خطي, أعمدة, دائري

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer2<FuelProvider, ThemeProvider>(
        builder: (context, prov, themeProvider, _) {
      final sahara = context.sahara;
      final fmt = NumberFormat('#,###');
      final totalStock =
          prov.tanks.fold<double>(0, (s, t) => s + t.currentAmount);
      final totalCapacity =
          prov.tanks.fold<double>(0, (s, t) => s + t.capacity);
      final fillPercent =
          totalCapacity > 0 ? (totalStock / totalCapacity * 100) : 0;

      return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: Theme.of(context).extension<SaharaColors>()!.pageGradient)),
            child: Column(children: [
              // ===== الهيدر + فلاتر التاريخ =====
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(children: [
                    Row(children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('التقارير المتقدمة',
                                style: GoogleFonts.cairo(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface)),
                            Text('تحليلات ومقارنات تفصيلية',
                                style: GoogleFonts.cairo(
                                    fontSize: 13, color: Theme.of(context).extension<SaharaColors>()!.subtleText)),
                          ]),
                      const Spacer(),
                      // فلتر التاريخ
                      _dateRangeButton(),
                      const SizedBox(width: 10),
                      _compareModeButton(),
                      const SizedBox(width: 10),
                      _chartTypeButton(),
                    ]),
                    const SizedBox(height: 16),

                    // ===== بطاقات ملخص =====
                    Row(children: [
                      _miniStat(
                          'المخزون الكلي',
                          '${fmt.format(totalStock)} لتر',
                          Icons.inventory_2,
                          Theme.of(context).colorScheme.primary,
                          '${fillPercent.toStringAsFixed(0)}%'),
                      const SizedBox(width: 12),
                      _miniStat(
                          'وارد الفترة',
                          '${fmt.format(prov.todayIncoming * _dateRange.duration.inDays)} لتر',
                          Icons.arrow_downward,
                          context.sahara.chartGreen,
                          '+${(_dateRange.duration.inDays * 0.8).toStringAsFixed(0)}%'),
                      const SizedBox(width: 12),
                      _miniStat(
                          'صادر الفترة',
                          '${fmt.format(prov.todayOutgoing * _dateRange.duration.inDays)} لتر',
                          Icons.arrow_upward,
                          context.sahara.chartRed,
                          '-${(_dateRange.duration.inDays * 0.3).toStringAsFixed(0)}%'),
                      const SizedBox(width: 12),
                      _miniStat('الشحنات', '${prov.incomingRecords.length}',
                          Icons.local_shipping, context.sahara.chartBlue, ''),
                      const SizedBox(width: 12),
                      _miniStat('التحويلات', '${prov.unionTransfers.length}',
                          Icons.swap_horiz, context.sahara.chartPurple, ''),
                      const SizedBox(width: 12),
                      _miniStat('الأيام', '${_dateRange.duration.inDays}',
                          Icons.date_range, context.sahara.chartOrange, ''),
                    ]),
                  ])),
              const SizedBox(height: 16),

              // ===== التابات =====
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                        color: Theme.of(context).extension<SaharaColors>()!.sidebar,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.sahara.statBorder)),
                    child: TabBar(
                        controller: _tabCtrl,
                        isScrollable: false,
                        dividerHeight: 0,
                        indicator: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.4))),
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: context.sahara.hintText,
                        labelStyle: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold, fontSize: 11),
                        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 10),
                        tabs: const [
                          Tab(text: 'الوارد/الصادر'),
                          Tab(text: 'الخزانات'),
                          Tab(text: 'المحطات'),
                          Tab(text: 'الاتجاهات'),
                          Tab(text: 'المقارنات'),
                          Tab(text: 'الجدول')
                        ]),
                  )),
              const SizedBox(height: 12),

              Expanded(
                  child: TabBarView(controller: _tabCtrl, children: [
                _inOutTab(prov, fmt),
                _tanksAnalyticsTab(prov, fmt),
                _stationsAnalyticsTab(prov, fmt),
                _trendsTab(prov, fmt),
                _comparisonTab(prov, fmt),
                _dataTableTab(prov, fmt),
              ])),
            ]),
          ));
    });
  }

  // ===== تاب الوارد والصادر مع رسوم بيانية =====
  Widget _inOutTab(FuelProvider prov, NumberFormat fmt) {
    final days = _dateRange.duration.inDays.clamp(1, 365);
    final rng = Random(42);

    // بيانات يومية - fallback عند عدم وجود بيانات من السيرفر
    final baseIn = prov.todayIncoming > 0 ? prov.todayIncoming : 85000.0;
    final baseOut = prov.todayOutgoing > 0 ? prov.todayOutgoing : 62000.0;
    final inData = List.generate(
        min(days, 30),
        (i) => FlSpot(i.toDouble(),
            (baseIn * (0.7 + rng.nextDouble() * 0.6)).roundToDouble()));
    final outData = List.generate(
        min(days, 30),
        (i) => FlSpot(i.toDouble(),
            (baseOut * (0.6 + rng.nextDouble() * 0.8)).roundToDouble()));

    // حساب حدود المحور Y
    final allY = [...inData.map((s) => s.y), ...outData.map((s) => s.y)];
    final maxY = allY.isEmpty ? 100000.0 : (allY.reduce(max) * 1.15);

    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          // الرسم البياني الرئيسي
          _chartCard(
              'حركة الوارد والصادر اليومية',
              320,
              LineChart(LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 5,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: Theme.of(context).colorScheme.onSurface!, strokeWidth: 0.5)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: max(1, (min(days, 30) / 8).ceilToDouble()),
                          getTitlesWidget: (v, m) => Text('${v.toInt() + 1}',
                              style: GoogleFonts.cairo(
                                  color: context.sahara.hintText, fontSize: 9)))),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (v, m) => Text(fmt.format(v.toInt()),
                              style: GoogleFonts.cairo(
                                  color: context.sahara.hintText, fontSize: 9)))),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                      spots: inData,
                      isCurved: true,
                      color: context.sahara.chartGreen,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color: context.sahara.chartGreen.withOpacity(0.08))),
                  LineChartBarData(
                      spots: outData,
                      isCurved: true,
                      color: context.sahara.chartRed,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color: context.sahara.chartRed.withOpacity(0.08))),
                ],
                lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) => spots
                            .map((s) => LineTooltipItem(
                                '${fmt.format(s.y.toInt())} لتر',
                                GoogleFonts.cairo(
                                    color: s.bar.color!, fontSize: 11)))
                            .toList())),
              ))),
          const SizedBox(height: 16),

          // رسم بياني أعمدة - ملخص أسبوعي
          Row(children: [
            Expanded(
                child: _chartCard(
                    'توزيع الوارد حسب النوع',
                    220,
                    PieChart(PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                            value: 45,
                            title: '45%',
                            color: context.sahara.chartGreen,
                            radius: 50,
                            titleStyle: GoogleFonts.cairo(
                                color: Theme.of(context).colorScheme.surface,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                        PieChartSectionData(
                            value: 30,
                            title: '30%',
                            color: context.sahara.chartBlue,
                            radius: 45,
                            titleStyle: GoogleFonts.cairo(
                                color: Theme.of(context).colorScheme.surface,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                        PieChartSectionData(
                            value: 25,
                            title: '25%',
                            color: context.sahara.chartOrange,
                            radius: 40,
                            titleStyle: GoogleFonts.cairo(
                                color: Theme.of(context).colorScheme.surface,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    )))),
            const SizedBox(width: 16),
            Expanded(
                child: _chartCard(
                    'أعلى 5 موردين', 220, _topSuppliersWidget(prov))),
          ]),
          const SizedBox(height: 24),
        ]));
  }

  Widget _topSuppliersWidget(FuelProvider prov) {
    final suppliers = {
      'شركة النفط الوطنية': 45,
      'مصفاة البصرة': 28,
      'الشركة العامة': 15,
      'القطاع الخاص': 8,
      'أخرى': 4
    };
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: suppliers.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(
                        flex: 3,
                        child: Text(e.key,
                            style: GoogleFonts.cairo(
                                color: context.sahara.subtleText, fontSize: 11))),
                    Expanded(
                        flex: 4,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                                value: e.value / 50,
                                backgroundColor: Theme.of(context).colorScheme.onSurface,
                                color: Theme.of(context).colorScheme.primary,
                                minHeight: 8))),
                    const SizedBox(width: 8),
                    Text('${e.value}%',
                        style: GoogleFonts.cairo(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ]),
                ))
            .toList());
  }

  // ===== تاب تحليلات الخزانات =====
  Widget _tanksAnalyticsTab(FuelProvider prov, NumberFormat fmt) {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          // مخطط الخزانات
          _chartCard(
              'نسبة امتلاء الخزانات',
              280,
              BarChart(BarChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: Theme.of(context).colorScheme.onSurface!, strokeWidth: 0.5)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) {
                            final idx = v.toInt();
                            if (idx < prov.tanks.length)
                              return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                      prov.tanks[idx].name.split(' ').last,
                                      style: GoogleFonts.cairo(
                                          color: context.sahara.hintText,
                                          fontSize: 9)));
                            return const SizedBox();
                          })),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (v, m) => Text('${v.toInt()}%',
                              style: GoogleFonts.cairo(
                                  color: context.sahara.hintText, fontSize: 9)))),
                ),
                borderData: FlBorderData(show: false),
                maxY: 100,
                barGroups: List.generate(prov.tanks.length, (i) {
                  final t = prov.tanks[i];
                  final pct =
                      t.capacity > 0 ? (t.currentAmount / t.capacity * 100) : 0;
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                        toY: pct.toDouble(),
                        width: 22,
                        color: pct > 70
                            ? context.sahara.chartGreen
                            : pct > 30
                                ? context.sahara.chartOrange
                                : context.sahara.chartRed,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: Theme.of(context).colorScheme.onSurface!.withOpacity(0.3))),
                  ]);
                }),
              ))),
          const SizedBox(height: 16),

          // جدول تفاصيل الخزانات
          Container(
            decoration: BoxDecoration(
                color: Theme.of(context).extension<SaharaColors>()!.sidebar,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.sahara.statBorder)),
            child: Column(children: [
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: context.sahara.dialogHeader,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16))),
                  child: Row(children: [
                    Icon(Icons.propane_tank, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Text('تفاصيل الخزانات',
                        style: GoogleFonts.cairo(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const Spacer(),
                    Text('${prov.tanks.length} خزان',
                        style: GoogleFonts.cairo(
                            color: context.sahara.hintText, fontSize: 12)),
                  ])),
              ...prov.tanks.map((t) {
                final pct =
                    t.capacity > 0 ? (t.currentAmount / t.capacity * 100) : 0;
                final color = pct > 70
                    ? context.sahara.chartGreen
                    : pct > 30
                        ? context.sahara.chartOrange
                        : context.sahara.chartRed;
                return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface!, width: 0.5))),
                    child: Row(children: [
                      Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10)),
                          child:
                              Icon(Icons.propane_tank, color: color, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                          flex: 2,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.name,
                                    style: GoogleFonts.cairo(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text(t.location,
                                    style: GoogleFonts.cairo(
                                        color: context.sahara.hintText, fontSize: 10)),
                              ])),
                      Expanded(
                          flex: 3,
                          child: Column(children: [
                            Row(children: [
                              Text(
                                  '${fmt.format(t.currentAmount)} / ${fmt.format(t.capacity)} لتر',
                                  style: GoogleFonts.cairo(
                                      color: context.sahara.subtleText, fontSize: 11)),
                              const Spacer(),
                              Text('${pct.toStringAsFixed(1)}%',
                                  style: GoogleFonts.cairo(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ]),
                            const SizedBox(height: 4),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                    value: pct / 100,
                                    backgroundColor: Theme.of(context).colorScheme.onSurface,
                                    color: color,
                                    minHeight: 6)),
                          ])),
                      const SizedBox(width: 12),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(t.arabicStatus,
                              style: GoogleFonts.cairo(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold))),
                    ]));
              }),
            ]),
          ),
          const SizedBox(height: 24),
        ]));
  }

  // ===== تاب تحليلات المحطات =====
  Widget _stationsAnalyticsTab(FuelProvider prov, NumberFormat fmt) {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          // مقارنة المحطات
          _chartCard(
              'استهلاك المحطات',
              300,
              BarChart(BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) {
                            final idx = v.toInt();
                            if (idx < prov.stations.length)
                              return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                      prov.stations[idx].name.split(' ').last,
                                      style: GoogleFonts.cairo(
                                          color: context.sahara.hintText,
                                          fontSize: 8)));
                            return const SizedBox();
                          })),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (v, m) => Text(fmt.format(v.toInt()),
                              style: GoogleFonts.cairo(
                                  color: context.sahara.hintText, fontSize: 9)))),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(prov.stations.length, (i) {
                  final s = prov.stations[i];
                  return BarChartGroupData(x: i, barsSpace: 4, barRods: [
                    BarChartRodData(
                        toY: s.balance,
                        width: 14,
                        color: context.sahara.chartBlue,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4))),
                    BarChartRodData(
                        toY: s.dailyConsumption,
                        width: 14,
                        color: context.sahara.chartOrange,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4))),
                  ]);
                }),
              ))),
          const SizedBox(height: 12),
          // مفتاح الألوان
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendDot('الرصيد', context.sahara.chartBlue),
            const SizedBox(width: 24),
            _legendDot('الاستهلاك اليومي', context.sahara.chartOrange),
          ]),
          const SizedBox(height: 16),

          // جدول أداء المحطات
          Container(
            decoration: BoxDecoration(
                color: Theme.of(context).extension<SaharaColors>()!.sidebar,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.sahara.statBorder)),
            child: Column(children: [
              Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: context.sahara.dialogHeader,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16))),
                  child: Row(children: [
                    for (final h in [
                      'المحطة',
                      'الرصيد',
                      'الاستهلاك',
                      'الهدف',
                      'الإنجاز',
                      'المزارع',
                      'الحالة'
                    ])
                      Expanded(
                          child: Text(h,
                              style: GoogleFonts.cairo(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                  ])),
              ...List.generate(prov.stations.length, (i) {
                final s = prov.stations[i];
                final achievement = s.monthlyTarget > 0
                    ? (s.dailyConsumption * 30 / s.monthlyTarget * 100)
                        .clamp(0, 150)
                    : 0;
                final color = achievement > 90
                    ? context.sahara.chartGreen
                    : achievement > 60
                        ? context.sahara.chartOrange
                        : context.sahara.chartRed;
                return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    color: i.isOdd
                        ? context.sahara.dialogHeader.withOpacity(0.3)
                        : Colors.transparent,
                    child: Row(children: [
                      Expanded(
                          child: Text(s.name,
                              style: GoogleFonts.cairo(
                                  color: Theme.of(context).colorScheme.surface,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text('${fmt.format(s.balance)}',
                              style: GoogleFonts.cairo(
                                  color: context.sahara.chartBlue, fontSize: 11),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text('${fmt.format(s.dailyConsumption)}',
                              style: GoogleFonts.cairo(
                                  color: context.sahara.chartOrange, fontSize: 11),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text('${fmt.format(s.monthlyTarget)}',
                              style: GoogleFonts.cairo(
                                  color: context.sahara.subtleText, fontSize: 11),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text('${achievement.toStringAsFixed(0)}%',
                              style: GoogleFonts.cairo(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text('${s.farms}',
                              style: GoogleFonts.cairo(
                                  color: context.sahara.subtleText, fontSize: 11),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Center(
                              child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: color, shape: BoxShape.circle)))),
                    ]));
              }),
            ]),
          ),
          const SizedBox(height: 24),
        ]));
  }

  // ===== تاب الاتجاهات =====
  Widget _trendsTab(FuelProvider prov, NumberFormat fmt) {
    final rng = Random(99);
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    final baseIn = prov.todayIncoming > 0 ? prov.todayIncoming : 85000.0;
    final baseOut = prov.todayOutgoing > 0 ? prov.todayOutgoing : 62000.0;
    final monthlyIn = List.generate(
        12, (i) => (baseIn * 28 * (0.7 + rng.nextDouble() * 0.6)).round());
    final monthlyOut = List.generate(
        12, (i) => (baseOut * 28 * (0.6 + rng.nextDouble() * 0.8)).round());

    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          // اتجاه سنوي
          _chartCard(
              'الاتجاه السنوي — الوارد مقابل الصادر',
              300,
              BarChart(BarChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50000),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) => Text(
                              months[v.toInt() % 12].substring(0, 3),
                              style: GoogleFonts.cairo(
                                  color: context.sahara.hintText, fontSize: 8)))),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (v, m) => Text(
                              '${(v / 1000).toStringAsFixed(0)}K',
                              style: GoogleFonts.cairo(
                                  color: context.sahara.hintText, fontSize: 9)))),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                    12,
                    (i) => BarChartGroupData(x: i, barsSpace: 3, barRods: [
                          BarChartRodData(
                              toY: monthlyIn[i].toDouble(),
                              width: 10,
                              color: context.sahara.chartGreen,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3))),
                          BarChartRodData(
                              toY: monthlyOut[i].toDouble(),
                              width: 10,
                              color: context.sahara.chartRed,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3))),
                        ])),
              ))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendDot('الوارد', context.sahara.chartGreen),
            const SizedBox(width: 20),
            _legendDot('الصادر', context.sahara.chartRed)
          ]),
          const SizedBox(height: 16),

          // مؤشرات الأداء
          Row(children: [
            Expanded(
                child: _kpiCard(
                    'معدل الاستهلاك اليومي',
                    '${fmt.format(prov.todayOutgoing)} لتر',
                    Icons.speed,
                    context.sahara.chartOrange,
                    '+5.2%')),
            const SizedBox(width: 12),
            Expanded(
                child: _kpiCard(
                    'معدل التعبئة',
                    '${fmt.format(prov.todayIncoming)} لتر/يوم',
                    Icons.trending_up,
                    context.sahara.chartGreen,
                    '+12%')),
            const SizedBox(width: 12),
            Expanded(
                child: _kpiCard('كفاءة التوزيع', '94.3%', Icons.pie_chart,
                    context.sahara.chartBlue, '+2.1%')),
            const SizedBox(width: 12),
            Expanded(
                child: _kpiCard(
                    'أيام التغطية',
                    '${(prov.tanks.fold<double>(0, (s, t) => s + t.currentAmount) / max(1, prov.todayOutgoing)).toStringAsFixed(0)} يوم',
                    Icons.calendar_today,
                    context.sahara.chartPurple,
                    '')),
          ]),
          const SizedBox(height: 24),
        ]));
  }

  // ===== تاب المقارنات =====
  Widget _comparisonTab(FuelProvider prov, NumberFormat fmt) {
    final rng = Random(77);
    final baseIn = prov.todayIncoming > 0 ? prov.todayIncoming : 85000.0;
    final currentMonth = List.generate(
        30, (i) => (baseIn * (0.8 + rng.nextDouble() * 0.4)).roundToDouble());
    final prevMonth = List.generate(
        30,
        (i) =>
            (baseIn * 0.85 * (0.75 + rng.nextDouble() * 0.5)).roundToDouble());
    final currentTotal = currentMonth.fold<double>(0, (s, v) => s + v);
    final prevTotal = prevMonth.fold<double>(0, (s, v) => s + v);
    final changePercent =
        prevTotal > 0 ? ((currentTotal - prevTotal) / prevTotal * 100) : 0;

    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          // ملخص المقارنة
          Row(children: [
            Expanded(
                child: _compareCard('الشهر الحالي',
                    fmt.format(currentTotal.toInt()), 'لتر', Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 12),
            Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                    color: Theme.of(context).extension<SaharaColors>()!.sidebar,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.sahara.statBorder)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          changePercent >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: changePercent >= 0
                              ? context.sahara.chartGreen
                              : context.sahara.chartRed,
                          size: 24),
                      Text(
                          '${changePercent >= 0 ? "+" : ""}${changePercent.toStringAsFixed(1)}%',
                          style: GoogleFonts.cairo(
                              color: changePercent >= 0
                                  ? context.sahara.chartGreen
                                  : context.sahara.chartRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ])),
            const SizedBox(width: 12),
            Expanded(
                child: _compareCard('الشهر السابق',
                    fmt.format(prevTotal.toInt()), 'لتر', Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 16),

          // رسم المقارنة
          _chartCard(
              'مقارنة يومية — الشهر الحالي مقابل السابق',
              280,
              LineChart(LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: 5,
                          getTitlesWidget: (v, m) => Text('${v.toInt() + 1}',
                              style: GoogleFonts.cairo(
                                  color: context.sahara.hintText, fontSize: 9)))),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (v, m) => Text(fmt.format(v.toInt()),
                              style: GoogleFonts.cairo(
                                  color: context.sahara.hintText, fontSize: 9)))),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                      spots: List.generate(
                          30, (i) => FlSpot(i.toDouble(), currentMonth[i])),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.06))),
                  LineChartBarData(
                      spots: List.generate(
                          30, (i) => FlSpot(i.toDouble(), prevMonth[i])),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      dashArray: [5, 5]),
                ],
              ))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendDot('الشهر الحالي', Theme.of(context).colorScheme.primary),
            const SizedBox(width: 20),
            _legendDot('الشهر السابق', Theme.of(context).colorScheme.onSurfaceVariant)
          ]),
          const SizedBox(height: 24),
        ]));
  }

  // ===== تاب الجدول الشامل =====
  Widget _dataTableTab(FuelProvider prov, NumberFormat fmt) {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          Container(
            decoration: BoxDecoration(
                color: Theme.of(context).extension<SaharaColors>()!.sidebar,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.sahara.statBorder)),
            child: Column(children: [
              Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: context.sahara.dialogHeader,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16))),
                  child: Row(children: [
                    Icon(Icons.table_chart, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Text('سجل الوارد التفصيلي',
                        style: GoogleFonts.cairo(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('${prov.incomingRecords.length} سجل',
                            style: GoogleFonts.cairo(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold))),
                  ])),
              // رؤوس الأعمدة
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: context.sahara.sidebar,
                  child: Row(children: [
                    for (final h in [
                      'التاريخ',
                      'المورد',
                      'النوع',
                      'الكمية',
                      'السعر',
                      'الإجمالي',
                      'الخزان'
                    ])
                      Expanded(
                          child: Text(h,
                              style: GoogleFonts.cairo(
                                  color: context.sahara.subtleText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                  ])),
              // البيانات
              ...List.generate(min(prov.incomingRecords.length, 20), (i) {
                final r = prov.incomingRecords[i];
                return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: i.isOdd
                        ? context.sahara.dialogHeader.withOpacity(0.3)
                        : Colors.transparent,
                    child: Row(children: [
                      Expanded(
                          child: Text(DateFormat('MM/dd').format(r.date),
                              style: GoogleFonts.cairo(
                                  color: context.sahara.subtleText, fontSize: 10),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(r.supplier,
                              style: GoogleFonts.cairo(
                                  color: Theme.of(context).colorScheme.onSurface, fontSize: 10),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(r.fuelType,
                              style: GoogleFonts.cairo(
                                  color: context.sahara.subtleText, fontSize: 10),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(fmt.format(r.quantity),
                              style: GoogleFonts.cairo(
                                  color: context.sahara.chartGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(fmt.format(r.unitPrice),
                              style: GoogleFonts.cairo(
                                  color: context.sahara.subtleText, fontSize: 10),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(fmt.format(r.totalCost),
                              style: GoogleFonts.cairo(
                                  color: context.sahara.chartOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text(r.tankName,
                              style: GoogleFonts.cairo(
                                  color: context.sahara.subtleText, fontSize: 10),
                              textAlign: TextAlign.center)),
                    ]));
              }),
            ]),
          ),
          const SizedBox(height: 24),
        ]));
  }

  // ===== أدوات واجهة =====
  Widget _dateRangeButton() => GestureDetector(
      onTap: () async {
        final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2025),
            lastDate: DateTime.now(),
            initialDateRange: _dateRange,
            locale: const Locale('ar'),
            builder: (ctx, child) => Theme(
                data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(
                        primary: Theme.of(context).colorScheme.primary, surface: Theme.of(context).extension<SaharaColors>()!.sidebar)),
                child: child!));
        if (picked != null) setState(() => _dateRange = picked);
      },
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: Theme.of(context).extension<SaharaColors>()!.sidebar,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.sahara.statBorder)),
          child: Row(children: [
            Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary, size: 16),
            const SizedBox(width: 8),
            Text(
                '${DateFormat('MM/dd').format(_dateRange.start)} - ${DateFormat('MM/dd').format(_dateRange.end)}',
                style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.surface, fontSize: 11)),
          ])));

  Widget _compareModeButton() => PopupMenuButton<String>(
      onSelected: (v) => setState(() => _compareMode = v),
      color: Theme.of(context).extension<SaharaColors>()!.sidebar,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: Theme.of(context).extension<SaharaColors>()!.sidebar,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.sahara.statBorder)),
          child: Row(children: [
            Icon(Icons.compare_arrows,
                color: context.sahara.chartPurple, size: 16),
            const SizedBox(width: 6),
            Text(_compareMode,
                style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.surface, fontSize: 11))
          ])),
      itemBuilder: (_) => ['لا شيء', 'الشهر السابق', 'العام السابق']
          .map((e) => PopupMenuItem(
              value: e,
              child: Text(e,
                  style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface, fontSize: 12))))
          .toList());

  Widget _chartTypeButton() => PopupMenuButton<String>(
      onSelected: (v) => setState(() => _chartType = v),
      color: Theme.of(context).extension<SaharaColors>()!.sidebar,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: Theme.of(context).extension<SaharaColors>()!.sidebar,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.sahara.statBorder)),
          child: Row(children: [
            Icon(
                _chartType == 'خطي'
                    ? Icons.show_chart
                    : _chartType == 'أعمدة'
                        ? Icons.bar_chart
                        : Icons.pie_chart,
                color: context.sahara.chartOrange,
                size: 16),
            const SizedBox(width: 6),
            Text(_chartType,
                style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.surface, fontSize: 11))
          ])),
      itemBuilder: (_) => ['خطي', 'أعمدة', 'دائري']
          .map((e) => PopupMenuItem(
              value: e,
              child: Text(e,
                  style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface, fontSize: 12))))
          .toList());

  Widget _miniStat(String label, String value, IconData icon, Color color,
          String change) =>
      Expanded(
          child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Theme.of(context).extension<SaharaColors>()!.sidebar,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.15))),
              child: Row(children: [
                Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 18)),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(label,
                          style: GoogleFonts.cairo(
                              color: context.sahara.hintText, fontSize: 9)),
                      Text(value,
                          style: GoogleFonts.cairo(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ])),
                if (change.isNotEmpty)
                  Text(change,
                      style: GoogleFonts.cairo(
                          color: change.startsWith('+')
                              ? context.sahara.chartGreen
                              : context.sahara.chartRed,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
              ])));

  Widget _chartCard(String title, double height, Widget chart) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).extension<SaharaColors>()!.sidebar,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.sahara.statBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.cairo(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 16),
        SizedBox(height: height, child: chart),
      ]));

  Widget _kpiCard(String title, String value, IconData icon, Color color,
          String change) =>
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Theme.of(context).extension<SaharaColors>()!.sidebar,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.15))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              if (change.isNotEmpty)
                Text(change,
                    style: GoogleFonts.cairo(
                        color: change.startsWith('+')
                            ? context.sahara.chartGreen
                            : context.sahara.chartRed,
                        fontSize: 11,
                        fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 10),
            Text(value,
                style: GoogleFonts.cairo(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(title,
                style:
                    GoogleFonts.cairo(color: context.sahara.hintText, fontSize: 11)),
          ]));

  Widget _compareCard(String title, String value, String unit, Color color) =>
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.cairo(color: color, fontSize: 12)),
            Text(value,
                style: GoogleFonts.cairo(
                    color: Theme.of(context).colorScheme.surface,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
            Text(unit,
                style:
                    GoogleFonts.cairo(color: context.sahara.hintText, fontSize: 11)),
          ]));

  Widget _legendDot(String label, Color color) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.cairo(color: context.sahara.hintText, fontSize: 10))
      ]);
}

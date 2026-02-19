import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../core/theme/color_schemes.dart';
import '../providers/fuel_provider.dart';
import '../providers/theme_provider.dart';

class GasBalancePage extends StatefulWidget {
  const GasBalancePage({super.key});

  @override
  State<GasBalancePage> createState() => _GasBalancePageState();
}

class _GasBalancePageState extends State<GasBalancePage> {
  String _selectedPeriod = 'شهري';
  String? _selectedStation;
  DateTime? _selectedDate;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = Theme.of(context).extension<SaharaColors>()!;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final provider = Provider.of<FuelProvider>(context);
        final formatter = NumberFormat('#,###', 'ar');
        final gasRecords = provider.gasRecords.where((r) {
          if (_searchQuery.isNotEmpty) {
            return r.station.contains(_searchQuery) ||
                r.farm.contains(_searchQuery) ||
                r.operator.contains(_searchQuery);
          }
          if (_selectedStation != null) return r.station == _selectedStation;
          return true;
        }).toList();

        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: sahara.pageGradient,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(provider, formatter, colorScheme, sahara),
                  const SizedBox(height: 24),
                  _buildStationCards(provider, formatter, colorScheme, sahara),
                  const SizedBox(height: 24),
                  _buildColoredStatCards(provider, formatter, sahara),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 800) {
                        return Column(
                          children: [
                            _buildMainChart(provider, colorScheme, sahara),
                            const SizedBox(height: 20),
                            _buildTrafficDonut(provider, colorScheme, sahara),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildMainChart(provider, colorScheme, sahara)),
                          const SizedBox(width: 20),
                          Expanded(flex: 1, child: _buildTrafficDonut(provider, colorScheme, sahara)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildFarmBalances(provider, formatter, colorScheme, sahara),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 800) {
                        return Column(
                          children: [
                            _buildDataTable(gasRecords, formatter, colorScheme, sahara),
                            const SizedBox(height: 20),
                            _buildRecentActivities(provider, colorScheme, sahara),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 2,
                              child: _buildDataTable(gasRecords, formatter, colorScheme, sahara)),
                          const SizedBox(width: 20),
                          Expanded(
                              flex: 1,
                              child: _buildRecentActivities(provider, colorScheme, sahara)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader(
      FuelProvider provider, NumberFormat formatter, ColorScheme colorScheme, SaharaColors sahara) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('رصيد الغاز',
              style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          Text('نظرة عامة على رصيد الغاز للشهر الحالي',
              style: GoogleFonts.cairo(fontSize: 14, color: colorScheme.onSurfaceVariant)),
        ]),
        Row(children: [
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                  color: sahara.sidebar,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.2))),
              child: Row(children: [
                Icon(Icons.calendar_today, color: colorScheme.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                    _selectedDate != null
                        ? DateFormat('d MMMM yyyy', 'ar').format(_selectedDate!)
                        : DateFormat('d MMMM yyyy', 'ar').format(DateTime.now()),
                    style: GoogleFonts.cairo(fontSize: 13, color: colorScheme.onSurface)),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          ...['يومي', 'أسبوعي', 'شهري', 'سنوي'].map((p) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == p ? colorScheme.primary : sahara.sidebar,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(p,
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: _selectedPeriod == p
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                            fontWeight:
                                _selectedPeriod == p ? FontWeight.bold : FontWeight.normal)),
                  ),
                ),
              )),
        ]),
      ],
    );
  }

  // ==================== STATION CARDS ====================
  Widget _buildStationCards(
      FuelProvider provider, NumberFormat formatter, ColorScheme colorScheme, SaharaColors sahara) {
    final stationBalances = provider.gasBalanceByStation;
    final stations = provider.stations;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 140,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: stations.length > 6 ? 6 : stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        final balance = stationBalances[station.name] ?? 0;
        final isSelected = _selectedStation == station.name;
        return GestureDetector(
          onTap: () => setState(
              () => _selectedStation = _selectedStation == station.name ? null : station.name),
          child: Card(
            color: sahara.sidebar,
            elevation: isSelected ? 12 : 6,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isSelected
                    ? BorderSide(color: station.color.withOpacity(0.6), width: 2)
                    : BorderSide.none),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [
                    station.color.withOpacity(0.12),
                    station.color.withOpacity(0.03)
                  ])),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: station.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.local_fire_department, color: station.color, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: (balance >= 0 ? sahara.chartGreen : sahara.chartRed)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                        '${balance >= 0 ? "+" : ""}${formatter.format(balance)} لتر',
                        style: TextStyle(
                            color: balance >= 0 ? sahara.chartGreen : sahara.chartRed,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
                const Spacer(),
                Text('${formatter.format(balance.abs())} لتر',
                    style: GoogleFonts.cairo(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(station.name,
                    style: GoogleFonts.cairo(fontSize: 11, color: colorScheme.onSurfaceVariant)),
              ]),
            ),
          ),
        );
      },
    );
  }

  // ==================== COLORED STAT CARDS ====================
  Widget _buildColoredStatCards(FuelProvider provider, NumberFormat formatter, SaharaColors sahara) {
    final cards = [
      _ColoredCardData(
          'إجمالي الوارد',
          formatter.format(provider.totalGasIncoming),
          'لتر',
          sahara.chartRed,
          sahara.chartRed.withOpacity(0.7),
          Icons.arrow_downward),
      _ColoredCardData(
          'إجمالي الصادر',
          formatter.format(provider.totalGasOutgoing),
          'لتر',
          sahara.chartOrange,
          sahara.chartOrange.withOpacity(0.6),
          Icons.arrow_upward),
      _ColoredCardData(
          'صافي الرصيد',
          formatter.format(provider.totalGasBalance),
          'لتر',
          sahara.chartBlue,
          sahara.chartBlue.withOpacity(0.6),
          Icons.account_balance_wallet),
      _ColoredCardData(
          'إجمالي التكلفة',
          formatter.format(provider.totalGasCost),
          'د.ع',
          sahara.chartPurple,
          sahara.chartPurple.withOpacity(0.5),
          Icons.attach_money),
    ];

    return Row(
      children: cards
          .map((card) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                        colors: [card.color1, card.color2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    boxShadow: [
                      BoxShadow(
                          color: card.color1.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(card.title,
                          style: GoogleFonts.cairo(
                              fontSize: 12, color: Colors.white.withOpacity(0.9))),
                      Icon(card.icon, color: Colors.white.withOpacity(0.7), size: 20),
                    ]),
                    const SizedBox(height: 12),
                    Text(card.value,
                        style: GoogleFonts.cairo(
                            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(card.unit,
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: Colors.white.withOpacity(0.7))),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 30,
                      child: _buildMiniSparkline(
                          card.color1 == sahara.chartRed
                              ? provider.gasWeeklyData
                              : provider.gasWeeklyOutgoing),
                    ),
                  ]),
                ),
              ))
          .toList(),
    );
  }

  // ==================== MINI SPARKLINE ====================
  Widget _buildMiniSparkline(List<double> data) {
    if (data.every((d) => d == 0)) return const SizedBox();
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox();
    return CustomPaint(
      size: const Size(double.infinity, 30),
      painter: _SparklinePainter(data, maxVal),
    );
  }

  // ==================== MAIN CHART ====================
  Widget _buildMainChart(FuelProvider provider, ColorScheme colorScheme, SaharaColors sahara) {
    final incoming = provider.gasWeeklyData;
    final outgoing = provider.gasWeeklyOutgoing;
    final days = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];

    return Card(
      color: sahara.sidebar,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Dashboard',
                style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface)),
            Row(children: [
              _legendDot(colorScheme.primary, 'الوارد', colorScheme),
              const SizedBox(width: 16),
              _legendDot(sahara.chartRed, 'الصادر', colorScheme),
            ]),
          ]),
          Text('نظرة عامة على الغاز للشهر الحالي',
              style: GoogleFonts.cairo(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: colorScheme.outline.withOpacity(0.3), strokeWidth: 0.5)),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          if (v.toInt() >= 0 && v.toInt() < days.length) {
                            return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(days[v.toInt()],
                                    style: GoogleFonts.cairo(
                                        color: colorScheme.onSurfaceVariant, fontSize: 10)));
                          }
                          return const SizedBox();
                        })),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (v, _) => Text('${(v / 1000).toStringAsFixed(0)}K',
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant, fontSize: 9)))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                      incoming.length, (i) => FlSpot(i.toDouble(), incoming[i])),
                  isCurved: true,
                  color: colorScheme.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacity(0.3),
                            Colors.transparent
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter)),
                ),
                LineChartBarData(
                  spots: List.generate(
                      outgoing.length, (i) => FlSpot(i.toDouble(), outgoing[i])),
                  isCurved: true,
                  color: sahara.chartRed,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                          colors: [
                            sahara.chartRed.withOpacity(0.15),
                            Colors.transparent
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter)),
                ),
              ],
            )),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _chartStat(Icons.local_fire_department, 'إجمالي الرصيد',
                  FuelProvider.formatNumber(provider.totalGasBalance), colorScheme.primary, colorScheme, sahara),
              _chartStat(Icons.arrow_downward, 'الوارد',
                  FuelProvider.formatNumber(provider.totalGasIncoming), sahara.chartGreen, colorScheme, sahara),
              _chartStat(Icons.arrow_upward, 'الصادر',
                  FuelProvider.formatNumber(provider.totalGasOutgoing), sahara.chartRed, colorScheme, sahara),
              _chartStat(Icons.monetization_on, 'التكلفة',
                  FuelProvider.formatNumber(provider.totalGasCost), sahara.chartOrange, colorScheme, sahara),
            ],
          ),
        ]),
      ),
    );
  }

  // ==================== TRAFFIC DONUT ====================
  Widget _buildTrafficDonut(FuelProvider provider, ColorScheme colorScheme, SaharaColors sahara) {
    final total = provider.totalGasIncoming + provider.totalGasOutgoing;
    final inPct = total > 0 ? (provider.totalGasIncoming / total * 100) : 50.0;
    final outPct = total > 0 ? (provider.totalGasOutgoing / total * 100) : 50.0;

    return Card(
      color: sahara.sidebar,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text('Traffic',
              style: GoogleFonts.cairo(
                  fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                    value: inPct,
                    color: sahara.chartRed,
                    title: '${inPct.toStringAsFixed(0)}%',
                    titleStyle: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    radius: 35),
                PieChartSectionData(
                    value: outPct,
                    color: sahara.chartOrange,
                    title: '${outPct.toStringAsFixed(0)}%',
                    titleStyle: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    radius: 35),
                PieChartSectionData(
                    value: 12,
                    color: sahara.chartPurple,
                    title: '12%',
                    titleStyle: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    radius: 35),
              ],
            )),
          ),
          const SizedBox(height: 20),
          _trafficLegend(sahara.chartRed, 'الوارد', '${inPct.toStringAsFixed(0)}%', colorScheme),
          const SizedBox(height: 8),
          _trafficLegend(sahara.chartOrange, 'الصادر', '${outPct.toStringAsFixed(0)}%', colorScheme),
          const SizedBox(height: 8),
          _trafficLegend(sahara.chartPurple, 'مخزون', '12%', colorScheme),
        ]),
      ),
    );
  }

  // ==================== FARM BALANCES ====================
  Widget _buildFarmBalances(
      FuelProvider provider, NumberFormat formatter, ColorScheme colorScheme, SaharaColors sahara) {
    final farmBalances = provider.gasFarmBalances;
    final farms = farmBalances.entries.toList();

    return Card(
      color: sahara.sidebar,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('أرصدة المزارع',
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${farms.length} مزرعة',
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 16),
          if (farms.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  Icon(Icons.agriculture, size: 48, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text('لا توجد بيانات متاحة',
                      style: GoogleFonts.cairo(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                ]),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: farms.map((farm) {
                final isPositive = farm.value >= 0;
                return Container(
                  width: 200,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sahara.statBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sahara.statBorder),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.agriculture,
                          size: 16, color: colorScheme.primary.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(farm.key,
                            style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${formatter.format(farm.value.abs())} لتر',
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isPositive ? sahara.chartGreen : sahara.chartRed)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                              isPositive ? Icons.trending_up : Icons.trending_down,
                              size: 12,
                              color: isPositive ? sahara.chartGreen : sahara.chartRed),
                          const SizedBox(width: 2),
                          Text(isPositive ? 'موجب' : 'سالب',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: isPositive ? sahara.chartGreen : sahara.chartRed,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ]),
                  ]),
                );
              }).toList(),
            ),
        ]),
      ),
    );
  }

  // ==================== DATA TABLE ====================
  Widget _buildDataTable(
      List<dynamic> gasRecords, NumberFormat formatter, ColorScheme colorScheme, SaharaColors sahara) {
    return Card(
      color: sahara.sidebar,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('سجلات الغاز',
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.cairo(fontSize: 13, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'بحث...',
                  hintStyle: GoogleFonts.cairo(color: sahara.hintText),
                  prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant, size: 18),
                  filled: true,
                  fillColor: sahara.inputBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          if (gasRecords.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  Icon(Icons.inbox, size: 48, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text('لا توجد سجلات',
                      style: GoogleFonts.cairo(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                ]),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(sahara.tableHeader),
                dataRowColor: WidgetStateProperty.resolveWith<Color>((states) {
                  final index = states.contains(WidgetState.selected) ? 0 : 1;
                  return index.isOdd ? sahara.tableRowOdd : sahara.tableRowEven;
                }),
                headingTextStyle: GoogleFonts.cairo(
                    fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                dataTextStyle: GoogleFonts.cairo(fontSize: 12, color: colorScheme.onSurface),
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('المحطة')),
                  DataColumn(label: Text('المزرعة')),
                  DataColumn(label: Text('المشغل')),
                  DataColumn(label: Text('الكمية (لتر)')),
                  DataColumn(label: Text('النوع')),
                  DataColumn(label: Text('التاريخ')),
                ],
                rows: gasRecords.take(20).map((record) {
                  final isIncoming = record.type == 'وارد';
                  return DataRow(cells: [
                    DataCell(Text(record.station)),
                    DataCell(Text(record.farm)),
                    DataCell(Text(record.operator)),
                    DataCell(Text(formatter.format(record.quantity))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isIncoming ? sahara.chartGreen : sahara.chartRed)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                          isIncoming ? 'وارد' : 'صرف',
                          style: TextStyle(
                              color: isIncoming ? sahara.chartGreen : sahara.chartRed,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    )),
                    DataCell(Text(DateFormat('yyyy/MM/dd').format(record.date))),
                  ]);
                }).toList(),
              ),
            ),
        ]),
      ),
    );
  }

  // ==================== RECENT ACTIVITIES ====================
  Widget _buildRecentActivities(FuelProvider provider, ColorScheme colorScheme, SaharaColors sahara) {
    final recentRecords = provider.gasRecords.take(8).toList();

    return Card(
      color: sahara.sidebar,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('النشاط الأخير',
              style: GoogleFonts.cairo(
                  fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 16),
          if (recentRecords.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('لا يوجد نشاط حديث',
                    style: GoogleFonts.cairo(fontSize: 13, color: colorScheme.onSurfaceVariant)),
              ),
            )
          else
            ...recentRecords.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              final isIncoming = record.type == 'وارد';
              final activityColor = isIncoming ? sahara.chartGreen : sahara.chartRed;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: index.isEven ? sahara.tableRowEven : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: activityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(
                          isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                          color: activityColor,
                          size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(record.station,
                            style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('${record.farm} - ${record.operator}',
                            style: GoogleFonts.cairo(
                                fontSize: 10, color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${NumberFormat('#,###', 'ar').format(record.quantity)} لتر',
                          style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: activityColor)),
                      Text(DateFormat('MM/dd', 'ar').format(record.date),
                          style: GoogleFonts.cairo(
                              fontSize: 9, color: colorScheme.onSurfaceVariant)),
                    ]),
                  ]),
                ),
              );
            }),
        ]),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _legendDot(Color color, String label, ColorScheme colorScheme) {
    return Row(children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.cairo(fontSize: 11, color: colorScheme.onSurfaceVariant)),
    ]);
  }

  Widget _chartStat(
      IconData icon, String label, String value, Color color, ColorScheme colorScheme, SaharaColors sahara) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(height: 8),
      Text(value,
          style: GoogleFonts.cairo(
              fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
      Text(label, style: GoogleFonts.cairo(fontSize: 10, color: colorScheme.onSurfaceVariant)),
    ]);
  }

  Widget _trafficLegend(Color color, String label, String pct, ColorScheme colorScheme) {
    return Row(children: [
      Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Expanded(
        child: Text(label, style: GoogleFonts.cairo(fontSize: 12, color: colorScheme.onSurface)),
      ),
      Text(pct,
          style: GoogleFonts.cairo(
              fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
    ]);
  }
}

// ==================== DATA MODELS ====================

class _ColoredCardData {
  final String title;
  final String value;
  final String unit;
  final Color color1;
  final Color color2;
  final IconData icon;

  const _ColoredCardData(this.title, this.value, this.unit, this.color1, this.color2, this.icon);
}

// ==================== SPARKLINE PAINTER ====================

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final double maxVal;

  _SparklinePainter(this.data, this.maxVal);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxVal == 0) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.2), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    final step = size.width / (data.length - 1).clamp(1, double.infinity);

    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - (data[i] / maxVal * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo((data.length - 1) * step, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      data != oldDelegate.data || maxVal != oldDelegate.maxVal;
}

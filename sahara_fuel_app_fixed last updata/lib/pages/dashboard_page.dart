import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/color_schemes.dart';
import '../providers/fuel_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import 'dart:ui' as ui;

/// صفحة لوحة التحكم الرئيسية - النسخة المطورة
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = context.sahara;

    return Consumer2<FuelProvider, ThemeProvider>(
      builder: (context, provider, themeProvider, _) {
        final formatter = NumberFormat('#,###', 'ar');
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
                  // ===== الهيدر =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نظرة عامة',
                            style: GoogleFonts.cairo(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'مرحباً ${Provider.of<AuthService>(context).userName.isNotEmpty ? Provider.of<AuthService>(context).userName : "بك"} - ${DateFormat('EEEE d MMMM yyyy', 'ar').format(DateTime.now())}',
                            style: GoogleFonts.cairo(
                                fontSize: 14, color: sahara.subtleText),
                          ),
                        ],
                      ),
                      // مؤشر نسبة الامتلاء الإجمالية
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: sahara.sidebar,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: colorScheme.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: provider.overallFillPercentage / 100,
                                    strokeWidth: 4,
                                    backgroundColor: sahara.inputBg,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      provider.overallFillPercentage > 50
                                          ? colorScheme.primary
                                          : sahara.chartOrange,
                                    ),
                                  ),
                                  Text(
                                    '${provider.overallFillPercentage.toStringAsFixed(0)}%',
                                    style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('نسبة الامتلاء',
                                    style: GoogleFonts.cairo(
                                        fontSize: 11, color: sahara.subtleText)),
                                Text('الإجمالية',
                                    style: GoogleFonts.cairo(
                                        fontSize: 11, color: sahara.subtleText)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ===== البطاقات الإحصائية - الصف الأول (3 بطاقات رئيسية) =====
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'رصيد الصحاري الكلي',
                          value:
                              '${formatter.format(provider.saharaBalance)} لتر',
                          change:
                              '${provider.saharaChangePercent >= 0 ? "+" : ""}${provider.saharaChangePercent.toStringAsFixed(0)}%',
                          color: sahara.cardGreen,
                          icon: Icons.account_balance_wallet_rounded,
                          isPositive: provider.saharaChangePercent >= 0,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'رصيد الاتحاد',
                          value:
                              '${formatter.format(provider.unionBalance)} لتر',
                          change:
                              '${provider.unionChangePercent >= 0 ? "+" : ""}${provider.unionChangePercent.toStringAsFixed(0)}%',
                          color: sahara.cardOrange,
                          icon: Icons.swap_horiz_rounded,
                          isPositive: provider.unionChangePercent >= 0,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'رصيد المحطات',
                          value:
                              '${formatter.format(provider.stationsBalance)} لتر',
                          change:
                              '${provider.stationsChangePercent >= 0 ? "+" : ""}${provider.stationsChangePercent.toStringAsFixed(0)}%',
                          color: sahara.cardPurple,
                          icon: Icons.location_on_rounded,
                          isPositive: provider.stationsChangePercent >= 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ===== البطاقات الإحصائية - الصف الثاني (3 بطاقات إضافية) =====
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'الوارد اليوم',
                          value:
                              '${formatter.format(provider.todayIncoming)} لتر',
                          change: 'اليوم',
                          color: sahara.chartGreen,
                          icon: Icons.arrow_downward_rounded,
                          isPositive: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'الصادر اليوم',
                          value:
                              '${formatter.format(provider.todayOutgoing)} لتر',
                          change: 'اليوم',
                          color: sahara.chartRed,
                          icon: Icons.arrow_upward_rounded,
                          isPositive: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'المحطات النشطة',
                          value:
                              '${provider.activeStations} / ${provider.totalStations}',
                          change: 'محطة',
                          color: sahara.chartBlue,
                          icon: Icons.ev_station_rounded,
                          isPositive: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ===== القسم الأوسط: الرسم البياني + حالة الخزانات =====
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الرسم البياني
                      Expanded(
                        flex: 3,
                        child: _buildConsumptionChart(context, provider),
                      ),
                      const SizedBox(width: 20),
                      // حالة الخزانات
                      Expanded(
                        flex: 2,
                        child: _buildTankStatusSummary(context, provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ===== القسم السفلي: آخر العمليات + ملخص سريع =====
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // آخر العمليات
                      Expanded(
                        flex: 3,
                        child: _buildRecentActivities(context, provider),
                      ),
                      const SizedBox(width: 20),
                      // ملخص الإشعارات
                      Expanded(
                        flex: 2,
                        child: _buildQuickAlerts(context, provider),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== رسم بياني الاستهلاك =====
  Widget _buildConsumptionChart(BuildContext context, FuelProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = context.sahara;
    final data = provider.dailyConsumption;

    return Card(
      color: sahara.sidebar,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الاستهلاك اليومي - آخر 30 يوم',
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'متوسط: ${NumberFormat('#,###', 'ar').format(provider.averageDailyConsumption)} لتر/يوم',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: colorScheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // وسائل الإيضاح
            Row(
              children: [
                _legendItem(context, 'الاستهلاك', sahara.cardGreen),
                const SizedBox(width: 20),
                _legendItem(context, 'الوارد', sahara.cardOrange),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                          color: colorScheme.outlineVariant, strokeWidth: 0.5);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${data[value.toInt()].date.day}',
                                style: TextStyle(
                                    color: sahara.hintText, fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20000,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}K',
                            style: TextStyle(
                                color: sahara.hintText, fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // خط الاستهلاك
                    LineChartBarData(
                      spots: List.generate(
                        data.length,
                        (i) => FlSpot(i.toDouble(), data[i].consumed),
                      ),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [sahara.cardGreen, sahara.chartGreen],
                      ),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            sahara.cardGreen.withOpacity(0.3),
                            sahara.cardGreen.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // خط الوارد
                    LineChartBarData(
                      spots: List.generate(
                        data.length,
                        (i) => FlSpot(i.toDouble(), data[i].incoming),
                      ),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [sahara.cardOrange, sahara.chartOrange],
                      ),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      dashArray: [8, 4],
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final isConsumption = spot.barIndex == 0;
                          return LineTooltipItem(
                            '${isConsumption ? "استهلاك" : "وارد"}: ${NumberFormat('#,###', 'ar').format(spot.y)} لتر',
                            TextStyle(
                              color: isConsumption
                                  ? sahara.cardGreen
                                  : sahara.cardOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(BuildContext context, String label, Color color) {
    final sahara = context.sahara;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 3,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.cairo(fontSize: 11, color: sahara.subtleText)),
      ],
    );
  }

  // ===== ملخص حالة الخزانات =====
  Widget _buildTankStatusSummary(BuildContext context, FuelProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = context.sahara;

    return Card(
      color: sahara.sidebar,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('حالة الخزانات',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // رسم دائري
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 35,
                  sections: [
                    PieChartSectionData(
                      value: provider
                          .tanksWithStatus(TankStatus.excellent)
                          .toDouble(),
                      color: sahara.chartGreen,
                      title:
                          '${provider.tanksWithStatus(TankStatus.excellent)}',
                      titleStyle: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                      radius: 40,
                    ),
                    PieChartSectionData(
                      value:
                          provider.tanksWithStatus(TankStatus.good).toDouble(),
                      color: colorScheme.primary,
                      title: '${provider.tanksWithStatus(TankStatus.good)}',
                      titleStyle: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                      radius: 40,
                    ),
                    PieChartSectionData(
                      value: provider
                          .tanksWithStatus(TankStatus.medium)
                          .toDouble(),
                      color: sahara.cardOrange,
                      title: '${provider.tanksWithStatus(TankStatus.medium)}',
                      titleStyle: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                      radius: 40,
                    ),
                    PieChartSectionData(
                      value:
                          provider.tanksWithStatus(TankStatus.low).toDouble(),
                      color: colorScheme.error,
                      title: '${provider.tanksWithStatus(TankStatus.low)}',
                      titleStyle: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                      radius: 40,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // وسائل الإيضاح
            _statusLegend(context, 'ممتاز', sahara.chartGreen,
                provider.tanksWithStatus(TankStatus.excellent)),
            const SizedBox(height: 8),
            _statusLegend(context, 'جيد', colorScheme.primary,
                provider.tanksWithStatus(TankStatus.good)),
            const SizedBox(height: 8),
            _statusLegend(context, 'متوسط', sahara.cardOrange,
                provider.tanksWithStatus(TankStatus.medium)),
            const SizedBox(height: 8),
            _statusLegend(context, 'منخفض', colorScheme.error,
                provider.tanksWithStatus(TankStatus.low)),
            const SizedBox(height: 16),
            // شريط المخزون الإجمالي
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sahara.inputBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المخزون الإجمالي',
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: sahara.subtleText)),
                      Text(
                        '${NumberFormat('#,###', 'ar').format(provider.totalCurrentStock)} / ${NumberFormat('#,###', 'ar').format(provider.totalTankCapacity)}',
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: provider.overallFillPercentage / 100,
                      minHeight: 6,
                      backgroundColor: colorScheme.outlineVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        provider.overallFillPercentage > 60
                            ? colorScheme.primary
                            : provider.overallFillPercentage > 30
                                ? sahara.cardOrange
                                : colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusLegend(
      BuildContext context, String label, Color color, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = context.sahara;

    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.cairo(
                fontSize: 13, color: colorScheme.onSurfaceVariant)),
        const Spacer(),
        Text('$count خزان',
            style: GoogleFonts.cairo(
                fontSize: 13,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ===== آخر العمليات =====
  Widget _buildRecentActivities(BuildContext context, FuelProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = context.sahara;
    final activities = provider.recentActivities.take(6).toList();

    return Card(
      color: sahara.sidebar,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('آخر العمليات',
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold)),
                Text('اليوم',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: sahara.subtleText)),
              ],
            ),
            const SizedBox(height: 16),
            ...activities.map((activity) => _activityTile(context, activity)),
          ],
        ),
      ),
    );
  }

  Widget _activityTile(BuildContext context, RecentActivity activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = context.sahara;

    Color iconColor;
    IconData icon;
    switch (activity.type) {
      case ActivityType.incoming:
        iconColor = sahara.chartGreen;
        icon = Icons.arrow_downward_rounded;
        break;
      case ActivityType.outgoing:
        iconColor = sahara.chartRed;
        icon = Icons.arrow_upward_rounded;
        break;
      case ActivityType.transfer:
        iconColor = sahara.chartBlue;
        icon = Icons.swap_horiz_rounded;
        break;
    }

    final timeAgo = _getTimeAgo(activity.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sahara.inputBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600)),
                Text(activity.description,
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: sahara.subtleText)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${NumberFormat('#,###', 'ar').format(activity.amount)} لتر',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: activity.type == ActivityType.incoming
                      ? sahara.chartGreen
                      : activity.type == ActivityType.outgoing
                          ? sahara.chartRed
                          : sahara.chartBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(timeAgo,
                  style:
                      GoogleFonts.cairo(fontSize: 10, color: sahara.hintText)),
            ],
          ),
        ],
      ),
    );
  }

  // ===== التنبيهات السريعة =====
  Widget _buildQuickAlerts(BuildContext context, FuelProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = context.sahara;
    final alerts = provider.notifications.take(4).toList();

    return Card(
      color: sahara.sidebar,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('آخر التنبيهات',
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold)),
                if (provider.unreadNotifications > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: colorScheme.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('${provider.unreadNotifications} جديد',
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: colorScheme.error)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...alerts.map((alert) => _alertTile(context, alert)),
          ],
        ),
      ),
    );
  }

  Widget _alertTile(BuildContext context, AppNotification alert) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = context.sahara;

    Color color;
    IconData icon;
    switch (alert.type) {
      case NotificationType.success:
        color = sahara.chartGreen;
        icon = Icons.check_circle_outline;
        break;
      case NotificationType.warning:
        color = sahara.cardOrange;
        icon = Icons.warning_amber_rounded;
        break;
      case NotificationType.error:
        color = colorScheme.error;
        icon = Icons.error_outline;
        break;
      case NotificationType.info:
        color = sahara.chartBlue;
        icon = Icons.info_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.isRead
            ? sahara.inputBg.withOpacity(0.3)
            : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: alert.isRead ? null : Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(alert.title,
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: colorScheme.onSurface,
                              fontWeight: alert.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold)),
                    ),
                    if (!alert.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration:
                            BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                  ],
                ),
                Text(alert.message,
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: sahara.subtleText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}

// ===== Widget بطاقة الإحصائية المطورة =====
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final Color color;
  final IconData icon;
  final bool isPositive;

  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.color,
    required this.icon,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = context.sahara;

    final positiveColor = sahara.chartGreen;
    final negativeColor = sahara.chartRed;

    return Card(
      color: sahara.sidebar,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.03)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? positiveColor : negativeColor)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive ? positiveColor : negativeColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        change,
                        style: TextStyle(
                          color: isPositive ? positiveColor : negativeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(title,
                style:
                    GoogleFonts.cairo(fontSize: 13, color: sahara.subtleText)),
          ],
        ),
      ),
    );
  }
}

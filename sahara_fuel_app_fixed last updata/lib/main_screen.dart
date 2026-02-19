import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/core.dart';
import 'pages/sahara_balance_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/reports_page.dart';
import 'pages/tanks_page.dart';
import 'pages/notifications_page.dart';
import 'pages/audit_trail_page.dart';
import 'pages/settings_page.dart';
import 'pages/union_balance_page.dart';
import 'pages/incoming_report_page.dart';
import 'pages/advanced_reports_page.dart';
import 'pages/station_manager_page.dart';
import 'pages/data_management_page.dart';
import 'providers/fuel_provider.dart';
import 'services/auth_service.dart';
import 'services/license_service.dart';
import 'services/smart_alert_service.dart';
import 'widgets/responsive_layout.dart';
import 'main.dart';
import 'pages/gas_balance_page.dart';
import 'pages/vehicles_page.dart';
import 'widgets/theme_toggle_button.dart';
import 'pages/Deserty_eye.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  LicenseInfo? _license;
  bool _bannerDismissed = false;
  bool _showAlertPanel = false;

  @override
  void initState() {
    super.initState();
    _checkLicense();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final prov = Provider.of<FuelProvider>(context, listen: false);
        SmartAlertService().startMonitoring(prov);
      }
    });
  }

  Future<void> _checkLicense() async {
    final lic = await LicenseService.loadSavedLicense();
    if (mounted) setState(() => _license = lic);
  }

  static const Map<String, int> _pageKeyToIndex = {
    'dashboard': 0,
    'sahara_balance': 1,
    'reports': 2,
    'union_balance': 3,
    'tanks': 4,
    'incoming_report': 5,
    'advanced_reports': 6,
    'station_manager': 7,
    'data_management': 8,
    'notifications': 9,
    'audit_trail': 10,
    'settings': 11,
    'gas_balance': 12,
    'vehicles': 13,
    'deserty_eye': 14,
  };

  static const List<Widget> _allPages = [
    DashboardPage(),
    SaharaBalancePage(),
    ReportsPage(),
    UnionBalancePage(),
    TanksPage(),
    IncomingReportPage(),
    AdvancedReportsPage(),
    StationManagerPage(),
    DataManagementPage(),
    NotificationsPage(),
    AuditTrailPage(),
    SettingsPage(),
    GasBalancePage(),
    VehiclesPage(),
    DesertEyePage(),
  ];

  List<ErpMenuSection> _buildSidebarSections(
      Set<String> allowedKeys, int unreadNotifications) {
    return [
      ErpMenuSection('الصفحات الرئيسية', [
        ErpMenuItem(key: 'dashboard', label: 'الرئيسية', icon: Icons.dashboard_rounded),
        ErpMenuItem(key: 'sahara_balance', label: 'رصيد الصحاري', icon: Icons.account_balance_wallet_rounded, locked: !allowedKeys.contains('sahara_balance')),
        ErpMenuItem(key: 'gas_balance', label: 'رصيد الغاز', icon: Icons.local_fire_department_rounded, locked: !allowedKeys.contains('gas_balance')),
        ErpMenuItem(key: 'union_balance', label: 'رصيد الاتحاد', icon: Icons.swap_horiz_rounded, locked: !allowedKeys.contains('union_balance')),
        ErpMenuItem(key: 'vehicles', label: 'العربات', icon: Icons.directions_car_rounded, locked: !allowedKeys.contains('vehicles')),
        ErpMenuItem(key: 'deserty_eye', label: 'عين الصحراء', icon: Icons.map_rounded, locked: !allowedKeys.contains('deserty_eye')),
      ]),
      ErpMenuSection('التقارير والتحليلات', [
        ErpMenuItem(key: 'reports', label: 'التقارير', icon: Icons.analytics_rounded, locked: !allowedKeys.contains('reports')),
        ErpMenuItem(key: 'advanced_reports', label: 'تقارير متقدمة', icon: Icons.insights_rounded, locked: !allowedKeys.contains('advanced_reports')),
        ErpMenuItem(key: 'incoming_report', label: 'تقرير الوارد', icon: Icons.arrow_downward_rounded, locked: !allowedKeys.contains('incoming_report')),
        ErpMenuItem(key: 'tanks', label: 'خزانات الوقود', icon: Icons.propane_tank_rounded, locked: !allowedKeys.contains('tanks')),
      ]),
      ErpMenuSection('الإدارة', [
        ErpMenuItem(key: 'station_manager', label: 'إدارة المحطات', icon: Icons.store_rounded, locked: !allowedKeys.contains('station_manager')),
        ErpMenuItem(key: 'data_management', label: 'إدارة البيانات', icon: Icons.cloud_upload_rounded, locked: !allowedKeys.contains('data_management')),
      ]),
      ErpMenuSection('النظام', [
        ErpMenuItem(key: 'notifications', label: 'الإشعارات', icon: Icons.notifications_rounded, badge: allowedKeys.contains('notifications') ? unreadNotifications : 0, locked: !allowedKeys.contains('notifications')),
        ErpMenuItem(key: 'audit_trail', label: 'سجل العمليات', icon: Icons.history_rounded, locked: !allowedKeys.contains('audit_trail')),
        ErpMenuItem(key: 'settings', label: 'الإعدادات', icon: Icons.settings_rounded, locked: !allowedKeys.contains('settings')),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final fuel = Provider.of<FuelProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = context.sahara;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= AppDimensions.breakpointTablet;

    final allowed = auth.allowedPages;
    final allowedKeys = allowed.map((p) => p.key).toSet();

    if (_selectedIndex >= _allPages.length) _selectedIndex = 0;

    String currentPageKey = _pageKeyToIndex.entries
        .firstWhere((e) => e.value == _selectedIndex,
            orElse: () => const MapEntry('dashboard', 0))
        .key;

    final isCurrentAllowed = allowedKeys.contains(currentPageKey);

    final pageContent = Stack(
      children: [
        if (isCurrentAllowed)
          _allPages[_selectedIndex]
        else
          _accessDeniedPage(auth, colorScheme, sahara),

        // Top actions (mobile)
        if (!isDesktop)
          Positioned(
            top: 12,
            right: 12,
            child: _buildTopActions(auth, fuel, allowedKeys, colorScheme, sahara),
          ),

        // Top actions (desktop — compact)
        if (isDesktop)
          Positioned(
            top: 12,
            left: 12,
            child: _buildDesktopTopActions(fuel, allowedKeys, colorScheme, sahara),
          ),

        if (_showAlertPanel) const FloatingAlertsPanel(),

        if (_license != null &&
            !_bannerDismissed &&
            (_license!.type == LicenseType.trial || _license!.daysRemaining <= 30))
          Positioned(bottom: 0, left: 0, right: 0, child: _buildLicenseBanner()),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            ErpSidebar(
              sections: _buildSidebarSections(allowedKeys, fuel.unreadNotifications),
              selectedIndex: _selectedIndex,
              keyToIndex: _pageKeyToIndex,
              onItemSelected: (idx) {
                final key = _pageKeyToIndex.entries
                    .firstWhere((e) => e.value == idx, orElse: () => const MapEntry('dashboard', 0))
                    .key;
                if (allowedKeys.contains(key)) {
                  setState(() => _selectedIndex = idx);
                } else {
                  _showLockedSnackbar(context, key);
                }
              },
              onLogout: () => _confirmLogout(auth, colorScheme, sahara),
              userName: auth.isLoggedIn ? auth.userName : null,
              userRole: auth.isLoggedIn ? auth.userRole : null,
              roleColor: auth.isLoggedIn ? auth.role.color : null,
              roleIcon: auth.isLoggedIn ? auth.role.icon : null,
              licenseWidget: _license != null ? _buildLicenseBadge(colorScheme, sahara) : null,
            ),
            Expanded(child: pageContent),
          ],
        ),
      );
    }

    return Scaffold(
      body: pageContent,
      endDrawer: _buildDrawer(auth, fuel, allowedKeys, colorScheme, sahara),
    );
  }

  Widget _buildDesktopTopActions(FuelProvider fuel, Set<String> allowedKeys, ColorScheme cs, SaharaColors sahara) {
    return Row(
      children: [
        _actionChip(
          onTap: () => setState(() => _showAlertPanel = !_showAlertPanel),
          icon: Icons.notifications_active,
          iconColor: SmartAlertService().criticalCount > 0 ? cs.error : sahara.chartOrange,
          badge: SmartAlertService().activeCount,
          cs: cs, sahara: sahara,
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: sahara.sidebar.withOpacity(0.9),
            borderRadius: AppDimensions.borderRadiusMd,
            border: Border.all(color: sahara.sidebarBorder),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ThemeToggleButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildTopActions(AuthService auth, FuelProvider fuel, Set<String> allowedKeys, ColorScheme cs, SaharaColors sahara) {
    return Row(
      children: [
        if (auth.isLoggedIn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: sahara.sidebar.withOpacity(0.9),
              borderRadius: AppDimensions.borderRadiusMd,
              border: Border.all(color: sahara.sidebarBorder),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(radius: 14, backgroundColor: auth.role.color.withOpacity(0.2), child: Icon(auth.role.icon, color: auth.role.color, size: 16)),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(auth.userName, style: GoogleFonts.cairo(fontSize: 12, color: cs.onSurface, fontWeight: FontWeight.bold)),
                Row(children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: auth.role.color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(auth.userRole, style: GoogleFonts.cairo(fontSize: 10, color: auth.role.color)),
                ]),
              ]),
            ]),
          ),
        if (fuel.unreadNotifications > 0 && allowedKeys.contains('notifications'))
          _actionChip(
            onTap: () => setState(() => _selectedIndex = _pageKeyToIndex['notifications']!),
            icon: Icons.notifications_outlined,
            badge: fuel.unreadNotifications,
            cs: cs, sahara: sahara,
          ),
        _actionChip(
          onTap: () => setState(() => _showAlertPanel = !_showAlertPanel),
          icon: Icons.notifications_active,
          iconColor: SmartAlertService().criticalCount > 0 ? cs.error : sahara.chartOrange,
          badge: SmartAlertService().activeCount,
          cs: cs, sahara: sahara,
        ),
        Container(
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: sahara.sidebar.withOpacity(0.9),
            borderRadius: AppDimensions.borderRadiusMd,
            border: Border.all(color: sahara.sidebarBorder),
          ),
          child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: ThemeToggleButton()),
        ),
        Builder(
          builder: (ctx) => Container(
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.8)]),
              borderRadius: AppDimensions.borderRadiusMd,
            ),
            child: IconButton(
              icon: Icon(Icons.menu, color: cs.onPrimary, size: 22),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionChip({required VoidCallback onTap, required IconData icon, Color? iconColor, int badge = 0, required ColorScheme cs, required SaharaColors sahara}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: sahara.sidebar.withOpacity(0.9),
          borderRadius: AppDimensions.borderRadiusMd,
          border: Border.all(color: sahara.sidebarBorder),
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          Icon(icon, color: iconColor ?? cs.onSurface, size: 20),
          if (badge > 0)
            Positioned(
              top: -6, right: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle),
                child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
        ]),
      ),
    );
  }

  void _showLockedSnackbar(BuildContext context, String key) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.lock, color: Colors.white, size: 16),
        const SizedBox(width: 10),
        Text('ليس لديك صلاحية للوصول إلى هذه الصفحة', style: GoogleFonts.cairo(fontSize: 12)),
      ]),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _accessDeniedPage(AuthService auth, ColorScheme cs, SaharaColors sahara) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: sahara.pageGradient),
      ),
      child: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: sahara.sidebar,
            borderRadius: AppDimensions.borderRadiusLg,
            border: Border.all(color: cs.error.withOpacity(0.2)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: cs.error.withOpacity(0.1), borderRadius: AppDimensions.borderRadiusXl),
              child: Icon(Icons.lock, color: cs.error, size: 40),
            ),
            const SizedBox(height: 24),
            Text('الوصول مرفوض', style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: cs.error)),
            const SizedBox(height: 8),
            Text('ليس لديك صلاحية للوصول إلى هذه الصفحة', style: GoogleFonts.cairo(fontSize: 14, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text('تواصل مع مدير النظام لتعديل صلاحياتك', style: GoogleFonts.cairo(fontSize: 12, color: sahara.subtleText)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: sahara.inputBg, borderRadius: AppDimensions.borderRadiusMd),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(auth.role.icon, color: auth.role.color, size: 16),
                const SizedBox(width: 8),
                Text('${auth.userName} (${auth.userRole})', style: GoogleFonts.cairo(color: cs.onSurfaceVariant, fontSize: 12)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: sahara.accent.withOpacity(0.1), borderRadius: AppDimensions.borderRadiusSm),
                  child: Text('${auth.allowedPages.length} صفحة متاحة', style: GoogleFonts.cairo(color: sahara.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'العودة للصفحة الرئيسية',
              icon: Icons.arrow_back,
              expand: true,
              onPressed: () {
                final firstAllowed = auth.allowedPages.isNotEmpty ? _pageKeyToIndex[auth.allowedPages.first.key] ?? 0 : 0;
                setState(() => _selectedIndex = firstAllowed);
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLicenseBadge(ColorScheme cs, SaharaColors sahara) {
    if (_license == null) return const SizedBox.shrink();
    final lic = _license!;
    final color = lic.type == LicenseType.trial ? sahara.chartOrange : lic.type == LicenseType.permanent ? sahara.accent : sahara.chartBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppDimensions.borderRadiusMd,
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.vpn_key, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          '${lic.typeArabic} ${lic.isExpired ? "(منتهي)" : "• ${lic.daysRemaining} يوم"}',
          style: GoogleFonts.cairo(fontSize: 9, color: color, fontWeight: FontWeight.bold),
        ),
      ]),
    );
  }

  Widget _buildLicenseBanner() {
    final lic = _license!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          lic.isExpired ? const Color(0xFFEF5350) : lic.daysRemaining <= 7 ? const Color(0xFFFF7043) : const Color(0xFFFFA726),
          lic.isExpired ? const Color(0xFFD32F2F) : lic.daysRemaining <= 7 ? const Color(0xFFE64A19) : const Color(0xFFFF8F00),
        ]),
      ),
      child: Row(children: [
        Icon(lic.isExpired ? Icons.error : Icons.warning_amber, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            lic.isExpired
                ? 'انتهت صلاحية الترخيص! يرجى التجديد للاستمرار.'
                : lic.type == LicenseType.trial
                    ? 'وضع تجريبي - متبقي ${lic.daysRemaining} يوم (${lic.maxStations} محطات، ${lic.maxUsers} مستخدمين)'
                    : 'ينتهي الترخيص خلال ${lic.daysRemaining} يوم - تواصل مع الدعم للتجديد',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _bannerDismissed = true),
          child: const Icon(Icons.close, color: Colors.white70, size: 18),
        ),
      ]),
    );
  }

  Widget _buildDrawer(AuthService auth, FuelProvider fuel, Set<String> allowedKeys, ColorScheme cs, SaharaColors sahara) {
    return Drawer(
      backgroundColor: sahara.sidebar,
      width: 280,
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [sahara.accent.withOpacity(0.3), sahara.sidebar], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: Column(children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.7)]),
                borderRadius: AppDimensions.borderRadiusXl,
              ),
              child: Icon(Icons.local_gas_station, color: cs.onPrimary, size: 38),
            ),
            const SizedBox(height: 16),
            Text('صحاري كربلاء', style: GoogleFonts.cairo(fontSize: 22, color: cs.onSurface, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('نظام إدارة الوقود', style: GoogleFonts.cairo(fontSize: 12, color: sahara.subtleText)),
            if (auth.isLoggedIn) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: auth.role.color.withOpacity(0.15),
                  borderRadius: AppDimensions.borderRadiusRound,
                  border: Border.all(color: auth.role.color.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(auth.role.icon, color: auth.role.color, size: 14),
                  const SizedBox(width: 6),
                  Text('${auth.userName} - ${auth.userRole}', style: GoogleFonts.cairo(fontSize: 11, color: auth.role.color, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
            if (_license != null) ...[const SizedBox(height: 8), _buildLicenseBadge(cs, sahara)],
          ]),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingSm),
            children: [
              for (final section in _buildSidebarSections(allowedKeys, fuel.unreadNotifications)) ...[
                _menuSectionHeader(section.title, sahara),
                for (final item in section.items) _drawerItem(item, cs, sahara),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.lock_open, color: sahara.accent.withOpacity(0.5), size: 14),
            const SizedBox(width: 6),
            Text('${allowedKeys.length} صفحة متاحة من ${_pageKeyToIndex.length}', style: GoogleFonts.cairo(fontSize: 10, color: sahara.subtleText)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: cs.error.withOpacity(0.15), borderRadius: AppDimensions.borderRadiusSm),
              child: Icon(Icons.logout_rounded, color: cs.error, size: 20),
            ),
            title: Text('تسجيل الخروج', style: GoogleFonts.cairo(fontSize: 14, color: cs.error, fontWeight: FontWeight.w500)),
            onTap: () => _confirmLogout(auth, cs, sahara),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.circle, color: sahara.accent, size: 8),
            const SizedBox(width: 8),
            Text('الإصدار 2.0.0', style: GoogleFonts.cairo(fontSize: 11, color: sahara.subtleText)),
          ]),
        ),
      ]),
    );
  }

  Widget _menuSectionHeader(String title, SaharaColors sahara) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: Text(title, style: GoogleFonts.cairo(fontSize: 11, color: sahara.subtleText, fontWeight: FontWeight.w600)),
    );
  }

  Widget _drawerItem(ErpMenuItem item, ColorScheme cs, SaharaColors sahara) {
    final idx = _pageKeyToIndex[item.key];
    if (idx == null) return const SizedBox.shrink();
    final isSelected = _selectedIndex == idx;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? sahara.accent.withOpacity(0.15) : Colors.transparent,
        borderRadius: AppDimensions.borderRadiusMd,
        border: isSelected ? Border.all(color: sahara.accent.withOpacity(0.3)) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: isSelected ? sahara.accent.withOpacity(0.2) : sahara.inputBg,
            borderRadius: AppDimensions.borderRadiusSm,
          ),
          child: Stack(clipBehavior: Clip.none, children: [
            Center(child: Icon(item.icon, color: item.locked ? sahara.hintText : isSelected ? sahara.accent : sahara.subtleText, size: 20)),
            if (item.badge > 0)
              Positioned(top: -4, right: -4, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle), child: Text('${item.badge}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
            if (item.locked)
              Positioned(bottom: -2, left: -2, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: sahara.sidebar, shape: BoxShape.circle, border: Border.all(color: sahara.sidebarBorder, width: 1)), child: Icon(Icons.lock, color: sahara.hintText, size: 10))),
          ]),
        ),
        title: Text(item.label, style: GoogleFonts.cairo(fontSize: 14, color: item.locked ? sahara.hintText : isSelected ? sahara.accent : cs.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
        trailing: isSelected
            ? Container(width: 4, height: 24, decoration: BoxDecoration(color: sahara.accent, borderRadius: BorderRadius.circular(2)))
            : item.locked ? Icon(Icons.block, color: sahara.hintText, size: 14) : null,
        onTap: item.locked
            ? () { Navigator.pop(context); _showLockedSnackbar(context, item.key); }
            : () { setState(() => _selectedIndex = idx); Navigator.pop(context); },
      ),
    );
  }

  void _confirmLogout(AuthService auth, ColorScheme cs, SaharaColors sahara) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sahara.sidebar,
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLg),
        title: Text('تسجيل الخروج', style: GoogleFonts.cairo(color: cs.onSurface, fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من تسجيل الخروج؟', style: GoogleFonts.cairo(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo(color: sahara.subtleText))),
          ElevatedButton(
            onPressed: () { auth.logout(); Navigator.pop(ctx); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())); },
            style: ElevatedButton.styleFrom(backgroundColor: cs.error, shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusSm)),
            child: Text('خروج', style: GoogleFonts.cairo(color: cs.onError)),
          ),
        ],
      ),
    );
  }
}

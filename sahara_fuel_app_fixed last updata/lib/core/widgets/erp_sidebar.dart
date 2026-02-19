import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_dimensions.dart';
import '../theme/color_schemes.dart';

/// Menu item model for the sidebar.
class ErpMenuItem {
  final String key;
  final String label;
  final IconData icon;
  final int badge;
  final bool locked;

  const ErpMenuItem({
    required this.key,
    required this.label,
    required this.icon,
    this.badge = 0,
    this.locked = false,
  });
}

/// Menu section groups items under a heading.
class ErpMenuSection {
  final String title;
  final List<ErpMenuItem> items;
  const ErpMenuSection(this.title, this.items);
}

/// Professional ERP sidebar with collapse/expand, hover, animation, and keyboard nav.
class ErpSidebar extends StatefulWidget {
  final List<ErpMenuSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onLogout;
  final String appTitle;
  final String? userName;
  final String? userRole;
  final Color? roleColor;
  final IconData? roleIcon;
  final Widget? licenseWidget;
  final Map<String, int> keyToIndex;

  const ErpSidebar({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.keyToIndex,
    this.onLogout,
    this.appTitle = 'صحاري كربلاء',
    this.userName,
    this.userRole,
    this.roleColor,
    this.roleIcon,
    this.licenseWidget,
  });

  @override
  State<ErpSidebar> createState() => _ErpSidebarState();
}

class _ErpSidebarState extends State<ErpSidebar>
    with SingleTickerProviderStateMixin {
  bool _collapsed = false;
  late AnimationController _animController;
  late Animation<double> _widthAnim;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: AppDimensions.sidebarAnimationDuration,
      vsync: this,
    );
    _widthAnim = Tween<double>(
      begin: AppDimensions.sidebarExpandedWidth,
      end: AppDimensions.sidebarCollapsedWidth,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    setState(() {
      _collapsed = !_collapsed;
      if (_collapsed) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = context.sahara;

    return AnimatedBuilder(
      animation: _widthAnim,
      builder: (context, _) {
        final isExpanded = _widthAnim.value > AppDimensions.sidebarCollapsedWidth + 10;
        return Container(
          width: _widthAnim.value,
          decoration: BoxDecoration(
            color: sahara.sidebar,
            border: Border(
              left: BorderSide(
                color: sahara.sidebarBorder,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // ── Header ──
              _buildHeader(colorScheme, sahara, isExpanded),

              // ── User info ──
              if (widget.userName != null && isExpanded)
                _buildUserInfo(colorScheme, sahara),

              const SizedBox(height: AppDimensions.spacingSm),

              // ── Menu items ──
              Expanded(
                child: _buildMenuList(colorScheme, sahara, isExpanded),
              ),

              // ── Footer ──
              _buildFooter(colorScheme, sahara, isExpanded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ColorScheme cs, SaharaColors sahara, bool isExpanded) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? AppDimensions.spacingMd : AppDimensions.spacingSm,
        vertical: AppDimensions.spacingMd,
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withOpacity(0.7)],
              ),
              borderRadius: AppDimensions.borderRadiusMd,
            ),
            child: Icon(
              Icons.local_gas_station,
              color: cs.onPrimary,
              size: 22,
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.appTitle,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'نظام إدارة الوقود',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: sahara.subtleText,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          // Collapse toggle
          InkWell(
            onTap: _toggleCollapse,
            borderRadius: AppDimensions.borderRadiusSm,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: sahara.inputBg,
                borderRadius: AppDimensions.borderRadiusSm,
              ),
              child: AnimatedRotation(
                turns: _collapsed ? 0.5 : 0,
                duration: AppDimensions.sidebarAnimationDuration,
                child: Icon(
                  Icons.chevron_right,
                  color: sahara.hintText,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(ColorScheme cs, SaharaColors sahara) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingSm + 2),
        decoration: BoxDecoration(
          color: sahara.inputBg,
          borderRadius: AppDimensions.borderRadiusMd,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: (widget.roleColor ?? cs.primary).withOpacity(0.2),
              child: Icon(
                widget.roleIcon ?? Icons.person,
                color: widget.roleColor ?? cs.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.roleColor ?? cs.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.userRole ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: widget.roleColor ?? cs.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuList(ColorScheme cs, SaharaColors sahara, bool isExpanded) {
    // Flatten sections into a sequential list with section headers
    final List<Widget> children = [];
    int flatIndex = 0;

    for (final section in widget.sections) {
      // Section header
      if (isExpanded) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(
              right: AppDimensions.spacingMd,
              left: AppDimensions.spacingMd,
              top: AppDimensions.spacingSm + 4,
              bottom: AppDimensions.spacingXs,
            ),
            child: Text(
              section.title,
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: sahara.subtleText,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      } else {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingSm,
            vertical: AppDimensions.spacingXs,
          ),
          child: Divider(color: sahara.sidebarBorder, height: 1),
        ));
      }

      // Items
      for (final item in section.items) {
        final idx = widget.keyToIndex[item.key];
        if (idx == null) continue;

        final isSelected = idx == widget.selectedIndex;
        final isHovered = idx == _hoveredIndex;

        children.add(
          _buildMenuItem(
            item: item,
            index: idx,
            isSelected: isSelected,
            isHovered: isHovered,
            isExpanded: isExpanded,
            cs: cs,
            sahara: sahara,
          ),
        );
        flatIndex++;
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingSm),
      children: children,
    );
  }

  Widget _buildMenuItem({
    required ErpMenuItem item,
    required int index,
    required bool isSelected,
    required bool isHovered,
    required bool isExpanded,
    required ColorScheme cs,
    required SaharaColors sahara,
  }) {
    final activeColor = sahara.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withOpacity(0.12)
                : isHovered
                    ? cs.onSurface.withOpacity(0.04)
                    : Colors.transparent,
            borderRadius: AppDimensions.borderRadiusSm,
            border: isSelected
                ? Border.all(color: activeColor.withOpacity(0.25))
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppDimensions.borderRadiusSm,
              onTap: item.locked ? null : () => widget.onItemSelected(index),
              child: isExpanded
                  ? _expandedItem(item, isSelected, cs, sahara, activeColor)
                  : _collapsedItem(item, isSelected, cs, sahara, activeColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _expandedItem(
    ErpMenuItem item,
    bool isSelected,
    ColorScheme cs,
    SaharaColors sahara,
    Color activeColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingSm + 4,
        vertical: AppDimensions.spacingSm,
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withOpacity(0.2)
                  : sahara.inputBg,
              borderRadius: AppDimensions.borderRadiusSm,
            ),
            child: Center(
              child: Icon(
                item.icon,
                color: item.locked
                    ? sahara.hintText
                    : isSelected
                        ? activeColor
                        : sahara.subtleText,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          // Label
          Expanded(
            child: Text(
              item.label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: item.locked
                    ? sahara.hintText
                    : isSelected
                        ? activeColor
                        : cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Badge
          if (item.badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.error,
                borderRadius: AppDimensions.borderRadiusRound,
              ),
              child: Text(
                '${item.badge}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          // Lock icon
          if (item.locked)
            Icon(Icons.lock, size: 14, color: sahara.hintText),
          // Active indicator
          if (isSelected)
            Container(
              width: 3,
              height: 20,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _collapsedItem(
    ErpMenuItem item,
    bool isSelected,
    ColorScheme cs,
    SaharaColors sahara,
    Color activeColor,
  ) {
    return Tooltip(
      message: item.label,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 300),
      child: SizedBox(
        height: 44,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                item.icon,
                color: item.locked
                    ? sahara.hintText
                    : isSelected
                        ? activeColor
                        : sahara.subtleText,
                size: 20,
              ),
              if (item.badge > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${item.badge}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              if (item.locked)
                Positioned(
                  bottom: -2,
                  left: -2,
                  child: Icon(Icons.lock, size: 8, color: sahara.hintText),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs, SaharaColors sahara, bool isExpanded) {
    return Column(
      children: [
        // License widget
        if (widget.licenseWidget != null && isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
            child: widget.licenseWidget!,
          ),

        Divider(color: sahara.sidebarBorder, height: 1),

        // Logout
        if (widget.onLogout != null)
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingSm),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: AppDimensions.borderRadiusSm,
                onTap: widget.onLogout,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isExpanded ? AppDimensions.spacingSm + 4 : 0,
                    vertical: AppDimensions.spacingSm,
                  ),
                  child: isExpanded
                      ? Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: cs.error.withOpacity(0.1),
                                borderRadius: AppDimensions.borderRadiusSm,
                              ),
                              child: Icon(Icons.logout_rounded,
                                  color: cs.error, size: 18),
                            ),
                            const SizedBox(width: AppDimensions.spacingSm),
                            Text(
                              'تسجيل الخروج',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: cs.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Tooltip(
                            message: 'تسجيل الخروج',
                            child: Icon(Icons.logout_rounded,
                                color: cs.error, size: 20),
                          ),
                        ),
                ),
              ),
            ),
          ),

        // Version
        Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
          child: isExpanded
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, color: sahara.accent, size: 6),
                    const SizedBox(width: 6),
                    Text(
                      'الإصدار 2.0.0',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: sahara.subtleText,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

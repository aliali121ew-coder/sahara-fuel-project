import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/color_schemes.dart';

/// قائمة مع ترقيم صفحات احترافي
class PaginatedList<T> extends StatelessWidget {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final Widget Function(T item, int index) itemBuilder;
  final ValueChanged<int> onPageChanged;
  final Widget? emptyState;
  final bool isLoading;

  const PaginatedList({
    super.key,
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.itemBuilder,
    required this.onPageChanged,
    this.emptyState,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (items.isEmpty) {
      return emptyState ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inbox_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
                const SizedBox(height: 12),
                Text('لا توجد بيانات',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ),
          );
    }

    return Column(
      children: [
        // Items
        ...items.asMap().entries.map((e) => itemBuilder(e.value, e.key)),

        // Pagination controls
        if (totalPages > 1) ...[
          const SizedBox(height: 16),
          _PaginationControls(
            currentPage: currentPage,
            totalPages: totalPages,
            onPageChanged: onPageChanged,
          ),
        ],
      ],
    );
  }
}

class _PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = Theme.of(context).extension<SaharaColors>()!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous
          _navBtn(Icons.chevron_right_rounded, currentPage > 1,
              () => onPageChanged(currentPage - 1), colorScheme, sahara),
          const SizedBox(width: 8),

          // Page numbers
          ...List.generate(_visiblePages.length, (i) {
            final page = _visiblePages[i];
            if (page == -1) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('...', style: GoogleFonts.cairo(color: colorScheme.onSurfaceVariant)),
              );
            }
            final isActive = page == currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: isActive ? null : () => onPageChanged(page),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive ? colorScheme.primary : sahara.inputBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('$page',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant)),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(width: 8),
          // Next
          _navBtn(Icons.chevron_left_rounded, currentPage < totalPages,
              () => onPageChanged(currentPage + 1), colorScheme, sahara),
        ],
      ),
    );
  }

  List<int> get _visiblePages {
    if (totalPages <= 7) return List.generate(totalPages, (i) => i + 1);
    final pages = <int>[];
    pages.add(1);
    if (currentPage > 3) pages.add(-1); // ellipsis
    for (int i = currentPage - 1; i <= currentPage + 1; i++) {
      if (i > 1 && i < totalPages) pages.add(i);
    }
    if (currentPage < totalPages - 2) pages.add(-1); // ellipsis
    pages.add(totalPages);
    return pages;
  }

  Widget _navBtn(IconData icon, bool enabled, VoidCallback onTap,
      ColorScheme colorScheme, SaharaColors sahara) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: sahara.inputBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 20,
            color: enabled
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withOpacity(0.3)),
      ),
    );
  }
}

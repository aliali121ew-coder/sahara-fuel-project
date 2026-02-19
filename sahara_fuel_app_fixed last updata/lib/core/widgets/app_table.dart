import 'package:flutter/material.dart';
import '../theme/app_dimensions.dart';
import '../theme/color_schemes.dart';

/// Column definition for [AppTable].
class AppTableColumn<T> {
  final String label;
  final Widget Function(T item, int index) cellBuilder;
  final double? flex;
  final TextAlign? align;

  const AppTableColumn({
    required this.label,
    required this.cellBuilder,
    this.flex,
    this.align,
  });
}

/// Unified ERP-style data table with header, alternating rows, and empty state.
class AppTable<T> extends StatelessWidget {
  final List<AppTableColumn<T>> columns;
  final List<T> data;
  final String? emptyMessage;
  final ScrollController? scrollController;
  final void Function(T item)? onRowTap;

  const AppTable({
    super.key,
    required this.columns,
    required this.data,
    this.emptyMessage,
    this.scrollController,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = context.sahara;

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined,
                  size: 48, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: AppDimensions.spacingSm),
              Text(
                emptyMessage ?? 'لا توجد بيانات',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            color: sahara.tableHeader,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusMd),
              topRight: Radius.circular(AppDimensions.radiusMd),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingSm + 4,
          ),
          child: Row(
            children: columns.map((col) {
              return Expanded(
                flex: col.flex?.toInt() ?? 1,
                child: Text(
                  col.label,
                  textAlign: col.align,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Rows
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final isEven = index.isEven;
              return InkWell(
                onTap: onRowTap != null ? () => onRowTap!(item) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isEven ? sahara.tableRowEven : sahara.tableRowOdd,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingMd,
                    vertical: AppDimensions.spacingSm + 2,
                  ),
                  child: Row(
                    children: columns.map((col) {
                      return Expanded(
                        flex: col.flex?.toInt() ?? 1,
                        child: col.cellBuilder(item, index),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/color_schemes.dart';

/// بطاقة KPI احترافية مع مؤشر تقدم دائري
class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double? progress; // 0.0 - 1.0
  final double? change; // النسبة المئوية للتغيير
  final bool isPositiveGood; // هل الزيادة جيدة أم لا

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    this.subtitle,
    required this.icon,
    required this.color,
    this.progress,
    this.change,
    this.isPositiveGood = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = Theme.of(context).extension<SaharaColors>()!;
    final isChangePositive = (change ?? 0) >= 0;
    final isChangeGood = isPositiveGood ? isChangePositive : !isChangePositive;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sahara.sidebar,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: sahara.statBorder),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),

              // Change badge
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isChangeGood
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      isChangePositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: isChangeGood
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${isChangePositive ? "+" : ""}${change!.toStringAsFixed(1)}%',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isChangeGood
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ]),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Title
          Text(title,
              style: GoogleFonts.cairo(
                  fontSize: 12, color: colorScheme.onSurfaceVariant)),

          const SizedBox(height: 4),

          // Value
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value,
                style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface)),
            if (unit != null) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit!,
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: colorScheme.onSurfaceVariant)),
              ),
            ],
          ]),

          // Progress bar
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  style: GoogleFonts.cairo(
                      fontSize: 10, color: colorScheme.onSurfaceVariant)),
            ],
          ] else if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                style: GoogleFonts.cairo(
                    fontSize: 10, color: colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// شبكة KPI جاهزة
class KpiGrid extends StatelessWidget {
  final List<KpiCard> cards;
  final int crossAxisCount;
  final double spacing;

  const KpiGrid({
    super.key,
    required this.cards,
    this.crossAxisCount = 4,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveCols = constraints.maxWidth > 1000
            ? crossAxisCount
            : constraints.maxWidth > 600
                ? (crossAxisCount / 2).ceil()
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: effectiveCols,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: 180,
          ),
          itemCount: cards.length,
          itemBuilder: (context, i) => cards[i],
        );
      },
    );
  }
}

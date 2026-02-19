import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/color_schemes.dart';

/// صفحة 403 - الوصول ممنوع
class ForbiddenPage extends StatelessWidget {
  final String? pageName;
  final VoidCallback? onGoBack;

  const ForbiddenPage({super.key, this.pageName, this.onGoBack});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = Theme.of(context).extension<SaharaColors>()!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: sahara.pageGradient,
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: sahara.sidebar,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: sahara.statBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.lock_outline_rounded,
                      color: colorScheme.error, size: 40),
                ),
                const SizedBox(height: 24),

                // Title
                Text('الوصول ممنوع',
                    style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error)),
                const SizedBox(height: 8),

                // Code
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('403',
                      style: GoogleFonts.sourceCodePro(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.error)),
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  pageName != null
                      ? 'ليس لديك صلاحية الوصول إلى "$pageName"'
                      : 'ليس لديك صلاحية الوصول إلى هذه الصفحة',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontSize: 14, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى التواصل مع مدير النظام لمنحك الصلاحيات المطلوبة',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 12, color: sahara.hintText),
                ),
                const SizedBox(height: 32),

                // Back button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onGoBack ?? () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text('العودة للصفحة الرئيسية',
                        style: GoogleFonts.cairo(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

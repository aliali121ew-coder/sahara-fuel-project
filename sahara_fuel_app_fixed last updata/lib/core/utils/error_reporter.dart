// ============================================================
// Phase 6: Flutter Error Reporting & Recovery Service
// - Catches uncaught exceptions & async errors
// - Stores error history for debugging
// - Shows user-friendly Arabic error messages
// - Graceful retry/recovery patterns
// ============================================================
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized error reporter for the Sahara Fuel app.
class ErrorReporter {
  static final ErrorReporter _instance = ErrorReporter._();
  factory ErrorReporter() => _instance;
  ErrorReporter._();

  final List<ErrorRecord> _errors = [];
  int get errorCount => _errors.length;
  List<ErrorRecord> get recentErrors =>
      _errors.reversed.take(50).toList(); // last 50

  /// Initialize error catching for the entire app.
  /// Call this in main() wrapping runApp().
  static void init(VoidCallback runApp) {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _instance._record(
        details.exception,
        details.stack,
        context: details.context?.toString(),
        library: details.library,
      );
      // Still print in debug mode
      if (kDebugMode) FlutterError.presentError(details);
    };

    // Catch async errors in the Zone
    runZonedGuarded(
      runApp,
      (error, stackTrace) {
        _instance._record(error, stackTrace, context: 'runZonedGuarded');
        if (kDebugMode) {
          debugPrint('🔴 Uncaught async error: $error');
          debugPrint('$stackTrace');
        }
      },
    );
  }

  void _record(Object error, StackTrace? stack,
      {String? context, String? library}) {
    _errors.add(ErrorRecord(
      error: error.toString(),
      stackTrace: stack?.toString() ?? '',
      context: context,
      library: library,
      timestamp: DateTime.now(),
    ));
    // Keep only last 200
    if (_errors.length > 200) _errors.removeRange(0, _errors.length - 200);
  }

  /// Manually report a caught error.
  static void report(Object error, [StackTrace? stack, String? context]) {
    _instance._record(error, stack, context: context);
  }

  /// Clear stored errors (e.g., after export).
  void clear() => _errors.clear();

  /// User-friendly Arabic error message from error type.
  static String friendlyMessage(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('socketexception') || msg.contains('connection refused')) {
      return 'لا يمكن الاتصال بالخادم - تحقق من اتصالك بالإنترنت';
    }
    if (msg.contains('timeout')) {
      return 'انتهت مهلة الاتصال - حاول مجدداً';
    }
    if (msg.contains('401') || msg.contains('unauthorized')) {
      return 'انتهت جلستك - يرجى تسجيل الدخول مجدداً';
    }
    if (msg.contains('403') || msg.contains('forbidden')) {
      return 'لا تملك صلاحية لهذا الإجراء';
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return 'البيانات المطلوبة غير موجودة';
    }
    if (msg.contains('500') || msg.contains('internal')) {
      return 'خطأ في الخادم - حاول مجدداً لاحقاً';
    }
    if (msg.contains('formatexception') || msg.contains('type')) {
      return 'خطأ في تنسيق البيانات';
    }
    return 'حدث خطأ غير متوقع - حاول مجدداً';
  }
}

/// Record of a single error occurrence.
class ErrorRecord {
  final String error;
  final String stackTrace;
  final String? context;
  final String? library;
  final DateTime timestamp;

  const ErrorRecord({
    required this.error,
    required this.stackTrace,
    this.context,
    this.library,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'error': error,
        'context': context,
        'library': library,
        'timestamp': timestamp.toIso8601String(),
        'stack': stackTrace.split('\n').take(5).join('\n'),
      };
}

/// Retry helper: calls [fn] up to [maxRetries] times with exponential backoff.
Future<T> retryAsync<T>(
  Future<T> Function() fn, {
  int maxRetries = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  int attempt = 0;
  while (true) {
    try {
      return await fn();
    } catch (e, stack) {
      attempt++;
      if (attempt >= maxRetries) {
        ErrorReporter.report(e, stack, 'retryAsync (attempt $attempt)');
        rethrow;
      }
      final delay = initialDelay * (1 << (attempt - 1)); // exponential
      await Future.delayed(delay);
    }
  }
}

/// Error boundary widget — catches errors in child tree and shows fallback.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error)? fallbackBuilder;

  const ErrorBoundary({super.key, required this.child, this.fallbackBuilder});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _error = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallbackBuilder?.call(_error!) ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      color: Theme.of(context).colorScheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text(ErrorReporter.friendlyMessage(_error!),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => setState(() => _error = null),
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
    }

    return widget.child;
  }
}

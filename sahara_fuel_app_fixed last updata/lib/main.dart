import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'constants/app_colors.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/color_schemes.dart';
import 'main_screen.dart';
import 'providers/fuel_provider.dart';
import 'providers/theme_provider.dart';
import 'services/license_service.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/api_service.dart';
import 'pages/activation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة قاعدة البيانات المحلية
  await DatabaseService().init();

  // إعداد API Service من الإعدادات البيئية
  ApiService().setBaseUrl(EnvConfig.apiBaseUrl);

  // إنشاء الخدمات مع تحميل البيانات
  final fuelProvider = FuelProvider();
  final authService = AuthService();
  await fuelProvider.loadFromDatabase();
  await authService.loadFromDatabase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: fuelProvider),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'وقود صحاري كربلاء',
          locale: const Locale('ar'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeProvider.themeMode,
          home: const LicenseCheckWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class LicenseCheckWrapper extends StatefulWidget {
  const LicenseCheckWrapper({super.key});

  @override
  State<LicenseCheckWrapper> createState() => _LicenseCheckWrapperState();
}

class _LicenseCheckWrapperState extends State<LicenseCheckWrapper> {
  @override
  void initState() {
    super.initState();
    _checkLicense();
  }

  Future<void> _checkLicense() async {
    // محاكاة تحميل بسيط للشعار
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final licenseService = LicenseService();
    // نحصل على النتيجة
    // ملاحظة: في النسخة النهائية يجب تفعيل فحص الوقت (NTP) بشكل صارم
    final result = await licenseService.validateLicense();

    if (!mounted) return;

    if (result.isValid) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ActivationPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_gas_station,
                  size: 50, color: colorScheme.onPrimary),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'جاري التحقق من الترخيص...',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool keepLogged = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _shakeController;

  // مفتاح الفورم للتحقق
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// التحقق من تسجيل الدخول - يحاول API أولاً ثم المحلي
  Future<void> _handleLogin() async {
    // التحقق من صحة الفورم
    if (!_formKey.currentState!.validate()) {
      _shakeError();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!mounted) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final provider = Provider.of<FuelProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final api = ApiService();
    bool success = false;
    String? errorMsg;

    // ===== محاولة تسجيل الدخول عبر API أولاً =====
    try {
      final res = await api.login(email, password);
      if (res.success && res.data != null) {
        // نجاح API - مزامنة البيانات محلياً
        success = true;
        authService.login(email, password);
        provider.login(email, password);
        await provider.syncWithApi();
        debugPrint('✅ تسجيل دخول ناجح عبر API + مزامنة');
      } else if (res.code == 'NETWORK_ERROR' || res.code == 'UNKNOWN_ERROR' || res.code == 'FORMAT_ERROR') {
        // السيرفر غير متاح - fallback للتسجيل المحلي
        debugPrint('⚠️ السيرفر غير متاح (${res.code}), محاولة تسجيل الدخول محلياً...');
        success = authService.login(email, password);
        if (success) {
          provider.login(email, password);
          debugPrint('✅ تسجيل دخول ناجح محلياً (offline)');
        } else {
          errorMsg = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        }
      } else {
        // API رد بخطأ (بيانات خاطئة فعلاً)
        errorMsg = res.error ?? 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      }
    } catch (e) {
      // خطأ غير متوقع - fallback للمحلي
      debugPrint('⚠️ خطأ غير متوقع: $e، محاولة تسجيل الدخول محلياً...');
      success = authService.login(email, password);
      if (success) {
        provider.login(email, password);
        debugPrint('✅ تسجيل دخول ناجح محلياً (offline)');
      } else {
        errorMsg = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      }
    }

    if (!mounted) return;

    if (success) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            errorMsg ?? 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      });
      _shakeError();
    }
  }

  void _shakeError() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;
    final sahara = Theme.of(context).extension<SaharaColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: sahara.pageGradient,
              ),
            ),
            child: CustomPaint(size: size, painter: ModernBackgroundPainter()),
          ),
          Center(
            child: Container(
              width: 900,
              height: 580,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Row(
                  children: [
                    // === الجانب الأيسر - الترحيب ===
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              sahara.gradientStart,
                              sahara.gradientMiddle,
                              sahara.gradientEnd,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(50),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CustomPaint(painter: DotPatternPainter()),
                            ),
                            const SizedBox(height: 40),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'JOIN THE\nLARGEST ',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimaryContainer,
                                      height: 1.2,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'FUEL SYSTEM',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? colorScheme.primary : colorScheme.onPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            SizedBox(
                              width: 300,
                              child: Text(
                                'Explore fuel management and connect with teams.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey[300] : colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            // معلومات الحسابات التجريبية
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : colorScheme.onPrimaryContainer.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : colorScheme.onPrimaryContainer.withValues(alpha: 0.12)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'حسابات تجريبية:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[300] : colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _accountHint('مدير', 'admin@sahara-fuel.com',
                                      'admin123'),
                                  _accountHint('مدير محطة',
                                      'manager@sahara-fuel.com', 'manager123'),
                                  _accountHint(
                                      'مشغّل',
                                      'operator@sahara-fuel.com',
                                      'operator123'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // === الجانب الأيمن - نموذج الدخول ===
                    Expanded(
                      child: Container(
                        color: colorScheme.surfaceContainerHighest,
                        padding: const EdgeInsets.all(45),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -20,
                              right: -20,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SingleChildScrollView(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // زر الإغلاق
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: GestureDetector(
                                        onTap: () {},
                                        child: Container(
                                          width: 45,
                                          height: 45,
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: colorScheme.onPrimary,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      'Log In',
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Become a Manager . ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'Join',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 30),

                                    // === رسالة الخطأ ===
                                    AnimatedBuilder(
                                      animation: _shakeController,
                                      builder: (context, child) {
                                        final offset = _shakeController.value <
                                                0.5
                                            ? (_shakeController.value * 20 - 5)
                                            : ((1 - _shakeController.value) *
                                                    20 -
                                                5);
                                        return Transform.translate(
                                          offset: Offset(
                                              _shakeController.isAnimating
                                                  ? offset
                                                  : 0,
                                              0),
                                          child: child,
                                        );
                                      },
                                      child: AnimatedSize(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        child: _errorMessage != null
                                            ? Container(
                                                width: double.infinity,
                                                margin: const EdgeInsets.only(
                                                    bottom: 16),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.error.withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: colorScheme.error.withOpacity(0.3)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.error_outline,
                                                        color: colorScheme.error,
                                                        size: 20),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        _errorMessage!,
                                                        style: TextStyle(
                                                            color: colorScheme.error,
                                                            fontSize: 13),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () => setState(
                                                          () => _errorMessage =
                                                              null),
                                                      child: Icon(Icons.close,
                                                          color: colorScheme.error.withOpacity(0.5),
                                                          size: 18),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ),

                                    // === حقل البريد الإلكتروني ===
                                    TextFormField(
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: TextStyle(color: colorScheme.onSurface),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'يرجى إدخال البريد الإلكتروني';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _handleLogin(),
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.person_outline,
                                          color: sahara.hintText,
                                          size: 20,
                                        ),
                                        hintText: 'Email Address',
                                        hintStyle: TextStyle(
                                          color: sahara.hintText,
                                          fontSize: 14,
                                        ),
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: colorScheme.outline),
                                        ),
                                        focusedBorder:
                                            UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: colorScheme.primary,
                                              width: 2),
                                        ),
                                        errorBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: colorScheme.error),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 25),

                                    // === حقل كلمة المرور ===
                                    TextFormField(
                                      controller: passwordController,
                                      obscureText: _obscurePassword,
                                      style: TextStyle(color: colorScheme.onSurface),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'يرجى إدخال كلمة المرور';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _handleLogin(),
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.lock_outline,
                                          color: sahara.hintText,
                                          size: 20,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: sahara.hintText,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                        ),
                                        hintText: 'Password',
                                        hintStyle: TextStyle(
                                          color: sahara.hintText,
                                          fontSize: 14,
                                        ),
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: colorScheme.outline),
                                        ),
                                        focusedBorder:
                                            UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: colorScheme.primary,
                                              width: 2),
                                        ),
                                        errorBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: colorScheme.error),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Keep me logged in
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: keepLogged,
                                          onChanged: (val) => setState(
                                              () => keepLogged = val ?? true),
                                          activeColor: colorScheme.primary,
                                          side: BorderSide(
                                              color: colorScheme.outline),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Keep me logged in',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: colorScheme.onSurfaceVariant),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 25),

                                    // === زر تسجيل الدخول ===
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          disabledBackgroundColor:
                                              colorScheme.primary
                                                  .withOpacity(0.6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: colorScheme.onPrimary,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : Text(
                                                'LOG IN',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onPrimary,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: Text(
                                        'Forgot your username or password?',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Center(
                                      child: RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  'By clicking Log In, I confirm that I have read and agree to the ',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: colorScheme.onSurfaceVariant),
                                            ),
                                            TextSpan(
                                              text:
                                                  'Terms of Service, Privacy Policy',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '.',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: colorScheme.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountHint(String role, String email, String password) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: () {
          setState(() {
            emailController.text = email;
            passwordController.text = password;
            _errorMessage = null;
          });
        },
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isDarkMode ? colorScheme.primary : colorScheme.onPrimaryContainer,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$role: $email / $password',
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.grey[400] : colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = const Color(0xFF1F4D6D).withOpacity(0.6);
    paint.strokeWidth = 3;
    paint.style = PaintingStyle.stroke;
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(size.width * 0.2 + (i * 60), 0),
        Offset(0, size.height * 0.4 + (i * 60)),
        paint,
      );
    }
    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(size.width - (i * 80), size.height),
        Offset(size.width, size.height * 0.3 + (i * 80)),
        paint,
      );
    }
    paint.style = PaintingStyle.fill;
    paint.color = Colors.cyan.withOpacity(0.1);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), 120, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 100, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D9A3)
      ..style = PaintingStyle.fill;
    final dotSize = 6.0;
    final spacing = 20.0;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        canvas.drawCircle(
          Offset(spacing + (i * spacing), spacing + (j * spacing)),
          dotSize,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

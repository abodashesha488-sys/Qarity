import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/navigator_key.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _startAnimationSequence();
  }

  void _safeNavigate(String route, {Object? arguments}) {
    if (_navigated || !mounted) return;
    _navigated = true;
    if (arguments != null) {
      Navigator.pushReplacementNamed(context, route, arguments: arguments);
    } else {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  Future<void> _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _logoController.forward();
    _textController.forward();
    // لا ننتظر الشبكة أو مصادقة الفيربيس: المستخدم الحالي متاح فوراً من
    // الجلسة المحفوظة محلياً، لذا يفتح التطبيق مباشرة إن كان مسجّلاً.
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _safeNavigate(AppRoutes.login);
      return;
    }

    // قراءة محليّة أولوية (تعمل أوفلاين من الكاش) لتقرير المسار دون انتظار الشبكة.
    UserModel? model;
    try {
      model = await UserService().getUser(currentUser.uid);
    } catch (_) {
      model = null;
    }

    // حساب معطّل → تسجيل خروج.
    if (model != null && !model.isActive) {
      await firebase_auth.FirebaseAuth.instance.signOut();
      if (!mounted) return;
      _safeNavigate(AppRoutes.login);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Text('تم تعطيل حسابك — يرجى التواصل مع إدارة القرية'),
            backgroundColor: Colors.red,
          ));
        }
      });
      return;
    }

    // مستخدم جديد/غير مكتمل البيانات (اسم أو هاتف فارغ) → شاشة الإكمال.
    // لا نوجّه إن تعذّرت القراءة (أوفلاين بلا كاش) حتى لا نُغلِق الوصول.
    if (model != null && !UserService.isProfileComplete(model)) {
      _safeNavigate(AppRoutes.completeProfile, arguments: currentUser.uid);
      return;
    }

    _safeNavigate(AppRoutes.home);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/images/Qurity.png',
                  fit: BoxFit.contain,
                ),
              ),
            )
                .animate(controller: _logoController)
                .scale(
                  begin: const Offset(0.0, 0.0),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                )
                .fade(duration: 600.ms),

            const SizedBox(height: 40),

            Text(
              'قريتي',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 36,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
            )
                .animate(controller: _textController)
                .fade(duration: 600.ms)
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 12),

            Text(
              'قريتك بين يديك',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
            )
                .animate(controller: _textController)
                .fade(
                  delay: 200.ms,
                  duration: 600.ms,
                )
                .slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 200.ms,
                  duration: 600.ms,
                ),

            const SizedBox(height: 60),

            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.8),
                ),
                strokeWidth: 3,
              ),
            )
                .animate(controller: _textController)
                .fade(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
      ),
    );
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // أخطاء تعني أن النافذة المنبثقة غير متاحة: المتصفح حجبها، أو التطبيق
  // مثبّت كـPWA على الشاشة الرئيسية (iOS) حيث تُرفض popups تلقائياً ويرمي
  // Firebase نفسه `popup-blocked` — كلها تُحوَّل لمسار إعادة التوجيه الرسمي.
  static const Set<String> _popupUnavailableCodes = {
    'popup-blocked',
    'cancelled-popup-request',
    'operation-not-allowed',
  };

  Future<UserCredential?> _googleCredentialFlow() async {
    if (kIsWeb) {
      // على الويب: signInWithPopup هو المسار الرسمي لـ Firebase Auth
      // (يتجنب أخطاء client/origin في حزمة google_sign_in على الويب).
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      try {
        return await FirebaseAuth.instance.signInWithPopup(provider);
      } on FirebaseAuthException catch (e) {
        if (!_popupUnavailableCodes.contains(e.code)) rethrow;
        return _startRedirectSignIn(provider);
      }
    }
    final GoogleSignInAccount? googleUser = await GoogleSignIn(
      scopes: const <String>['openid', 'email', 'profile'],
    ).signIn();
    if (googleUser == null) return null; // أُلغيت العملية
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  /// إعادة توجيه لمرة واحدة مع علم يمنع أي حلقة: إذا رجع المستخدم من
  /// Google بدون إتمام تسجيل دخول، لا نُعيد التوجيه تلقائياً في نفس الجلسة.
  Future<UserCredential?> _startRedirectSignIn(GoogleAuthProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AppConfig.googleRedirectFlagKey) ?? false) {
      throw FirebaseAuthException(
        code: 'redirect-incomplete',
        message: 'تعذّر إتمام تسجيل الدخول عبر إعادة التوجيه — '
            'أغلق اللسان وأعد المحاولة من متصفح Safari العادي',
      );
    }
    await prefs.setBool(AppConfig.googleRedirectFlagKey, true);
    try {
      await FirebaseAuth.instance.signInWithRedirect(provider);
    } catch (_) {
      await prefs.setBool(AppConfig.googleRedirectFlagKey, false);
      rethrow;
    }
    // الصفحة ستغادر إلى Google وتعود بإقلاع جديد يستهلك النتيجة في main.dart.
    return null;
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final userCredential =
          await _googleCredentialFlow().timeout(const Duration(seconds: 60));
      if (userCredential == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;
      final currentUser = userCredential.user!;

      // Try to sync user data to Firestore, but don't block login if it fails
      try {
        await UserService().saveUserToFirestore(currentUser);
      } catch (e) {
        // Firestore write failed - still allow login
        debugPrint('Firestore write failed: $e');
      }

      if (!mounted) return;

      // مستخدم جديد/غير مكتمل البيانات → شاشة إكمال الملف، غير ذلك → الرئيسية.
      UserModel? profile;
      try {
        profile = await UserService().getUser(currentUser.uid);
      } catch (_) {
        profile = null;
      }
      if (!mounted) return;
      if (profile != null && !UserService.isProfileComplete(profile)) {
        Navigator.pushReplacementNamed(context, AppRoutes.completeProfile,
            arguments: currentUser.uid);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'خطأ في المصادقة: ${_mapFirebaseAuthError(e.code)}',
          isError: true,
        );
      }
    } on TimeoutException {
      if (mounted) {
        AppHelpers.showSnackBar(context,
            'انتهت مهلة تسجيل الدخول — تحقق من اتصالك وأعد المحاولة',
            isError: true);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'خطأ في قاعدة البيانات: ${e.message}',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'خطأ في تسجيل الدخول: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'network-request-failed':
        return 'مشكلة في الاتصال بالإنترنت';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      case 'account-exists-with-different-credential':
        return 'الحساب موجود بوسيلة تسجيل أخرى';
      case 'unauthorized-domain':
        return 'هذا النطاق غير معتمد — أضِفه من Firebase Console ← Authentication ← Settings ← Authorized domains';
      case 'operation-not-allowed':
        return 'طريقة تسجيل Google غير مفعّلة في مشروع Firebase';
      case 'popup-closed-by-user':
      case 'closed-by-window':
      case 'cancelled':
      case 'google-sign-in-cancelled':
        return 'أُلغيت عملية تسجيل الدخول';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/Qurity.png',
                          fit: BoxFit.cover,
                          width: 110,
                          height: 110,
                        ),
                      ),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.easeOutBack)
                        .fade(duration: 400.ms),
                    const SizedBox(height: 24),
                    const Text(
                      'قرية أبوديشيشة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.2, delay: 200.ms),
                    const SizedBox(height: 8),
                    const Text(
                      'بوابتك إلى الخدمات الرقمية والمجتمع المحلي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fade(delay: 300.ms),
                  ],
                ),
              ).animate().fade(duration: 500.ms).slideY(begin: -0.1),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FeatureItem(text: 'أخبار القرية والمناسبات', delay: 400),
                    _FeatureItem(text: 'سوق القرية والمنتجات المحلية', delay: 500),
                    _FeatureItem(text: 'منتدى المجتمع المحلي', delay: 600),
                    _FeatureItem(text: 'أرقام الطوارئ ودليل الهاتف', delay: 700),
                  ],
                ),
              ).animate().fade(delay: 400.ms).slideY(begin: 0.3, delay: 400.ms),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login_rounded, size: 22),
                  label: Text(
                    _isLoading ? 'جاري تسجيل الدخول...' : 'تسجيل الدخول باستخدام Google',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ).animate().fade(delay: 600.ms).slideY(begin: 0.2, delay: 600.ms),

              const SizedBox(height: 16),
              Text(
                'بتسجيل الدخول فإنك توافق على شروط الاستخدام وسياسة الخصوصية',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  final int delay;

  const _FeatureItem({required this.text, required this.delay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(delay: delay.ms).slideX(begin: -0.1, delay: delay.ms);
  }
}

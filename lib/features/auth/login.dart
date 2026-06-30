import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../routes/app_routes.dart';
import '../../services/user_service.dart';
import '../auth/complete_profile.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: <String>[
          'openid',
          'email',
          'profile',
        ],
      ).signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final userService = UserService();

      if (userCredential.user != null) {
        await userService.saveUserToFirestore(userCredential.user!);
      }

      if (mounted) {
        final currentUser = userCredential.user!;
        final dbUser = await userService.getCurrentUser();
        if (dbUser?.phone == null || dbUser?.phone?.isEmpty == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => CompleteProfileScreen(userId: currentUser.uid)),
          );
        } else {
          final isAdmin = await userService.isAdmin(currentUser.uid);
          Navigator.pushReplacementNamed(
            context,
            isAdmin ? AppRoutes.admin : AppRoutes.home,
          );
        }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.villa_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .fade(duration: 400.ms),

                const SizedBox(height: 28),

                Text(
                  'قرية أبوديشيشة',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fade(delay: 200.ms).slideY(begin: 0.2, delay: 200.ms),

                const SizedBox(height: 8),

                Text(
                  'بوابتك إلى الخدمات الرقمية والمجتمع المحلي',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fade(delay: 300.ms),

                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
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

                const SizedBox(height: 40),

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
                        : const Icon(Icons.login, size: 22),
                    label: Text(
                      _isLoading ? 'جاري تسجيل الدخول...' : 'تسجيل الدخول باستخدام Google',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ).animate().fade(delay: 600.ms).slideY(begin: 0.2, delay: 600.ms),
              ],
            ),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(delay: delay.ms).slideX(begin: -0.1, delay: delay.ms);
  }
}
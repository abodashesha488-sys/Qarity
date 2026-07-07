import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoScale = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.addListener(() => setState(() {}));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn(
          scopes: const <String>['openid', 'email', 'profile'],
        ).signIn().timeout(const Duration(seconds: 30));

        if (googleUser == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(credential).timeout(const Duration(seconds: 20));
      }

      if (!mounted) return;
      final currentUser = userCredential.user;

      if (currentUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      try {
        await UserService().updateUser(UserModel(
          id: currentUser.uid,
          name: currentUser.displayName ?? '',
          email: currentUser.email ?? '',
          photoUrl: currentUser.photoURL,
          joinDate: currentUser.metadata.creationTime ?? DateTime.now(),
        ));
      } catch (e) {
        debugPrint('Firestore write failed: $e');
      }

      if (!mounted) return;

      final adminEmail = 'eleraki2040@gmail.com';
      final isOwner = currentUser.email != null &&
          currentUser.email!.toLowerCase() == adminEmail.toLowerCase();

      if (isOwner) {
        try {
          await UserService().setRoleIfNeeded(currentUser.uid, 'admin');
        } catch (e) {
          debugPrint('set admin role failed: $e');
        }
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.splash);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'خطأ في المصادقة: ${_mapFirebaseAuthError(e.code)}',
          isError: true,
        );
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
      default:
        return code;
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
                ScaleTransition(
                  scale: _logoScale,
                  child: Container(
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
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'قرية أبوديشيشة',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'بوابتك إلى الخدمات الرقمية والمجتمع المحلي',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 36),

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ماذا يمكنك القيام به؟', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      const _FeatureItem(text: 'أخبار القرية والمناسبات', color: Colors.blue),
                      const SizedBox(height: 10),
                      const _FeatureItem(text: 'سوق القرية والمنتجات المحلية', color: Colors.deepOrange),
                      const SizedBox(height: 10),
                      const _FeatureItem(text: 'منتدى المجتمع المحلي', color: Colors.purple),
                      const SizedBox(height: 10),
                      const _FeatureItem(text: 'أرقام الطوارئ ودليل الهاتف', color: Colors.teal),
                    ],
                  ),
                ),

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
                        : Image.asset('assets/google_logo.png', width: 22, height: 22),
                    label: Text(
                      _isLoading ? 'جاري تسجيل الدخول...' : 'تسجيل الدخول باستخدام Google',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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

class _FeatureItem extends StatelessWidget {
  final String text;
  final Color color;

  const _FeatureItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/navigator_key.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/user_service.dart';
// ignore: directives_ordering
import '../../services/update_service.dart';

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
  bool _isDownloading = false;

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
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _safeNavigate(AppRoutes.login);
      return;
    }

    UserModel? model;
    try {
      model = await UserService().getUser(currentUser.uid);
    } catch (_) {
      model = null;
    }

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

    if (model != null && !UserService.isProfileComplete(model)) {
      _safeNavigate(AppRoutes.completeProfile, arguments: currentUser.uid);
      return;
    }

    await _checkUpdateAndNavigate(currentUser);
  }

  // ignore: use_build_context_synchronously
  Future<void> _checkUpdateAndNavigate(
    firebase_auth.User? currentUser,
  ) async {
    UpdateInfo? updateInfo;
    try {
      updateInfo = await UpdateService().getUpdateInfo();
    } catch (_) {}
    if (!mounted) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    if (updateInfo != null && currentUser != null) {
      // ignore: use_build_context_synchronously
      final result = await UpdateService.showUpdateDialog(ctx, updateInfo);
      if (result == DialogResult.updateNow) {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        await _handleDownloadAndInstall(ctx, updateInfo);
        if (!mounted) return;
        _safeNavigate(AppRoutes.home);
        return;
      }
      if (!mounted) return;
    }
    _safeNavigate(AppRoutes.home);
  }

  Future<void> _handleDownloadAndInstall(
    BuildContext context,
    UpdateInfo info,
  ) async {
    if (_isDownloading) return;
    _isDownloading = true;

    final UpdateInstallResult? result = await showDialog<UpdateInstallResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DownloadProgressDialog(
        apkUrl: info.apkUrl,
      ),
    );

    if (!mounted) {
      _isDownloading = false;
      return;
    }

    _isDownloading = false;

    if (result == null || !result.isSuccess) {
      // ignore: use_build_context_synchronously
      _showSnackBar(context, 'تعذر تنزيل التحديث. حاول مرة أخرى.');
      return;
    }

    final apkPath = result.apkPath;
    if (apkPath == null) {
      // ignore: use_build_context_synchronously
      _showSnackBar(context, 'تعذر تنزيل التحديث.');
      return;
    }

    // ignore: use_build_context_synchronously
    _showSnackBar(context, 'جاري فتح مثبت التطبيقات...');

    final service = UpdateService();
    final canInstall = await service.canInstallPackages();
    if (!canInstall) {
      // ignore: use_build_context_synchronously
      _showSnackBar(context,
          'يتوجب عليك السماح بتثبيت التطبيقات من هذا المصدر.');
      await service.openInstallPermissionSettings();
      if (!mounted) return;
      final canInstallNow = await service.canInstallPackages();
      if (!canInstallNow) {
        // ignore: use_build_context_synchronously
        _showSnackBar(context,
            'لم يتم منح الإذن. يمكنك محاولة التحديث لاحقاً من الإعدادات.');
        return;
      }
    }

    final installResult = await service.installApk(apkPath);

    if (!installResult.isSuccess) {
      // ignore: use_build_context_synchronously
      _showSnackBar(context,
          'لم يتم التثبيت. يمكنك محاولة التحديث لاحقاً.');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    if (!mounted) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

class _DownloadProgressDialog extends StatefulWidget {
  final String apkUrl;

  const _DownloadProgressDialog({required this.apkUrl});

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  final UpdateService _service = UpdateService();
  final ValueNotifier<int> _receivedNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int?> _totalNotifier = ValueNotifier<int?>(null);
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    debugPrint('[UPDATE] download start');
    final stopwatch = Stopwatch()..start();
    debugPrint('[UPDATE] timer started at ${stopwatch.elapsed.inMilliseconds}ms');

    final result = await _service.downloadAndInstall(
      widget.apkUrl,
      (int received, int? total) {
        if (!mounted) return;
        _receivedNotifier.value = received;
        _totalNotifier.value = total;
        debugPrint('[UPDATE] progress: received=$received total=$total at ${stopwatch.elapsed.inMilliseconds}ms');
      },
    ).then((result) {
      debugPrint('[UPDATE] downloadAndInstall completed at ${stopwatch.elapsed.inMilliseconds}ms');
      return result;
    }).catchError((dynamic e, StackTrace st) {
      debugPrint('[UPDATE][ERROR] type=${e.runtimeType} message=$e');
      debugPrint('[UPDATE][ERROR] stack=$st');
      return UpdateInstallResult.failure(e.toString());
    });

    if (!mounted) return;
    if (_completed) return;
    _completed = true;
    debugPrint('[UPDATE] calling Navigator.pop at ${stopwatch.elapsed.inMilliseconds}ms');
    Navigator.pop(context, result);
  }

  @override
  void dispose() {
    _receivedNotifier.dispose();
    _totalNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _receivedNotifier,
      builder: (context, received, _) {
        final total = _totalNotifier.value;
        String progressText;
        if (total != null && total > 0) {
          final pct = (received / total * 100).round();
          progressText =
              '${(received / (1024 * 1024)).toStringAsFixed(1)} MB / ${(total / (1024 * 1024)).toStringAsFixed(1)} MB ($pct%)';
        } else {
          progressText = '${(received / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'جاري تنزيل التحديث...',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
            ],
          ),
          content: Text(progressText,
              style: const TextStyle(fontSize: 14)),
        );
      },
    );
  }
}

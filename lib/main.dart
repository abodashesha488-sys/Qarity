import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import './firebase_options.dart';
import 'core/network/connectivity_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/navigator_key.dart';
import 'routes/app_routes.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'widgets/connectivity_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    // تفعيل التخزين المحلي الدائم: قراءة/كتابة بدون إنترنت + مزامنة تلقائية عند العودة.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // تحميل السمة فقط ضروري قبل runApp (سريع ومحلي).
  await ThemeService().loadTheme();

  // بقية التهيئة في الخلفية حتى يفتح التطبيق فوراً دون انتظار الشبكة.
  unawaited(_backgroundInit());

  runApp(const QarityApp());
}

Future<void> _backgroundInit() async {
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }
  try {
    await ConnectivityManager.instance.init();
  } catch (e) {
    debugPrint('Connectivity init failed: $e');
  }
}

class QarityApp extends StatelessWidget {
  const QarityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, child) {
        return MaterialApp(
          title: 'قرية أبوديشيشة',
          debugShowCheckedModeBanner: false,
          // يُوصل الـNavigator للرسائل العامة وتنقّل ضغط الإشعارات.
          navigatorKey: navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService().themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar', 'EG')],
          locale: const Locale('ar', 'EG'),
          // الأساس الموحَّد لكل نصوص التطبيق: خط Tajawal.
          builder: (context, child) => DefaultTextStyle(
            style: GoogleFonts.tajawal(),
            child: ConnectivityOverlay(child: child ?? const SizedBox.shrink()),
          ),
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}

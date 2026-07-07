import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import './core/utils/navigator_key.dart';
import './firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/market/cart.dart';
import 'routes/app_routes.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  await ThemeService().loadTheme();
  await Cart.instance.init();
  _initNotifications();
  runApp(const QarityApp());
}

Future<void> _initNotifications() async {
  try {
    await FirebaseMessaging.instance.requestPermission();
  } catch (_) {
    // Notification permission may fail on some devices
  }
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message.notification?.title ?? '', style: const TextStyle(color: Colors.white))));
      }
    }
  });
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
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService().themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar', 'SA')],
          locale: const Locale('ar', 'SA'),
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }  // محمد العراقي
}
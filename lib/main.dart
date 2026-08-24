import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import './firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/market/cart.dart';
import 'routes/app_routes.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  await ThemeService().loadTheme();
  await Cart.instance.init();
  await NotificationService.initialize();
  runApp(const QarityApp());
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
          supportedLocales: const [Locale('ar', 'EG')],
          locale: const Locale('ar', 'EG'),
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  } // محمد العراقي
}

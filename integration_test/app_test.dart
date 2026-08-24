import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:qurity/firebase_options.dart';
import 'package:qurity/main.dart' as app;
import 'package:qurity/routes/app_routes.dart';

/// End-to-end smoke test. Runs on a real device/emulator via:
///   flutter test integration_test
///
/// It initializes Firebase from the platform options and boots the real
/// app, then verifies the first screen renders without a fatal error.
/// This exercises the full boot path (Firebase, ThemeService, Cart,
/// NotificationService) and catches per-screen build/runtime crashes
/// that unit tests cannot.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App boots end-to-end and renders the first screen', (tester) async {
    // app.main() initializes Firebase itself; re-init is safe (returns existing app).
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {
      // ignore — main() handles initialization and tolerates failures.
    }

    app.main();
    await _settle(tester);

    // The app built exactly one MaterialApp.
    expect(find.byType(MaterialApp), findsOneWidget);

    // A screen (Scaffold) is rendered and no fatal error widget is shown.
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets('Navigating to key screens builds without errors', (tester) async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {
      // ignore — handled by main().
    }

    app.main();
    await _settle(tester);

    // Grab the root Navigator so we can drive navigation like a user would.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);

    // Public, argument-free list/info screens (work with or without auth).
    final routes = [
      AppRoutes.newsList,
      AppRoutes.forumPosts,
      AppRoutes.obituariesList,
      AppRoutes.occasionsList,
      AppRoutes.marketProducts,
      AppRoutes.emergencyContacts,
      AppRoutes.phoneDirectory,
      AppRoutes.about,
      AppRoutes.aboutApp,
      AppRoutes.settingsIndex,
    ];

    for (final route in routes) {
      await navigator.pushNamed(route);
      await _settle(tester);
      expect(find.byType(ErrorWidget), findsNothing,
          reason: 'Screen for route "$route" threw a build/runtime error.');
      navigator.pop();
      await _settle(tester);
    }
  });
}

/// Pumps through the splash sequence while tolerating perpetual
/// animations (staggered animations, indicators) that would otherwise
/// make [WidgetTester.pumpAndSettle] time out.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } on Object {
      // Ignore settle timeouts caused by looping animations.
    }
    await tester.pump(const Duration(seconds: 1));
  }
}

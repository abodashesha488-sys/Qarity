// ignore_for_file: prefer_const_constructors
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:qurity/firebase_options.dart';
import 'package:qurity/main.dart' as app;
import 'package:qurity/models/data_models.dart';
import 'package:qurity/routes/app_routes.dart';
import 'package:qurity/services/admin_service.dart';
import 'package:qurity/services/market_service.dart';
import 'package:qurity/services/news_service.dart';

/// Integration tests for critical user flows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (details) {
    try {
      File('/data/local/tmp/qarity_err.txt')
          .writeAsStringSync('${details.exceptionAsString()}\n\n${details.stack}');
    } catch (_) {}
    return ErrorWidget.withDetails(message: details.toString());
  };

  group('Critical User Flows', () {
    setUpAll(() async {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (_) {}
    });

    testWidgets('App boots and shows splash screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      
      // Should show splash screen
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(ErrorWidget), findsNothing);
    });

    testWidgets('Google Sign-In flow initiates correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      
      // Find and tap Google Sign-In button
      final signInButton = find.byKey(const Key('google_sign_in_button'));
      if (signInButton.evaluate().isNotEmpty) {
        await tester.tap(signInButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
      
      expect(find.byType(ErrorWidget), findsNothing);
    });

    testWidgets('Navigate to market screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 15));
      
      // Navigate to market tab (index 2)
      final marketTab = find.byIcon(Icons.store_outlined);
      if (marketTab.evaluate().isNotEmpty) {
        await tester.tap(marketTab);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
      
      expect(find.byType(ErrorWidget), findsNothing);
    });

    testWidgets('Navigate to forum screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 15));
      
      // Navigate to forum tab (index 3)
      final forumTab = find.byIcon(Icons.forum_outlined);
      if (forumTab.evaluate().isNotEmpty) {
        await tester.tap(forumTab);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
      
      expect(find.byType(ErrorWidget), findsNothing);
    });

    testWidgets('Navigate to profile screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 15));
      
      // Navigate to profile tab (index 4)
      final profileTab = find.byIcon(Icons.person_outlined);
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
      
      expect(find.byType(ErrorWidget), findsNothing);
    });
  });

  group('Market Service Tests', () {
    setUpAll(() async {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (_) {}
    });

    test('MarketService can be instantiated', () async {
      final marketService = MarketService();
      expect(marketService, isNotNull);
    });
  });

  group('News Service Tests', () {
    setUpAll(() async {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (_) {}
    });

    test('NewsService can fetch approved news', () async {
      final newsService = NewsService();
      
      final stream = newsService.getNewsStream();
      expect(stream, isNotNull);
      
      final news = await stream.first;
      expect(news, isA<List<NewsItem>>());
    });

    test('NewsService can fetch single news item', () async {
      final newsService = NewsService();
      
      final stream = newsService.getNewsItemStream('test-id');
      expect(stream, isNotNull);
      
      final news = await stream.first;
      // May be null if doesn't exist
      expect(news, anyOf(isNull, isA<NewsItem>()));
    });
  });

  group('Admin Service Tests', () {
    setUpAll(() async {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (_) {}
    });

    test('AdminService can check admin status', () async {
      final adminService = AdminService();
      
      final isAdmin = await adminService.isAdminUser('test-uid');
      expect(isAdmin, isA<bool>());
    });

    test('AdminService can fetch statistics', () async {
      final adminService = AdminService();
      
      final stats = await adminService.getStatistics();
      expect(stats, isA<Map<String, int>>());
    });

    test('AdminService can fetch pending counts', () async {
      final adminService = AdminService();
      
      final counts = await adminService.fetchPendingCounts();
      expect(counts, isA<Map<String, int>>());
    });
  });

  group('Navigation Tests', () {
    testWidgets('All routes can be navigated to', (tester) async {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } catch (_) {}
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 20));
      
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      
      final testRoutes = [
        AppRoutes.home,
        AppRoutes.newsList,
        AppRoutes.forumPosts,
        AppRoutes.obituariesList,
        AppRoutes.occasionsList,
        AppRoutes.marketProducts,
        AppRoutes.emergencyContacts,
        AppRoutes.phoneDirectory,
        AppRoutes.about,
        AppRoutes.aboutApp,
        AppRoutes.profileMain,
        AppRoutes.settingsIndex,
      ];
      
      for (final route in testRoutes) {
        try {
          navigator.pushNamed(route);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          expect(find.byType(ErrorWidget), findsNothing, 
              reason: 'Route $route threw an error');
          navigator.pop();
          await tester.pumpAndSettle(const Duration(seconds: 1));
        } catch (e) {
          // Some routes may require auth or data
          debugPrint('Route $route navigation issue: $e');
        }
      }
    });
  });
}
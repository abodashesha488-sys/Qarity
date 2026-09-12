// ignore_for_file: prefer_const_constructors
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:qurity/firebase_options.dart';
import 'package:qurity/main.dart' as app;
import 'package:qurity/models/data_models.dart';
import 'package:qurity/models/medical_models.dart';
import 'package:qurity/models/service_provider_model.dart';
import 'package:qurity/routes/app_routes.dart';

/// End-to-end smoke test. Runs on a real device/emulator via:
///   flutter test integration_test
///
/// It initializes Firebase from the platform options and boots the real
/// app, then verifies the first screen renders without a fatal error.
/// This exercises the full boot path (Firebase, ThemeService,
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

  testWidgets('All screens build without errors (full navigation coverage)', (tester) async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {
      // ignore — handled by main().
    }

    app.main();
    await _settle(tester);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);

    // Minimal model objects so argument-driven detail screens render.
    final newsItem = NewsItem(
      id: 'n1',
      title: 'عنوان',
      subtitle: 'موضوع',
      imageUrl: '',
      date: '2020',
    );
    final marketProduct = MarketProduct(
      id: 'p1',
      name: 'منتج',
      description: 'وصف',
      price: 10,
      imageUrl: '',
      category: 'عام',
      sellerName: 'بائع',
      sellerPhone: '123',
    );
    final forumPost = ForumPost(
      id: 'f1',
      userId: 'u1',
      userName: 'مستخدم',
      content: 'محتوى',
      createdAt: DateTime(2020),
    );
    final villageClinic = VillageClinic(
      id: 'c1',
      name: 'عيادة',
      specialty: 'باطنة',
      phone: '123',
    );
    final pharmacy = Pharmacy(
      id: 'ph1',
      name: 'صيدلية',
      phone: '123',
    );
    final obituary = Obituary(
      id: 'o1',
      name: 'محمد',
      age: '70',
      dateOfDeath: '2020',
      description: 'وصف',
    );
    final occasion = Occasion(
      id: 'oc1',
      title: 'فرح',
      date: '2020',
      description: 'وصف',
      location: 'مكان',
    );

    // Every reachable screen. The admin *wrapper* route is intentionally
    // skipped (it redirects unauthenticated users); admin detail/edit are
    // included since they render without an admin gate.
    final entries = <_Entry>[
      _Entry(AppRoutes.newsList),
      _Entry(AppRoutes.newsView, newsItem),
      _Entry(AppRoutes.newsAdd),
      _Entry(AppRoutes.forumPosts),
      _Entry(AppRoutes.forumPostDetail, forumPost),
      _Entry(AppRoutes.forumCreatePost),
      _Entry(AppRoutes.obituariesList),
      _Entry(AppRoutes.obituariesDetail, obituary),
      _Entry(AppRoutes.obituariesAdd),
      _Entry(AppRoutes.occasionsList),
      _Entry(AppRoutes.occasionsDetail, occasion),
      _Entry(AppRoutes.occasionsAdd),
      _Entry(AppRoutes.marketProducts),
      _Entry(AppRoutes.marketProductDetail, marketProduct),
      _Entry(AppRoutes.marketAdd),
      _Entry(AppRoutes.marketSellerDetail, <String, String>{'name': 'بائع', 'phone': '123', 'sellerId': ''}),
      _Entry(AppRoutes.marketSellerReviews, <String, String>{'name': 'بائع', 'phone': '123'}),
      _Entry(AppRoutes.marketSellerGallery, <String, String>{'name': 'بائع', 'sellerId': ''}),
      _Entry(AppRoutes.serviceRequest),
      _Entry(AppRoutes.serviceCategory, 'technicians'),
      _Entry(AppRoutes.serviceProviderDetail,
          const ServiceProvider(id: 'sp1', category: 'technicians', name: 'ورشة', specialty: 'نجارة')),
      _Entry(AppRoutes.medicalClinicDetail, villageClinic),
      _Entry(AppRoutes.medicalPharmacyDetail, pharmacy),
      _Entry(AppRoutes.emergencyContacts),
      _Entry(AppRoutes.phoneDirectory),
      _Entry(AppRoutes.about),
      _Entry(AppRoutes.aboutApp),
      _Entry(AppRoutes.profileMain),
      _Entry(AppRoutes.settingsIndex),
      _Entry(AppRoutes.notificationsSettings),
      _Entry(AppRoutes.weather),
      _Entry(AppRoutes.medicalSection, 0),
      _Entry(AppRoutes.medicalSection, 2),
      _Entry(AppRoutes.completeProfile, 'test-user-id'),
      _Entry(AppRoutes.adminDetail, <String, dynamic>{'collection': 'news', 'docId': 'x', 'item': <String, dynamic>{}}),
      _Entry(AppRoutes.adminEdit, <String, dynamic>{'collection': 'news', 'docId': 'x', 'item': <String, dynamic>{}}),
    ];

    for (final entry in entries) {
      await navigator.pushNamed(entry.route, arguments: entry.arguments);
      await _settle(tester);
      expect(find.byType(ErrorWidget), findsNothing,
          reason: 'Screen for route "${entry.route}" threw a build/runtime error.');
      navigator.pop();
      await _settle(tester);
    }
  });
}

class _Entry {
  const _Entry(this.route, [this.arguments]);
  final String route;
  final Object? arguments;
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

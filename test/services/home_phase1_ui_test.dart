import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/theme/app_design_tokens.dart';
import 'package:qurity/core/theme/app_theme.dart';
import 'package:qurity/routes/app_routes.dart';
import 'package:qurity/widgets/global_nav_shell.dart';
import 'package:qurity/widgets/home_floating_nav_bar.dart';
import 'package:qurity/widgets/qarity_shimmer.dart';

void main() {
  test('AppThemeTokens extension is registered in light and dark themes', () {
    final lightTokens = AppTheme.lightTheme.extension<AppThemeTokens>();
    final darkTokens = AppTheme.darkTheme.extension<AppThemeTokens>();
    expect(lightTokens, isNotNull);
    expect(darkTokens, isNotNull);
    expect(lightTokens!.shimmerBase, isNot(darkTokens!.shimmerBase));
  });

  testWidgets('HomeFloatingNavBar renders all 5 tabs and triggers onHomeTap',
      (tester) async {
    var homeTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: const SizedBox.shrink(),
          bottomNavigationBar: HomeFloatingNavBar(
            onHomeTap: () => homeTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('السوق'), findsOneWidget);
    expect(find.text('الصفقات'), findsOneWidget);
    expect(find.text('المندرة'), findsOneWidget);
    expect(find.text('حسابي'), findsOneWidget);

    await tester.tap(find.text('الرئيسية'));
    await tester.pump();
    expect(homeTapped, isTrue);
  });

  testWidgets('QarityHorizontalShimmerList builds in light and dark themes',
      (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: QarityHorizontalShimmerList(),
          ),
        ),
      );
      expect(find.byType(QarityHorizontalShimmerList), findsOneWidget);
    }
  });

  testWidgets(
      'GlobalNavShell hides bar on auth/splash routes and shows it across app routes',
      (tester) async {
    final tracker = AppRouteTracker(initialRoute: AppRoutes.splash);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.lightTheme,
        home: GlobalNavShell(
          tracker: tracker,
          child: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );

    expect(find.byType(HomeFloatingNavBar), findsNothing);

    for (final hidden in [AppRoutes.login, AppRoutes.completeProfile]) {
      tracker.currentRoute.value = hidden;
      await tester.pump();
      expect(find.byType(HomeFloatingNavBar), findsNothing);
    }

    tracker.currentRoute.value = AppRoutes.home;
    await tester.pump();
    expect(find.byType(HomeFloatingNavBar), findsOneWidget);
    expect(
      tester.widget<HomeFloatingNavBar>(find.byType(HomeFloatingNavBar)).selectedIndex,
      0,
    );

    tracker.currentRoute.value = AppRoutes.marketTabs;
    await tester.pump();
    expect(find.byType(HomeFloatingNavBar), findsOneWidget);
    expect(
      tester.widget<HomeFloatingNavBar>(find.byType(HomeFloatingNavBar)).selectedIndex,
      1,
    );

    tracker.currentRoute.value = AppRoutes.forumPosts;
    await tester.pump();
    expect(find.byType(HomeFloatingNavBar), findsOneWidget);
    expect(
      tester.widget<HomeFloatingNavBar>(find.byType(HomeFloatingNavBar)).selectedIndex,
      3,
    );

    tracker.currentRoute.value = AppRoutes.newsList;
    await tester.pump();
    expect(find.byType(HomeFloatingNavBar), findsOneWidget);
    expect(
      tester.widget<HomeFloatingNavBar>(find.byType(HomeFloatingNavBar)).selectedIndex,
      0,
    );
  });
}

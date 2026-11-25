import 'package:flutter/material.dart';

import '../core/utils/navigator_key.dart';
import '../routes/app_routes.dart';
import 'home_floating_nav_bar.dart';

/// مراقب مسارات التطبيق لتحديث الشريط السفلي الدائم وتحديد التبويب النشط.
class AppRouteTracker extends NavigatorObserver {
  AppRouteTracker({String? initialRoute})
      : currentRoute = ValueNotifier<String?>(initialRoute);

  final ValueNotifier<String?> currentRoute;

  void _sync(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null) return;
    if (currentRoute.value != name) {
      // تأجيل التحديث لما بعد إطار البناء الحالي لتفادي setState أثناء البناء.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentRoute.value != name) {
          currentRoute.value = name;
        }
      });
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _sync(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _sync(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _sync(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _sync(previousRoute);
  }
}

/// المثيل العام لمراقب المسارات المستخدم في [MaterialApp.navigatorObservers].
final AppRouteTracker appRouteTracker =
    AppRouteTracker(initialRoute: AppRoutes.splash);

/// غلاف عام يثبّت [HomeFloatingNavBar] أسفل كافة صفحات التطبيق
/// باستثناء شاشات البداية وتسجيل الدخول وإكمال الملف الشخصي.
class GlobalNavShell extends StatelessWidget {
  const GlobalNavShell({
    super.key,
    required this.child,
    this.tracker,
    this.navigatorStateOverride,
  });

  final Widget child;
  final AppRouteTracker? tracker;
  final NavigatorState? navigatorStateOverride;

  /// دالة مساعدة تُستدعى عند الضغط على تبويب «الرئيسية» أثناء التواجد بها.
  static VoidCallback? homeScrollToTopCallback;

  static const Set<String> _hiddenRoutes = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.completeProfile,
  };

  static bool shouldShowForRoute(String? routeName) {
    if (routeName == null || routeName.isEmpty) return false;
    return !_hiddenRoutes.contains(routeName);
  }

  static int selectedIndexForRoute(String? routeName) {
    switch (routeName) {
      case AppRoutes.marketTabs:
      case AppRoutes.marketProducts:
      case AppRoutes.marketAdd:
      case AppRoutes.marketProductDetail:
      case AppRoutes.marketSellerDetail:
      case AppRoutes.marketSellerProfile:
      case AppRoutes.marketSellers:
      case AppRoutes.marketSellerGallery:
      case AppRoutes.marketSellerReviews:
        return 1;
      case AppRoutes.groupDeals:
        return 2;
      case AppRoutes.forumPosts:
      case AppRoutes.forumCreatePost:
      case AppRoutes.forumPostDetail:
        return 3;
      case AppRoutes.profileMain:
      case AppRoutes.favorites:
        return 4;
      default:
        return 0;
    }
  }

  NavigatorState? get _nav =>
      navigatorStateOverride ?? navigatorKey.currentState;

  void _navigateHome() {
    final nav = _nav;
    if (nav == null) return;
    final activeRoute = (tracker ?? appRouteTracker).currentRoute.value;
    if (activeRoute == AppRoutes.home) {
      homeScrollToTopCallback?.call();
      return;
    }
    nav.popUntil(
      (route) => route.settings.name == AppRoutes.home || route.isFirst,
    );
    homeScrollToTopCallback?.call();
  }

  void _navigateTab(String targetRoute, int targetIndex, String? activeRoute) {
    final nav = _nav;
    if (nav == null) return;
    if (activeRoute == targetRoute) return;
    if (selectedIndexForRoute(activeRoute) == targetIndex &&
        activeRoute == targetRoute) {
      return;
    }
    nav.pushNamed(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final activeTracker = tracker ?? appRouteTracker;
    return ValueListenableBuilder<String?>(
      valueListenable: activeTracker.currentRoute,
      builder: (context, routeName, _) {
        final showBar = shouldShowForRoute(routeName);
        final selectedIndex = selectedIndexForRoute(routeName);

        return Column(
          children: [
            Expanded(child: child),
            if (showBar)
              HomeFloatingNavBar(
                selectedIndex: selectedIndex,
                onHomeTap: _navigateHome,
                onMarketTap: () =>
                    _navigateTab(AppRoutes.marketTabs, 1, routeName),
                onDealsTap: () =>
                    _navigateTab(AppRoutes.groupDeals, 2, routeName),
                onForumTap: () =>
                    _navigateTab(AppRoutes.forumPosts, 3, routeName),
                onProfileTap: () =>
                    _navigateTab(AppRoutes.profileMain, 4, routeName),
              ),
          ],
        );
      },
    );
  }
}

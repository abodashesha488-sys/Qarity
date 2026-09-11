import 'package:flutter/material.dart';

import '../core/utils/helpers.dart';
import '../core/utils/navigator_key.dart';
import '../routes/app_routes.dart';

/// الحالة المشتركة للشريط السفلي العام: التبويب المختار + اسم المسار الحالي.
/// الشريط يُعرض عبر [GlobalBottomNavShell] أعلى الـNavigator في MaterialApp،
/// فيظهر في كل صفحات التطبيق ما عدا شاشات التدفق (splash/دخول/إكمال ملف).
class GlobalNav {
  GlobalNav._();

  static final ValueNotifier<int> tab = ValueNotifier<int>(0);
  static final ValueNotifier<String> route =
      ValueNotifier<String>(AppRoutes.splash);

  static final NavigatorObserver observer = _RouteTrackingObserver();

  static const _hiddenRoutes = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.completeProfile,
  };

  /// على الرئيسية يعرض [HomeScreen] شريطه الخاص (حتى لا يُقتطع الـdrawer خلف
  /// شريط خارجي)، لذا نخفي الغلاف العام هناك وفي شاشات التدفق فقط.
  static bool showBar(String routeName) =>
      routeName != AppRoutes.home && !_hiddenRoutes.contains(routeName);

  /// مسارات لها مكافئ مباشر في التبويبات — مزامنة الإضاءة عند فتحها.
  static int? _tabForRoute(String? name) {
    switch (name) {
      case AppRoutes.about:
        return 1;
      case AppRoutes.marketProducts:
      case AppRoutes.marketTabs:
        return 2;
      case AppRoutes.forumPosts:
        return 3;
      case AppRoutes.profileMain:
        return 4;
      default:
        return null;
    }
  }

  static void select(int index) {
    if (tab.value != index) {
      tab.value = index;
      AppHelpers.hapticLight();
    }
    // العودة لجذر الـNavigator (الرئيسية) مهما كان عمق الصفحة الحالية.
    navigatorKey.currentState?.popUntil((r) => r.isFirst);
  }
}

class _RouteTrackingObserver extends NavigatorObserver {
  void _track(Route<dynamic>? top) {
    final name = top?.settings.name;
    if (name == null || name.isEmpty) return;
    GlobalNav.route.value = name;
    final tabIndex = GlobalNav._tabForRoute(name);
    if (tabIndex != null) GlobalNav.tab.value = tabIndex;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _track(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _track(newRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _track(previousRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _track(previousRoute);
}

/// يغلّف كل شاشات التطبيق ويثبت شريط التنقل السفلي أسفلها جميعاً.
class GlobalBottomNavShell extends StatelessWidget {
  const GlobalBottomNavShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: GlobalNav.route,
      builder: (context, routeName, _) {
        if (!GlobalNav.showBar(routeName)) return child;
        return Scaffold(
          body: child,
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, -4))
            ]),
            child: ValueListenableBuilder<int>(
              valueListenable: GlobalNav.tab,
              builder: (context, selected, _) => NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: GlobalNav.select,
                animationDuration: const Duration(milliseconds: 400),
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'الرئيسية'),
                  NavigationDestination(
                      icon: Icon(Icons.villa_outlined),
                      selectedIcon: Icon(Icons.villa_rounded),
                      label: 'عن القرية'),
                  NavigationDestination(
                      icon: Icon(Icons.store_outlined),
                      selectedIcon: Icon(Icons.store_rounded),
                      label: 'السوق'),
                  NavigationDestination(
                      icon: Icon(Icons.forum_outlined),
                      selectedIcon: Icon(Icons.forum_rounded),
                      label: 'المنتدى'),
                  NavigationDestination(
                      icon: Icon(Icons.person_outlined),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'الملف'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

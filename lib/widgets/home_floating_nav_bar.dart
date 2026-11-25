import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_design_tokens.dart';
import '../routes/app_routes.dart';

/// شريط التنقل السفلي العائم العصري للشاشة الرئيسية.
/// يوفّر وصولاً فورياً بضغطة واحدة لأهم 5 محاور في التطبيق مع كبسولة
/// نشطة متدرجة وتأثير لمسي مريح.
class HomeFloatingNavBar extends StatelessWidget {
  const HomeFloatingNavBar({
    super.key,
    required this.onHomeTap,
    this.selectedIndex = 0,
    this.onMarketTap,
    this.onDealsTap,
    this.onForumTap,
    this.onProfileTap,
  });

  final VoidCallback onHomeTap;
  final int selectedIndex;
  final VoidCallback? onMarketTap;
  final VoidCallback? onDealsTap;
  final VoidCallback? onForumTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.28),
            ),
            boxShadow: AppShadows.floatingBar(isDark),
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'الرئيسية',
                selected: selectedIndex == 0,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onHomeTap();
                },
              ),
              _NavItem(
                icon: Icons.storefront_rounded,
                label: 'السوق',
                selected: selectedIndex == 1,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (onMarketTap != null) {
                    onMarketTap!();
                  } else {
                    Navigator.pushNamed(context, AppRoutes.marketTabs);
                  }
                },
              ),
              _CenterDealNavItem(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (onDealsTap != null) {
                    onDealsTap!();
                  } else {
                    Navigator.pushNamed(context, AppRoutes.groupDeals);
                  }
                },
              ),
              _NavItem(
                icon: Icons.forum_rounded,
                label: 'المندرة',
                selected: selectedIndex == 3,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (onForumTap != null) {
                    onForumTap!();
                  } else {
                    Navigator.pushNamed(context, AppRoutes.forumPosts);
                  }
                },
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'حسابي',
                selected: selectedIndex == 4,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (onProfileTap != null) {
                    onProfileTap!();
                  } else {
                    Navigator.pushNamed(context, AppRoutes.profileMain);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pillColor = selected
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.transparent;
    final fgColor =
        selected ? Colors.white : Colors.white.withValues(alpha: 0.78);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 21, color: fgColor),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterDealNavItem extends StatelessWidget {
  const _CenterDealNavItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      size: 21, color: Colors.white),
                  SizedBox(height: 1),
                  Text(
                    'الصفقات',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

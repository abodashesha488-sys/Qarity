import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../routes/app_routes.dart';
import '../../widgets/qurity_app_bar.dart';

/// بوابة خدمات المزارع — خمس خدمات بصور موحّدة مثل شبكة الصفحة الرئيسية.
/// منها صفحة «خدمات زراعية» المستقلة (سجل مقدّمي الخدمات الزراعية).
class FarmerServicesScreen extends StatelessWidget {
  const FarmerServicesScreen({super.key});

  static const _services = [
    _FarmerService(
      title: 'خدمات زراعية',
      route: AppRoutes.agriculturalServices,
      image: 'assets/images/tools.jpg',
      description: 'سجل مقدّمي الآلات والعمال والمعدات والخدمات الزراعية',
    ),
    _FarmerService(
      title: 'مستشارك الزراعي',
      route: AppRoutes.farmerAdvisor,
      image: 'assets/images/eng.jpg',
      description: 'إرشادات المحاصيل والتقويم الزراعي',
    ),
    _FarmerService(
      title: 'المحاصيل',
      route: AppRoutes.farmerCrops,
      image: 'assets/images/plant.jpg',
      description: 'دليل المحاصيل المصرية ومواسمها',
    ),
    _FarmerService(
      title: 'الأسمدة والمبيدات',
      route: AppRoutes.farmerFertilizersPesticides,
      image: 'assets/images/asmda.jpg',
      description: 'دليل التسميد والمكافحة المتكاملة',
    ),
    _FarmerService(
      title: 'أحوال الطقس',
      route: AppRoutes.farmerWeather,
      image: 'assets/images/taqs.jpg',
      description: 'الطقس الحالي وإرشادات المزارع',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const QurityAppBar(title: 'خدمات المزارع'),
      body: LayoutBuilder(builder: (context, constraints) {
        const spacing = 10.0;
        const hPadding = 14.0;
        final cardWidth = (constraints.maxWidth - (hPadding * 2) - spacing) / 2;

        // حساب النسبة بحيث تتسع الشاشة لـ 8 أيقونات (4 صفوف × 2 أعمدة) بالتساوي وبشكل مدمج
        final availableGridHeight = constraints.maxHeight - 65;
        final targetRowHeight = (availableGridHeight - (spacing * 3)) / 4;
        final childAspectRatio = (targetRowHeight > 75 && targetRowHeight < 240)
            ? (cardWidth / targetRowHeight).clamp(1.15, 1.36)
            : 1.25;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.agriculture_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'كل ما يحتاجه المزارع في مكان واحد',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(hPadding, 4, hPadding, 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < _services.length) {
                      return _ServiceTile(
                        service: _services[index],
                        index: index,
                      );
                    }
                    const icons = [
                      Icons.eco_outlined,
                      Icons.inventory_2_outlined,
                      Icons.auto_awesome_outlined,
                    ];
                    return _FarmerComingSoonTile(
                      index: index,
                      label: 'قريباً',
                      subtitle: 'خدمة زراعية جديدة',
                      icon: icons[(index - _services.length) % icons.length],
                    );
                  },
                  childCount: 8,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _FarmerComingSoonTile extends StatelessWidget {
  const _FarmerComingSoonTile({
    required this.index,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final int index;
  final String label;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const imgRadius = BorderRadius.all(Radius.circular(16));
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
            : theme.colorScheme.surface,
        borderRadius: imgRadius,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.22),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: imgRadius,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.agriculture_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'هذه الخدمة الزراعية قيد الإعداد وستتوفر قريباً لمزارعي القرية إن شاء الله',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 35).ms).fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.94, 0.94),
        );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.index});

  final _FarmerService service;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const imgRadius = BorderRadius.all(Radius.circular(16));
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: imgRadius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: imgRadius,
          onTap: () => Navigator.pushNamed(context, service.route),
          child: Image.asset(
            service.image,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            cacheWidth: 520,
            semanticLabel: '${service.title}: ${service.description}',
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(service.title, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 40).ms).fadeIn(duration: 350.ms).scale(
          begin: const Offset(0.93, 0.93),
        );
  }
}

class _FarmerService {
  const _FarmerService({
    required this.title,
    required this.route,
    required this.image,
    required this.description,
  });

  final String title;
  final String route;
  final String image;
  final String description;
}

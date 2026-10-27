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
        const spacing = 14.0;
        const hPadding = 16.0;
        const childAspectRatio = 0.89;
        final cardWidth = (constraints.maxWidth - (hPadding * 2) - spacing) / 2;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.agriculture_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'كل ما يحتاجه المزارع في مكان واحد',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(hPadding, 6, hPadding, 0),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ServiceTile(
                    service: _services[index],
                    index: index,
                  ),
                  childCount: 4,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(hPadding, spacing, hPadding, 24),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: SizedBox(
                    width: cardWidth,
                    child: AspectRatio(
                      aspectRatio: childAspectRatio,
                      child: _ServiceTile(
                        service: _services[4],
                        index: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
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
    const imgRadius = BorderRadius.all(Radius.circular(18));
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

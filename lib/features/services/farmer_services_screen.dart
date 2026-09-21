import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../routes/app_routes.dart';
import '../../widgets/qurity_app_bar.dart';

/// بوابة خدمات المزارع — خمس خدمات بصور موحّدة مثل شبكة الصفحة الرئيسية.
class FarmerServicesScreen extends StatelessWidget {
  const FarmerServicesScreen({super.key});

  static const _services = [
    _FarmerService(
      title: 'عمال ومعدات',
      route: AppRoutes.farmerWorkersEquipment,
      image: 'assets/images/tools.jpg',
      description: 'عمال، جرارات، معدات وخدمات الحقول',
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'كل ما يحتاجه المزارع في مكان واحد',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ServiceTile(
                  service: _services[index],
                  index: index,
                ),
                childCount: _services.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.index});

  final _FarmerService service;
  final int index;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          borderRadius: radius,
          onTap: () => Navigator.pushNamed(context, service.route),
          child: Image.asset(
            service.image,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            cacheWidth: 280,
            semanticLabel: '${service.title}: ${service.description}',
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(service.title, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 45).ms).fadeIn(duration: 350.ms).scale(
          begin: const Offset(0.92, 0.92),
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

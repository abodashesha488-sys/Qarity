import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/qurity_app_bar.dart';
import '../../widgets/village_ornament.dart';
import 'village_hub_card.dart';

const Color kVillageLifeColor = Color(0xFF1565C0);

/// «معالم وحياة القرية» — مركز المكان والحياة اليومية عبر الزمن:
/// المعالم، الخريطة، بالأمس واليوم، الزراعة، التعليم، التطور، المنشآت.
class VillageLifeScreen extends StatelessWidget {
  const VillageLifeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const QurityAppBar(
          title: 'معالم وحياة القرية', color: kVillageLifeColor),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const VillageSectionHeader(
            accent: kVillageLifeColor,
            title: 'معالم وحياة القرية',
            subtitle: 'أماكنها وملامحها… كيف عاشت وكيف تطورت عبر السنين',
            icon: Icons.location_city_rounded,
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                VillageHubCard(
                  color: const Color(0xFF00897B),
                  icon: Icons.mosque_rounded,
                  title: 'معالم القرية',
                  subtitle:
                      'الكوبري والمساجد والمدارس والمزرعة والجمعية ومركز الشباب…',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.villageLandmarks),
                ),
                VillageHubCard(
                  index: 1,
                  color: const Color(0xFF0277BD),
                  icon: Icons.map_rounded,
                  title: 'خريطة القرية',
                  subtitle: 'حدود القرية وأماكن أحيائها ومعالمها على الخريطة',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.villageMap),
                ),
                VillageHubCard(
                  index: 2,
                  color: const Color(0xFF8D6E63),
                  icon: Icons.compare_rounded,
                  title: 'بالأمس واليوم',
                  subtitle: 'صور متقابلة تُظهر كيف تغيّرت معالم القرية',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.villageBeforeAfter),
                ),
                VillageHubCard(
                  index: 3,
                  color: const Color(0xFF689F38),
                  icon: Icons.agriculture_rounded,
                  title: 'تاريخ الزراعة',
                  subtitle:
                      'الأرض والمحاصيل وأدوات الزراعة… من الساقية إلى الطلمبة',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.villageAgricultureHistory),
                ),
                VillageHubCard(
                  index: 4,
                  color: const Color(0xFF5E35B1),
                  icon: Icons.school_rounded,
                  title: 'التعليم في القرية',
                  subtitle: 'من الكتاتيب إلى المدارس الحديثة عبر الأجيال',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.villageEducationHistory),
                ),
                VillageHubCard(
                  index: 5,
                  color: const Color(0xFF00ACC1),
                  icon: Icons.trending_up_rounded,
                  title: 'القرية عبر التطور',
                  subtitle:
                      'مراحل تطور الحياة: الكهرباء والمياه والطرق والخدمات',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.villageDevelopment),
                ),
                VillageHubCard(
                  index: 6,
                  color: const Color(0xFF6D4C41),
                  icon: Icons.domain_rounded,
                  title: 'منشآت القرية',
                  subtitle: 'المدارس والوحدات والمساجد والجمعيات والمؤسسات',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.villageInstitutions),
                ),
                VillageHubCard(
                  index: 1,
                  color: const Color(0xFF2E7D32),
                  icon: Icons.emoji_events_rounded,
                  title: 'إنجازات القرية',
                  subtitle: 'شهادات تفوق ومراكز رياضية ونجاحات يفتخر بها الأهل',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.villageAchievements),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: OrnamentDivider(),
          ),
        ],
      ),
    );
  }
}

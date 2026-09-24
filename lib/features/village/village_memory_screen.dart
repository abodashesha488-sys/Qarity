import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/qurity_app_bar.dart';
import '../../widgets/village_ornament.dart';
import 'village_hub_card.dart';

const Color kVillageMemoryColor = Color(0xFF6A1B9A);

/// «ذاكرة القرية» — مركز الذكريات والمواد الموثقة:
/// الصور القديمة، حكايات أهل القرية، الوثائق، والفيديوهات.
class VillageMemoryScreen extends StatelessWidget {
  const VillageMemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          const QurityAppBar(title: 'ذاكرة القرية', color: kVillageMemoryColor),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const VillageSectionHeader(
            accent: kVillageMemoryColor,
            title: 'ذاكرة القرية',
            subtitle:
                'كل صورة وحكاية ووثيقة… شاهدٌ على حياة أبودشيشة عبر الزمن',
            icon: Icons.auto_stories_rounded,
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                VillageHubCard(
                  color: const Color(0xFF5D4037),
                  icon: Icons.photo_library_rounded,
                  title: 'الصور القديمة',
                  subtitle: 'صور البيوت والحقول والمناسبات والأماكن كما كانت',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.villageMemoryList,
                      arguments: 'photos'),
                ),
                VillageHubCard(
                  index: 1,
                  color: const Color(0xFFAD1457),
                  icon: Icons.record_voice_over_rounded,
                  title: 'حكايات أهل القرية',
                  subtitle:
                      'قصص يرويها الكبار وأحداث عاشتها القرية ومواقف لا تُنسى',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.villageMemoryList,
                      arguments: 'stories'),
                ),
                VillageHubCard(
                  index: 2,
                  color: const Color(0xFF1565C0),
                  icon: Icons.description_rounded,
                  title: 'الوثائق والمستندات',
                  subtitle: 'حجج وعقود وخطابات ووثائق رسمية تخص القرية وأهلها',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.villageMemoryList,
                      arguments: 'documents'),
                ),
                VillageHubCard(
                  index: 3,
                  color: const Color(0xFF00838F),
                  icon: Icons.videocam_rounded,
                  title: 'فيديوهات من الماضي والحاضر',
                  subtitle: 'تسجيلات مرئية توثق الحياة والمناسبات في القرية',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.villageMemoryList,
                      arguments: 'videos'),
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

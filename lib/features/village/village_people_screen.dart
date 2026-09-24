import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/qurity_app_bar.dart';
import '../../widgets/village_ornament.dart';
import 'village_hub_card.dart';

const Color kVillagePeopleColor = Color(0xFF00695C);

/// «أهل أبودشيشة» — مركز أبناء القرية:
/// العائلات، الشخصيات البارزة، صفحة الوفيات والتكريم، والشخصيات الموثقة.
class VillagePeopleScreen extends StatelessWidget {
  const VillagePeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          const QurityAppBar(title: 'أهل أبودشيشة', color: kVillagePeopleColor),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const VillageSectionHeader(
            accent: kVillagePeopleColor,
            title: 'أهل أبودشيشة',
            subtitle: 'أهلُها… عائلاتها ورجالها ومن رحلوا وتركوا أثراً',
            icon: Icons.family_restroom_rounded,
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                VillageHubCard(
                  color: const Color(0xFF2E7D32),
                  icon: Icons.diversity_3_rounded,
                  title: 'العائلات',
                  subtitle: 'قائمة عائلات القرية وأصولها وفروعها وتاريخها',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.villageFamily),
                ),
                VillageHubCard(
                  index: 1,
                  color: const Color(0xFFEF6C00),
                  icon: Icons.workspace_premium_rounded,
                  title: 'الشخصيات البارزة',
                  subtitle:
                      'مشايخ وعلماء وأطباء ومهندسون وضباط وسياسيون من أبناء القرية',
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.villageNotablePeople),
                ),
                VillageHubCard(
                  index: 2,
                  color: const Color(0xFF455A64),
                  icon: Icons.spa_rounded,
                  title: 'صفحة الوفيات والتكريم',
                  subtitle:
                      'وفاءً لمن رحلوا… أسماؤهم وسيرهم محفوظة في ذاكرة القرية',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.villageMemorial),
                ),
                VillageHubCard(
                  index: 3,
                  color: const Color(0xFF6A1B9A),
                  icon: Icons.history_edu_rounded,
                  title: 'شخصيات عبر التاريخ',
                  subtitle:
                      'العمدة والمشايخ والنواب والشخصيات المؤثرة موثقة بالصور',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.villageArchive),
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

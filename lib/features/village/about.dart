import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../models/data_models.dart';
import '../../models/village_content_models.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/village_extended_service.dart';
import '../../services/village_info_service.dart';
import '../../widgets/offline_stream_builder.dart';
import '../../widgets/qurity_app_bar.dart';
import '../../widgets/village_ornament.dart';
import 'village_content_admin.dart';
import 'village_contribution_screen.dart';
import 'village_hub_card.dart';

Color get kVillageAboutColor => AppColors.primary;

/// «تعرف على القرية» — المركز الرئيسي لمرجع قرية أبودشيشة:
/// واجهة تنقّل سريعة واحترافية وبطاقات أيقونات لأقسام القرية:
/// (التاريخ، الذاكرة، الأهالي، التراث، المعالم والحياة، الخريطة)
/// + بطاقة هوية القرية مدمجة بالهيرو + بوابة المساهمة الأهلية + مراجعة الإدارة.
class VillageScreen extends StatefulWidget {
  const VillageScreen({super.key, this.initialTab = 'all'});

  final String initialTab;

  @override
  State<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends State<VillageScreen> {
  final VillageInfoService _infoService = VillageInfoService();
  final VillageExtendedService _extService = VillageExtendedService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _infoService.seedIfEmpty().catchError((_) {});
    canManageVillageContent().then((v) {
      if (mounted) setState(() => _isAdmin = v);
    });

    if (widget.initialTab != 'all') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleInitialTabRoute(widget.initialTab);
      });
    }
  }

  void _handleInitialTabRoute(String tab) {
    switch (tab) {
      case 'story':
        _open(AppRoutes.villageHistory);
        break;
      case 'videos':
        _open(AppRoutes.villageMemory);
        break;
      case 'landmarks':
        _open(AppRoutes.villageLife);
        break;
      case 'people':
        _open(AppRoutes.villagePeople);
        break;
      case 'heritage':
        _open(AppRoutes.villageHeritage);
        break;
    }
  }

  void _open(String route) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QurityAppBar(
        title: 'تعرف على القرية',
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.rule_folder_outlined, color: Colors.amber),
              tooltip: 'مراجعة مساهمات القرية',
              onPressed: () => _open(AppRoutes.villageContributionsReview),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          // ── ١. الترويسة الفنية الجامعة بصورة القرية والنقش الإسلامي وبطاقة الهوية ──
          _AboutHero(
            isAdmin: _isAdmin,
            onIdentityTap: () => _open(AppRoutes.villageProfile),
          ),

          const SizedBox(height: 14),

          // ── ٢. عنوان أقسام المرجع الرقمي ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: _SectionLabel(
              icon: Icons.account_tree_outlined,
              label: 'أقسام المرجع الرقمي',
            ),
          ),

          const SizedBox(height: 10),

          // ── ٣. بطاقات التنقل المبسطة للأقسام الستة الأساسية ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final (i, entry) in _entries.indexed)
                  VillageHubCard(
                    index: i,
                    color: entry.color,
                    icon: entry.icon,
                    title: entry.title,
                    subtitle: entry.subtitle,
                    onTap: () => _open(entry.route),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── ٤. دعوة المشاركة المجتمعية: ساهم في ذاكرة القرية ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ContributeCta(
              onTap: () => _open(AppRoutes.villageContribute),
            ),
          ),

          // ── ٥. شريط المساهمات المثبتة للأهالي ──
          _PinnedContributions(
            service: _extService,
            onOpenArchive: () => _open(AppRoutes.villageDigitalArchive),
          ),

          // ── ٦. بطاقة وصول سريع للمشرف وأدمن التراث ──
          if (_isAdmin) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AdminReviewCard(
                onTap: () => _open(AppRoutes.villageContributionsReview),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── ٧. التذييل الزخرفي ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: OrnamentDivider(),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'مرجع قرية أبودشيشة الرقمي — الذاكرة تُبنى وتُخلّد بمساهمة أهلها 💙\n'
              'كل مادة تُراجع قبل النشر وتُنسب لصاحبها.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.75,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ترويسة المركز: صورة القرية + نقش إسلامي + عنوان + معلومات سريعة وزر تعديل للإدارة.
class _AboutHero extends StatelessWidget {
  const _AboutHero({required this.isAdmin, required this.onIdentityTap});

  final bool isAdmin;
  final VoidCallback onIdentityTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // الخلفية: صورة القرية 0.jpg مع تدرّج داكن دافئ
        Positioned.fill(
          child: Image.asset(
            'assets/images/0.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: kVillageAboutColor.withValues(alpha: 0.9)),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kVillageAboutColor.withValues(alpha: 0.72),
                  const Color(0xFF2B1B0E).withValues(alpha: 0.94),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: GeoPatternPainter()),
        ),
        OfflineStreamBuilder<VillageInfo?>(
          stream: VillageInfoService().getInfoStream(),
          onlineBuilder: (context, snapshot) =>
              _buildContent(context, snapshot.data),
          cacheBuilder: (context) => FutureBuilder<VillageInfo?>(
            future: CacheService.getVillageInfo().then((map) =>
                map == null ? null : VillageInfo.fromJson(map, 'main')),
            builder: (context, snapshot) =>
                _buildContent(context, snapshot.data),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildContent(BuildContext context, VillageInfo? info) {
    final title = (info?.name.isNotEmpty ?? false) ? info!.name : 'أبودشيشة';
    final desc = (info?.description.isNotEmpty ?? false)
        ? info!.description
        : 'قرية مصرية عريقة تتبع مركز بلقاس بمحافظة الدقهلية، تتميز بتاريخها وتراثها الأصيل وأهلها الكرام.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: VillageOrnament.amiri(size: 34)
                      .copyWith(color: Colors.white, height: 1.1),
                ),
              ),
              if (isAdmin)
                Material(
                  color: Colors.white24,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'تعديل بيانات تعريف القرية',
                    icon: const Icon(Icons.edit_rounded,
                        size: 18, color: Color(0xFFFFD54F)),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) => VillageIntroForm(info: info),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: VillageOrnament.gold.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: VillageOrnament.gold.withValues(alpha: 0.65),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_stories_rounded,
                    size: 13, color: Color(0xFFFFD54F)),
                SizedBox(width: 5),
                Text(
                  'المرجع والتاريخ الرقمي للقرية',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.55,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (info != null &&
              (info.population.isNotEmpty ||
                  info.area.isNotEmpty ||
                  info.founded.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (info.population.isNotEmpty)
                  _HeroStatBadge(
                    icon: Icons.groups_rounded,
                    text: 'السكان: ${info.population}',
                  ),
                if (info.area.isNotEmpty)
                  _HeroStatBadge(
                    icon: Icons.square_foot_rounded,
                    text: 'المساحة: ${info.area}',
                  ),
                if (info.founded.isNotEmpty)
                  _HeroStatBadge(
                    icon: Icons.event_available_rounded,
                    text: 'التأسيس: ${info.founded}',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.20),
              foregroundColor: Colors.white,
              side: BorderSide(
                color: VillageOrnament.gold.withValues(alpha: 0.75),
                width: 1.1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: onIdentityTap,
            icon: const Icon(Icons.badge_outlined,
                size: 16, color: Color(0xFFFFD54F)),
            label: const Text(
              'عن القرية وتاريخ تسميتها',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatBadge extends StatelessWidget {
  const _HeroStatBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFFFD54F)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// عنوان قسم صغير بأيقونة ذهبية.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: VillageOrnament.goldDark),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 10),
        const Expanded(child: OrnamentDivider()),
      ],
    );
  }
}

/// بوابة «ساهم في ذاكرة القرية» — نداء دائم وواضح وبسيط لأهل القرية.
class _ContributeCta extends StatelessWidget {
  const _ContributeCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFF57C00), Color(0xFFD97706)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x35F57C00),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volunteer_activism_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شارك في ذاكرة القرية',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'عندك صورة قديمة، حكاية أو وثيقة من زمان؟ اضغط هنا وشاركها معنا',
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.4,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شريط عرض المساهمات الأهلية المعتمدة والمثبّتة.
class _PinnedContributions extends StatelessWidget {
  const _PinnedContributions(
      {required this.service, required this.onOpenArchive});

  final VillageExtendedService service;
  final VoidCallback onOpenArchive;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VillageContribution>>(
      stream: service.watchPinnedContributions(),
      builder: (context, snapshot) {
        final items = (snapshot.data ?? const <VillageContribution>[])
            .take(6)
            .toList(growable: false);
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: _SectionLabel(
                icon: Icons.push_pin_rounded,
                label: 'من مساهمات الأهالي الموثقة',
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 176,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _PinnedContributionCard(
                  item: items[i],
                  onTap: onOpenArchive,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PinnedContributionCard extends StatelessWidget {
  const _PinnedContributionCard({required this.item, required this.onTap});

  final VillageContribution item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = ContributionType.of(item.type);
    return SizedBox(
      width: 160,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: VillageOrnament.gold.withValues(alpha: 0.5), width: 1.2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: item.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        height: 92,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _typeBanner(type),
                      )
                    : _typeBanner(type),
              ),
              Padding(
                padding: const EdgeInsets.all(9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      '${type.label} · ${item.userName.isNotEmpty ? item.userName : 'مساهم'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 9.5,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBanner(ContributionType type) => Container(
        height: 92,
        width: double.infinity,
        color: type.color.withValues(alpha: 0.14),
        child: Icon(type.icon, size: 30, color: type.color),
      );
}

/// بطاقة إدارية للمراجعة (تظهر للأدمن وأدمن التراث فقط).
class _AdminReviewCard extends StatelessWidget {
  const _AdminReviewCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kVillageContribColor.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: kVillageContribColor.withValues(alpha: 0.12),
              shape: BoxShape.circle),
          child: const Icon(Icons.rule_folder_outlined,
              size: 18, color: kVillageContribColor),
        ),
        title: const Text('مراجعة مساهمات الأهالي',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        subtitle: const Text(
            'اعتماد / رفض / تثبيت على الرئيسية / إشعار المساهم',
            style: TextStyle(fontSize: 10.5)),
        trailing: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }
}

/// مدخل واحد من مداخل المرجع الأساسية.
class _VillageEntry {
  const _VillageEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
}

/// الأقسام الستة الأساسية لمرجع القرية (مبسطة، غير مكررة، وواضحة جداً)
List<_VillageEntry> get _entries => const [
  _VillageEntry(
    title: 'تاريخ القرية',
    subtitle: 'نشأة القرية، العصور والأحداث الكبرى في خط زمني',
    icon: Icons.history_edu_rounded,
    color: Color(0xFF5D4037),
    route: AppRoutes.villageHistory,
  ),
  _VillageEntry(
    title: 'ذاكرة وفيديوهات القرية',
    subtitle: 'الصور القديمة، حكايات الأجداد، الوثائق، وفيديوهات الماضي',
    icon: Icons.auto_stories_rounded,
    color: Color(0xFF6A1B9A),
    route: AppRoutes.villageMemory,
  ),
  _VillageEntry(
    title: 'أهل وعائلات أبودشيشة',
    subtitle: 'عائلات القرية، الشخصيات البارزة وسجل الراحلين',
    icon: Icons.family_restroom_rounded,
    color: Color(0xFF00695C),
    route: AppRoutes.villagePeople,
  ),
  _VillageEntry(
    title: 'تراث وعادات القرية',
    subtitle: 'العادات والتقاليد، المأكولات، الأمثال الشعبية والحرف القديمة',
    icon: Icons.festival_rounded,
    color: Color(0xFFBF360C),
    route: AppRoutes.villageHeritage,
  ),
  _VillageEntry(
    title: 'معالم ومؤسسات القرية',
    subtitle: 'المساجد، المدارس، المؤسسات الخدمية، والزراعة قديماً وحديثاً',
    icon: Icons.location_city_rounded,
    color: Color(0xFF1565C0),
    route: AppRoutes.villageLife,
  ),
  _VillageEntry(
    title: 'خريطة القرية',
    subtitle: 'معالم أبودشيشة الجغرافية ومواقعها الحية على الخريطة',
    icon: Icons.map_rounded,
    color: Color(0xFF2E7D32),
    route: AppRoutes.villageMap,
  ),
];

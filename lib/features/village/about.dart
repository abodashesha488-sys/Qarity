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
/// (عن أبودشيشة، التاريخ، الذاكرة، الأهالي، التراث، المعالم والحياة،
/// الخريطة، المناسبات، الأرشيف) + بطاقة هوية القرية + بوابة المساهمة
/// الأهلية + شريط المساهمات المثبّتة + مدخل المراجعة للإدارة.
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

    // إذا تم استدعاء الشاشة مع تحديد تبويب معيّن من مسار فرعي
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
          // ── ١. الترويسة الفنية بصورة القرية والنقش الإسلامي ──
          _AboutHero(onIdentityTap: () => _open(AppRoutes.villageProfile)),

          // ── ٢. بطاقة هوية ونظرة سريعة على القرية ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: _VillageIdCard(onTap: () => _open(AppRoutes.villageProfile)),
          ),

          const SizedBox(height: 12),

          // ── ٣. عنوان أقسام المرجع الرقمي ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: _SectionLabel(
              icon: Icons.account_tree_outlined,
              label: 'أقسام المرجع الرقمي',
            ),
          ),

          const SizedBox(height: 10),

          // ── ٤. بطاقات وأيقونات التنقل لأقسام القرية ──
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

          const SizedBox(height: 12),

          // ── ٥. دعوة المشاركة المجتمعية: ساهم في ذاكرة القرية ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ContributeCta(
              onTap: () => _open(AppRoutes.villageContribute),
            ),
          ),

          // ── ٦. شريط المساهمات المثبتة للأهالي ──
          _PinnedContributions(
            service: _extService,
            onOpenArchive: () => _open(AppRoutes.villageDigitalArchive),
          ),

          // ── ٧. بطاقة وصول سريع للمشرف / الأدمن ──
          if (_isAdmin) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AdminReviewCard(
                onTap: () => _open(AppRoutes.villageContributionsReview),
              ),
            ),
          ],

          const SizedBox(height: 26),

          // ── ٨. التذييل الزخرفي ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: OrnamentDivider(),
          ),
          const SizedBox(height: 14),
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

/// ترويسة المركز: صورة القرية + نقش إسلامي + عنوان بخط أميري.
class _AboutHero extends StatelessWidget {
  const _AboutHero({required this.onIdentityTap});

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
                  const Color(0xFF2B1B0E).withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: GeoPatternPainter()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أبودشيشة',
                style: VillageOrnament.amiri(size: 36)
                    .copyWith(color: Colors.white, height: 1.1),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: VillageOrnament.gold.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: VillageOrnament.gold.withValues(alpha: 0.65),
                      width: 1.1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories_rounded,
                        size: 14, color: Color(0xFFFFD54F)),
                    SizedBox(width: 6),
                    Text(
                      'الذاكرة والمرجع الرقمي لقرية أبودشيشة',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'تاريخ • أهل • تراث • معالم • أرشيف مصوّر وموثّق',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.6,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                  side: BorderSide(
                      color: VillageOrnament.gold.withValues(alpha: 0.7),
                      width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: onIdentityTap,
                icon: const Icon(Icons.badge_outlined,
                    size: 18, color: Color(0xFFFFD54F)),
                label: const Text(
                  'بطاقة تعريف القرية',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
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

/// بطاقة تعريف القرية السريعة (من `village_info/main`) مع رابط للتفاصيل.
class _VillageIdCard extends StatelessWidget {
  const _VillageIdCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: kVillageAboutColor.withValues(alpha: 0.18),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: OfflineStreamBuilder<VillageInfo?>(
          stream: VillageInfoService().getInfoStream(),
          onlineBuilder: (context, snapshot) =>
              _buildBody(context, snapshot.data),
          cacheBuilder: (context) => FutureBuilder<VillageInfo?>(
            future: CacheService.getVillageInfo().then(
                (map) => map == null ? null : VillageInfo.fromJson(map, 'main')),
            builder: (context, snapshot) => _buildBody(context, snapshot.data),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, VillageInfo? info) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: kVillageAboutColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.badge_outlined,
                    size: 18, color: kVillageAboutColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (info?.name.isNotEmpty ?? false)
                      ? info!.name
                      : 'قرية أبودشيشة',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (info?.description.isNotEmpty ?? false)
                ? info!.description
                : 'قرية مصرية عريقة تتبع مركز بلقاس بمحافظة الدقهلية، تتميز بتاريخها وتراثها الأصيل وأهلها الطيبين.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (info != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (info.population.isNotEmpty)
                  _IdChip(icon: Icons.groups_rounded, text: info.population),
                if (info.area.isNotEmpty)
                  _IdChip(icon: Icons.square_foot_rounded, text: info.area),
                if (info.founded.isNotEmpty)
                  _IdChip(
                      icon: Icons.event_available_rounded, text: info.founded),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _IdChip extends StatelessWidget {
  const _IdChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kVillageAboutColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kVillageAboutColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: kVillageAboutColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: kVillageAboutColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// بوابة «ساهم في ذاكرة القرية» — نداء دائم في أسفل قائمة الأقسام.
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
          padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volunteer_activism_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ساهم في ذاكرة القرية',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'شارك بصورة، قصة، وثيقة قديمة أو ذكرى من ماضي القرية',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.45,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.white),
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

/// بطاقة إدارية للمراجعة (تظهر للأدمن فقط).
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

/// مدخل واحد من مداخل المرجع (بيانات ثابتة — لا نصوص تُخترع).
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

List<_VillageEntry> get _entries => [
  _VillageEntry(
    title: 'عن أبودشيشة',
    subtitle: 'بطاقة تعريف القرية: الاسم والموقع والسكان والمساحة',
    icon: Icons.menu_book_rounded,
    color: AppColors.primary,
    route: AppRoutes.villageProfile,
  ),
  const _VillageEntry(
    title: 'تاريخ القرية',
    subtitle: 'العصور والأحداث الكبرى في خط زمني ذهبي',
    icon: Icons.history_edu_rounded,
    color: Color(0xFF5D4037),
    route: AppRoutes.villageHistory,
  ),
  const _VillageEntry(
    title: 'ذاكرة القرية',
    subtitle: 'الصور القديمة والحكايات والوثائق والفيديوهات',
    icon: Icons.auto_stories_rounded,
    color: Color(0xFF6A1B9A),
    route: AppRoutes.villageMemory,
  ),
  const _VillageEntry(
    title: 'أهل أبودشيشة',
    subtitle: 'العائلات والشخصيات البارزة وسجل الراحلين',
    icon: Icons.family_restroom_rounded,
    color: Color(0xFF00695C),
    route: AppRoutes.villagePeople,
  ),
  const _VillageEntry(
    title: 'تراث القرية',
    subtitle: 'العادات والتقاليد والمأكولات والأمثال والحرف',
    icon: Icons.festival_rounded,
    color: Color(0xFFBF360C),
    route: AppRoutes.villageHeritage,
  ),
  const _VillageEntry(
    title: 'معالم وحياة القرية',
    subtitle: 'المعالم والخدمات والزراعة والتعليم والتطور',
    icon: Icons.location_city_rounded,
    color: Color(0xFF1565C0),
    route: AppRoutes.villageLife,
  ),
  const _VillageEntry(
    title: 'خريطة القرية',
    subtitle: 'معالم أبودشيشة الجغرافية ومواقعها على الخريطة',
    icon: Icons.map_rounded,
    color: Color(0xFF2E7D32),
    route: AppRoutes.villageMap,
  ),
  const _VillageEntry(
    title: 'المناسبات والأعراس',
    subtitle: 'أفراح القرية وطقوس مناسباتها السعيدة',
    icon: Icons.celebration_rounded,
    color: Color(0xFFAD1457),
    route: AppRoutes.occasionsList,
  ),
  const _VillageEntry(
    title: 'الأرشيف الرقمي',
    subtitle: 'مكتبة موحّدة لكل مواد المرجع مع بحث وفلترة',
    icon: Icons.inventory_2_rounded,
    color: Color(0xFF37474F),
    route: AppRoutes.villageDigitalArchive,
  ),
];

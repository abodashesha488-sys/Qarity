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
import 'village_extended_admin.dart';

Color get kVillageAboutColor => AppColors.primary;

/// «تعرف على القرية» — الموسوعة والرابط الرقمي الشامل لقرية أبودشيشة:
/// واجهة عصرية بتنسيق شبكي تفاعلي 2×3، هيرو فخم بالهوية والإحصائيات،
/// شريط استكشاف سريع، لوحة تحكم إدارية فورية للأدمن العام وأدمن التراث،
/// وبوابة مساهمة مجتمعية بمراحل تدقيق واعتماد واضحة وموثوقة.
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
  VillageInfo? _currentInfo;

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

  Future<void> _openFormSheet(Widget form) async {
    HapticFeedback.mediumImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(child: form),
      ),
    );
  }

  void _showQuickAddSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.post_add_rounded,
                        color: Colors.amber, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إضافة سجل فوري للموسوعة',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'اختر القسم لإدخال المادة واعتمادها فوراً',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _QuickAddTile(
                      icon: Icons.history_edu_rounded,
                      color: const Color(0xFF5D4037),
                      title: 'عصر تاريخي جديد',
                      subtitle: 'إضافة حقبة أو عصر في تاريخ القرية',
                      onTap: () {
                        Navigator.pop(ctx);
                        _openFormSheet(const HistoryEraForm());
                      },
                    ),
                    _QuickAddTile(
                      icon: Icons.family_restroom_rounded,
                      color: const Color(0xFF00695C),
                      title: 'عائلة جديدة من عائلات القرية',
                      subtitle: 'توثيق أصل عائلة، فروعها ومنازلها',
                      onTap: () {
                        Navigator.pop(ctx);
                        _openFormSheet(const FamilyForm());
                      },
                    ),
                    _QuickAddTile(
                      icon: Icons.military_tech_rounded,
                      color: const Color(0xFFC2185B),
                      title: 'شخصية بارزة',
                      subtitle: 'توثيق مسيرة أحد أعلام وشخصيات القرية',
                      onTap: () {
                        Navigator.pop(ctx);
                        _openFormSheet(const NotablePersonForm());
                      },
                    ),
                    _QuickAddTile(
                      icon: Icons.photo_library_outlined,
                      color: const Color(0xFF6A1B9A),
                      title: 'مادة أرشيفية (صورة / وثيقة)',
                      subtitle: 'إضافة صورة قديمة أو وثيقة نادرة للأرشيف',
                      onTap: () {
                        Navigator.pop(ctx);
                        _openFormSheet(const ArchiveItemForm());
                      },
                    ),
                    _QuickAddTile(
                      icon: Icons.festival_rounded,
                      color: const Color(0xFFBF360C),
                      title: 'مادة تراثية أو مثل شعبي',
                      subtitle: 'عادات، مأكولات شعبية، أمثال، أو حرف قديمة',
                      onTap: () {
                        Navigator.pop(ctx);
                        _openFormSheet(const HeritageForm());
                      },
                    ),
                    _QuickAddTile(
                      icon: Icons.location_on_rounded,
                      color: const Color(0xFF2E7D32),
                      title: 'مَعلَم جغرافي أو أثري',
                      subtitle: 'توثيق موقع مَعلَم وإحداثياته',
                      onTap: () {
                        Navigator.pop(ctx);
                        _openFormSheet(const LandmarkForm());
                      },
                    ),
                    _QuickAddTile(
                      icon: Icons.location_city_rounded,
                      color: const Color(0xFF1565C0),
                      title: 'منشأة أو مؤسسة خدمية',
                      subtitle: 'إضافة مركز شباب، وحدة صحية، مدرسة، مسجد…',
                      onTap: () {
                        Navigator.pop(ctx);
                        _openFormSheet(const InstitutionForm());
                      },
                    ),
                    _QuickAddTile(
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF455A64),
                      title: 'سيرة في ذاكرة القرية',
                      subtitle: 'توثيق مسيرة أحد الراحلين في ذاكرة أبودشيشة',
                      onTap: () {
                        Navigator.pop(ctx);
                        _openFormSheet(const MemorialPersonForm());
                      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QurityAppBar(
        title: 'تعرف على القرية',
        actions: [
          if (_isAdmin) ...[
            StreamBuilder<List<VillageContribution>>(
              stream: _extService.watchPendingContributions(),
              builder: (context, snapshot) {
                final pendingCount = (snapshot.data ?? const []).length;
                return IconButton(
                  icon: Badge(
                    isLabelVisible: pendingCount > 0,
                    label: Text(
                      '$pendingCount',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.rule_folder_outlined,
                        color: Colors.amber),
                  ),
                  tooltip: 'مراجعة مساهمات القرية ($pendingCount معلقة)',
                  onPressed: () => _open(AppRoutes.villageContributionsReview),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: Colors.amber),
              tooltip: 'إضافة سجل فوري للموسوعة',
              onPressed: _showQuickAddSheet,
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          // ── ١. الترويسة الفنية الجامعة بصورة القرية والنقش الإسلامي وبطاقة الهوية ──
          _AboutHero(
            isAdmin: _isAdmin,
            onInfoLoaded: (info) => _currentInfo = info,
            onEditIntro: (info) => _openFormSheet(VillageIntroForm(info: info)),
            onIdentityTap: () => _open(AppRoutes.villageProfile),
          ),

          const SizedBox(height: 12),

          // ── ٢. لوحة الإدارة السريعة الفورية (تظهر للأدمن العام وأدمن التراث فقط) ──
          if (_isAdmin) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AdminDirectToolbar(
                extService: _extService,
                onEditIntro: () =>
                    _openFormSheet(VillageIntroForm(info: _currentInfo)),
                onReview: () => _open(AppRoutes.villageContributionsReview),
                onQuickAdd: _showQuickAddSheet,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── ٣. شريط الاستكشاف السريع (كبسولات أفقية أنيقة) ──
          _QuickExplorationBar(
            onOpenMap: () => _open(AppRoutes.villageMap),
            onOpenFacilities: () => _open(AppRoutes.villageFacilities),
            onOpenFamilies: () => _open(AppRoutes.villagePeople),
            onOpenArchive: () => _open(AppRoutes.villageDigitalArchive),
          ),

          const SizedBox(height: 14),

          // ── ٤. عنوان شبكة أقسام المرجع الرقمي ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: _SectionLabel(
              icon: Icons.account_tree_outlined,
              label: 'أقسام الموسوعة والمرجع الرقمي',
            ),
          ),

          const SizedBox(height: 10),

          // ── ٥. شبكة ٢×٣ العصرية المتناسقة لأقسام الموسوعة الستة ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ModernGrid2x3(
              isAdmin: _isAdmin,
              onOpen: _open,
              onQuickAdd: _showQuickAddSheet,
            ),
          ),

          const SizedBox(height: 16),

          // ── ٦. بوابة مساهمة الأهالي المحفزة: خطوات توثيق واضحة ومضمونة ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _CommunityContributionSection(
              onContribute: () => _open(AppRoutes.villageContribute),
              onBrowseArchive: () => _open(AppRoutes.villageDigitalArchive),
            ),
          ),

          // ── ٧. شريط المعروضات والمساهمات المثبتة للأهالي في الأرشيف ──
          _PinnedContributions(
            service: _extService,
            onOpenArchive: () => _open(AppRoutes.villageDigitalArchive),
          ),

          const SizedBox(height: 24),

          // ── ٨. التذييل الزخرفي ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: OrnamentDivider(),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'موسوعة ومرجع قرية أبودشيشة الرقمي — الذاكرة تُبنى وتُخلّد بمساهمة أهلها 💙\n'
              'كل مساهمة تُدقق وتُعتمد من إدارة التراث وتُنشر منسوبة لصاحبها.',
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

/// كارت خيار إضافة سجل فوري داخل البوتوم شيت
class _QuickAddTile extends StatelessWidget {
  const _QuickAddTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_left_rounded, size: 20),
      onTap: onTap,
    );
  }
}

/// ترويسة المركز: صورة القرية 0.jpg + نقش إسلامي + عنوان + إحصائيات ثلاثية فخمة وزر تعديل فوري.
class _AboutHero extends StatelessWidget {
  const _AboutHero({
    required this.isAdmin,
    required this.onInfoLoaded,
    required this.onEditIntro,
    required this.onIdentityTap,
  });

  final bool isAdmin;
  final ValueChanged<VillageInfo?> onInfoLoaded;
  final ValueChanged<VillageInfo?> onEditIntro;
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
                  const Color(0xFF2B1B0E).withValues(alpha: 0.95),
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
          onlineBuilder: (context, snapshot) {
            onInfoLoaded(snapshot.data);
            return _buildContent(context, snapshot.data);
          },
          cacheBuilder: (context) => FutureBuilder<VillageInfo?>(
            future: CacheService.getVillageInfo().then((map) =>
                map == null ? null : VillageInfo.fromJson(map, 'main')),
            builder: (context, snapshot) {
              onInfoLoaded(snapshot.data);
              return _buildContent(context, snapshot.data);
            },
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

    final population =
        (info?.population.isNotEmpty ?? false) ? info!.population : '—';
    final area = (info?.area.isNotEmpty ?? false) ? info!.area : '—';
    final founded = (info?.founded.isNotEmpty ?? false) ? info!.founded : '—';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                    tooltip: 'تعديل بيانات تعريف القرية فوراً',
                    icon: const Icon(Icons.edit_rounded,
                        size: 20, color: Color(0xFFFFD54F)),
                    onPressed: () => onEditIntro(info),
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
                  'الموسوعة والتاريخ الرقمي للقرية',
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
          const SizedBox(height: 14),

          // بطاقة الإحصائيات الثلاثية الفخمة (السكان | المساحة | التأسيس)
          Row(
            children: [
              Expanded(
                child: _HeroStatCapsule(
                  icon: Icons.groups_rounded,
                  label: 'السكان',
                  value: population,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStatCapsule(
                  icon: Icons.square_foot_rounded,
                  label: 'المساحة',
                  value: area,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStatCapsule(
                  icon: Icons.history_edu_rounded,
                  label: 'التأسيس',
                  value: founded,
                ),
              ),
            ],
          ),

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

/// كبسولة إحصائية زجاجية فخمة في ترويسة الهيرو
class _HeroStatCapsule extends StatelessWidget {
  const _HeroStatCapsule({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: VillageOrnament.gold.withValues(alpha: 0.35),
          width: 0.9,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: const Color(0xFFFFD54F)),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// شريط التحكم والإدارة المباشر (يظهر للأدمن العام وأدمن التراث فقط)
class _AdminDirectToolbar extends StatelessWidget {
  const _AdminDirectToolbar({
    required this.extService,
    required this.onEditIntro,
    required this.onReview,
    required this.onQuickAdd,
  });

  final VillageExtendedService extService;
  final VoidCallback onEditIntro;
  final VoidCallback onReview;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.amber.shade700.withValues(alpha: 0.40),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.amber.shade800, size: 18),
              const SizedBox(width: 6),
              Text(
                'لوحة التحكم السريعة بالموسوعة والتراث',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.amber.shade900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'أدمن التراث',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AdminToolbarButton(
                  icon: Icons.edit_note_rounded,
                  label: 'تعديل الهوية',
                  color: Colors.brown.shade700,
                  onTap: onEditIntro,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StreamBuilder<List<VillageContribution>>(
                  stream: extService.watchPendingContributions(),
                  builder: (context, snapshot) {
                    final count = (snapshot.data ?? const []).length;
                    return _AdminToolbarButton(
                      icon: Icons.rule_folder_outlined,
                      label: count > 0 ? 'مراجعة ($count)' : 'المراجعة',
                      badgeCount: count,
                      color: Colors.teal.shade800,
                      onTap: onReview,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AdminToolbarButton(
                  icon: Icons.add_circle_rounded,
                  label: 'إضافة سجل',
                  color: Colors.deepOrange.shade800,
                  onTap: onQuickAdd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminToolbarButton extends StatelessWidget {
  const _AdminToolbarButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: badgeCount > 0,
                backgroundColor: Colors.redAccent,
                label: Text(
                  '$badgeCount',
                  style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.bold),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شريط الاستكشاف والتنقل السريع (كبسولات أفقية أنيقة)
class _QuickExplorationBar extends StatelessWidget {
  const _QuickExplorationBar({
    required this.onOpenMap,
    required this.onOpenFacilities,
    required this.onOpenFamilies,
    required this.onOpenArchive,
  });

  final VoidCallback onOpenMap;
  final VoidCallback onOpenFacilities;
  final VoidCallback onOpenFamilies;
  final VoidCallback onOpenArchive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _QuickChip(
            icon: Icons.map_outlined,
            label: 'خريطة القرية',
            color: const Color(0xFF2E7D32),
            onTap: onOpenMap,
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon: Icons.domain_rounded,
            label: 'منشآت القرية',
            color: const Color(0xFF1565C0),
            onTap: onOpenFacilities,
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon: Icons.account_tree_outlined,
            label: 'شجرة العائلات',
            color: const Color(0xFF00695C),
            onTap: onOpenFamilies,
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon: Icons.photo_library_outlined,
            label: 'الأرشيف المصور',
            color: const Color(0xFF6A1B9A),
            onTap: onOpenArchive,
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شبكة ٢×٣ العصرية المتناسقة لأقسام الموسوعة الستة
class _ModernGrid2x3 extends StatelessWidget {
  const _ModernGrid2x3({
    required this.isAdmin,
    required this.onOpen,
    required this.onQuickAdd,
  });

  final bool isAdmin;
  final ValueChanged<String> onOpen;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.98,
      ),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return _ModernVillageGridCard(
          index: index,
          entry: entry,
          isAdmin: isAdmin,
          onTap: () => onOpen(entry.route),
          onQuickAdd: onQuickAdd,
        );
      },
    );
  }
}

/// كارت شبكة فردي لأقسام المرجع الرقمي
class _ModernVillageGridCard extends StatelessWidget {
  const _ModernVillageGridCard({
    required this.index,
    required this.entry,
    required this.isAdmin,
    required this.onTap,
    required this.onQuickAdd,
  });

  final int index;
  final _VillageEntry entry;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: entry.color.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: entry.color.withValues(alpha: 0.28),
          width: 1.1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                entry.color.withValues(alpha: 0.08),
                Theme.of(context).cardColor,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          entry.color,
                          Color.alphaBlend(
                            Colors.black.withValues(alpha: 0.20),
                            entry.color,
                          ),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: entry.color.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(entry.icon, color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: entry.color.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: entry.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  entry.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: (200 + index * 40).ms).slideY(begin: 0.08);
  }
}

/// بوابة مساهمة الأهالي المحفزة: خطوات توثيق واضحة ومضمونة
class _CommunityContributionSection extends StatelessWidget {
  const _CommunityContributionSection({
    required this.onContribute,
    required this.onBrowseArchive,
  });

  final VoidCallback onContribute;
  final VoidCallback onBrowseArchive;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFE65100), Color(0xFFD84315)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x35E65100),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ساهم في بناء وتوثيق موسوعة القرية 🤍',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'الذاكرة والتاريخ يُحفظان بأيدي أهلها للأجيال القادمة',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // خطوات المساهمة والاعتماد الثلاث (واضحة ومطمئنة)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: _ContributionStep(
                      number: '١',
                      title: 'أرسل المادة',
                      desc: 'صورة أو وثيقة أو حكاية',
                    ),
                  ),
                  _StepDivider(),
                  Expanded(
                    child: _ContributionStep(
                      number: '٢',
                      title: 'تدقيق الإدارة',
                      desc: 'مراجعة وتوثيق دقيق',
                    ),
                  ),
                  _StepDivider(),
                  Expanded(
                    child: _ContributionStep(
                      number: '٣',
                      title: 'حفظ حقك',
                      desc: 'نشر منسوب لاسمك',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // أزرار العمل والمشاركة
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFD84315),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onContribute,
                    icon: const Icon(Icons.add_photo_alternate_rounded,
                        size: 18),
                    label: const Text(
                      'أرسل مساهمتك الآن',
                      style:
                          TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onBrowseArchive,
                    child: const Text(
                      'الأرشيف',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributionStep extends StatelessWidget {
  const _ContributionStep({
    required this.number,
    required this.title,
    required this.desc,
  });

  final String number;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white24,
    );
  }
}

/// شريط عرض المساهمات الأهلية المعتمدة والمثبّتة.
class _PinnedContributions extends StatelessWidget {
  const _PinnedContributions({
    required this.service,
    required this.onOpenArchive,
  });

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
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: _SectionLabel(
                icon: Icons.push_pin_rounded,
                label: 'من مساهمات الأهالي الموثقة في الأرشيف',
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
            color: VillageOrnament.gold.withValues(alpha: 0.5),
            width: 1.2,
          ),
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
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${type.label} · ${item.userName.isNotEmpty ? item.userName : 'مساهم'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 10),
        const Expanded(child: OrnamentDivider()),
      ],
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
        title: 'ذاكرة القرية',
        subtitle: 'الصور القديمة، حكايات الأجداد، الوثائق وفيديوهات الماضي',
        icon: Icons.auto_stories_rounded,
        color: Color(0xFF6A1B9A),
        route: AppRoutes.villageMemory,
      ),
      _VillageEntry(
        title: 'أهل وعائلات القرية',
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
        title: 'معالم ومنشآت القرية',
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

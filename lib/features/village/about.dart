import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../models/data_models.dart';
import '../../models/village_content_models.dart';
import '../../services/cache_service.dart';
import '../../services/village_content_service.dart';
import '../../services/village_extended_service.dart';
import '../../services/village_info_service.dart';
import '../../widgets/offline_stream_builder.dart';
import '../../widgets/qurity_app_bar.dart';
import '../../widgets/village_ornament.dart';
import '../../widgets/village_video_card.dart';
import 'village_content_admin.dart';

Color get kVillageAboutColor => AppColors.primary;

/// 🏛️ صفحة «تعرف على القرية» الموحدة والمبسّطة:
/// تجمع كل ما يخص القرية في مكان واحد بتصميم دافئ وسهل وبسيط يناسب كافة أهالي القرية:
/// - هوية وإحصائيات وبطاقة القرية
/// - حكاية وسر تسمية أبوديشيشة
/// - معالم ورموز القرية مع دعم عرض الفيديوهات داخل التطبيق
/// - أهلنا وشخصيات من ذهب والرموز والراحلين بالرحمة
/// - فيديوهات وأرشيف ذكريات زمان المصور مع تشغيل مباشر
/// - تراث وعادات القرية الأصيلة
/// - نافذة مشاركة مباشرة للأهالي
/// - صلاحيات كاملة للتعديل والحذف للأدمن العام و«أدمن التراث»
class VillageScreen extends StatefulWidget {
  const VillageScreen({super.key, this.initialTab = 'all'});

  final String initialTab;

  @override
  State<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends State<VillageScreen> {
  final VillageInfoService _infoService = VillageInfoService();
  final VillageContentService _contentService = VillageContentService();
  final VillageExtendedService _extService = VillageExtendedService();

  bool _isHeritageAdmin = false;
  late String _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _infoService.seedIfEmpty().catchError((_) {});
    canManageVillageContent().then((can) {
      if (mounted) setState(() => _isHeritageAdmin = can);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QurityAppBar(
        title: 'تعرف على القرية',
        actions: [
          if (_isHeritageAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.amber),
              tooltip: 'إدارة محتوى وتراث القرية',
              onPressed: () => _showAdminManagementSheet(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── ١. الهيرو الترحيبي وبطاقة الهوية ──
          _VillageHero(
            canManage: _isHeritageAdmin,
            onEditInfo: () => _openEditVillageInfoDialog(context),
          ),

          const SizedBox(height: 12),

          // ── ٢. بطاقة إحصائيات ومعلومات سريعة ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _VillageQuickStats(
              canManage: _isHeritageAdmin,
              onEdit: () => _openEditVillageInfoDialog(context),
            ),
          ),

          const SizedBox(height: 16),

          // ── ٣. شريط التصفية السريع والبسيط ──
          _buildFilterTabs(),

          const SizedBox(height: 14),

          // ── ٤. المحتوى حسب التبويب المختار ──
          if (_selectedTab == 'all' || _selectedTab == 'story') ...[
            _buildSectionHeader(
              icon: Icons.menu_book_rounded,
              title: 'حكاية وسر التسمية',
              subtitle: 'من أين جاء اسم «أبوديشيشة» ونشأة قريتنا الطيبة',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _VillageStoryCard(
                canManage: _isHeritageAdmin,
                onEdit: () => _openEditVillageInfoDialog(context),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_selectedTab == 'all' || _selectedTab == 'landmarks') ...[
            _buildSectionHeader(
              icon: Icons.mosque_rounded,
              title: 'معالم ورموز القرية',
              subtitle: 'المساجد، الصروح الطبية، المدارس، والمصالح العامة',
              trailingAction: _isHeritageAdmin
                  ? TextButton.icon(
                      onPressed: () => _openAddLandmarkDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text('إضافة معلم', style: TextStyle(fontSize: 12)),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _VillageLandmarksSection(
                extService: _extService,
                canManage: _isHeritageAdmin,
                onEdit: (item) => _openEditLandmarkDialog(context, item),
                onDelete: (id) => _deleteItem(context, 'village_landmarks', id),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_selectedTab == 'all' || _selectedTab == 'people') ...[
            _buildSectionHeader(
              icon: Icons.family_restroom_rounded,
              title: 'أهلنا وشخصيات من ذهب',
              subtitle: 'شيوخ القرية، كبار العائلات، والعمد، والراحلون بالرحمة',
              trailingAction: _isHeritageAdmin
                  ? TextButton.icon(
                      onPressed: () => _openAddFigureDialog(context),
                      icon: const Icon(Icons.person_add_rounded, size: 17),
                      label: const Text('إضافة شخصية', style: TextStyle(fontSize: 12)),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _VillageFiguresSection(
                contentService: _contentService,
                canManage: _isHeritageAdmin,
                onEdit: (fig) => _openEditFigureDialog(context, fig),
                onDelete: (id) => _deleteItem(context, 'village_figures', id),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_selectedTab == 'all' || _selectedTab == 'videos') ...[
            _buildSectionHeader(
              icon: Icons.movie_filter_rounded,
              title: 'فيديوهات وذكريات القرية',
              subtitle: 'فيديوهات حية وصور نادرة من أرشيف زمان مع تشغيل مباشر',
              trailingAction: _isHeritageAdmin
                  ? TextButton.icon(
                      onPressed: () => _openAddVideoDialog(context),
                      icon: const Icon(Icons.video_call_rounded, size: 18),
                      label: const Text('إضافة فيديو', style: TextStyle(fontSize: 12)),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _VillageVideosSection(
                extService: _extService,
                canManage: _isHeritageAdmin,
                onDelete: (id) => _deleteItem(context, 'village_contributions', id),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_selectedTab == 'all' || _selectedTab == 'heritage') ...[
            _buildSectionHeader(
              icon: Icons.festival_rounded,
              title: 'تراث وعادات أهل البلد',
              subtitle: 'كرم الضيافة، مواسم الخير والزراعة، والتكافل الريفي الأصيل',
              trailingAction: _isHeritageAdmin
                  ? TextButton.icon(
                      onPressed: () => _openAddHeritageDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text('إضافة مادة', style: TextStyle(fontSize: 12)),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _VillageHeritageSection(
                extService: _extService,
                canManage: _isHeritageAdmin,
                onDelete: (id) => _deleteItem(context, 'village_heritage', id),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── ٥. دعوة المساهمة البسيطة لكل أهالي القرية ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _SimpleContributeCard(
              onTap: () => _openContributeBottomSheet(context),
            ),
          ),

          const SizedBox(height: 20),

          // ── خاتمة الصفحة ──
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'قرية أبوديشيشة — تاريخ مجيد وحاضر مشرق بسواعد أهلها الطيبين\nذاكرتنا تُبنى بحب وتكافل الجميع',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, height: 1.7, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      ('all', '🌟 الكل', Icons.explore_rounded),
      ('story', '📖 الحكاية والتسمية', Icons.menu_book_rounded),
      ('landmarks', '🕌 معالم القرية', Icons.mosque_rounded),
      ('people', '👥 أهلنا ورموزنا', Icons.family_restroom_rounded),
      ('videos', '🎬 فيديوهات وذكريات', Icons.videocam_rounded),
      ('heritage', '🌾 تراثنا الأصيل', Icons.festival_rounded),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = filters[i];
          final isSelected = _selectedTab == item.$1;
          return FilterChip(
            selected: isSelected,
            avatar: Icon(
              item.$3,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            label: Text(
              item.$2,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.white : null,
              ),
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            onSelected: (_) => setState(() => _selectedTab = item.$1),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailingAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (trailingAction != null) trailingAction,
        ],
      ),
    );
  }

  // ══════════════════════ إجراءات الإدارة والحذف ══════════════════════

  Future<void> _deleteItem(
      BuildContext context, String collection, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العنصر نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف العنصر بنجاح')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل الحذف: $e')),
          );
        }
      }
    }
  }

  void _showAdminManagementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'لوحة إدارة التراث ومحتوى القرية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                title: const Text('تعديل بطاقة وسر تسمية القرية'),
                subtitle: const Text('السكان والمساحة وحكاية التسمية والموقع'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openEditVillageInfoDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.mosque_rounded, color: Colors.teal),
                title: const Text('إضافة معلم جديد'),
                subtitle: const Text('إضافة مسجد أو صرح طبي أو مدرسة مع رابط فيديو'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openAddLandmarkDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_rounded, color: Colors.green),
                title: const Text('إضافة شخصية من رموز القرية'),
                subtitle: const Text('إضافة شيخ أو عمدة أو رمز من رموز العائلات'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openAddFigureDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_call_rounded, color: Colors.red),
                title: const Text('إضافة فيديو من القرية'),
                subtitle: const Text('وضع رابط فيديو YouTube أو ويب وتشغيله بالتطبيق'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openAddVideoDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════ حوارات التعديل والإضافة ══════════════════════

  Future<void> _openEditVillageInfoDialog(BuildContext context) async {
    final info = await _infoService.getInfo();
    if (!context.mounted) return;

    final nameCtrl = TextEditingController(text: info?.name ?? 'قرية أبوديشيشة');
    final descCtrl = TextEditingController(text: info?.description ?? '');
    final originCtrl = TextEditingController(text: info?.nameOrigin ?? '');
    final popCtrl = TextEditingController(text: info?.population ?? '');
    final areaCtrl = TextEditingController(text: info?.area ?? '');
    final foundedCtrl = TextEditingController(text: info?.founded ?? '');
    final locCtrl = TextEditingController(text: info?.location ?? 'مركز بلقاس - محافظة الدقهلية');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل بيانات وهوية القرية', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم القرية')),
              TextField(controller: popCtrl, decoration: const InputDecoration(labelText: 'عدد السكان (مثال: ١٥ ألف نسمة)')),
              TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: 'المساحة')),
              TextField(controller: foundedCtrl, decoration: const InputDecoration(labelText: 'تاريخ النشأة')),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'الموقع والتبعية الإدارية')),
              const SizedBox(height: 8),
              TextField(
                controller: originCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'سر تسمية القرية وحكايتها',
                  hintText: 'اكتب حكاية سبب تسمية أبوديشيشة ونشأتها بأسلوب دافئ ومبسط...',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'نبذة عامة عن القرية'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final curr = info ?? VillageInfo.defaults();
              final newInfo = VillageInfo(
                id: curr.id,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
                nameOrigin: originCtrl.text.trim(),
                population: popCtrl.text.trim(),
                area: areaCtrl.text.trim(),
                founded: foundedCtrl.text.trim(),
                location: locCtrl.text.trim(),
                nature: curr.nature,
                famousFor: curr.famousFor,
                imageUrl: curr.imageUrl,
                mapUrl: curr.mapUrl,
                history: curr.history,
                institutions: curr.institutions,
                archive: curr.archive,
              );
              await _infoService.saveInfo(newInfo);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddLandmarkDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imgCtrl = TextEditingController();
    final videoCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة معلم جديد للقرية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'اسم المعلم (مثال: المسجد الكبير)')),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'وصف المعلم ومكانته')),
              TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'رابط صورة المعلم (اختياري)')),
              TextField(
                controller: videoCtrl,
                decoration: const InputDecoration(
                  labelText: 'رابط فيديو للمعلم (YouTube أو ويب)',
                  hintText: 'https://youtu.be/...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final landmark = VillageLandmark(
                name: titleCtrl.text.trim(),
                category: 'main',
                description: descCtrl.text.trim(),
                location: videoCtrl.text.trim(), // تخزين رابط الفيديو في المعلم
                currentImages: imgCtrl.text.trim().isNotEmpty
                    ? [imgCtrl.text.trim()]
                    : const [],
              );
              await _extService.saveLandmark(landmark);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditLandmarkDialog(BuildContext context, VillageLandmark item) async {
    final titleCtrl = TextEditingController(text: item.name);
    final descCtrl = TextEditingController(text: item.description);
    final currentImg = item.currentImages.isNotEmpty ? item.currentImages.first : '';
    final imgCtrl = TextEditingController(text: currentImg);
    final videoCtrl = TextEditingController(text: item.location);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل المعلم'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'اسم المعلم')),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'الوصف')),
              TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'رابط الصورة')),
              TextField(controller: videoCtrl, decoration: const InputDecoration(labelText: 'رابط الفيديو (YouTube)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final updated = VillageLandmark(
                id: item.id,
                name: titleCtrl.text.trim(),
                category: item.category.isNotEmpty ? item.category : 'main',
                description: descCtrl.text.trim(),
                location: videoCtrl.text.trim(),
                currentImages: imgCtrl.text.trim().isNotEmpty
                    ? [imgCtrl.text.trim()]
                    : item.currentImages,
                sortOrder: item.sortOrder,
                createdAt: item.createdAt,
              );
              await _extService.saveLandmark(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddFigureDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final tributeCtrl = TextEditingController();
    final imgCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة شخصية من رموز القرية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الكامل للشخصية')),
              TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'الصفة أو المنصب (مثال: عمدة القرية / شيخ جليل)')),
              TextField(controller: tributeCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'كلمة وفاء أو ما اشتهر به')),
              TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'رابط الصورة الشخصية (اختياري)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final fig = VillageFigure(
                name: nameCtrl.text.trim(),
                title: roleCtrl.text.trim(),
                bio: tributeCtrl.text.trim(),
                photoUrl: imgCtrl.text.trim(),
                category: FigureCategory.elders,
              );
              await _contentService.saveFigure(fig);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditFigureDialog(BuildContext context, VillageFigure fig) async {
    final nameCtrl = TextEditingController(text: fig.name);
    final roleCtrl = TextEditingController(text: fig.title);
    final bioCtrl = TextEditingController(text: fig.bio);
    final imgCtrl = TextEditingController(text: fig.photoUrl);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الشخصية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
              TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'الصفة أو المنصب')),
              TextField(controller: bioCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'الوصف أو النبذة')),
              TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'رابط الصورة')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final updated = VillageFigure(
                id: fig.id,
                name: nameCtrl.text.trim(),
                title: roleCtrl.text.trim(),
                bio: bioCtrl.text.trim(),
                photoUrl: imgCtrl.text.trim(),
                category: fig.category,
                era: fig.era,
                sortOrder: fig.sortOrder,
                createdAt: fig.createdAt,
              );
              await _contentService.saveFigure(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddVideoDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final videoCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة فيديو عن القرية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الفيديو')),
              TextField(
                controller: videoCtrl,
                decoration: const InputDecoration(
                  labelText: 'رابط الفيديو (YouTube أو مباشر)',
                  hintText: 'https://www.youtube.com/watch?v=...',
                ),
              ),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'وصف مختصر للفيديو')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || videoCtrl.text.trim().isEmpty) return;
              final user = FirebaseAuth.instance.currentUser;
              final contrib = VillageContribution(
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                type: 'video',
                videoUrl: videoCtrl.text.trim(),
                userId: user?.uid ?? 'admin',
                userName: user?.displayName ?? 'إدارة القرية',
                approvalStatus: 'approved',
                pinOnHome: true,
                createdAt: DateTime.now(),
              );
              await _extService.saveContribution(contrib);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('إضافة ونشر'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddHeritageDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imgCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة من تراث القرية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان المادة التراثية')),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'التفاصيل والعادة التراثية')),
              TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'رابط صورة توضيحية (اختياري)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final h = VillageHeritage(
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                images: imgCtrl.text.trim().isNotEmpty ? [imgCtrl.text.trim()] : const [],
                category: 'tradition',
              );
              await _extService.saveHeritage(h);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _openContributeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: _ContributeModalContent(
          extService: _extService,
          onComplete: () => Navigator.pop(ctx),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ودجات وعناصر الصفحة الموحدة
// ══════════════════════════════════════════════════════════════════════════

/// ١. الهيرو الترحيبي للقرية: يعتمد على أصل الصورة 0.jpg مع تدرج ذهبي
class _VillageHero extends StatelessWidget {
  const _VillageHero({required this.canManage, required this.onEditInfo});

  final bool canManage;
  final VoidCallback onEditInfo;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أبوديشيشة',
                          style: VillageOrnament.amiri(size: 36).copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: VillageOrnament.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: VillageOrnament.gold.withValues(alpha: 0.6)),
                          ),
                          child: const Text(
                            'أرض الخير • كرم وتاريخ وعراقة الدلتا',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canManage)
                    IconButton.filledTonal(
                      onPressed: onEditInfo,
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      style: IconButton.styleFrom(backgroundColor: Colors.white24),
                      tooltip: 'تعديل هوية القرية',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'مرحباً بكم في المرجع الموحد لقرية أبوديشيشة.. تاريخ الأجداد وحاضر الأبناء وذكريات تمتد في أعماق قلوبنا.',
                style: TextStyle(fontSize: 12.5, height: 1.7, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}

/// ٢. بطاقة إحصائيات سريعة للقرية
class _VillageQuickStats extends StatelessWidget {
  const _VillageQuickStats({required this.canManage, required this.onEdit});

  final bool canManage;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: OfflineStreamBuilder<VillageInfo?>(
        stream: VillageInfoService().getInfoStream(),
        onlineBuilder: (context, snapshot) => _buildStats(context, snapshot.data),
        cacheBuilder: (context) => FutureBuilder<VillageInfo?>(
          future: CacheService.getVillageInfo().then(
              (m) => m == null ? null : VillageInfo.fromJson(m, 'main')),
          builder: (context, snap) => _buildStats(context, snap.data),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, VillageInfo? info) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statItem(
                  icon: Icons.groups_rounded,
                  label: 'أهلنا الطيبين',
                  val: (info?.population.isNotEmpty ?? false) ? info!.population : '١٥,٠٠٠ نسمة',
                  color: Colors.teal,
                ),
              ),
              Container(width: 1, height: 42, color: Colors.black12),
              Expanded(
                child: _statItem(
                  icon: Icons.landscape_rounded,
                  label: 'طبيعة القرية',
                  val: (info?.nature.isNotEmpty ?? false) ? info!.nature : 'زراعية عريقة',
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  icon: Icons.location_on_rounded,
                  label: 'الموقع والتبعية',
                  val: (info?.location.isNotEmpty ?? false) ? info!.location : 'بلقاس - الدقهلية',
                  color: Colors.blue.shade700,
                ),
              ),
              Container(width: 1, height: 42, color: Colors.black12),
              Expanded(
                child: _statItem(
                  icon: Icons.event_available_rounded,
                  label: 'تاريخ النشأة',
                  val: (info?.founded.isNotEmpty ?? false) ? info!.founded : 'منذ عقود أصيلة',
                  color: Colors.brown.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String label,
    required String val,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                Text(
                  val,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ٣. بطاقة حكاية وسر التسمية
class _VillageStoryCard extends StatelessWidget {
  const _VillageStoryCard({required this.canManage, required this.onEdit});

  final bool canManage;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: VillageOrnament.gold.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: OfflineStreamBuilder<VillageInfo?>(
        stream: VillageInfoService().getInfoStream(),
        onlineBuilder: (context, snapshot) => _buildContent(context, snapshot.data),
        cacheBuilder: (context) => FutureBuilder<VillageInfo?>(
          future: CacheService.getVillageInfo().then(
              (m) => m == null ? null : VillageInfo.fromJson(m, 'main')),
          builder: (context, snap) => _buildContent(context, snap.data),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VillageInfo? info) {
    final story = (info?.nameOrigin.isNotEmpty ?? false)
        ? info!.nameOrigin
        : 'سُميت قرية «أبوديشيشة» بهذا الاسم نسبةً إلى كرم أهلها وأجدادها الأوائل، حيث اشتُهروا قديماً بإعداد طعام «الدشيشة» من القمح الصافي وإطعام عابري السبيل والضيوف والفقراء بحب وسخاء، فصارت مأوى الكرم وعنوان الجود، واستقرت العائلات الطيبة في أرضها الخصبة بمركز بلقاس بمحافظة الدقهلية.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: VillageOrnament.gold.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, size: 20, color: Color(0xFFB8860B)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'سر التسمية وحكاية الأجداد',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                ),
              ),
              if (canManage)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'تعديل الحكاية',
                  onPressed: onEdit,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            story,
            style: const TextStyle(
              fontSize: 13,
              height: 1.85,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ٤. قسم معالم ورموز القرية
class _VillageLandmarksSection extends StatelessWidget {
  const _VillageLandmarksSection({
    required this.extService,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final VillageExtendedService extService;
  final bool canManage;
  final ValueChanged<VillageLandmark> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VillageLandmark>>(
      stream: extService.watchLandmarks(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <VillageLandmark>[];
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'سيتم إدراج معالم القرية قريباً.. المسجد الكبير، المركز الطبي، والمصالح.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: [
            for (final item in items)
              _LandmarkCard(
                item: item,
                canManage: canManage,
                onEdit: () => onEdit(item),
                onDelete: () => onDelete(item.id),
              ),
          ],
        );
      },
    );
  }
}

class _LandmarkCard extends StatelessWidget {
  const _LandmarkCard({
    required this.item,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final VillageLandmark item;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasVideo = item.location.trim().startsWith('http');
    final img = item.currentImages.isNotEmpty ? item.currentImages.first : '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (img.isNotEmpty)
            CachedNetworkImage(
              imageUrl: img,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.place_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (canManage) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: onEdit,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 12, height: 1.6, color: Colors.black87),
                  ),
                ],
                if (hasVideo) ...[
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: () => VillageVideoHelper.playInApp(context, item.location, title: item.name),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.12),
                      foregroundColor: Colors.red.shade800,
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                    label: const Text('مشاهدة فيديو عن المعلم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ٥. قسم أهلنا وشخصيات من ذهب
class _VillageFiguresSection extends StatelessWidget {
  const _VillageFiguresSection({
    required this.contentService,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final VillageContentService contentService;
  final bool canManage;
  final ValueChanged<VillageFigure> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VillageFigure>>(
      stream: contentService.watchFigures(),
      builder: (context, snapshot) {
        final figures = snapshot.data ?? const <VillageFigure>[];
        if (figures.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'سجل رموز وأعلام القرية قيد التوثيق والتحديث.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: [
            for (final fig in figures)
              Card(
                elevation: 1.5,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundImage: fig.photoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(fig.photoUrl)
                        : null,
                    child: fig.photoUrl.isEmpty
                        ? Icon(Icons.person_rounded, color: AppColors.primary)
                        : null,
                  ),
                  title: Text(
                    fig.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    fig.title.isNotEmpty ? fig.title : (fig.bio.isNotEmpty ? fig.bio : 'من رموز القرية'),
                    style: const TextStyle(fontSize: 11.5, height: 1.5),
                  ),
                  trailing: canManage
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => onEdit(fig),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                              onPressed: () => onDelete(fig.id),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// ٦. قسم فيديوهات وذكريات القرية مع تشغيل مباشر
class _VillageVideosSection extends StatelessWidget {
  const _VillageVideosSection({
    required this.extService,
    required this.canManage,
    required this.onDelete,
  });

  final VillageExtendedService extService;
  final bool canManage;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VillageContribution>>(
      stream: extService.watchContributions().map((items) => items
          .where((item) => item.approvalStatus == 'approved')
          .toList(growable: false)),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <VillageContribution>[];
        final videos = all.where((c) => c.videoUrl.isNotEmpty || c.type == 'video').toList();

        if (videos.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black12),
            ),
            child: const Column(
              children: [
                Icon(Icons.video_collection_rounded, size: 36, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'لا توجد فيديوهات منشورة حالياً.. يمكن للإدارة إضافة روابط فيديوهات القرية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            for (final v in videos)
              VillageVideoCard(
                title: v.title,
                videoUrl: v.videoUrl,
                description: v.description,
                source: v.userName.isNotEmpty ? v.userName : 'أهالي قرية أبوديشيشة',
                canManage: canManage,
                onDelete: () => onDelete(v.id),
              ),
          ],
        );
      },
    );
  }
}

/// ٧. قسم تراث وعادات القرية
class _VillageHeritageSection extends StatelessWidget {
  const _VillageHeritageSection({
    required this.extService,
    required this.canManage,
    required this.onDelete,
  });

  final VillageExtendedService extService;
  final bool canManage;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VillageHeritage>>(
      stream: extService.watchHeritage(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <VillageHeritage>[];
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'عادات وتراث القرية الأصيل قيد النشر والإعداد.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: [
            for (final h in items)
              Card(
                elevation: 1.5,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF6C00).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.grain_rounded, color: Color(0xFFEF6C00), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              h.description,
                              style: const TextStyle(fontSize: 12, height: 1.6, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      if (canManage)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                          onPressed: () => onDelete(h.id),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// ٨. زر دعوة المساهمة البسيطة
class _SimpleContributeCard extends StatelessWidget {
  const _SimpleContributeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFEF6C00), Color(0xFFB45309)],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عندك صورة أو حكاية أو فيديو عن بلدنا؟',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'اضغط هنا وشاركها مع أهالي قريتك بلمسة واحدة لنشرها وتوثيقها',
                      style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// نافذة نموذج المساهمة المبسط
class _ContributeModalContent extends StatefulWidget {
  const _ContributeModalContent({required this.extService, required this.onComplete});

  final VillageExtendedService extService;
  final VoidCallback onComplete;

  @override
  State<_ContributeModalContent> createState() => _ContributeModalContentState();
}

class _ContributeModalContentState extends State<_ContributeModalContent> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  String _imageUrl = '';
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _isUploading = true);
    final url = await pickAndUploadImage(context);
    if (mounted) {
      setState(() {
        if (url != null) _imageUrl = url;
        _isUploading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة عنوان للمساهمة')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final video = _videoCtrl.text.trim();
      final contrib = VillageContribution(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrl: _imageUrl,
        videoUrl: video,
        type: video.isNotEmpty ? 'video' : (_imageUrl.isNotEmpty ? 'photo' : 'info'),
        userId: user?.uid ?? 'guest',
        userName: user?.displayName ?? 'ابن القرية',
        createdAt: DateTime.now(),
      );

      await widget.extService.saveContribution(contrib);
      if (mounted) {
        widget.onComplete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('شكراً لمساهمتك! ستتم مراجعتها ونشرها قريباً.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الإرسال: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.red),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'شارك في توثيق ذكريات القرية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'عنوان الصورة أو الحكاية أو الفيديو *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'اكتب حكايتك أو تفاصيل الصورة أو الذكرى',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _videoCtrl,
          decoration: const InputDecoration(
            labelText: 'رابط فيديو YouTube (اختياري)',
            hintText: 'https://youtu.be/...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickImage,
              icon: _isUploading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.photo_camera_rounded),
              label: Text(_imageUrl.isNotEmpty ? 'تم اختيار صورة ✓' : 'إرفاق صورة قديمة'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('إرسال للمراجعة'),
            ),
          ],
        ),
      ],
    );
  }
}

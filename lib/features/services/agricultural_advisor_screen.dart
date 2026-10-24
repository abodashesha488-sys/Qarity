import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/relative_time.dart';
import '../../models/agriculture_consultation_model.dart';
import '../../services/admin_service.dart';
import '../../services/agriculture_consultation_service.dart';
import '../../widgets/agriculture_promo_banner.dart';
import '../../widgets/consultation_widgets.dart';
import '../../widgets/document_field_editor.dart';
import '../../widgets/owner_actions.dart';
import '../../widgets/qurity_app_bar.dart';
import 'crops_screen.dart';

const Color kAgriColor = Color(0xFF2E7D32); // أخضر زراعي داكن

/// شاشة مستشارك الزراعي — إرشادات موثقة واستشارات زراعية متخصصة
class AgriculturalAdvisorScreen extends StatefulWidget {
  const AgriculturalAdvisorScreen({super.key, this.service});

  final AgricultureConsultationService? service;

  @override
  State<AgriculturalAdvisorScreen> createState() =>
      _AgriculturalAdvisorScreenState();
}

class _AgriculturalAdvisorScreenState extends State<AgriculturalAdvisorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final GlobalKey<_AgriConsultationsTabState> _consultationsKey =
      GlobalKey<_AgriConsultationsTabState>();

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _onAddPressed() {
    if (_tabs.index == 1) {
      _consultationsKey.currentState?.openAskSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QurityAppBar(
        title: 'مستشارك الزراعي',
        onAdd: _tabs.index == 1 ? _onAddPressed : null,
        addTooltip: 'طرح استشارة زراعية',
        bottom: TabBar(
          controller: _tabs,
          onTap: (_) => setState(() {}),
          dividerColor: Colors.transparent,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: const [
            Tab(
              icon: Icon(Icons.menu_book_rounded, size: 20),
              text: 'الدليل والإرشادات',
            ),
            Tab(
              icon: Icon(Icons.psychology_alt_rounded, size: 20),
              text: 'الاستشارات الزراعية',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          const _AgriGuideTab(),
          _AgriConsultationsTab(
            key: _consultationsKey,
            service: widget.service,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════ تبويب الدليل والإرشادات ═══════════════════════════
class _AgriGuideTab extends StatefulWidget {
  const _AgriGuideTab();

  @override
  State<_AgriGuideTab> createState() => _AgriGuideTabState();
}

class _AgriGuideTabState extends State<_AgriGuideTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = kAgriColor;
    final query = _searchQuery.toLowerCase();
    final guidelines = CropsScreen.crops.where((item) {
      final matchesCategory = switch (_selectedCategory) {
        'محاصيل شتوية' => item.season.contains('شتوي'),
        'محاصيل صيفية' => item.season.contains('صيفي'),
        'حبوب وعلف' => const [
            'القمح',
            'الأرز',
            'الذرة الشامية',
            'الشعير',
            'الشوفان',
            'البرسيم الحجازي'
          ].contains(item.name),
        'بقوليات وزيتية' => const [
            'فول بلدي',
            'فول الصويا',
            'عباد الشمس',
            'السمسم',
            'الترمس',
            'الحمّص',
            'العدس',
            'الكتان',
            'حبة البركة'
          ].contains(item.name),
        'خضروات' => const [
            'الطماطم',
            'البطاطس',
            'البصل',
            'الثوم',
            'الخيار',
            'الفلفل',
            'البامية',
            'البطاطا الحلوة'
          ].contains(item.name),
        'فاكهة وأشجار' => const [
            'البرتقال',
            'العنب',
            'الزيتون',
            'الرمان',
            'البطيخ',
            'الشمام',
            'البلح (نخيل التمر)',
            'التين',
            'المانجو'
          ].contains(item.name),
        'محاصيل سكرية' =>
          const ['بنجر السكر', 'قصب السكر'].contains(item.name),
        'ري حديث' =>
          item.irrigation.contains('حديث') || item.irrigation.contains('تنقيط'),
        _ => true,
      };
      final searchable = '${item.name} ${item.nameEn} ${item.scientificName} '
              '${item.season} ${item.region} ${item.soilType} ${item.irrigation} '
              '${item.pests} ${item.varieties} ${item.description}'
          .toLowerCase();
      return matchesCategory && (query.isEmpty || searchable.contains(query));
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeroSection(theme, color),
        const AgriculturePromoBanner(placement: 'svc_agricultural'),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value.trim()),
          decoration: InputDecoration(
            hintText: 'ابحث عن محصول أو إرشاد أو آفة أو صنف...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: const Icon(Icons.clear_rounded),
                  ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 20),
        _buildCategoryFilterRow(color),
        const SizedBox(height: 24),
        _buildSectionTitle(
            theme, 'دليل وإرشادات المحاصيل (${guidelines.length} محصول)', color),
        const SizedBox(height: 12),
        if (guidelines.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('لا توجد نتائج مطابقة لبحثك')),
          ),
        ...guidelines.asMap().entries.map((e) =>
            _GuidelineCard(crop: e.value, color: color)
                .animate(delay: (e.key * 30).ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.08)),
        const SizedBox(height: 24),
        _buildSectionTitle(
            theme, 'التقويم الزراعي الشهري (شمال ووسط الدلتا)', color),
        const SizedBox(height: 12),
        ..._monthlyCalendar.asMap().entries.map((e) =>
            _MonthCard(month: e.value, color: color)
                .animate(delay: (e.key * 40).ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08)),
        const SizedBox(height: 24),
        _buildSectionTitle(theme, 'نصائح ذهبية للمزارع', color),
        const SizedBox(height: 12),
        ..._goldenTips.asMap().entries.map((e) =>
            _TipCard(tip: e.value, color: color)
                .animate(delay: (e.key * 40).ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeroSection(ThemeData theme, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.agriculture_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً بك في مستشارك الزراعي',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'إرشادات علمية موثقة لمحاصيل شمال ووسط الدلتا',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: '🌾 35 محصولاً موثقاً', color: Colors.white, textColor: Color(0xFF2E7D32)),
              _Chip(label: '🧪 برامج التسميد والمكافحة', color: Colors.white, textColor: Color(0xFF2E7D32)),
              _Chip(label: '🏛️ مركز البحوث الزراعية', color: Colors.white, textColor: Color(0xFF2E7D32)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterRow(Color color) {
    const categories = [
      'الكل',
      'محاصيل شتوية',
      'محاصيل صيفية',
      'حبوب وعلف',
      'بقوليات وزيتية',
      'خضروات',
      'فاكهة وأشجار',
      'محاصيل سكرية',
      'ري حديث',
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedCategory = cat),
            selectedColor: color,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected
                  ? Colors.white
                  : AppColors.readableInk(
                      color, Theme.of(context).brightness),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isSelected ? color : color.withValues(alpha: 0.25),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.readableInk(color, theme.brightness))),
      ],
    );
  }
}

// ═══════════════════════════ تبويب الاستشارات الزراعية ═══════════════════════════
class _AgriConsultationsTab extends StatefulWidget {
  const _AgriConsultationsTab({super.key, this.service});

  final AgricultureConsultationService? service;

  @override
  State<_AgriConsultationsTab> createState() => _AgriConsultationsTabState();
}

class _AgriConsultationsTabState extends State<_AgriConsultationsTab> {
  late final AgricultureConsultationService _service =
      widget.service ?? AgricultureConsultationService();
  late final Stream<List<AgricultureConsultation>> _feed =
      _service.watchApproved();

  Stream<List<AgricultureConsultation>>? _mineStream;
  Stream<List<AgricultureConsultation>>? _allStream;

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  bool _mineOnly = false;
  bool _isAgriAdmin = false;
  String _myUid = '';

  @override
  void initState() {
    super.initState();
    try {
      _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      _myUid = '';
    }
    _checkAgriAdmin();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAgriAdmin() async {
    if (_myUid.isEmpty) return;
    try {
      final isAdm = await AdminService().isAgriculturalAdmin(_myUid);
      if (mounted && isAdm) {
        setState(() {
          _isAgriAdmin = true;
          _allStream = _service.watchAll();
        });
      }
    } catch (_) {}
  }

  void _toggleMine() {
    if (_myUid.isEmpty) {
      _snack('يرجى تسجيل الدخول لعرض استشاراتك الخاصة');
      return;
    }
    setState(() {
      _mineOnly = !_mineOnly;
      if (_mineOnly) {
        _mineStream ??= _service.watchMine(_myUid);
      }
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void openAskSheet({AgricultureConsultation? existing}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('يرجى تسجيل الدخول لطرح استشارة زراعية');
      return;
    }

    final questionCtrl = TextEditingController(text: existing?.question ?? '');
    final detailsCtrl = TextEditingController(text: existing?.details ?? '');
    final cropCtrl = TextEditingController(text: existing?.cropName ?? '');
    var selectedCat = existing?.category ?? 'زراعة محصول';
    var pickedImages = List<String>.from(existing?.images ?? []);
    var isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 6,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kAgriColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.psychology_alt_rounded,
                            color: kAgriColor, size: 24),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        existing != null
                            ? 'تعديل الاستشارة الزراعية'
                            : 'طرح استشارة زراعية جديدة',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('مجال الاستشارة:',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: kAgricultureConsultationCategories.map((cat) {
                      final isSel = selectedCat == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: kAgriColor,
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isSel ? Colors.white : null,
                        ),
                        onSelected: (v) {
                          if (v) setSheetState(() => selectedCat = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cropCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم المحصول أو النبات (اختياري)',
                      hintText: 'مثلاً: طماطم، قمح، بطاطس، نخيل...',
                      prefixIcon: Icon(Icons.grass_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: questionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'موضوع الاستشارة أو المشكلة *',
                      hintText: 'مثلاً: اصفرار أوراق الطماطم، مكافحة المن...',
                      prefixIcon: Icon(Icons.help_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: detailsCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'تفاصيل السؤال أو الأعراض والظروف *',
                      hintText:
                          'اكتب عمر النبات، مواعيد الري، الأسمدة المضافة، وأي أعراض تلاحظها بدقة...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ImageListEditor(
                    label: 'صور الإصابة أو النبات (حتى ٣ صور)',
                    fieldKey: 'agriConsultationImages',
                    maxImages: 3,
                    urls: pickedImages,
                    onChanged: (imgs) =>
                        setSheetState(() => pickedImages = imgs),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              isSubmitting ? null : () => Navigator.pop(sheetCtx),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: kAgriColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final q = questionCtrl.text.trim();
                                  final d = detailsCtrl.text.trim();
                                  if (q.isEmpty || d.isEmpty) {
                                    ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'يرجى ملء موضوع الاستشارة وتفاصيلها'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  setSheetState(() => isSubmitting = true);
                                  try {
                                    if (existing != null) {
                                      final updated = existing.copyWith(
                                        question: q,
                                        details: d,
                                        category: selectedCat,
                                        cropName: cropCtrl.text.trim(),
                                        images: pickedImages,
                                      );
                                      await _service.update(existing.id, updated);
                                      if (sheetCtx.mounted) {
                                        Navigator.pop(sheetCtx);
                                      }
                                      _snack('تم تعديل استشارتك بنجاح');
                                    } else {
                                      final c = AgricultureConsultation(
                                        question: q,
                                        details: d,
                                        category: selectedCat,
                                        cropName: cropCtrl.text.trim(),
                                        userId: user.uid,
                                        userName: (user.displayName ?? '')
                                                .trim()
                                                .isNotEmpty
                                            ? user.displayName!.trim()
                                            : 'مزارع',
                                        images: pickedImages,
                                      );
                                      await _service.create(c);
                                      if (sheetCtx.mounted) {
                                        Navigator.pop(sheetCtx);
                                      }
                                      _snack(
                                          'تم إرسال الاستشارة وسيتم الرد عليها من المستشار الزراعي');
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSubmitting = false);
                                    if (sheetCtx.mounted) {
                                      ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                        SnackBar(content: Text('خطأ: $e')),
                                      );
                                    }
                                  }
                                },
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(isSubmitting
                              ? 'جاري الإرسال...'
                              : (existing != null
                                  ? 'حفظ التعديل'
                                  : 'إرسال الاستشارة')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAnswerDialog(AgricultureConsultation c) async {
    final controller = TextEditingController(text: c.answer);
    var approve = true;
    var submitting = false;
    var selectedResponder = c.answeredByName.isNotEmpty
        ? c.answeredByName
        : 'أدمن الزراعة';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kAgriColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.eco_rounded,
                            color: kAgriColor, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          c.hasAnswer
                              ? 'تعديل الرد الزراعي'
                              : 'الرد على الاستشارة الزراعية',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kAgriColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: kAgriColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: kAgriColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.category,
                                style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                              ),
                            ),
                            if (c.cropName.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kAgriColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('محصول: ${c.cropName}',
                                    style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: kAgriColor)),
                              ),
                            ],
                            const Spacer(),
                            if (c.userName.isNotEmpty)
                              Text(
                                'السائل: ${c.userName}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.question,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                        if (c.details.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            c.details,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(ctx)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'نص الرد والتوجيه الزراعي:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText:
                          'اكتب التوجيه العلمي أو العلاج أو المبيد الموصى به وطريقة التطبيق...',
                      filled: true,
                      fillColor: Theme.of(ctx)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: kAgriColor.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide:
                            BorderSide(color: kAgriColor, width: 1.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'المستشار الذي قام بالرد:',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['أدمن الزراعة', 'الأدمن العام'].map((role) {
                      final isSel = selectedResponder == role;
                      return ChoiceChip(
                        label: Text(
                          role,
                          style: TextStyle(
                            fontWeight:
                                isSel ? FontWeight.w900 : FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSel,
                        selectedColor: kAgriColor.withValues(alpha: 0.18),
                        onSelected: (v) {
                          if (v) setModalState(() => selectedResponder = role);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('اعتماد ونشر الاستشارة للقرية',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: const Text(
                      'عند التفعيل، ستظهر الاستشارة وردها للجميع في قسم الاستشارات',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: approve,
                    activeThumbColor: kAgriColor,
                    onChanged: (v) => setModalState(() => approve = v),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              submitting ? null : () => Navigator.pop(ctx),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: kAgriColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: submitting
                              ? null
                              : () async {
                                  final text = controller.text.trim();
                                  if (text.isEmpty && approve) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'يرجى كتابة الرد أولاً قبل الاعتماد'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  setModalState(() => submitting = true);
                                  try {
                                    await _service.submitAnswer(
                                      c.id,
                                      text,
                                      approve: approve,
                                      answeredByName: selectedResponder,
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    _snack('تم حفظ الرد ونشر الاستشارة بنجاح');
                                  } catch (e) {
                                    setModalState(() => submitting = false);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                            content: Text('خطأ في الحفظ: $e')),
                                      );
                                    }
                                  }
                                },
                          icon: submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                              submitting ? 'جاري الحفظ...' : 'حفظ وإرسال الرد'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showConsultationDetails(AgricultureConsultation c) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kAgriColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(c.category,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: kAgriColor)),
                    ),
                    if (c.cropName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kAgriColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: kAgriColor.withValues(alpha: 0.2)),
                        ),
                        child: Text('🌾 ${c.cropName}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: kAgriColor)),
                      ),
                    ],
                    const Spacer(),
                    Text(relativeTimeLabelAr(c.createdAt),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(c.question,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        height: 1.5)),
                if (c.details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(c.details,
                      style: TextStyle(
                          fontSize: 13.5,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
                if (c.images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ConsultationImageGallery(images: c.images),
                ],
                const SizedBox(height: 14),
                if (c.hasAnswer) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: kAgriColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: kAgriColor.withValues(alpha: 0.3))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded,
                                size: 16, color: kAgriColor),
                            const SizedBox(width: 6),
                            Text('رد المستشار الزراعي (${c.responderTitle})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: kAgriColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(c.answer,
                            style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.7,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConsultationRepliesThread(
                    consultationId: c.id,
                    ownerId: c.userId,
                    currentUserId: _myUid,
                    primaryColor: kAgriColor,
                    isAdvisor: _isAgriAdmin,
                    advisorTitle: 'المستشار الزراعي',
                    repliesStream: _service.watchReplies(c.id),
                    onSendReply: (text) => _service.addReply(
                      c.id,
                      ConsultationReply(
                        consultationId: c.id,
                        authorId: _myUid,
                        authorName: FirebaseAuth.instance.currentUser?.displayName ?? 'مزارع',
                        text: text,
                        isAdvisor: _isAgriAdmin,
                        advisorTitle: _isAgriAdmin ? 'المستشار الزراعي' : '',
                        createdAt: DateTime.now(),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_empty_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          'بانتظار رد وتوجيه المستشار الزراعي...',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (c.userId == _myUid || _isAgriAdmin) ...[
                  const SizedBox(height: 16),
                  OwnerActions(
                    keyTag: 'agri-consult-modal-${c.id}',
                    ownerId: c.userId,
                    currentUserId: _myUid,
                    isAdmin: _isAgriAdmin,
                    itemName: 'الاستشارة',
                    editLabel: 'تعديل الاستشارة',
                    deleteLabel: 'حذف الاستشارة',
                    onEdit: () {
                      Navigator.of(ctx).pop();
                      openAskSheet(existing: c);
                    },
                    onDelete: () async {
                      try {
                        await _service.delete(c.id);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        _snack('تم حذف الاستشارة');
                        return true;
                      } catch (e) {
                        _snack('خطأ: $e');
                        return false;
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stream = _mineOnly
        ? (_mineStream ??= _service.watchMine(_myUid))
        : (_isAgriAdmin ? (_allStream ?? _service.watchAll()) : _feed);

    return Column(
      children: [
        // شريط رأس تبويب الاستشارات
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'ابحث في الاستشارات أو المحاصيل...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('استشاراتي'),
                    avatar: Icon(
                      _mineOnly
                          ? Icons.person_rounded
                          : Icons.person_outline_rounded,
                      size: 16,
                      color: _mineOnly ? Colors.white : kAgriColor,
                    ),
                    selected: _mineOnly,
                    selectedColor: kAgriColor,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: _mineOnly ? Colors.white : kAgriColor,
                    ),
                    onSelected: (_) => _toggleMine(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // فلاتر التصنيف
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ['الكل', ...kAgricultureConsultationCategories].length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final cat = ['الكل', ...kAgricultureConsultationCategories][i];
                    final isSel = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      selectedColor: kAgriColor,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSel ? Colors.white : null,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (_isAgriAdmin && !_mineOnly)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: kAgriColor.withValues(alpha: 0.1),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded,
                    size: 16, color: kAgriColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'لوحة تحكم المستشار الزراعي — الرد على الاستشارات والاعتماد',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: kAgriColor),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<List<AgricultureConsultation>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: kAgriColor),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('خطأ في تحميل الاستشارات: ${snapshot.error}'),
                );
              }
              var items = snapshot.data ?? [];
              if (_selectedCategory != 'الكل') {
                items = items
                    .where((c) => c.category == _selectedCategory)
                    .toList();
              }
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                items = items.where((c) {
                  return c.question.toLowerCase().contains(q) ||
                      c.details.toLowerCase().contains(q) ||
                      c.cropName.toLowerCase().contains(q) ||
                      c.answer.toLowerCase().contains(q);
                }).toList();
              }

              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.psychology_alt_outlined,
                            size: 64, color: kAgriColor.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          _mineOnly
                              ? 'لم تطرح أي استشارة زراعية بعد'
                              : 'لا توجد استشارات زراعية مطابقة',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'اطرح سؤالك عن زراعة أي محصول أو آفة أو تسميد وسيقوم المستشار بالرد عليك',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: kAgriColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: openAskSheet,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('طرح استشارة الآن'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final c = items[i];
                  return _AgriConsultationCard(
                    consultation: c,
                    currentUserId: _myUid,
                    isAgriAdmin: _isAgriAdmin,
                    showStatus: _mineOnly || _isAgriAdmin,
                    onTap: () => _showConsultationDetails(c),
                    onAnswer: _isAgriAdmin ? () => _showAnswerDialog(c) : null,
                    onEdit: (c.userId == _myUid || _isAgriAdmin)
                        ? () => openAskSheet(existing: c)
                        : null,
                    onDelete: c.userId == _myUid || _isAgriAdmin
                        ? () async {
                            try {
                              await _service.delete(c.id);
                              _snack('تم حذف الاستشارة');
                              return true;
                            } catch (e) {
                              _snack('خطأ: $e');
                              return false;
                            }
                          }
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AgriConsultationCard extends StatelessWidget {
  const _AgriConsultationCard({
    required this.consultation,
    required this.currentUserId,
    this.isAgriAdmin = false,
    this.showStatus = false,
    this.onTap,
    this.onAnswer,
    this.onEdit,
    this.onDelete,
  });

  final AgricultureConsultation consultation;
  final String currentUserId;
  final bool isAgriAdmin;
  final bool showStatus;
  final VoidCallback? onTap;
  final VoidCallback? onAnswer;
  final VoidCallback? onEdit;
  final Future<bool> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = consultation;
    final isMine = c.userId == currentUserId;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kAgriColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c.category,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: kAgriColor,
                        ),
                      ),
                    ),
                    if (c.cropName.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🌾 ${c.cropName}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      relativeTimeLabelAr(c.createdAt),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.4,
                  ),
                ),
                if (c.details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    c.details,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
                if (c.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ConsultationImageGallery(images: c.images, thumbHeight: 52),
                ],
                const SizedBox(height: 10),
                // صندوق رد المستشار الزراعي
                if (c.hasAnswer) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kAgriColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: kAgriColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded,
                                size: 14, color: kAgriColor),
                            const SizedBox(width: 5),
                            Text(
                              'رد المستشار الزراعي (${c.responderTitle})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: kAgriColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.answer,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'بانتظار رد المستشار الزراعي',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (showStatus) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.isApproved
                              ? AppColors.success.withValues(alpha: 0.12)
                              : Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: c.isApproved
                                ? AppColors.success.withValues(alpha: 0.3)
                                : Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          c.isApproved ? 'معتمدة ومنشورة' : 'بانتظار المراجعة',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: c.isApproved
                                ? AppColors.success
                                : Colors.orange,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (c.userName.isNotEmpty && !isMine)
                        Text(
                          'السائل: ${c.userName}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
                if ((isMine || isAgriAdmin) && onEdit != null) ...[
                  const SizedBox(height: 8),
                  OwnerActions(
                    keyTag: 'agri-consult-${c.id}',
                    ownerId: c.userId,
                    currentUserId: currentUserId,
                    isAdmin: isAgriAdmin,
                    itemName: 'الاستشارة',
                    editLabel: 'تعديل السؤال',
                    deleteLabel: 'حذف السؤال',
                    onEdit: onEdit ?? () {},
                    onDelete: onDelete ?? () async => false,
                  ),
                ],
                if (isAgriAdmin && onAnswer != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: kAgriColor,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onAnswer,
                      icon: const Icon(Icons.reply_rounded, size: 16),
                      label: Text(
                        c.hasAnswer ? 'تعديل الرد' : 'الرد على الاستشارة',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final List<_MonthGuideline> _monthlyCalendar = [
  const _MonthGuideline(
    month: 'يناير',
    season: 'شتاء',
    crops: [
      'قمح: ري + أزوت دفعة 2',
      'فول: ري + مكافحة المن',
      'بنجر: ري + أزوت دفعة 1',
      'برسيم: حشائش + ري'
    ],
    operations: 'مكافحة الحشائش في المحاصيل الشتوية، متابعة المن على الفول',
  ),
  const _MonthGuideline(
    month: 'فبراير',
    season: 'شتاء',
    crops: [
      'قمح: أزوت دفعة 3 + مكافحة صدأ',
      'فول: ري + مكافحة دودة الأوراق',
      'بنجر: ري منتظم',
      'بطاطس مبكرة: زراعة'
    ],
    operations: 'متابعة الصدأ على القمح، تجهيز أرض للذرة الصيفية',
  ),
  const _MonthGuideline(
    month: 'مارس',
    season: 'ربيع',
    crops: [
      'قطن: زراعة مبكرة',
      'ذرة: زراعة صيفية',
      'طماطم: زراعة',
      'خيار: زراعة'
    ],
    operations: 'بداية الموسم الصيفي، تجهيز أرض الأرز، خدمة القمح قبل الحصاد',
  ),
  const _MonthGuideline(
    month: 'أبريل',
    season: 'ربيع',
    crops: [
      'قمح: حصاد',
      'قطن: خدمة + أزوت',
      'ذرة: خدمة + أزوت',
      'أرز: تجهيز مشاتل'
    ],
    operations: 'حصاد القمح والفول، بداية زراعة المحاصيل الصيفية',
  ),
  const _MonthGuideline(
    month: 'مايو',
    season: 'صيف مبكر',
    crops: [
      'أرز: زراعة/شتل',
      'قطن: أزوت + مكافحة',
      'ذرة: أزوت دفعة 2',
      'فول صويا: زراعة'
    ],
    operations: 'زراعة الأرز، متابعة مكافحة الآفات في القطن والذرة',
  ),
  const _MonthGuideline(
    month: 'يونيو',
    season: 'صيف',
    crops: [
      'أرز: خدمة + أزوت',
      'قطن: تزهير + مكافحة',
      'ذرة: تزهير + أزوت 3',
      'عباد شمس: زراعة'
    ],
    operations: 'خدمة الأرز (أزوت + مكافحة حشائش)، مكافحة ذبابة ساق الذرة',
  ),
  const _MonthGuideline(
    month: 'يوليو',
    season: 'صيف',
    crops: [
      'أرز: طرد + أزوت',
      'قطن: عقد + مكافحة',
      'ذرة: عقد',
      'فول بلدي نيلي: زراعة'
    ],
    operations: 'متابعة طرد الأرز، مكافحة دودة اللوز في القطن',
  ),
  const _MonthGuideline(
    month: 'أغسطس',
    season: 'صيف متأخر',
    crops: ['أرز: نضج', 'قطن: نضج + تحضير حصاد', 'ذرة: نضج', 'بنجر: تجهيز أرض'],
    operations: 'بداية حصاد الذرة المبكرة، تجهيز أرض البنجر والفول الشتوي',
  ),
  const _MonthGuideline(
    month: 'سبتمبر',
    season: 'خريف',
    crops: ['أرز: حصاد', 'قطن: حصاد مبكر', 'ذرة: حصاد', 'قمح: تجهيز أرض'],
    operations: 'حصاد الأرز والذرة، تجهيز أرض المحاصيل الشتوية',
  ),
  const _MonthGuideline(
    month: 'أكتوبر',
    season: 'خريف',
    crops: ['قمح: زراعة مبكرة', 'فول: زراعة', 'بنجر: زراعة', 'برسيم: زراعة'],
    operations: 'بداية الموسم الشتوي، زراعة القمح والفول والبنجر',
  ),
  const _MonthGuideline(
    month: 'نوفمبر',
    season: 'خريف متأخر',
    crops: [
      'قمح: زراعة + ري أول',
      'فول: زراعة + ري أول',
      'بنجر: زراعة + خدمة',
      'برسيم: حشائش'
    ],
    operations: 'خدمة المحصولات الشتوية المزروعة حديثاً، مكافحة حشائش مبكرة',
  ),
  const _MonthGuideline(
    month: 'ديسمبر',
    season: 'شتاء',
    crops: [
      'قمح: خدمة + أزوت 1',
      'فول: خدمة + مكافحة من',
      'بنجر: خدمة + أزوت',
      'برسيم: حشيشة 1'
    ],
    operations: 'متابعة الإنبات، مكافحة الحشائش، أول رية للقمح',
  ),
];

final List<String> _goldenTips = [
  '🌱 تحليل التربة كل 3 سنوات أساس التسميد السليم — لا تسمد بالحدس',
  '💧 الري الحديث (تنقيط/رش) يوفر 40% ماء ويزيد المحصول 20-30%',
  '🌾 تدوير المحاصيل (قمح → ذرة → قطن → فول) يكسر دورة الآفات ويحسن التربة',
  '🐛 المكافحة المتكاملة: مراقبة → حد اقتصادي → حيوي → كيميائي (كحل أخير)',
  '🌿 البذور المعتمدة من مركز البحوث الزراعية تضمن النقاء الوراثي والإنتاجية',
  '📅 الالتزام بالمواعيد المثلى للزراعة = أعلى إنتاجية وأقل إصابات',
  '🧪 إضافة المادة العضوية (سماد بلدي/كمبوست) 10-15 م3/فدان سنوياً يحسن خصوبة التربة',
  '🔬 فحص الآفات أسبوعياً بمصائد ضوئية/فرمونية يكشف الإصابة مبكراً',
  '☀️ تجنب الرش في ساعات الحرارة (10 ص - 4 م) — رش فجراً أو غروباً',
  '📝 سجل كل عملية (تسميد، ري، رش، حصاد) — التاريخ يعلمك للموسم القادم',
];

class _MonthGuideline {
  final String month;
  final String season;
  final List<String> crops;
  final String operations;

  const _MonthGuideline({
    required this.month,
    required this.season,
    required this.crops,
    required this.operations,
  });
}

class _GuidelineCard extends StatelessWidget {
  final CropRecord crop;
  final Color color;
  const _GuidelineCard({required this.crop, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = AppColors.readableInk(color, theme.brightness);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withValues(alpha: isDark ? 0.35 : 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          trailing: Icon(Icons.keyboard_arrow_down_rounded, color: ink, size: 24),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                crop.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: color.withValues(alpha: 0.12),
                  child: Icon(Icons.eco_rounded, color: ink, size: 26),
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  crop.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: ink,
                    fontSize: 15.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  crop.season.contains('شتوي')
                      ? 'شتوي'
                      : (crop.season.contains('صيفي') ? 'صيفي' : 'حولي'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                '${crop.nameEn} • ${crop.scientificName}',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _miniPill(theme, Icons.timelapse_rounded, crop.growthPeriod, color),
                  _miniPill(theme, Icons.grain_rounded, crop.seedRate, color),
                  _miniPill(theme, Icons.trending_up_rounded, crop.yieldTarget, Colors.amber),
                ],
              ),
            ],
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, thickness: 0.7),
            const SizedBox(height: 12),
            if (crop.description.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Text(
                  crop.description,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45, fontSize: 12.5),
                ),
              ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.location_on_rounded,
              label: 'المنطقة الملائمة',
              value: crop.region,
              color: color,
            ),
            _DetailRow(
              icon: Icons.terrain_rounded,
              label: 'نوع التربة والصرف',
              value: crop.soilType,
              color: color,
            ),
            _DetailRow(
              icon: Icons.water_drop_rounded,
              label: 'نظام ومواعيد الري',
              value: crop.irrigation,
              color: const Color(0xFF1976D2),
            ),
            _DetailRow(
              icon: Icons.science_rounded,
              label: 'برنامج التسميد الموصى به',
              value: crop.fertilization,
              color: const Color(0xFFE65100),
            ),
            _DetailRow(
              icon: Icons.bug_report_rounded,
              label: 'أهم الآفات والمكافحة',
              value: crop.pests,
              color: const Color(0xFFC62828),
            ),
            _DetailRow(
              icon: Icons.eco_rounded,
              label: 'الأصناف والهجن الموصى بها',
              value: crop.varieties,
              color: color,
            ),
            _DetailRow(
              icon: Icons.agriculture_rounded,
              label: 'طريقة ومسافات الزراعة',
              value: crop.plantingMethod,
              color: color,
            ),
            _DetailRow(
              icon: Icons.content_cut_rounded,
              label: 'طريقة وميعاد الحصاد',
              value: crop.harvestMethod,
              color: color,
            ),
            _DetailRow(
              icon: Icons.monetization_on_rounded,
              label: 'الأهمية الاقتصادية',
              value: crop.economicImportance,
              color: const Color(0xFFF57F17),
            ),
            _DetailRow(
              icon: Icons.verified_user_rounded,
              label: 'المرجع والجهة العلمية المعتمدة',
              value: crop.source,
              color: color,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ink,
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: const Text(
                  'عرض صفحة المحصول التخصصية كاملة',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CropDetailScreen(crop: crop)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniPill(ThemeData theme, IconData icon, String text, Color accent) {
    final ink = AppColors.readableInk(accent, theme.brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: ink),
          const SizedBox(width: 3.5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final _MonthGuideline month;
  final Color color;
  const _MonthCard({required this.month, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = AppColors.readableInk(color, theme.brightness);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: ExpansionTile(
        trailing: Icon(Icons.keyboard_arrow_down_rounded, color: ink, size: 24),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(month.month.substring(0, 1),
              style: TextStyle(color: ink, fontWeight: FontWeight.w900)),
        ),
        title: Text(month.month,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900, color: ink)),
        subtitle: Text(month.season,
            style: theme.textTheme.bodySmall?.copyWith(color: ink)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...month.crops.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right_rounded, size: 16, color: ink),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              )),
          const Divider(height: 16),
          Text('عمليات الشهر:',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: ink, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(month.operations, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String tip;
  final Color color;
  const _TipCard({required this.tip, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_rounded, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Text(tip,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5))),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = AppColors.readableInk(color, theme.brightness);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ink),
          const SizedBox(width: 10),
          Text('$label: ',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700, color: ink)),
          Expanded(
              child: Text(value,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4))),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Chip(
      {required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

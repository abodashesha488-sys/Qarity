import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/agriculture_promo_banner.dart';
import '../../widgets/qurity_app_bar.dart';
import 'crops_screen.dart';

/// شاشة مستشارك الزراعي — إرشادات موثقة لكافة المحاصيل المصرية وشمال ووسط الدلتا
class AgriculturalAdvisorScreen extends StatefulWidget {
  const AgriculturalAdvisorScreen({super.key});

  @override
  State<AgriculturalAdvisorScreen> createState() =>
      _AgriculturalAdvisorScreenState();
}

class _AgriculturalAdvisorScreenState extends State<AgriculturalAdvisorScreen> {
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
    const color = Color(0xFF2E7D32); // أخضر داكن
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

    return Scaffold(
      appBar: const QurityAppBar(
        title: 'مستشارك الزراعي',
      ),
      body: ListView(
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
      ),
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
        // الشريط الزخرفي يبقى على لونه الأصلي: رسم 4×24 يكفيه 3.0 في السمتين.
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
    // حرف الشهر وعنوانه وسطر الفصل وأيقونة السهم والعتبة — كلها حبر على
    // سطح الكارت، فالأصلي 3.4 على سطح الداكن ولا يجتاز 4.5.
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
    // التسمية حبر بحروف 14 ثخين فقدرها 4.5، والأيقونة رسم 18 يكفيه 3.0؛
    // يستعمل الحبر الموثق واحدا حتى لا يختلف لونهما في السطر نفسه.
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

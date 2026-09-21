import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/agriculture_content_model.dart';
import '../../widgets/agriculture_content_panel.dart';
import '../../widgets/qurity_app_bar.dart';
import '../../widgets/agriculture_promo_banner.dart';

/// شاشة مستشارك الزراعي — إرشادات موثقة لمحاصيل شمال ووسط الدلتا
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
    final guidelines = _cropGuidelines.where((item) {
      final matchesCategory = switch (_selectedCategory) {
        'محاصيل شتوية' => item.season.contains('شتوي'),
        'محاصيل صيفية' => item.season.contains('صيفي'),
        'أراضي طينية' => item.soil.contains('طينية'),
        'ري حديث' => item.irrigation.contains('حديث'),
        'مكافحة متكاملة' => item.pests.isNotEmpty,
        _ => true,
      };
      final searchable = '${item.name} ${item.season} ${item.region} '
              '${item.soil} ${item.irrigation} ${item.pests}'
          .toLowerCase();
      return matchesCategory && (query.isEmpty || searchable.contains(query));
    }).toList();

    return Scaffold(
      appBar: const QurityAppBar(
        title: 'مستشارك الزراعي',
        color: color,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroSection(theme, color),
          const AgriculturePromoBanner(placement: 'svc_agricultural'),
          const AgricultureContentPanel(section: AgricultureSections.advisor),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
            decoration: InputDecoration(
              hintText: 'ابحث عن محصول أو إرشاد أو آفة...',
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
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(theme, 'الإرشادات حسب المحصول', color),
          const SizedBox(height: 12),
          if (guidelines.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('لا توجد نتائج لهذا التصنيف')),
            ),
          ...guidelines.asMap().entries.map((e) =>
              _GuidelineCard(guideline: e.value, color: color)
                  .animate(delay: (e.key * 60).ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1)),
          const SizedBox(height: 24),
          _buildSectionTitle(
              theme, 'التقويم الزراعي الشهري (شمال ووسط الدلتا)', color),
          const SizedBox(height: 12),
          ..._monthlyCalendar.asMap().entries.map((e) =>
              _MonthCard(month: e.value, color: color)
                  .animate(delay: (e.key * 60).ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1)),
          const SizedBox(height: 24),
          _buildSectionTitle(theme, 'نصائح ذهبية للمزارع', color),
          const SizedBox(height: 12),
          ..._goldenTips.asMap().entries.map((e) =>
              _TipCard(tip: e.value, color: color)
                  .animate(delay: (e.key * 60).ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1)),
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in const [
                'محاصيل شتوية',
                'محاصيل صيفية',
                'أراضي طينية',
                'ري حديث',
                'مكافحة متكاملة',
              ])
                GestureDetector(
                  onTap: () => setState(() => _selectedCategory =
                      _selectedCategory == category ? 'الكل' : category),
                  child: _Chip(
                    label: _selectedCategory == category
                        ? '✓ $category'
                        : category,
                    color: _selectedCategory == category
                        ? Colors.amber
                        : Colors.white,
                    textColor: color,
                  ),
                ),
            ],
          ),
        ],
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
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// البيانات: إرشادات المحاصيل الرئيسية
// ════════════════════════════════════════════════════════════════════

final List<_CropGuideline> _cropGuidelines = [
  const _CropGuideline(
    name: 'القمح',
    season: 'شتوي (نوفمبر - أبريل)',
    icon: Icons.grass_rounded,
    region: 'شمال ووسط الدلتا',
    soil: 'طينية ثقيلة - جيدة الصرف',
    irrigation: 'ري بالغمر كل 10-15 يوم / ري حديث كل 5-7 أيام',
    fertilization:
        'أزوت: 100-120 كجم/فدان (على 3 دفعات)\nفوسفات: 30-40 كجم P2O5/فدان\nبوتاس: 24 كجم K2O/فدان',
    pests: 'حشرة الحشد الخريفية، صدأ القمح، بقعة سيبتوريا',
    varieties: 'جميزة 11، سوهاج 3، مصر 1، سخا 94',
    yieldTarget: '18-22 أردب/فدان',
  ),
  const _CropGuideline(
    name: 'الأرز',
    season: 'صيفي (مايو - أكتوبر)',
    icon: Icons.grass_rounded,
    region: 'شمال الدلتا (كفر الشيخ، البحيرة، الدقهلية)',
    soil: 'طينية ثقيلة - تحتفظ بالماء',
    irrigation: 'غمر مستمر - مستوى ماء 5-10 سم',
    fertilization:
        'أزوت: 80-100 كجم/فدان (على دفعتين)\nفوسفات: 30 كجم P2O5/فدان\nزنك: 5 كجم/فدان (كبريتات الزنك)',
    pests: 'دودة ورق الأرز، حفار الساق، ذبابة الساق، تبقع الأوراق',
    varieties: 'جيزة 177، جيزة 178، سخا 101، سخا 104',
    yieldTarget: '3.5-4.5 طن/فدان',
  ),
  const _CropGuideline(
    name: 'الذرة الشامية',
    season: 'صيفي (أبريل - أغسطس) / نيلي (يوليو - نوفمبر)',
    icon: Icons.grass_rounded,
    region: 'شمال ووسط الدلتا',
    soil: 'طينية صفراء - جيدة التهوية',
    irrigation: 'ري حديث: كل 3-5 أيام\nري غمر: كل 7-10 أيام',
    fertilization:
        'أزوت: 120-150 كجم/فدان (على 3 دفعات)\nفوسفات: 40-50 كجم P2O5/فدان\nبوتاس: 48 كجم K2O/فدان',
    pests: 'حفار الساق، دودة الحشد الخريفية، ذبابة الساق، لفحة التبقع',
    varieties: 'هجين 10، هجين 168، هجين 310، توبة 1',
    yieldTarget: '2.5-3.5 طن/فدان',
  ),
  const _CropGuideline(
    name: 'القطن',
    season: 'صيفي (مارس - أكتوبر)',
    icon: Icons.grass_rounded,
    region: 'وسط الدلتا (الغربية، المنوفية، القليوبية)',
    soil: 'طينية صفراء - عميقة - جيدة الصرف',
    irrigation: 'ري حديث: كل 5-7 أيام\nمهم: عدم العطش في طور التزهير والعقد',
    fertilization:
        'أزوت: 60-80 كجم/فدان (على دفعتين)\nفوسفات: 30 كجم P2O5/فدان\nبوتاس: 24 كجم K2O/فدان',
    pests: 'دودة اللوز، دودة الورق، المن، ذبابة الورق، تبقع الأوراق',
    varieties: 'جيزة 94، جيزة 95، جيزة 96، جيزة 97',
    yieldTarget: '10-12 قنطار/فدان',
  ),
  const _CropGuideline(
    name: 'فول بلدي',
    season: 'شتوي (نوفمبر - أبريل)',
    icon: Icons.grass_rounded,
    region: 'شمال ووسط الدلتا',
    soil: 'طينية - جيدة الصرف',
    irrigation: 'ري غمر كل 15-20 يوم\nري حديث كل 7-10 أيام',
    fertilization:
        'أزوت: 15-20 كجم/فدان (بداية النمو)\nفوسفات: 30-40 كجم P2O5/فدان\nبوتاس: 24 كجم K2O/فدان',
    pests: 'المن، دودة الأوراق، صدأ الفول، عفن الجذور',
    varieties: 'جيزة 3، جيزة 40، جيزة 843، نوبارية 1',
    yieldTarget: '12-15 أردب/فدان',
  ),
  const _CropGuideline(
    name: 'بنجر السكر',
    season: 'شتوي (أكتوبر - مايو)',
    icon: Icons.grass_rounded,
    region: 'شمال ووسط الدلتا',
    soil: 'طينية عميقة - جيدة الصرف - خالية من الحجارة',
    irrigation: 'ري حديث: كل 5-7 أيام\nمهم: انتظام الري لزيادة نسبة السكر',
    fertilization:
        'أزوت: 80-100 كجم/فدان (على دفعتين)\nفوسفات: 40 كجم P2O5/فدان\nبوتاس: 60 كجم K2O/فدان (مهم للسكر)',
    pests: 'دودة الحشد، المن، عفن الجذور، تبقع الأوراق',
    varieties: 'جلوريا، مونوفورت، كاسندرا، فيلينا',
    yieldTarget: '25-30 طن/فدان (نسبة سكر 18-20%)',
  ),
];

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

class _CropGuideline {
  final String name;
  final String season;
  final IconData icon;
  final String region;
  final String soil;
  final String irrigation;
  final String fertilization;
  final String pests;
  final String varieties;
  final String yieldTarget;

  const _CropGuideline({
    required this.name,
    required this.season,
    required this.icon,
    required this.region,
    required this.soil,
    required this.irrigation,
    required this.fertilization,
    required this.pests,
    required this.varieties,
    required this.yieldTarget,
  });
}

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
  final _CropGuideline guideline;
  final Color color;
  const _GuidelineCard({required this.guideline, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(guideline.icon, color: color, size: 24),
        ),
        title: Text(guideline.name,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900, color: color)),
        subtitle: Text('${guideline.season} • ${guideline.region}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(
              icon: Icons.location_on_rounded,
              label: 'المنطقة',
              value: guideline.region,
              color: color),
          _DetailRow(
              icon: Icons.terrain_rounded,
              label: 'نوع التربة',
              value: guideline.soil,
              color: color),
          _DetailRow(
              icon: Icons.water_drop_rounded,
              label: 'الري',
              value: guideline.irrigation,
              color: color),
          _DetailRow(
              icon: Icons.science_rounded,
              label: 'التسميد',
              value: guideline.fertilization,
              color: color),
          _DetailRow(
              icon: Icons.bug_report_rounded,
              label: 'أهم الآفات',
              value: guideline.pests,
              color: color),
          _DetailRow(
              icon: Icons.eco_rounded,
              label: 'الأصناف الموصى بها',
              value: guideline.varieties,
              color: color),
          _DetailRow(
              icon: Icons.trending_up_rounded,
              label: 'الهدف الإنتاجي',
              value: guideline.yieldTarget,
              color: color),
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(month.month.substring(0, 1),
              style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ),
        title: Text(month.month,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900, color: color)),
        subtitle: Text(month.season,
            style: theme.textTheme.bodySmall?.copyWith(color: color)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...month.crops.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right_rounded, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              )),
          const Divider(height: 16),
          Text('عمليات الشهر:',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.w800)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text('$label: ',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700, color: color)),
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

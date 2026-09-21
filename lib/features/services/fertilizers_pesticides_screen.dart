import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/agriculture_content_model.dart';
import '../../widgets/agriculture_content_panel.dart';
import '../../widgets/agriculture_promo_banner.dart';
import '../../widgets/qurity_app_bar.dart';

/// شاشة الأسمدة والمبيدات — تبويبين: أسمدة / مبيدات
class FertilizersPesticidesScreen extends StatefulWidget {
  const FertilizersPesticidesScreen({super.key});

  @override
  State<FertilizersPesticidesScreen> createState() =>
      _FertilizersPesticidesScreenState();
}

class _FertilizersPesticidesScreenState
    extends State<FertilizersPesticidesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFC62828); // أحمر

    return Scaffold(
      appBar: QurityAppBar(
        title: 'الأسمدة والمبيدات',
        color: color,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.eco_rounded), text: 'الأسمدة'),
            Tab(icon: Icon(Icons.science_rounded), text: 'المبيدات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FertilizersTab(color: color),
          _PesticidesTab(color: color),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// تبويب الأسمدة
// ════════════════════════════════════════════════════════════════════

class _FertilizersTab extends StatefulWidget {
  final Color color;
  const _FertilizersTab({required this.color});

  @override
  State<_FertilizersTab> createState() => _FertilizersTabState();
}

class _FertilizersTabState extends State<_FertilizersTab> {
  String _selectedCategory = 'الكل';

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeroSection(context, color),
        const AgriculturePromoBanner(placement: 'agri_fertilizers'),
        const AgricultureContentPanel(section: AgricultureSections.fertilizers),
        const SizedBox(height: 20),
        _categoryFilters(color),
        const SizedBox(height: 16),
        if (_selectedCategory == 'الكل' || _selectedCategory == 'آزوتية') ...[
          _buildSectionTitle(context, 'الأسمدة الآزوتية', color),
          const SizedBox(height: 12),
          ..._nitrogenFertilizers.asMap().entries.map((e) =>
              _FertilizerCard(item: e.value, color: color)
                  .animate(delay: (e.key * 60).ms)
                  .fadeIn()
                  .slideY(begin: 0.1)),
          const SizedBox(height: 20),
        ],
        if (_selectedCategory == 'الكل' || _selectedCategory == 'فوسفاتية') ...[
          _buildSectionTitle(context, 'الأسمدة الفوسفاتية', color),
          const SizedBox(height: 12),
          ..._phosphateFertilizers.asMap().entries.map((e) =>
              _FertilizerCard(item: e.value, color: color)
                  .animate(delay: (e.key * 60).ms)
                  .fadeIn()
                  .slideY(begin: 0.1)),
          const SizedBox(height: 20),
        ],
        if (_selectedCategory == 'الكل' || _selectedCategory == 'بوتاسية') ...[
          _buildSectionTitle(context, 'الأسمدة البوتاسية', color),
          const SizedBox(height: 12),
          ..._potashFertilizers.asMap().entries.map((e) =>
              _FertilizerCard(item: e.value, color: color)
                  .animate(delay: (e.key * 60).ms)
                  .fadeIn()
                  .slideY(begin: 0.1)),
          const SizedBox(height: 20),
        ],
        if (_selectedCategory == 'الكل' || _selectedCategory == 'مركبة') ...[
          _buildSectionTitle(context, 'الأسمدة المركبة والمتخصصة', color),
          const SizedBox(height: 12),
          ..._compoundFertilizers.asMap().entries.map((e) =>
              _FertilizerCard(item: e.value, color: color)
                  .animate(delay: (e.key * 60).ms)
                  .fadeIn()
                  .slideY(begin: 0.1)),
          const SizedBox(height: 20),
        ],
        if (_selectedCategory == 'الكل' ||
            _selectedCategory == 'عضوية وحيوية') ...[
          _buildSectionTitle(context, 'الأسمدة العضوية والحيوية', color),
          const SizedBox(height: 12),
          ..._organicFertilizers.asMap().entries.map((e) =>
              _FertilizerCard(item: e.value, color: color)
                  .animate(delay: (e.key * 60).ms)
                  .fadeIn()
                  .slideY(begin: 0.1)),
          const SizedBox(height: 20),
        ],
        _buildSectionTitle(
            context, 'برامج التسميد الموصى بها (مركز البحوث الزراعية)', color),
        const SizedBox(height: 12),
        ..._fertilizationPrograms.asMap().entries.map((e) =>
            _ProgramCard(program: e.value, color: color)
                .animate(delay: (e.key * 60).ms)
                .fadeIn()
                .slideY(begin: 0.1)),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _categoryFilters(Color color) {
    const categories = [
      'الكل',
      'آزوتية',
      'فوسفاتية',
      'بوتاسية',
      'مركبة',
      'عضوية وحيوية'
    ];
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.map((category) {
          final selected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: selected,
              onSelected: (_) => setState(() => _selectedCategory = category),
              selectedColor: color,
              labelStyle: TextStyle(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.w800),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.eco_rounded,
                    color: Colors.white, size: 28)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('دليل الأسمدة المصري',
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('أسمدة معتمدة من وزارة الزراعة — معدلات وتوقيتات موثقة',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9))),
                ])),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _Chip(label: 'آزوتية', color: Colors.white, textColor: color),
            _Chip(label: 'فوسفاتية', color: Colors.white, textColor: color),
            _Chip(label: 'بوتاسية', color: Colors.white, textColor: color),
            _Chip(label: 'مركبة', color: Colors.white, textColor: color),
            _Chip(label: 'عضوية/حيوية', color: Colors.white, textColor: color),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, Color color) {
    final theme = Theme.of(context);
    return Row(children: [
      Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w900, color: color)),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════════
// تبويب المبيدات
// ════════════════════════════════════════════════════════════════════

class _PesticidesTab extends StatefulWidget {
  final Color color;
  const _PesticidesTab({required this.color});

  @override
  State<_PesticidesTab> createState() => _PesticidesTabState();
}

class _PesticidesTabState extends State<_PesticidesTab> {
  String _selectedCategory = 'الكل';

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeroSection(context, color),
        const AgriculturePromoBanner(placement: 'agri_pesticides'),
        const AgricultureContentPanel(section: AgricultureSections.pesticides),
        const SizedBox(height: 20),
        _categoryFilters(color),
        const SizedBox(height: 16),
        if (_selectedCategory == 'الكل' || _selectedCategory == 'حشرية') ...[
          _buildSectionTitle(context, 'مبيدات الحشرات', color),
          const SizedBox(height: 12),
          ..._insecticides.asMap().entries.map((e) =>
              _PesticideCard(item: e.value, color: color)
                  .animate(delay: (e.key * 60).ms)
                  .fadeIn()
                  .slideY(begin: 0.1)),
          const SizedBox(height: 20),
        ],
        if (_selectedCategory == 'الكل' || _selectedCategory == 'فطرية') ...[
          _buildSectionTitle(context, 'مبيدات الفطريات', color),
          const SizedBox(height: 12),
          ..._fungicides.asMap().entries.map((e) =>
              _PesticideCard(item: e.value, color: color)
                  .animate(delay: (e.key * 60).ms)
                  .fadeIn()
                  .slideY(begin: 0.1)),
          const SizedBox(height: 20),
        ],
        if (_selectedCategory == 'الكل' || _selectedCategory == 'حشائش') ...[
          _buildSectionTitle(context, 'مبيدات الحشائش', color),
          const SizedBox(height: 12),
          ..._herbicides.asMap().entries.map((e) =>
              _PesticideCard(item: e.value, color: color)
                  .animate(delay: (e.key * 60).ms)
                  .fadeIn()
                  .slideY(begin: 0.1)),
          const SizedBox(height: 20),
        ],
        if (_selectedCategory == 'الكل' ||
            _selectedCategory == 'نيماتودا وقوارض') ...[
          _buildSectionTitle(context, 'مبيدات النيماتودا والقوارض', color),
          const SizedBox(height: 12),
          ..._otherPesticides.asMap().entries.map((e) =>
              _PesticideCard(item: e.value, color: color)
                  .animate(delay: (e.key * 60).ms)
                  .fadeIn()
                  .slideY(begin: 0.1)),
          const SizedBox(height: 20),
        ],
        _buildSectionTitle(
            context, 'برامج المكافحة المتكاملة (IPM) للمحاصيل الرئيسية', color),
        const SizedBox(height: 12),
        ..._ipmPrograms.asMap().entries.map((e) =>
            _ProgramCard(program: e.value, color: color)
                .animate(delay: (e.key * 60).ms)
                .fadeIn()
                .slideY(begin: 0.1)),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _categoryFilters(Color color) {
    const categories = ['الكل', 'حشرية', 'فطرية', 'حشائش', 'نيماتودا وقوارض'];
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.map((category) {
          final selected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: selected,
              onSelected: (_) => setState(() => _selectedCategory = category),
              selectedColor: color,
              labelStyle: TextStyle(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.w800),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.science_rounded,
                    color: Colors.white, size: 28)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('دليل المبيدات المصري',
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                      'مبيدات مسجلة بوزارة الزراعة — برامج مكافحة متكاملة موثقة',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9))),
                ])),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _Chip(label: 'حشري', color: Colors.white, textColor: color),
            _Chip(label: 'فطري', color: Colors.white, textColor: color),
            _Chip(label: 'حشائش', color: Colors.white, textColor: color),
            _Chip(label: 'نيماتودا', color: Colors.white, textColor: color),
            _Chip(label: 'IPM', color: Colors.white, textColor: color),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, Color color) {
    final theme = Theme.of(context);
    return Row(children: [
      Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w900, color: color)),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════════
// البيانات: الأسمدة
// ════════════════════════════════════════════════════════════════════

final List<_FertilizerItem> _nitrogenFertilizers = [
  const _FertilizerItem(
      name: 'يوريا (46% N)',
      type: 'آزوتية',
      form: 'حبوب',
      dosage: '50-100 كجم/فدان',
      timing: 'على 2-3 دفعات',
      crops: 'قمح، ذرة، أرز، قطن، خضار',
      notes: 'أعلى تركيز آزوت — لا تضاف مع الكالسيوم — تروى فوراً'),
  const _FertilizerItem(
      name: 'نترات الأمونيوم (33.5% N)',
      type: 'آزوتية',
      form: 'حبوب',
      dosage: '75-150 كجم/فدان',
      timing: 'على دفعتين',
      crops: 'قمح، شعير، بنجر، خضار',
      notes:
          'سريعة المفعول — أقل تطايراً من اليوريا — تروى بعد الإضافة مباشرة'),
  const _FertilizerItem(
      name: 'كبريتات الأمونيوم (20.5% N + 24% S)',
      type: 'آزوتية',
      form: 'حبوب',
      dosage: '100-200 كجم/فدان',
      timing: 'دفعة واحدة أو اثنتين',
      crops: 'أرز، قمح في أراضي قلوية',
      notes: 'تحتوي كبريت — تحسن pH التربة القلوية — لا تخلط مع فوسفات'),
  const _FertilizerItem(
      name: 'نترات الكالسيوم (15.5% N + 19% Ca)',
      type: 'آزوتية',
      form: 'حبوب/سائل',
      dosage: '50-100 كجم/فدان',
      timing: 'مع الري أو رش ورقي',
      crops: 'طماطم، فلفل، خيار، فراولة',
      notes: 'تزود بالكالسيوم — تمنع تعفن القمة — ممتازة للرش الورقي'),
];

final List<_FertilizerItem> _phosphateFertilizers = [
  const _FertilizerItem(
      name: 'سوبر فوسفات أحادي (15-18% P2O5)',
      type: 'فوسفاتية',
      form: 'حبوب',
      dosage: '100-200 كجم/فدان',
      timing: 'أثناء تجهيز الأرض',
      crops: 'جميع المحاصيل',
      notes: 'رخيصة — تضاف عند الحرث — لا تخلط مع آزوتية أمونيوم'),
  const _FertilizerItem(
      name: 'سوبر فوسفات ثلاثي (46% P2O5)',
      type: 'فوسفاتية',
      form: 'حبوب',
      dosage: '50-75 كجم/فدان',
      timing: 'عند الزراعة',
      crops: 'قمح، ذرة، فول، بنجر، بطاطس',
      notes: 'تركيز عالٍ — اقتصادية — تضاف في السماد الأساسي'),
  const _FertilizerItem(
      name: 'فوسفات صخري (28-30% P2O5)',
      type: 'فوسفاتية',
      form: 'مسحوق',
      dosage: '200-300 كجم/فدان',
      timing: 'قبل الزراعة بشهر',
      crops: 'أراضي جديدة، حمضية',
      notes: 'بطيء الإطلاق — يحتاج تربة حمضية — عضوي معتمد'),
];

final List<_FertilizerItem> _potashFertilizers = [
  const _FertilizerItem(
      name: 'كبريتات البوتاسيوم (50% K2O + 18% S)',
      type: 'بوتاسية',
      form: 'حبوب/سائل',
      dosage: '50-100 كجم/فدان',
      timing: 'مع التسميد الأساسي',
      crops: 'بطاطس، طماطم، عنب، حمضيات، بنجر',
      notes: 'تحتوي كبريت — خالية من الكلور — محاصيل حساسة للكلور'),
  const _FertilizerItem(
      name: 'كلوريد البوتاسيوم (60% K2O)',
      type: 'بوتاسية',
      form: 'حبوب',
      dosage: '50-75 كجم/فدان',
      timing: 'أساسي أو مع الأزوت',
      crops: 'قمح، ذرة، أرز، قصب، برسيم',
      notes: 'الأرخص — تحتوي كلور — لا تستعمل لمحاصيل حساسة (تبغ، بطاطس، عنب)'),
];

final List<_FertilizerItem> _compoundFertilizers = [
  const _FertilizerItem(
      name: 'NPK 19-19-19',
      type: 'مركبة',
      form: 'حبوب/سائل',
      dosage: '50-100 كجم/فدان',
      timing: 'على 2-3 دفعات',
      crops: 'خضار، فاكهة، زينة',
      notes: 'متوازنة — لجميع مراحل النمو — ممتازة للرش الورقي'),
  const _FertilizerItem(
      name: 'NPK 20-20-20 + عناصر صغرى',
      type: 'مركبة',
      form: 'ماء',
      dosage: '2-3 كجم/فدان/رشة',
      timing: 'رش ورقي كل 10-15 يوم',
      crops: 'طماطم، فلفل، خيار، فراولة',
      notes: 'تحتوي حديد، زنك، منجنيز، نحاس، بورون، موليبدينوم'),
  const _FertilizerItem(
      name: 'NPK 12-48-8 (مبدئية)',
      type: 'مركبة',
      form: 'حبوب',
      dosage: '50-75 كجم/فدان',
      timing: 'عند الزراعة',
      crops: 'قمح، ذرة، بنجر، بطاطس',
      notes: 'عالية فوسفور — لتشجيع الجذور — تسميد أساسي'),
  const _FertilizerItem(
      name: 'NPK 8-24-24 + مغنسيوم',
      type: 'مركبة',
      form: 'حبوب',
      dosage: '100-150 كجم/فدان',
      timing: 'أساسي',
      crops: 'بطاطس، بنجر، قصب',
      notes: 'مناسبة للمحاصيل الجذرية والدرنية — تحتوي مغنسيوم'),
];

final List<_FertilizerItem> _organicFertilizers = [
  const _FertilizerItem(
      name: 'سماد بلدي متحلل',
      type: 'عضوية',
      form: 'مادة عضوية',
      dosage: '10-20 م3/فدان',
      timing: 'قبل الزراعة بشهر',
      crops: 'جميع المحاصيل',
      notes:
          'يحسن خواص التربة — يزيد قدرة الاحتفاظ بالماء — مصدر بطيء للعناصر'),
  const _FertilizerItem(
      name: 'كمبوست (سماد عضوي مصنع)',
      type: 'عضوية',
      form: 'حبيبات',
      dosage: '2-5 طن/فدان',
      timing: 'أساسي',
      crops: 'خضار، فاكهة، مشاتل',
      notes: 'خالي من مسببات الأمراض — غني بالدبال — يحفز الكائنات النافعة'),
  const _FertilizerItem(
      name: 'حمض هيوميك / فولفيك',
      type: 'حيوية',
      form: 'سائل/بودرة',
      dosage: '1-2 كجم/فدان (سائل) / 0.5-1 كجم (بودرة)',
      timing: 'مع كل رية أو رش ورقي',
      crops: 'جميع المحاصيل',
      notes: 'محسنة للتربة — تزيد كفاءة الأسمدة — تحفز الجذور'),
  const _FertilizerItem(
      name: 'بكتيريا مثبتة للنيتروجين (أزوتوبكتير، ريزوبيوم)',
      type: 'حيوية',
      form: 'سائل/خث',
      dosage: '250-500 مل/فدان',
      timing: 'تلقيح البذور أو مع الري الأول',
      crops: 'فول، فول صويا، برسيم، بقوليات',
      notes: 'تثبت نيتروجين جوي — تقلل أزوت كيميائي 20-30%'),
  const _FertilizerItem(
      name: 'فطريات الميكوريزا',
      type: 'حيوية',
      form: 'مسحوق/حبيبات',
      dosage: '1-2 كجم/فدان',
      timing: 'عند الزراعة',
      crops: 'فاكهة، زيتون، نخيل، خضار',
      notes: 'توسع مساحة الامتصاص الجذري — تزيد تحمل الإجهاد'),
];

final List<_Program> _fertilizationPrograms = [
  const _Program(
      crop: 'القمح',
      program:
          'أساسي: سوبر فوسفات 150 كجم + سلفات بوتاسيوم 50 كجم/فدان\nآزوت: يوريا 100 كجم/فدان على 3 دفعات (بداية تفريع، تفريع كامل، طرد)\nرش ورقي: هيوميك + زنك + منجنيز عند بداية التفريع والطرد'),
  const _Program(
      crop: 'الأرز',
      program:
          'أساسي: سوبر فوسفات 100 كجم + سلفات بوتاسيوم 50 كجم/فدان\nآزوت: يوريا 80 كجم/فدان على دفعتين (زراعة، بداية تفريع)\nزنك: سلفات زنك 5 كجم/فدان مع السماد الأساسي'),
  const _Program(
      crop: 'الذرة الشامية',
      program:
          'أساسي: سوبر فوسفات 150 كجم + سلفات بوتاسيوم 50 كجم/فدان\nآزوت: يوريا 150 كجم/فدان على 3 دفعات (زراعة، تفريع، تزهير)\nرشي: حمض هيوميك + عناصر صغرى عند التزهير'),
  const _Program(
      crop: 'القطن',
      program:
          'أساسي: سوبر فوسفات 100 كجم + سلفات بوتاسيوم 50 كجم/فدان\nآزوت: نترات أمونيوم 70 كجم/فدان على دفعتين (تزهير، عقد)\nبوتاسيوم إضافي: سلفات بوتاسيوم 50 كجم عند بداية التزهير'),
  const _Program(
      crop: 'البطاطس',
      program:
          'أساسي: سماد بلدي 20 م3 + سوبر فوسفات 200 كجم + سلفات بوتاسيوم 100 كجم/فدان\nآزوت: نترات كالسيوم 150 كجم/فدان على 3 دفعات\nرش ورقي: كالسيوم + بورون + هيوميك أسبوعياً من التزهير'),
  const _Program(
      crop: 'طماطم (صوب/حقل)',
      program:
          'أساسي: كمبوست 5 طن + NPK 12-48-8 100 كجم/فدان\nآزوت: نترات كالسيوم 200 كجم/فدان على دفعات أسبوعية\nرش ورقي: 19-19-19 + كالسيوم + بورون + عناصر صغرى كل 7-10 أيام'),
];

// ════════════════════════════════════════════════════════════════════
// البيانات: المبيدات
// ════════════════════════════════════════════════════════════════════

final List<_PesticideItem> _insecticides = [
  const _PesticideItem(
      name: 'إيميداكلوبريد 20% SL',
      group: 'نيونيكوتينويد',
      target: 'من، ذبابة بيضاء، ثربس، جاسيد',
      crops: 'قطن، خضار، فاكهة، زينة',
      rate: '50-100 سم3/فدان',
      phi: '7-14 يوم',
      notes: 'جهازي — يمتص ويمتد — لا يستخدم أثناء الإزهار لحماية النحل'),
  const _PesticideItem(
      name: 'أسيتاميبريد 20% SP',
      group: 'نيونيكوتينويد',
      target: 'من، ذبابة بيضاء، ورقة القطن',
      crops: 'قطن، طماطم، خيار، فلفل',
      rate: '30-50 جم/فدان',
      phi: '7 يوم',
      notes: 'أقل سمية للنحل — فعال على طور الحورية'),
  const _PesticideItem(
      name: 'كلوربيريفوس 48% EC',
      group: 'فوسفور عضوي',
      target: 'حفار الساق، دودة ورق، دودة الحشد',
      crops: 'ذرة، قصب، أرز، قمح',
      rate: '1-1.5 لتر/فدان',
      phi: '21 يوم',
      notes:
          'ملامس ومعدي — واسع الطيف — فترة انتظار طويلة — مقيد في بعض الدول'),
  const _PesticideItem(
      name: 'بروفينوفوس 50% EC',
      group: 'فوسفور عضوي',
      target: 'دودة اللوز، دودة الورق، ثربس',
      crops: 'قطن، طماطم، بطاطس',
      rate: '1 لتر/فدان',
      phi: '14 يوم',
      notes: 'ملامس ومعدي — جيد لدودة اللوز — لا يخلط مع قلويات'),
  const _PesticideItem(
      name: 'لامبدا سايهالوثرين 5% EC',
      group: 'بيرثرويد',
      target: 'حفار الساق، دودة ورق، حشرات ليلية',
      crops: 'ذرة، قطن، قمح، خضار',
      rate: '200-300 سم3/فدان',
      phi: '7-14 يوم',
      notes: 'ملامس — سريع المفعول — سمية عالية للأسماك — لا يخلط مع قلويات'),
  const _PesticideItem(
      name: 'سبينوساد 24% SC',
      group: 'سبينوسين',
      target: 'دودة ورق، دودة حشد، حفار ثمار',
      crops: 'طماطم، فلفل، خيار، فاكهة',
      rate: '50-100 سم3/فدان',
      phi: '3-7 يوم',
      notes: 'بيولوجي المصدر — آمن للنحل بعد جفاف الرش — فترة انتظار قصيرة'),
  const _PesticideItem(
      name: 'أبامكتين 1.8% EC',
      group: 'أفيرمكتين',
      target: 'عثة ورق، ثربس، عثة ثمار',
      crops: 'حمضيات، عنب، رمان، خضار',
      rate: '50-75 سم3/فدان',
      phi: '7-14 يوم',
      notes:
          'ممتد ورقي — يخترق الورقة — لا يستخدم فوق 30°م — سمية عالية للنحل'),
  const _PesticideItem(
      name: 'بيفنتيلين 25% EC',
      group: 'بيرثرويد',
      target: 'حشرات تربة، يرقات، سوسة',
      crops: 'بطاطس، بنجر، قصب، ذرة',
      rate: '400-500 سم3/فدان',
      phi: '21 يوم',
      notes: 'رش تربة — مكافحة يرقات في التربة — فترة انتظار طويلة'),
];

final List<_PesticideItem> _fungicides = [
  const _PesticideItem(
      name: 'مانكوزيب 80% WP',
      group: 'ديثيوكاربامات',
      target: 'لفحة متأخرة، تبقع، أنثراكنوز',
      crops: 'طماطم، بطاطس، عنب، خيار',
      rate: '200-300 جم/فدان',
      phi: '7-14 يوم',
      notes:
          'وقائي واسع الطيف — متعدد المواقع — لا تظهر مقاومة — أساس برامج IPM'),
  const _PesticideItem(
      name: 'كليوروثالونيل 75% WP',
      group: 'كلورونايتريل',
      target: 'لفحة مبكرة/متأخرة، تبقع',
      crops: 'طماطم، بطاطس، فول، فول سوداني',
      rate: '200-300 جم/فدان',
      phi: '7-10 يوم',
      notes: 'واقي قوي — لا يخترق — يخلب مع جهازي'),
  const _PesticideItem(
      name: 'توبوكونازول 25% EC',
      group: 'تريازول',
      target: 'صدأ، بياض زغبي، أنثراكنوز',
      crops: 'قمح، شعير، عنب، تفاح، مانجو',
      rate: '75-100 سم3/فدان',
      phi: '14-21 يوم',
      notes:
          'جهازي علاجي ووقائي — حركة علوية — جرعة واحدة في الموسم لتجنب المقاومة'),
  const _PesticideItem(
      name: 'أزوكسيستروبين 23% SC',
      group: 'سترولوبيرين',
      target: 'صدأ، لفحة، بياض، أنثراكنوز',
      crops: 'قمح، أرز، ذرة، عنب، طماطم',
      rate: '50-75 سم3/فدان',
      phi: '14-21 يوم',
      notes: 'جهازي عابر للورقة — وقائي وعلاجي — لا يزيد عن 2 رشة/موسم'),
  const _PesticideItem(
      name: 'بوسكاليد 25% + بيراكلوستروبين 13% WG',
      group: 'SDHI + سترولوبيرين',
      target: 'بياض زغبي، أنثراكنوز، بقع',
      crops: 'عنب، تفاح، كمثرى، فراولة',
      rate: '50-75 جم/فدان',
      phi: '14-21 يوم',
      notes: 'تركيبة ثنائية — وقائية وعلاجية — إدارة مقاومة ممتازة'),
  const _PesticideItem(
      name: 'فوسفونات ألومنيوم 80% WP',
      group: 'فوسفونات',
      target: 'لفحة متأخرة، عفن جذري، فيتوفثورة',
      crops: 'بطاطس، طماطم، فلفل، خيار',
      rate: '150-200 جم/فدان',
      phi: '7 يوم',
      notes: 'جهازي صاعد ونازل — ممتاز للعفن الجذري واللفحة — آمن نسبياً'),
];

final List<_PesticideItem> _herbicides = [
  const _PesticideItem(
      name: 'جلايفوسات 48% SL',
      group: 'جلايسين',
      target: 'حشائش عريضة وضيقة (كلي)',
      crops: 'قبل زراعة جميع المحاصيل',
      rate: '2-4 لتر/فدان',
      phi: 'غير مطبق',
      notes:
          'جهازي كلي — يقتل كل الحشائش — لا يترك بقايا — لا يرش على المحصول'),
  const _PesticideItem(
      name: 'بي نوكسيل 75% WG',
      group: 'سولفونيل يوريا',
      target: 'حشائش عريضة في قمح/شعير',
      crops: 'قمح، شعير',
      rate: '15-20 جم/فدان',
      phi: '60 يوم',
      notes: 'انتقائي بعد الإنبات — يقتل عريضة الأوراق — لا يضر بالقمح'),
  const _PesticideItem(
      name: 'توبيرام 50% WP',
      group: 'أورون',
      target: 'حشائش عريضة وضيق في أرز',
      crops: 'أرز',
      rate: '2-3 كجم/فدان',
      phi: '60 يوم',
      notes:
          'ما قبل الإنبات أو مبكر — يحتاج ماء راكد — لا يستخدم في أراضي رملية'),
  const _PesticideItem(
      name: 'سايالوفوب 10.8% EC',
      group: 'أريلوكسي فينوكسي بروبيونات',
      target: 'حشائش ضيقة (نجيليات) في عريضة',
      crops: 'قطن، فول، بنجر، بطاطس، بصل',
      rate: '1-1.5 لتر/فدان',
      phi: '60 يوم',
      notes:
          'انتقائي للنجيليات — لا يضر بمحاصيل عريضة الأوراق — يحتاج مادة مساعدة'),
  const _PesticideItem(
      name: 'أوكسي فلورفين 24% EC',
      group: 'ديفيني إيثر',
      target: 'حشائش عريضة وضيق (ما قبل/بعد إنبات مبكر)',
      crops: 'بصل، ثوم، كرنب، بروكلي',
      rate: '1-2 لتر/فدان',
      phi: '60 يوم',
      notes: 'ملامس — يستخدم قبل أو بعد إنبات المحصول بفترة — حساس للري'),
];

final List<_PesticideItem> _otherPesticides = [
  const _PesticideItem(
      name: 'أبامكتين + ثياميثوكسام',
      group: 'أفيرمكتين + نيونيكوتينويد',
      target: 'نيماتودا + حشرات مبكرة',
      crops: 'بطاطس، طماطم، فلفل، فراولة',
      rate: '100-150 سم3/فدان',
      phi: '14-21 يوم',
      notes: 'تركيبة ثنائية — بذور/تربة — وقائية مبكرة'),
  const _PesticideItem(
      name: 'فوستهيازيت 10% GR',
      group: 'فوسفور عضوي',
      target: 'نيماتودا جذور',
      crops: 'موز، طماطم، خيار، بطيخ',
      rate: '15-20 كجم/فدان',
      phi: '60 يوم',
      notes: 'حبوب في التربة — تقتل النيماتودا — تضاف عند الزراعة'),
  const _PesticideItem(
      name: 'زئبق الفوسفيد 56% حبوب',
      group: 'فوسفيد معدني',
      target: 'قوارض (فئران، جرذان)',
      crops: 'مخازن، حقول، قنوات',
      rate: '3-5 جم/جحر',
      phi: 'غير مطبق',
      notes: 'غاز فوسفين — شديد السمية — يستخدم بحذر شديد — ترخيص مطلوب'),
  const _PesticideItem(
      name: 'بروماديولون 0.005% طعوم',
      group: 'أنتي كواجيولانت',
      target: 'فئران، جرذان',
      crops: 'مخازن، حقول، مباني',
      rate: 'طعم حر',
      phi: 'غير مطبق',
      notes: 'مضاد تخثر — موت خلال 3-5 أيام — محطات طعم آمنة'),
];

final List<_Program> _ipmPrograms = [
  const _Program(
      crop: 'القطن',
      program:
          '1. بذور معالجة (إيميداكلوبريد + مانكوزيب)\n2. مراقبة بمصائد فرمونية (دودة اللوز)\n3. حد اقتصادي: 5% تفاح مصابة أو 3 يرقات/نبات\n4. رش: سبينوساد/إيمامكتين عند تجاوز الحد\n5. فطريات: توبوكونازول/أزوكسيستروبين وقائي\n6. حفظ الأعداء الحيوية: لا رش واسع الطيف مبكراً'),
  const _Program(
      crop: 'الطماطم',
      program:
          '1. مشاتل نظيفة + تعقيم تربة\n2. مصائد صفراء/زرقاء (ذبابة بيضاء/ثربس)\n3. وقائي: مانكوزيب + نحاس (فطريات)\n4. حشري: سبينوساد/أبامكتين (دودة ثمار/عثة)\n5. فيروس: لا علاج — إعدام نباتات مصابة\n6. تدوير: لا طماطم بعد باذنجان/فلفل'),
  const _Program(
      crop: 'القمح',
      program:
          '1. بذور معالجة (مبيد بذور فطري/حشري)\n2. حشائش: ب نوكسيل/توبيرام مبكر\n3. صدأ: مراقبة — توبوكونازول/أزوكسيستروبين عند ظهور\n4. حشرات: لامبدا/كلوربيريفوس عند حد اقتصادي (حفار/حشد)\n5. حصاد جاف — تخزين نظيف'),
  const _Program(
      crop: 'الأرز',
      program:
          '1. مشاتل: معالجة بذور (فطري + حشري)\n2. حشائش: توبيرام/بيرازوسلفون ما قبل/بعد إنبات\n3. حفار ساق: مراقبة — كلوربيريفوس/كارتاب عند 10% نباتات مصابة\n4. فطريات: تريكوسايكلازول/أزوكسيستروبين (لفحة/تبقع)\n4. ماء: إدارة مستوى الماء يكافح حشائش ويرقات'),
  const _Program(
      crop: 'الذرة',
      program:
          '1. بذور معالجة (كلوربيريفوس/إيميداكلوبريد)\n2. حشائش: أتريزين/نوكسيل بعد إنبات\n3. حفار ساق: مراقبة فرمونية — سبينوساد/كلورانتانيلبرول عند 5% إصابات\n4. حشد خريفية: كشف مبكر — إيمامكتين/كلورانتانيلبرول\n5. فطريات: أزوكسيستروبين/بيراكلوستروبين (صدأ/لفحة)'),
];

// ════════════════════════════════════════════════════════════════════
// نماذج البيانات والبطاقات
// ════════════════════════════════════════════════════════════════════

class _FertilizerItem {
  final String name;
  final String type;
  final String form;
  final String dosage;
  final String timing;
  final String crops;
  final String notes;

  const _FertilizerItem({
    required this.name,
    required this.type,
    required this.form,
    required this.dosage,
    required this.timing,
    required this.crops,
    required this.notes,
  });
}

class _PesticideItem {
  final String name;
  final String group;
  final String target;
  final String crops;
  final String rate;
  final String phi;
  final String notes;

  const _PesticideItem({
    required this.name,
    required this.group,
    required this.target,
    required this.crops,
    required this.rate,
    required this.phi,
    required this.notes,
  });
}

class _Program {
  final String crop;
  final String program;
  const _Program({required this.crop, required this.program});
}

class _FertilizerCard extends StatelessWidget {
  final _FertilizerItem item;
  final Color color;
  const _FertilizerCard({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.3))),
      child: ExpansionTile(
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.eco_rounded, color: color, size: 24)),
        title: Text(item.name,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900, color: color)),
        subtitle: Text('${item.type} • ${item.form}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _DetailRow(label: 'المحاصيل', value: item.crops, color: color),
          _DetailRow(label: 'المعدل', value: item.dosage, color: color),
          _DetailRow(label: 'التوقيت', value: item.timing, color: color),
          _DetailRow(
              label: 'فترة ما قبل الحصاد (PHI)',
              value: item.type == 'حيوية' ? 'لا توجد' : 'حسب التوصيات',
              color: color),
          _DetailRow(label: 'ملاحظات هامة', value: item.notes, color: color),
        ],
      ),
    );
  }
}

class _PesticideCard extends StatelessWidget {
  final _PesticideItem item;
  final Color color;
  const _PesticideCard({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.3))),
      child: ExpansionTile(
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.science_rounded, color: color, size: 24)),
        title: Text(item.name,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900, color: color)),
        subtitle: Text('${item.group} • ${item.phi}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _DetailRow(
              label: 'المجموعة الكيميائية', value: item.group, color: color),
          _DetailRow(label: 'يستهدف', value: item.target, color: color),
          _DetailRow(label: 'المحاصيل', value: item.crops, color: color),
          _DetailRow(label: 'معدل الاستخدام', value: item.rate, color: color),
          _DetailRow(
              label: 'فترة ما قبل الحصاد (PHI)', value: item.phi, color: color),
          _DetailRow(label: 'ملاحظات هامة', value: item.notes, color: color),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final _Program program;
  final Color color;
  const _ProgramCard({required this.program, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.3))),
      child: ExpansionTile(
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.menu_book_rounded, color: color, size: 24)),
        title: Text(program.crop,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900, color: color)),
        subtitle: Text('برنامج تسميد/مكافحة متكامل',
            style: theme.textTheme.bodySmall?.copyWith(color: color)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SelectableText(program.program,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DetailRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.circle_rounded, size: 8, color: color),
        const SizedBox(width: 10),
        Text('$label: ',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: color)),
        Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4))),
      ]),
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
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

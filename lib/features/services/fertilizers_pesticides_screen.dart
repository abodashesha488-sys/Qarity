import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
          'أساسي: سوبر فوسفات 150 كجم + سلفات بوتاسيوم 50 كجم/فدان\nآزوت: يوريا 100 كجم/فدان على 3 دفعات (رية المحاياة، رية التفريع، طرد السنابل)\nرش ورقي: عناصر صغرى (زنك + حديد + منجنيز) + هيوميك عند التفريع'),
  const _Program(
      crop: 'الأرز',
      program:
          'أساسي: سوبر فوسفات 100 كجم + سلفات بوتاسيوم 50 كجم/فدان في الحرثة الأخيرة\nآزوت: يوريا 80 كجم/فدان على دفعتين (قبل الشتل/الزراعة، عند بداية التفريع)\nزنك: سلفات زنك 5 كجم/فدان خلطاً مع التراب الناعم قبل الشتل مباشرة'),
  const _Program(
      crop: 'الذرة الشامية',
      program:
          'أساسي: سوبر فوسفات 150 كجم + سلفات بوتاسيوم 50 كجم/فدان\nآزوت: يوريا 150 كجم/فدان على 3 دفعات (رية المحاياة، قبل الرية الثانية، قبل التزهير)\nرش ورقي: زنك مخلبي + بورون قبل طرد الشواشي لدعم الإخصاب والامتلاء'),
  const _Program(
      crop: 'القطن',
      program:
          'أساسي: سوبر فوسفات 100 كجم + سلفات بوتاسيوم 50 كجم/فدان\nآزوت: نترات أمونيوم 70 كجم/فدان على دفعتين (بعد الخف، وبداية التزهير)\nبوتاسيوم إضافي: رش سلفات بوتاسيوم أو سترات بوتاسيوم مرتين في طور الوسواس وتكوين اللوز'),
  const _Program(
      crop: 'البطاطس',
      program:
          'أساسي: سماد بلدي 20 م3 + سوبر فوسفات 200 كجم + سلفات بوتاسيوم 100 كجم/فدان\nآزوت: نترات نشادر/كالسيوم 150 كجم/فدان مقسمة على دفعات الري\nرش ورقي: كالسيوم مخلبي وبورون لدعم صلابة القشرة ومنع التفرغ الداخلي'),
  const _Program(
      crop: 'طماطم (صوب/حقل)',
      program:
          'أساسي: كمبوست 5 طن + سوبر فوسفات 150 كجم + كبريت زراعي 50 كجم/فدان\nتسميد بالري: نترات كالسيوم وبوتاسيوم ونترات نشادر ببرنامج أسبوعي متدرج\nرش ورقي: NPK متوازن + عناصر صغرى وبورون أثناء التزهير والعقد'),
  const _Program(
      crop: 'فول بلدي',
      program:
          'أساسي: سوبر فوسفات 150 كجم + سلفات بوتاسيوم 50 كجم/فدان عند الخدمة\nآزوت: جرعة منشطة 15 كجم يوريا فقط عند رية المحاياة (يعتمد على العقد الجذرية)\nرش ورقي: موليبدنوم وعناصر صغرى لتحفيز بكتيريا التثبيت وعقد الأزهار'),
  const _Program(
      crop: 'بنجر السكر',
      program:
          'أساسي: سوبر فوسفات 200 كجم + سلفات بوتاسيوم 75 كجم/فدان\nآزوت: 80-100 كجم آزوت صافي على دفعتين ويمنع تماماً بعد عمر 90-100 يوم لرفع نسبة السكر\nرش ورقي: بورون مرتين عند عمر 60 و90 يوماً لمنع مرض القلب الأسود'),
  const _Program(
      crop: 'قصب السكر',
      program:
          'أساسي: سوبر فوسفات 200 كجم + سلفات بوتاسيوم 100 كجم/فدان\nآزوت: 180-210 كجم آزوت صافي على 3-4 دفعات مع الريات حتى منتصف الصيف\nرش ورقي: عناصر صغرى وزنك أثناء التفريع والاستطالة'),
  const _Program(
      crop: 'عباد الشمس',
      program:
          'أساسي: سوبر فوسفات 100 كجم + سلفات بوتاسيوم 50 كجم/فدان\nآزوت: 60-80 كجم يوريا على دفعتين قبل رية المحاياة والرية التالية\nرش ورقي: بورون عند ظهور البرعم الزهري لزيادة نسبة الإخصاب ونسبة الزيت'),
  const _Program(
      crop: 'فول الصويا',
      program:
          'أساسي: سوبر فوسفات 150 كجم + سلفات بوتاسيوم 50 كجم/فدان\nتلقيح عقدي: عقدين الصويا للبذور قبل الزراعة مباشرة\nآزوت: جرعة تنشيطية 15 كجم/فدان عند المحاياة فقط\nرش ورقي: فوسفور وبوتاسيوم وبورون أثناء التزهير وامتلاء القرون'),
  const _Program(
      crop: 'السمسم',
      program:
          'أساسي: سوبر فوسفات 100 كجم + سلفات بوتاسيوم 50 كجم/فدان\nآزوت: 40-50 كجم نترات نشادر على دفعتين خفيفتين مع الري\nرش ورقي: عناصر صغرى وزنك عند بداية تكوين الكبسولات'),
  const _Program(
      crop: 'البرسيم الحجازي',
      program:
          'أساسي: سوبر فوسفات 200 كجم + كبريت 50 كجم + سلفات بوتاسيوم 50 كجم/فدان\nبعد كل حشة: سلفات بوتاسيوم 25 كجم + فوسفات 25 كجم/فدان لدعم النمو الجديد\nرش ورقي: مغنسيوم وحديد وبورون لتحسين الاخضرار والبروتين العلفي'),
  const _Program(
      crop: 'الشعير والشوفان',
      program:
          'أساسي: سوبر فوسفات 100 كجم + سلفات بوتاسيوم 25 كجم/فدان\nآزوت: يوريا 50-70 كجم/فدان على دفعتين (المحاياة والتفريع)\nملاحظة: تقليل الآزوت في الأراضي المطرية لتجنب الرقاد'),
  const _Program(
      crop: 'الترمس والحمص والعدس',
      program:
          'أساسي: سوبر فوسفات 100-150 كجم/فدان + سلفات بوتاسيوم 25 كجم\nتلقيح بكتيري بالريزوبيوم مع البذور\nآزوت: جرعة منشطة خفيفة 10-15 كجم مع رية المحاياة\nرش ورقي: فوسفور وزنك وموليبدنوم قبل التزهير'),
  const _Program(
      crop: 'البصل والثوم',
      program:
          'أساسي: سماد بلدي 15 م3 + سوبر فوسفات 150 كجم + كبريت زراعي 50 كجم + سلفات بوتاسيوم 50 كجم\nآزوت: 90-120 كجم نترات نشادر مقسمة على 3-4 دفعات وتوقف قبل الحصاد بشهر\nرش ورقي: بوتاسيوم وبورون وكبريت ميكروني لتحسين التحجيم والصلابة التخزينية'),
  const _Program(
      crop: 'الخيار والقرعيات (بطيخ وشمام)',
      program:
          'أساسي: كمبوست 5 طن + NPK 15-15-15 100 كجم + سوبر فوسفات 100 كجم/فدان\nبالتنقيط: برنامج متوازن NPK مع زيادة البوتاسيوم في مرحلة امتلاء الثمار\nرش ورقي: كالسيوم وبورون لمنع تنفيل الأزهار وعفن الطرف الزهري'),
  const _Program(
      crop: 'الفلفل والباذنجان والبامية',
      program:
          'أساسي: سماد بلدي 15 م3 + سوبر فوسفات 150 كجم + سلفات بوتاسيوم 50 كجم\nآزوت: نترات كالسيوم ونترات نشادر بانتظام مع دفعات الري\nرش ورقي: سترات بوتاسيوم + طحالب بحرية + بورون لدعم استمرار التزهير والعقد'),
  const _Program(
      crop: 'البطاطا الحلوة',
      program:
          'أساسي: سوبر فوسفات 150 كجم + سلفات بوتاسيوم 75 كجم/فدان\nآزوت: نترات نشادر 60-80 كجم/فدان على دفعتين فقط وتجنب الإفراط الآزوتي لعدم هيجان العرش على حساب الجذور\nرش ورقي: بوتاسيوم فوسفيت لدعم التدرن'),
  const _Program(
      crop: 'البرتقال والموالح (الحمضيات)',
      program:
          'شتوي (ديسمبر/يناير): سماد بلدي 10-15 م3 + سوبر فوسفات 100 كجم + كبريت 50 كجم\nربيع وصيف: NPK مقسم شهرياً مع زيادة الآزوت في النمو الخضري والبوتاسيوم في التحجيم\nرش ورقي: زنك وحديد ومنجنيز مخلبي مرتين في الربيع وبورون قبل التزهير'),
  const _Program(
      crop: 'العنب',
      program:
          'شتوي: كمبوست 5 طن + سوبر فوسفات 100 كجم + سلفات بوتاسيوم 50 كجم\nموسمي: آزوت حتى نهاية العقد ثم تحول تدريجي للبوتاسيوم لتحسين حلاوة الحبات ولونها\nرش ورقي: كالسيوم مخلبي وبورون لدعم تماسك الحبات ومنع التشقق'),
  const _Program(
      crop: 'المانجو',
      program:
          'شتوي: خدمة عضوية متحللة + سوبر فوسفات وسلفات نشادر\nما بعد العقد: سلفات بوتاسيوم ونترات كالسيوم بالتبادل مع الري بالتنقيط\nرش ورقي: بورون وموليبدنوم عند انتفاخ البراعم، وعناصر صغرى بعد اكتمال العقد'),
  const _Program(
      crop: 'الزيتون',
      program:
          'شتوي: سماد عضوي 10 م3 + سوبر فوسفات 75 كجم + سلفات بوتاسيوم 50 كجم\nموسمي: آزوت معتدل في الربيع وبوتاسيوم مركز في الصيف أثناء امتلاء اللب وبناء الزيت\nرش ورقي: بورون قبل التزهير وزنك وحديد لدعم المعاومة'),
  const _Program(
      crop: 'الرمان والتين',
      program:
          'أساسي شتوي: سماد عضوي + سوبر فوسفات 100 كجم + كبريت 25 كجم\nأثناء الإثمار: سلفات بوتاسيوم 50 كجم + نترات كالسيوم لدعم مرونة القشرة ومنع تشقق الثمار\nرش ورقي: كالسيوم وبورون شهرياً من العقد حتى قبل الحصاد'),
  const _Program(
      crop: 'البلح ونخيل التمر',
      program:
          'شتوي: سماد بلدي متحلل 25 كجم/نخلة + سوبر فوسفات 1.5 كجم + كبريت 1 كجم\nموسمي: سلفات نشادر 2 كجم/نخلة على 3 دفعات + سلفات بوتاسيوم 2 كجم عند مرحلة الخلال والبسر\nرش ورقي: مغنسيوم وبورون على السعف والشماريخ'),
  const _Program(
      crop: 'الكتان وحبة البركة',
      program:
          'أساسي: سوبر فوسفات 100 كجم + سلفات بوتاسيوم 25 كجم/فدان\nآزوت: 40-50 كجم نترات نشادر (الكتان يقلل آزوته لمنع الرقاد وحفظ جودة الألياف)\nرش ورقي: عناصر صغرى وفوسفور مخلبي قبل التزهير'),
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
          '1. بذور معالجة (إيميداكلوبريد + مانكوزيب)\n2. مراقبة بمصائد فرمونية (دودة اللوز الشوكية والقرنفلية)\n3. حد اقتصادي: 5% لوز مصاب أو 3 يرقات/100 نبات\n4. رش: سبينوساد/إيمامكتين بنزوات عند تجاوز الحد\n5. فطريات: توبوكونازول/أزوكسيستروبين وقائي للأصداء\n6. حفظ الأعداء الحيوية: تجنب الرش واسع الطيف في طور البادرات'),
  const _Program(
      crop: 'الطماطم',
      program:
          '1. مشاتل نظيفة + تعقيم تربة شمسي أو حيوي\n2. مصائد صفراء لاصقة (ذبابة بيضاء) وزرقاء (تربس)\n3. وقائي: مانكوزيب + هيدروكسيد نحاس (فطريات وبكتيريا)\n4. حشري: سبينوساد/أبامكتين/كلورانتانيلبرول (دودة ثمار وتوتا أبسلوتا)\n5. فيروس تجعد الأوراق: لا علاج كيميائي — إعدام الشتلات ومكافحة الذبابة فوراً\n6. تدوير زراعي: منع زراعة الطماطم بعد باذنجان أو بطاطس'),
  const _Program(
      crop: 'القمح',
      program:
          '1. تقاوي معتمدة ومعاملة بمطهر فطري (تيكسازول/مانكوزيب)\n2. مكافحة حشائش: مبيدات عريضة ورفيعة الأوراق مبكراً عند عمر 3-4 ورقات\n3. أصداء القمح (البرتقالي والأصفر والأسود): فحص دوري ورش توبوكونازول أو أزوكسيستروبين فور ظهور البثرات الأولى\n4. الحشرات: حشرة الحشد والمن — مبيد متخصص عند تجاوز الكثافة الحرجة\n5. حصاد جاف وتطهير الشون والمخازن بحبوب الفوسفين'),
  const _Program(
      crop: 'الأرز',
      program:
          '1. مشاتل: معاملة بذور بمطهر فطري + نقع في ماء جاري\n2. حشائش المشاتل والمستديم: مبيدات متخصصة (بيرازوسلفون/بينوكسولام) مع ضبط منسوب الماء\n3. حفار ساق الأرز: مراقبة الفراشات واللطع — معاملة بالكلوربيريفوس أو الكارتاب\n4. اللفحة وتبقع الأوراق: رش تريسيكلازول أو أزوكسيستروبين وقائياً عند طرد السنابل\n5. تجفيف الحقل دورياً لتهوية الجذور وتثبيط الفطريات'),
  const _Program(
      crop: 'الذرة الشامية',
      program:
          '1. بذور معالجة (إيميداكلوبريد + ثيوديكارب)\n2. دودة الحشد الخريفية: فحص بلعوم النبات أسبوعياً ورش إيمامكتين بنزوات أو كلورانتانيلبرول عند 5% إصابات\n3. ثاقبات الذرة وحفار الساق: مصائد فرمونية ورش موضعي في قلب النبات\n4. أعفان الكيزان واللفحة: أصناف مقاومة معتدلة الرطوبة وعدم زيادة الكثافة النباتية'),
  const _Program(
      crop: 'البطاطس',
      program:
          '1. تقاوي خالية من الفيروسات ومعاملة بمسحوق الكبريت والمطهر الفطري\n2. الندوة المتأخرة والمبكرة: رش وقائي بالمانكوزيب ورش علاجي بالدايمثومورف أو السيموكسانيل\n3. فراشة درنات البطاطس: الترديم الجيد حول الجذور ورش بيولوجي بالباسيلس أو سبينوساد\n4. الحفار والدودة القارضة: طعوم سامة بالردة والمبيد قبل الزراعة\n5. تعفير الدرنات عند التخزين بالبكتيريا النافعة أو الكبريت الميكروني'),
  const _Program(
      crop: 'بنجر السكر',
      program:
          '1. التبكير في الزراعة واستخدام بذور مغلفة معقمة\n2. دودة ورق القطن والحشد: رش إندوكساكارب أو كلورانتانيلبرول عند الفقس\n3. ذبابة أوراق البنجر: رش جهازي خفيف عند ظهور الأنفاق الشفافة بالأوراق\n4. التبقع السركسبوري: رش مركب نحاسي أو ديفينوكونازول عند ارتفاع الرطوبة\n5. نيماتودا الحوصلات: دورة زراعية ثلاثية وتجنب الزراعة في بؤر الإصابة'),
  const _Program(
      crop: 'قصب السكر',
      program:
          '1. انتخاب عقل تقاوي سليمة من حقول خالية من الإصابة\n2. حفار القصب الصغير والكبير: إطلاق طفيل التريكوجراما ومكافحة حيوية متقدمة\n3. الحشرة القشرية والبق الدقيقي: تنظيف القمم والأوراق الجافة والري المنتظم\n4. مرض التفحم: حرق السيقان المصابة وزراعة أصناف معتمدة مقاومة'),
  const _Program(
      crop: 'البصل والثوم',
      program:
          '1. تربس البصل: فحص قلب النبات والرش بمبيد سبينوساد أو أسيتاميبريد مع مادة لاصقة ناشرة\n2. البياض الزغبي واللطعة الأرجوانية: رش مانكوزيب وقائياً وأوكساديكسيل/ميتالاكسيل عند الرطوبة والضباب\n3. العفن الأبيض: معاملة الشتلات والفصوص بمبيد تيبوكونازول وتجنب الحقول المصابة\n4. منع الري قبل الحصاد بـ15-20 يوماً لمنع أعفان الرقبة أثناء التخزين'),
  const _Program(
      crop: 'الخيار والقرعيات (بطيخ وشمام)',
      program:
          '1. البياض الدقيقي: رش كبريت ميكروني وقائياً وبنزوات/تريازول عند ظهور الميسيليوم الأبيض\n2. البياض الزغبي: رش نحاس أو بروباموكارب هيدروكلوريد عند الضباب والأمطار\n3. الذبابة البيضاء والتربس: ألواح صفراء لاصقة ورش مبيدات جهازية آمنة ذات فترة أمان (PHI) قصيرة\n4. أعفان الجذور والفيوزاريوم: التعقيم الشمسي وزراعة هجن مطعومة على أصول مقاومة'),
  const _Program(
      crop: 'البقوليات (فول وحمص وعدس وصويا وترمس)',
      program:
          '1. حشرة المن وناقلات الفيروس: رش مبيد مانع للتغذية (بيمتروزين) فور رصد أول مستعمرة\n2. صانعات الأنفاق ودودة القرون: رش بايو-مبيد (باسيلس) أو إندوكساكارب عند العقد\n3. التبقع البني وصدأ الفول: رش أوكسي كلورور النحاس أو مانكوزيب مع بداية الشتاء\n4. الهالوك: رش راوند أب بجرعة مخفضة جداً (50-75 سم3/فدان) مرتين عند بداية التزهير'),
  const _Program(
      crop: 'المحاصيل الزيتية (سمسم وعباد شمس وكتان)',
      program:
          '1. دودة كبسولات السمسم وقرون عباد الشمس: رش سبينوساد عند تكوين البراعم الزهرية\n2. المن والتربس: مكافحة بؤرية مبكرة لتجنب تجعد الأوراق وتوقف القمم النامية\n3. أعفان التاج والذبول: الاعتدال في الري وتجنب الغدق، وزراعة على خطوط مرتفعة'),
  const _Program(
      crop: 'الحمضيات والموالح (البرتقال والليمون)',
      program:
          '1. ذبابة فاكهة البحر المتوسط: مصائد جاذبة ورش جزئي بالطعوم السامة أو سبينوساد مركز\n2. صانعة أنفاق الموالح: رش أبامكتين مخلوطاً بزيت صيفي على النموات الحديثة في الربيع والصيف\n3. الحشرات القشرية والعفن الهبابي: رش زيوت معدنية شتوية وصيفية مع تقليم الفروع المتشابكة\n4. الأشنات والأعفان: رش مركبات النحاس بعد جمع المحصول والتقليم مباشرة'),
  const _Program(
      crop: 'العنب',
      program:
          '1. البياض الدقيقي: تهوية العرائش ورش كبريت ميكروني دورياً حتى ما قبل جمع المحصول\n2. دودة ثمار العنب: مصائد فيرومونية ورش بيولوجي بالباسيلس أو ميتوكسيفينوزيد\n3. البق الدقيقي: تقشير القلف القديم ورش زيوت شتوية ومكافحة النمل الناقل للحشرة\n4. أعفان الثمار (البوتريتس): رش مبيدات متخصصة (سويتش/كانتوس) عند قفل العناقيد وبداية الطراوة'),
  const _Program(
      crop: 'المانجو',
      program:
          '1. تشوه الشماريخ الزهرية: قص الشماريخ المشوهة 20 سم أسفل الإصابة وتطهير المقصات بالنحاس\n2. البياض الدقيقي: كبريت ميكروني عند انتفاخ البراعم، وتوبوكونازول عند تفتح الأزهار\n3. ذبابة الفاكهة: حزم الأكياس على الثمار أو الرش بالطعوم الجاذبة\n4. الحشرة القشرية والعفن الهبابي: رش صابون زراعي بوتاسي يليه زيت معدني بعد الحصاد'),
  const _Program(
      crop: 'الزيتون',
      program:
          '1. ذبابة ثمار الزيتون: مصائد ماكفيل الغذائية ورش طعوم سامة فور رصد 2 حشرة/مصيدة\n2. عثة الزيتون (الجيل الزهري والثمري): رش باسيلس ثورنجينسيس عند تفتح البراعم الزهرية\n3. عين الطاووس الفطرية: رش أوكسي كلورور النحاس في الخريف بعد جمع المحصول وفي أوائل الربيع\n4. نيماتودا الزيتون: إضافة المواد العضوية المتحللة والمكافحة الحيوية بالنيماتودا النافعة'),
  const _Program(
      crop: 'البلح ونخيل التمر',
      program:
          '1. سوسة النخيل الحمراء: فحص دوري لقواعد الفسائل، حقن الجذوع المصابة بأقراص الفوسفين أو مبيد جهازي، وتلقيح الجروح ببودرة الكبريت والمبيد\n2. حلم الغبار (الغبير): تعفير العراجين بالكبريت الزراعي في الربيع قبل تلون الثمار\n3. دودة البلح الصغرى والكبرى: رش بكتيري (Bt) أو سبينوساد على العراجين بعد العقد\n4. خياس الطلع وعفن النورات: تطهير أدوات التلقيح ورش نحاسي بعد جمع المحصول'),
  const _Program(
      crop: 'الفلفل والباذنجانيات والبامية',
      program:
          '1. العنكبوت الأحمر العادي: رش أبامكتين أو بروبارجيت مع توجيه الرش للسطح السفلي للأوراق\n2. الذبابة البيضاء وفيروس تجعد الأوراق: شباك مانعة للحشرات على المشاتل ورش أسيتاميبريد\n3. أعفان الجذور والذبول: معاملة الشتلات بمحلول فطري قبل الشتل وضبط الصرف الزراعي'),
  const _Program(
      crop: 'النباتات الطبية والأعلاف (البرسيم وحبة البركة والكتان)',
      program:
          '1. دودة ورق القطن في البرسيم: الحش المبكر عند بداية الإصابة لتجويع اليرقات وتجنب المبيدات الكيماوية لحماية المواشي\n2. سوسة ورق البرسيم: رش بكتيري أو زيوت نباتية في البؤر المبكرة\n3. حشيشة الكسكوتا (الحامول): حرق البؤر فوراً ومنع انتقال بذورها بالآلات الزراعية\n4. أمراض الأصداء والذبول: استخدام تقاوي معتمدة وتطهير الحقل بعد الحصاد'),
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
        trailing: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 24),
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
        trailing: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 24),
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
        trailing: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 24),
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

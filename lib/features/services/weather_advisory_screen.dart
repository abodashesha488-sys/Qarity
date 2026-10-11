import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/utils/time_format.dart';
import '../../services/weather_service.dart';
import '../../widgets/qurity_app_bar.dart';

/// شاشة أحوال الطقس مع إرشادات وتوصيات زراعية علمية موثقة للمزارع
class WeatherAdvisoryScreen extends StatefulWidget {
  const WeatherAdvisoryScreen({super.key});

  @override
  State<WeatherAdvisoryScreen> createState() => _WeatherAdvisoryScreenState();
}

class _WeatherAdvisoryScreenState extends State<WeatherAdvisoryScreen> {
  final WeatherService _weather = WeatherService.instance;
  Map<String, dynamic>? _current;
  Map<String, dynamic>? _forecast;
  bool _loading = true;
  String? _error;

  // اللون الزراعي الأساسي والهوية
  static const Color kAgriPrimary = Color(0xFF1E5E3A); // أخضر زمردي زراعي

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _weather.getCurrent(),
        _weather.getForecast(),
      ]);
      if (mounted) {
        setState(() {
          _current = results[0];
          _forecast = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'تعذر تحميل بيانات الطقس الزراعي';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: QurityAppBar(
        title: 'أحوال الطقس والإرشاد الزراعي',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadWeather,
            tooltip: 'تحديث بيانات الطقس',
          ),
        ],
      ),
      body: _loading
          ? _buildSkeleton(theme)
          : _error != null
              ? _buildError(theme)
              : RefreshIndicator(
                  onRefresh: _loadWeather,
                  color: kAgriPrimary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_current != null) ...[
                          _buildCurrentWeatherCard(context),
                          const SizedBox(height: 16),
                          _buildFieldOperationsBar(context),
                          const SizedBox(height: 20),
                          _buildSeasonalCropAdvisories(context),
                          const SizedBox(height: 20),
                          _buildAgriculturalAdvisoryCard(context),
                          const SizedBox(height: 20),
                        ],
                        if (_forecast != null) ...[
                          _buildSectionHeader(
                            context,
                            title: 'توقعات الأيام القادمة للمزرعة',
                            subtitle: 'تنبؤات 5 أيام مع مؤشر العمل الحقلي اليومي',
                            icon: Icons.calendar_month_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildForecastList(context),
                          const SizedBox(height: 20),
                        ],
                        _buildSectionHeader(
                          context,
                          title: 'إرشادات زراعية حسب الطقس الحالي',
                          subtitle: 'توجيهات ديناميكية فورية وفق مستشعرات الطقس',
                          icon: Icons.eco_rounded,
                        ),
                        const SizedBox(height: 12),
                        ..._buildWeatherBasedAdvisory(context),
                        const SizedBox(height: 20),
                        _buildOfficialSourcesBanner(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    final base = theme.colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _skeletonCard(base, height: 210),
        const SizedBox(height: 16),
        _skeletonCard(base, height: 90),
        const SizedBox(height: 16),
        _skeletonCard(base, height: 260),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _skeletonCard(base, height: 75),
          ),
        ),
      ],
    );
  }

  Widget _skeletonCard(Color base, {required double height}) {
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: base.withValues(alpha: 0.5),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'تأكد من الاتصال بالإنترنت لتحديث بيانات طقس القرية والتوصيات',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadWeather,
              style: FilledButton.styleFrom(backgroundColor: kAgriPrimary),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // 1. بطاقة الطقس الزراعي للقرية الحالية
  // ═════════════════════════════════════════════════════════════════════
  Widget _buildCurrentWeatherCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = _current!;
    final main = data['main'] as Map<String, dynamic>;
    final weather = (data['weather'] as List).first as Map<String, dynamic>;
    final wind = data['wind'] as Map<String, dynamic>;
    final sys = data['sys'] as Map<String, dynamic>;
    final dt = DateTime.fromMillisecondsSinceEpoch(
      (data['dt'] as num).toInt() * 1000,
      isUtc: true,
    ).add(Duration(seconds: data['timezone'] as int? ?? 0));

    final temp = (main['temp'] as num).toDouble();
    final feelsLike = (main['feels_like'] as num).toDouble();
    final humidity = main['humidity'] as int;
    final pressure = main['pressure'] as int;
    final windSpeed = (wind['speed'] as num).toDouble();
    final windDeg = (wind['deg'] as num?)?.toInt() ?? 0;
    final iconId = weather['icon'] as String;
    final conditionAr = WeatherFormat.conditionAr(
      iconId,
      weather['description'] as String?,
    );
    final iconUrl = WeatherFormat.iconUrl(iconId, big: true);
    final sunrise = DateTime.fromMillisecondsSinceEpoch(
      (sys['sunrise'] as num).toInt() * 1000,
      isUtc: true,
    ).add(Duration(seconds: data['timezone'] as int? ?? 0));
    final sunset = DateTime.fromMillisecondsSinceEpoch(
      (sys['sunset'] as num).toInt() * 1000,
      isUtc: true,
    ).add(Duration(seconds: data['timezone'] as int? ?? 0));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF133220), const Color(0xFF0D2316)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: kAgriPrimary.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة: اسم القرية والتاريخ
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kAgriPrimary.withValues(alpha: isDark ? 0.3 : 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: kAgriPrimary),
                    const SizedBox(width: 4),
                    Text(
                      'أحوال طقس قرية أبوديشيشة',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF81C784) : kAgriPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('d MMMM yyyy', 'ar').format(dt),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // صف الحرارة والحالة والأيقونة
          Row(
            children: [
              // الأيقونة من مزود الخدمة
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kAgriPrimary.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Image.network(
                  iconUrl,
                  width: 56,
                  height: 56,
                  errorBuilder: (c, u, e) => Icon(
                    WeatherFormat.iconGlyph(iconId),
                    color: kAgriPrimary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // درجة الحرارة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${temp.round()}°',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            color: isDark ? Colors.white : const Color(0xFF1B3824),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kAgriPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              conditionAr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFFA5D6A7) : kAgriPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الحرارة المحسوسة: ${feelsLike.round()}° مئوية',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.7),
          const SizedBox(height: 14),

          // المؤشرات الحقلية الأربعة
          Row(
            children: [
              _AgriMetric(
                icon: Icons.water_drop_rounded,
                label: 'الرطوبة الجوية',
                value: '$humidity%',
                color: const Color(0xFF0288D1),
              ),
              const SizedBox(width: 8),
              _AgriMetric(
                icon: Icons.air_rounded,
                label: 'سرعة الرياح',
                value: WeatherFormat.windSpeedKmh(windSpeed),
                subValue: WeatherFormat.windDirection(windDeg),
                color: const Color(0xFF00796B),
              ),
              const SizedBox(width: 8),
              _AgriMetric(
                icon: Icons.speed_rounded,
                label: 'الضغط الجوي',
                value: '$pressure hPa',
                color: const Color(0xFF5D4037),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _AgriMetric(
                icon: Icons.wb_sunny_rounded,
                label: 'شروق الشمس',
                value: formatTime12(sunrise),
                color: const Color(0xFFF57C00),
              ),
              const SizedBox(width: 8),
              _AgriMetric(
                icon: Icons.nights_stay_rounded,
                label: 'غروب الشمس',
                value: formatTime12(sunset),
                color: const Color(0xFF5C6BC0),
              ),
              const SizedBox(width: 8),
              _AgriMetric(
                icon: Icons.thermostat_rounded,
                label: 'الإجهاد الحراري',
                value: temp > 33 ? 'مرتفع' : (temp < 12 ? 'منخفض' : 'معتدل'),
                color: temp > 33 ? Colors.orange : kAgriPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // 2. مؤشرات ملائمة العمليات الحقلية اليوم (رش، ري، تسميد)
  // ═════════════════════════════════════════════════════════════════════
  Widget _buildFieldOperationsBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = _current!;
    final main = data['main'] as Map<String, dynamic>;
    final weather = (data['weather'] as List).first as Map<String, dynamic>;
    final wind = data['wind'] as Map<String, dynamic>;

    final humidity = main['humidity'] as int;
    final windSpeed = (wind['speed'] as num).toDouble();
    final condition = (weather['main'] as String).toLowerCase();

    // حساب ملائمة الرش: الرياح < 6 م/ث (22 كم/س) وبدون أمطار
    final bool canSpray = windSpeed <= 6 && !condition.contains('rain');
    // حساب ملائمة الري: لا أمطار والرياح ليست شديدة
    final bool canIrrigate = !condition.contains('rain') && windSpeed < 10;
    // خطر الفطريات مع ارتفاع الرطوبة
    final bool highFungalRisk = humidity > 80;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_rounded, color: kAgriPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'مؤشرات العمل الحقلي الميداني اليوم',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E3A24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FieldStatusBadge(
                  title: 'عمليات الرش',
                  status: canSpray ? 'ملائم للرش' : 'تأجيل الرش',
                  isGood: canSpray,
                  icon: Icons.water_rounded,
                  hint: canSpray ? 'رياح هادئة' : 'رياح/أمطار مانعة',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FieldStatusBadge(
                  title: 'عمليات الري',
                  status: canIrrigate ? 'ري آمن' : 'حذر بالري',
                  isGood: canIrrigate,
                  icon: Icons.waves_rounded,
                  hint: canIrrigate ? 'طقس مستقر' : 'تجنب رقاد النبات',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FieldStatusBadge(
                  title: 'الوقاية الفطرية',
                  status: highFungalRisk ? 'إنذار رطوبة' : 'خطر منخفض',
                  isGood: !highFungalRisk,
                  icon: Icons.shield_rounded,
                  hint: highFungalRisk ? 'رش وقائي نحاسي' : 'رطوبة متوازنة',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // 3. التوصيات الزراعية الميدانية الموثقة لموسم الخريف وبداية الشتاء
  // ═════════════════════════════════════════════════════════════════════
  Widget _buildSeasonalCropAdvisories(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cropAdvisories = [
      const _CropAdvisoryData(
        crop: 'القمح (الذهب الأصفر)',
        icon: Icons.grass_rounded,
        color: Color(0xFFD4A017),
        stage: 'تجهيز الأرض وبدء موسم الزراعة الشتوية',
        recommendations: [
          'الميعاد الأمثل للزراعة في محافظات الدلتا والوجه البحري هو من 15 إلى 30 نوفمبر، وتجنب التبكير أو التأخير لتفادي انخفاض التفريع أو طرد السنابل المبكر.',
          'التقاوي المعتمدة الموصى بها هذا الموسم من مركز البحوث الزراعية: (جيزة 171، مصر 3، مصر 4، سخا 95، سدس 14، سخا 96). يُحذر تماماً من زراعة سدس 12 ومصر 1 في الوجه البحري لشدة حساسيتها لصدأ الأصداء.',
          'الخدمة والتسميد الفوسفاتي: إضافة 100-150 كجم سوبر فوسفات الكالسيوم (15.5% P2O5) للفدان أثناء الحرث والخدمة وقبل التخطيط لتقوية المجموع الجذري.',
          'التسوية الدقيقة بالليزر ترفع كفاءة الري وتوفر ما بين 20% إلى 25% من مياه الري والأسمدة.',
        ],
      ),
      const _CropAdvisoryData(
        crop: 'بنجر السكر',
        icon: Icons.spa_rounded,
        color: Color(0xFF2E7D32),
        stage: 'العروة المبكرة والمتوسطة (مرحلة الإنبات والتفريع)',
        recommendations: [
          'الخف في الوقت المناسب: يتم الخف على نبات واحد فقط قوي في الجورة عند ظهور 4 إلى 6 أوراق حقيقية (عمر 30-40 يوماً). لا تؤخر الخف لتفادي سرولة الجذور.',
          'التسميد الآزوتي: إنهاء كامل الدفعات السمادية الآزوتية (نترات نشادر أو يوريا) قبل عمر 90 يوماً من الزراعة، لأن الآزوت المتأخر يخفض نسبة السكر والوزن النوعي.',
          'الري بالحوال وعلى الحامي: بنجر السكر شديد الحساسية لركود المياه؛ يجب صرف المياه الزائدة فوراً لمنع انتشار فطر الريزوكتونيا وأعفان الجذور.',
        ],
      ),
      const _CropAdvisoryData(
        crop: 'البرسيم المسقاوي',
        icon: Icons.forest_rounded,
        color: Color(0xFF43A047),
        stage: 'زراعة العروة الرئيسية وبادرات النمو',
        recommendations: [
          'رية المحاياة: تُعطى بعد 7 إلى 10 أيام من رية الزراعة على الهادئ لتثبيت البادرات وامتصاص العناصر وتجنب تغريق الأرض.',
          'مكافحة دودة ورق القطن في البادرات: تفقد الحقل صباحاً ورش المبيدات الموصى بها فور ظهور أي بؤر إصابة لحماية أوراق الحشة الأولى.',
        ],
      ),
      const _CropAdvisoryData(
        crop: 'محاصيل الخضر والبطاطس الشتوية',
        icon: Icons.yard_rounded,
        color: Color(0xFFE65100),
        stage: 'مرحلة تكوين الدرنات والنمو الخضري',
        recommendations: [
          'الوقاية من الندوة المتأخرة: الرش الوقائي بالمركبات النحاسية (أوكسي كلورور النحاس أو هيدروكسيد النحاس) خاصة مع تكون الشبورة المائية الصباحية والندى الكثيف.',
          'التسميد البوتاسي: إضافة سلفات البوتاسيوم رياً أو رشاً لدعم امتلاء الدرنات وزيادة مقاومة النباتات للتذبذبات الحرارية الليلية.',
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'التوصيات الزراعية لموسم الخريف والشتاء',
          subtitle: 'توجيهات علمية معتمدة من قطاع الإرشاد ومركز البحوث الزراعية',
          icon: Icons.agriculture_rounded,
        ),
        const SizedBox(height: 12),
        ...cropAdvisories.map((crop) => _buildCropCard(context, crop, isDark)),
      ],
    );
  }

  Widget _buildCropCard(BuildContext context, _CropAdvisoryData data, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.color.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: data.crop.contains('القمح'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          title: Text(
            data.crop,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          subtitle: Text(
            data.stage,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFA5D6A7) : kAgriPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(height: 1, thickness: 0.7),
            const SizedBox(height: 12),
            ...data.recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: data.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rec,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // 4. إرشادات الطقس الحالية
  // ═════════════════════════════════════════════════════════════════════
  Widget _buildAgriculturalAdvisoryCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = _current!;
    final main = data['main'] as Map<String, dynamic>;
    final weather = (data['weather'] as List).first as Map<String, dynamic>;
    final wind = data['wind'] as Map<String, dynamic>;

    final temp = (main['temp'] as num).toDouble();
    final humidity = main['humidity'] as int;
    final windSpeed = (wind['speed'] as num).toDouble();
    final condition = (weather['main'] as String).toLowerCase();

    final advisories = _generateAdvisories(temp, humidity, windSpeed, condition);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: kAgriPrimary.withValues(alpha: isDark ? 0.35 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kAgriPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tips_and_updates_rounded, color: kAgriPrimary, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'إرشادات المزارع الآن حسب طقس اليوم',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1B3824),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...advisories.map((a) => _AdvisoryItem(text: a, color: kAgriPrimary)),
        ],
      ),
    );
  }

  List<String> _generateAdvisories(
      double temp, int humidity, double windSpeed, String condition) {
    final List<String> advisories = [];

    // حرارة
    if (temp > 38) {
      advisories.add(
          '🔥 حرارة شديدة (>38°): ريّ صباحاً باكراً أو مساءً — تجنب الرش — استخدم تظليل للصوب');
    } else if (temp > 32) {
      advisories.add(
          '☀️ حرارة عالية (32-38°): ريّ مبكر — رش ورقي مبكراً — تظليل جزئي للخضار');
    } else if (temp < 5) {
      advisories.add(
          '❄️ برودة شديدة (<5°): خطر صقيع — ريّ خفيف مساءً للتدفئة — أغلق الصوب — لا رش');
    } else if (temp < 10) {
      advisories.add(
          '🌡️ برودة (5-10°): قلل الري — لا تسميد آزوت — احمِ المحاصيل الحساسة');
    }

    // رطوبة
    if (humidity > 85) {
      advisories.add(
          '💧 رطوبة عالية (>85%): خطر أمراض فطرية (بياض، لفحة) — رش وقائي (مانكوزيب/كليوروثالونيل) — تهوية الصوب');
    } else if (humidity < 30) {
      advisories.add(
          '🏜️ رطوبة منخفضة (<30%): إجهاد مائي — زيادة تردد الري — رش ورقي صباحاً — ملاحة حول النباتات');
    }

    // رياح — العتبة تُقارن بالأمتار/الثانية كما يرسلها المزود، وتُسمّى بالمقاس
    // الذي يقرأه المزارع في كل صفحة (كم/س)، فلا يكذب نص الإرشاد على الرقم المعروض.
    if (windSpeed > 10) {
      advisories.add(
          '💨 رياح قوية (>36 كم/س): خطر تطاير رش — لا رش — ثبت الصوب والتلاحيف — تحقق من تكاسير');
    } else if (windSpeed > 6) {
      advisories.add(
          '🌬️ رياح معتدلة (22-36 كم/س): رش مع الحذر — اتجاه الريح — تجنب الرش الظهيرة');
    }

    // حالة الطقس
    if (condition.contains('rain') || condition.contains('drizzle')) {
      advisories.add(
          '🌧️ ممطر: تأخر الري — لا رش (يغسل المبيد) — تحقق من تصريف الحقول — راقب تعفن الجذور');
    } else if (condition.contains('thunderstorm')) {
      advisories.add(
          '⛈️ عواصف رعدية: لا تعمل في الحقول — افصل الكهرباء عن الصوب — ثبت المعدات');
    } else if (condition.contains('clear')) {
      advisories.add(
          '☀️ صافٍ: وقت مناسب للرش صباحاً/مساءً — ريّ منتظم — مراقبة آفات');
    } else if (condition.contains('cloud')) {
      advisories.add(
          '☁️ غائم: مناسب للرش الورقي — ريّ حسب الحاجة — مراقبة أمراض فطرية');
    }

    // نصائح عامة دائماً
    advisories.add(
        '📋 عام: سجل كل عملية (ري، رش، تسميد) — تفقد الحقول يومياً — استخدم مصائد فرمونية للمراقبة');

    return advisories;
  }

  // ═════════════════════════════════════════════════════════════════════
  // 5. توقعات 5 أيام
  // ═════════════════════════════════════════════════════════════════════
  Widget _buildForecastList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final forecast = _forecast!['list'] as List;
    final daily = <DateTime, List<Map<String, dynamic>>>{};

    for (final item in forecast) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        (item['dt'] as num).toInt() * 1000,
        isUtc: true,
      );
      final day = DateTime(dt.year, dt.month, dt.day);
      daily.putIfAbsent(day, () => []).add(item);
    }

    final sortedDays = daily.keys.toList()..sort();

    return Column(
      children: sortedDays.take(5).map((day) {
        final items = daily[day]!;
        final midday = items.firstWhere(
          (i) =>
              DateTime.fromMillisecondsSinceEpoch(
                (i['dt'] as num).toInt() * 1000,
              ).hour >=
              12,
          orElse: () => items[items.length ~/ 2],
        );
        final main = midday['main'] as Map<String, dynamic>;
        final weather =
            (midday['weather'] as List).first as Map<String, dynamic>;
        final tempMin = items
            .map((i) => (i['main']['temp_min'] as num).toDouble())
            .reduce((a, b) => a < b ? a : b);
        final tempMax = items
            .map((i) => (i['main']['temp_max'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b);
        final iconId = weather['icon'] as String;
        final iconUrl = WeatherFormat.iconUrl(iconId);
        final desc = WeatherFormat.conditionAr(
          iconId,
          weather['description'] as String?,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHigh
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE', 'ar').format(day),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    Text(
                      DateFormat('d MMMM', 'ar').format(day),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Image.network(
                iconUrl,
                width: 40,
                height: 40,
                errorBuilder: (c, u, e) => Icon(
                  WeatherFormat.iconGlyph(iconId),
                  size: 32,
                  color: kAgriPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tempMin.round()}° صغرى / ${tempMax.round()}° عظمى',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFA5D6A7) : kAgriPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _AdvisoryBadge(
                text: _dailyAdvisory(main, weather),
                color: kAgriPrimary,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _dailyAdvisory(
      Map<String, dynamic> main, Map<String, dynamic> weather) {
    final temp = (main['temp'] as num).toDouble();
    final humidity = main['humidity'] as int;
    final condition = (weather['main'] as String).toLowerCase();

    if (condition.contains('rain')) return '🌧️ ممطر';
    if (temp > 35) return '🔥 حار';
    if (temp < 10) return '❄️ بارد';
    if (humidity > 80) return '💧 رطب';
    return '☀️ ملائم';
  }

  List<Widget> _buildWeatherBasedAdvisory(BuildContext context) {
    if (_current == null) return [];
    final data = _current!;
    final main = data['main'] as Map<String, dynamic>;
    final weather = (data['weather'] as List).first as Map<String, dynamic>;
    final wind = data['wind'] as Map<String, dynamic>;

    final temp = (main['temp'] as num).toDouble();
    final humidity = main['humidity'] as int;
    final windSpeed = (wind['speed'] as num).toDouble();
    final condition = (weather['main'] as String).toLowerCase();

    final advisories = _generateAdvisories(temp, humidity, windSpeed, condition);

    return advisories.map((a) => _AdvisoryItem(text: a, color: kAgriPrimary)).toList();
  }

  // ═════════════════════════════════════════════════════════════════════
  // 6. بطاقة توثيق المصادر الزراعية المصرية المعتمدة
  // ═════════════════════════════════════════════════════════════════════
  Widget _buildOfficialSourcesBanner(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF12281A)
            : const Color(0xFFE8F5E9).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kAgriPrimary.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: kAgriPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'المصادر العلمية والجهات المعتمدة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark ? const Color(0xFFA5D6A7) : kAgriPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'تعتمد هذه الإرشادات والتوصيات الفنية على النشرات الدورية الرسمية الصادرة عن:\n'
            '• وزارة الزراعة واستصلاح الأراضي المصرية (MALR)\n'
            '• مركز البحوث الزراعية (ARC) — المعاهد المتخصصة للمحاصيل وأمراض النبات\n'
            '• المعمل المركزي للمناخ الزراعي (CLAC) ومنظومة الإنذار المناخي المبكر\n'
            '• قطاع الإرشاد الزراعي والإدارة المركزية للإرشاد',
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.6,
              color: isDark ? Colors.white70 : const Color(0xFF2C3E2D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kAgriPrimary.withValues(alpha: isDark ? 0.25 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kAgriPrimary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1B3824),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// ويدجتس مساعدة
// ═════════════════════════════════════════════════════════════════════

class _AgriMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color color;

  const _AgriMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF1A3322),
              ),
            ),
            if (subValue != null)
              Text(
                subValue!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldStatusBadge extends StatelessWidget {
  final String title;
  final String status;
  final bool isGood;
  final IconData icon;
  final String hint;

  const _FieldStatusBadge({
    required this.title,
    required this.status,
    required this.isGood,
    required this.icon,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isGood ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: statusColor),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: TextStyle(
              fontSize: 9,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CropAdvisoryData {
  final String crop;
  final IconData icon;
  final Color color;
  final String stage;
  final List<String> recommendations;

  const _CropAdvisoryData({
    required this.crop,
    required this.icon,
    required this.color,
    required this.stage,
    required this.recommendations,
  });
}

class _AdvisoryItem extends StatelessWidget {
  final String text;
  final Color color;

  const _AdvisoryItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvisoryBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _AdvisoryBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

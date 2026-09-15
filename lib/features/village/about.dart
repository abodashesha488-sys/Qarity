import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/village_info_service.dart';
import '../../widgets/offline_stream_builder.dart';
import '../../widgets/qurity_app_bar.dart';
import 'village_archive_screen.dart' show kVillageArchiveColor;
import 'village_content_admin.dart';
import 'village_history_screen.dart' show kVillageHistoryColor;
import 'village_institutions_screen.dart' show kVillageInstitutionsColor;
import 'village_ornament.dart';

/// «تعرف على القرية» — بوابة التراث: بطاقة تعريف وأقسام التاريخ والأرشيف والمنشآت.
class VillageScreen extends StatefulWidget {
  const VillageScreen({super.key});

  @override
  State<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends State<VillageScreen> {
  final VillageInfoService _service = VillageInfoService();
  late final Stream<VillageInfo?> _stream = _service.getInfoStream();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _service.seedIfEmpty().catchError((_) {});
    canManageVillageContent().then((v) {
      if (mounted) setState(() => _isAdmin = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const QurityAppBar(title: 'تعرف على القرية'),
      body: OfflineStreamBuilder<VillageInfo?>(
        stream: _stream,
        onlineBuilder: (context, snapshot) {
          return _buildBody(theme, snapshot.data, loading: !snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting);
        },
        cacheBuilder: (context) => FutureBuilder(
          future: CacheService.getVillageInfo(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final info = snapshot.data != null
                ? VillageInfo.fromJson(snapshot.data!, 'main')
                : null;
            return _buildBody(theme, info, loading: false);
          },
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, VillageInfo? info,
      {required bool loading}) {
    if (loading && info == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        // ── هيرو القسم ──
        Container(
          height: 168,
          decoration: const BoxDecoration(
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(30)),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF6F4E37), Color(0xFF462F1F)],
            ),
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(30)),
            child: Stack(
              children: [
                Positioned.fill(
                    child: CustomPaint(painter: GeoPatternPainter())),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('قرية أبوديشيشة',
                          style: VillageOrnament.amiri(
                              size: 30,
                              color: VillageOrnament.gold)),
                      const SizedBox(height: 2),
                      Text('روحُ التطبيق النابض… وذاكرةُ القرية الحية',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white
                                  .withValues(alpha: 0.85))),
                      const SizedBox(height: 8),
                      const SizedBox(
                        width: 120,
                        child: OrnamentDivider(
                            color: VillageOrnament.gold),
                      ),
                    ],
                  ),
                ),
                if (_isAdmin)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Tooltip(
                      message: 'تعديل بطاقة التعريف',
                      child: Material(
                        color: Colors.white24,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => editVillageIntro(context, info),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.edit_rounded,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms),
        // ── بطاقة التعريف ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color:
                      const Color(0xFF6F4E37).withValues(alpha: 0.25),
                  width: 1.2),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 12,
                    offset: Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_rounded,
                          size: 18, color: Color(0xFF6F4E37)),
                      const SizedBox(width: 7),
                      Text('بطاقة تعريف القرية',
                          style: VillageOrnament.amiri(
                              size: 17,
                              color: const Color(0xFF6F4E37))),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((info?.description ?? '').isNotEmpty) ...[
                        Text(info!.description,
                            style: const TextStyle(
                                fontSize: 13, height: 1.9)),
                        const SizedBox(height: 12),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statChip(Icons.groups_rounded, 'السكان',
                              (info?.population ?? '').isNotEmpty
                                  ? info!.population
                                  : '—'),
                          _statChip(Icons.map_rounded, 'المساحة',
                              (info?.area ?? '').isNotEmpty
                                  ? info!.area
                                  : '—'),
                          _statChip(Icons.celebration_rounded, 'التأسيس',
                              (info?.founded ?? '').isNotEmpty
                                  ? info!.founded
                                  : '—'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.08),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Expanded(child: OrnamentDivider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('كنوز القسم',
                    style: VillageOrnament.amiri(
                        size: 15,
                        color: const Color(0xFF6F4E37))),
              ),
              const Expanded(child: OrnamentDivider()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── بلاطات الأقسام الثلاثة ──
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _SectionTile(
                color: kVillageHistoryColor,
                icon: Icons.history_edu_rounded,
                title: 'تاريخ القرية',
                subtitle: 'حقباتُ أبوديشيشة على خطٍّ زمني مزخرف',
                route: AppRoutes.villageHistory,
              ),
              SizedBox(height: 12),
              _SectionTile(
                color: kVillageArchiveColor,
                icon: Icons.architecture_rounded,
                title: 'أرشيف القرية',
                subtitle: 'شخصياتٌ صنعت المجد، وصورٌ تحفظ الذاكرة',
                route: AppRoutes.villageArchive,
              ),
              SizedBox(height: 12),
              _SectionTile(
                color: kVillageInstitutionsColor,
                icon: Icons.account_balance_rounded,
                title: 'منشآت القرية',
                subtitle: 'مدارسٌ ومعاهد ومساجد ومرافق الخدمة',
                route: AppRoutes.villageInstitutions,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                VillageOrnament.goldDark.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF8D6E00)),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black54)),
          Text(value,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6F4E37))),
        ],
      ),
    );
  }
}

/// بلاطة قسم بأسلوب دليل الخدمات — لون مميز لا يتكرر.
class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.withValues(alpha: 0.06),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.38), width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [color, color.withValues(alpha: 0.72)]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.amiri(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: color)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.arrow_back_ios_rounded,
                  size: 15, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

/// تعديل بطاقة التعريف (village_info/main) — للأدمن فقط.
Future<void> editVillageIntro(BuildContext context, VillageInfo? info) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: _IntroForm(info: info),
      ),
    ),
  );
}

class _IntroForm extends StatefulWidget {
  const _IntroForm({this.info});
  final VillageInfo? info;

  @override
  State<_IntroForm> createState() => _IntroFormState();
}

class _IntroFormState extends State<_IntroForm> {
  late final _name =
      TextEditingController(text: widget.info?.name ?? 'قرية أبوديشيشة');
  late final _description =
      TextEditingController(text: widget.info?.description ?? '');
  late final _population =
      TextEditingController(text: widget.info?.population ?? '');
  late final _area = TextEditingController(text: widget.info?.area ?? '');
  late final _founded =
      TextEditingController(text: widget.info?.founded ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _population.dispose();
    _area.dispose();
    _founded.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: const Color(0x0A000000),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12)),
      );

  Future<void> _save() async {
    setState(() => _saving = true);
    final info = VillageInfo(
      id: widget.info?.id ?? 'main',
      name: _name.text.trim().isEmpty ? 'قرية أبوديشيشة' : _name.text.trim(),
      description: _description.text.trim(),
      population: _population.text.trim(),
      area: _area.text.trim(),
      founded: _founded.text.trim(),
      history: widget.info?.history ?? const [],
      institutions: widget.info?.institutions ?? const [],
      archive: widget.info?.archive ?? const [],
    );
    await VillageInfoService().saveInfo(info);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم تحديث بطاقة التعريف'),
          backgroundColor: Color(0xFF6F4E37)));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تعديل بطاقة تعريف القرية',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 12),
          TextField(
              controller: _name,
              decoration: _dec('اسم القرية')),
          const SizedBox(height: 10),
          TextField(
              controller: _description,
              maxLines: 5,
              decoration: _dec('النبذة التعريفية…')),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _population,
                      decoration: _dec('عدد السكان'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: _area, decoration: _dec('المساحة'))),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
              controller: _founded,
              decoration: _dec('سنة/رواية التأسيس')),
          const SizedBox(height: 14),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6F4E37),
                      padding: const EdgeInsets.symmetric(vertical: 13)),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('حفظ البطاقة',
                      style: TextStyle(fontWeight: FontWeight.w800)))),
          const SizedBox(height: 8),
        ],
      );
}

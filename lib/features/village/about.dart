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

/// ألوان أقسام «تعرف على القرية» — كل قسم بلون مميز لا يتكرر.
const Color kVillageIntroColor = Color(0xFF6F4E37);

/// «تعرف على القرية» — بوابة التراث: بطاقة تعريف وأقسام التاريخ والأرشيف
/// والمنشآت كأيقونات ملونة منظمة.
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
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }
          return _buildBody(theme, snapshot.data);
        },
        cacheBuilder: (context) => FutureBuilder(
          future: CacheService.getVillageInfo(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2));
            }
            final info = snapshot.data != null
                ? VillageInfo.fromJson(snapshot.data!, 'main')
                : null;
            return _buildBody(theme, info);
          },
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, VillageInfo? info) {
    final desc = (info?.description ?? '').trim();
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        // ── الهيرو الترحيبي ──
        Container(
          height: 150,
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
                      Text(info?.name.isNotEmpty == true
                              ? info!.name
                              : 'قرية أبوديشيشة',
                          style: VillageOrnament.amiri(
                              size: 28,
                              color: VillageOrnament.gold)),
                      const SizedBox(height: 4),                      Text('روحُ التطبيق النابض… وذاكرةُ القرية الحية',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color:
                                  Colors.white.withValues(alpha: 0.85))),
                      const SizedBox(height: 8),
                      const SizedBox(
                          width: 120,
                          child: OrnamentDivider(
                              color: VillageOrnament.gold)),
                    ],
                  ),
                ),
                if (_isAdmin)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Material(
                      color: Colors.white24,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'تعديل بطاقة التعريف',
                        icon: const Icon(Icons.edit_rounded,
                            size: 16, color: Colors.white),
                        onPressed: () => editVillageIntro(context, info),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 14),
        if (desc.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    height: 1.7,
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
        const SizedBox(height: 16),
        // ── ترويسة الشبكة ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Expanded(child: OrnamentDivider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('استكشف تراث القرية',
                    style: VillageOrnament.amiri(
                        size: 16,
                        color: kVillageIntroColor)),
              ),
              const Expanded(child: OrnamentDivider()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── أيقونات الأقسام ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.92,
            children: [
              _IconTile(
                color: kVillageIntroColor,
                icon: Icons.badge_rounded,
                title: 'بطاقة القرية',
                subtitle: 'الهوية والسكان والمساحة والتأسيس',
                onTap: () => _openIntroSheet(info),
              ),
              _IconTile(
                color: kVillageHistoryColor,
                icon: Icons.history_edu_rounded,
                title: 'تاريخ القرية',
                subtitle: 'حقباتٌ على خطٍّ زمني مزخرف',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.villageHistory),
              ),
              _IconTile(
                color: kVillageArchiveColor,
                icon: Icons.architecture_rounded,
                title: 'أرشيف القرية',
                subtitle: 'شخصياتٌ وصورٌ تحفظ الذاكرة',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.villageArchive),
              ),
              _IconTile(
                color: kVillageInstitutionsColor,
                icon: Icons.account_balance_rounded,
                title: 'منشآت القرية',
                subtitle: 'مدارسُ ومعاهدُ ومساجدُ ومرافق',
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.villageInstitutions),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // ── تلميح سفلي ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 14, color: kVillageIntroColor.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'محتوى هذه الأقسام ينسّقه مسؤولو القرية — كل قسم يفتح عالمه الخاص',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10.5,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openIntroSheet(VillageInfo? info) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge_rounded,
                      color: kVillageIntroColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('بطاقة تعريف القرية',
                        style: VillageOrnament.amiri(
                            size: 18,
                            color: kVillageIntroColor)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const OrnamentDivider(),
              const SizedBox(height: 12),
              if ((info?.description ?? '').trim().isNotEmpty) ...[
                Text(info!.description,
                    style: const TextStyle(fontSize: 13, height: 1.9)),
                const SizedBox(height: 14),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(Icons.groups_rounded, 'السكان',
                      (info?.population ?? '').isNotEmpty
                          ? info!.population
                          : '—'),
                  _chip(Icons.map_rounded, 'المساحة',
                      (info?.area ?? '').isNotEmpty ? info!.area : '—'),
                  _chip(Icons.celebration_rounded, 'التأسيس',
                      (info?.founded ?? '').isNotEmpty
                          ? info!.founded
                          : '—'),
                ],
              ),
              if (_isAdmin) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: kVillageIntroColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      editVillageIntro(context, info);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 17),
                    label: const Text('تعديل البطاقة',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: VillageOrnament.goldDark.withValues(alpha: 0.45)),
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
                  color: kVillageIntroColor)),
        ],
      ),
    );
  }
}

/// بلاطة قسم مربعة — دائرة أيقونة متدرجة بلون القسم + عنوان Amiri.
class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(13),
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
                child: Icon(icon, color: Colors.white, size: 27),
              ),
              const SizedBox(height: 11),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.amiri(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.5,
                      color: color)),
              const SizedBox(height: 3),
              Text(subtitle,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 10.5,
                      height: 1.5,
                      color: theme.colorScheme.onSurfaceVariant)),
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
          backgroundColor: kVillageIntroColor));
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
                      backgroundColor: kVillageIntroColor,
                      padding: const EdgeInsets.symmetric(vertical: 13)),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('حفظ البطاقة',
                      style: TextStyle(fontWeight: FontWeight.w800)))),
          const SizedBox(height: 8),
        ],
      );
}

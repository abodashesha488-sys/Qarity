import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/village_info_service.dart';
import '../../widgets/offline_stream_builder.dart';
import '../../widgets/qurity_app_bar.dart';
import '../../widgets/village_ornament.dart';
import 'village_content_admin.dart';

const Color kVillageProfileColor = Color(0xFF6F4E37);

/// «عن أبودشيشة» — بطاقة تعريف القرية الكاملة:
/// صورة، سبب التسمية، الموقع، التبعية الإدارية، الطبيعة، ما اشتهرت به،
/// نبذة مختصرة، وإحصاءات (سكان/مساحة/تأسيس).
class VillageProfileScreen extends StatefulWidget {
  const VillageProfileScreen({super.key});

  @override
  State<VillageProfileScreen> createState() => _VillageProfileScreenState();
}

class _VillageProfileScreenState extends State<VillageProfileScreen> {
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
    return Scaffold(
      appBar:
          const QurityAppBar(title: 'عن أبودشيشة', color: kVillageProfileColor),
      body: OfflineStreamBuilder<VillageInfo?>(
        stream: _stream,
        onlineBuilder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }
          return _buildBody(snapshot.data);
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
            return _buildBody(info);
          },
        ),
      ),
    );
  }

  Widget _buildBody(VillageInfo? info) {
    final theme = Theme.of(context);
    final hasImage = (info?.imageUrl ?? '').isNotEmpty;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // ── الهيرو: صورة القرية ──
        SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                CachedNetworkImage(
                  imageUrl: info!.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      Image.asset('assets/images/About.jpg', fit: BoxFit.cover),
                )
              else
                Image.asset('assets/images/About.jpg', fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: GeoPatternPainter())),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                        info?.name.isNotEmpty == true
                            ? info!.name
                            : 'قرية أبودشيشة',
                        style: VillageOrnament.amiri(
                            size: 30, color: VillageOrnament.gold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: VillageOrnament.gold.withValues(alpha: 0.6)),
                      ),
                      child: const Text('بطاقة تعريف القرية',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
              if (_isAdmin)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Material(
                    color: Colors.white24,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'تعديل بطاقة التعريف',
                      icon: const Icon(Icons.edit_rounded,
                          size: 17, color: Colors.white),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24))),
                        builder: (context) => VillageIntroForm(info: info),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 16),

        // ── الإحصاءات الذهبية ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _StatChip(
                  label: 'السكان',
                  value: info?.population ?? '—',
                  icon: Icons.groups_rounded),
              const SizedBox(width: 10),
              _StatChip(
                  label: 'المساحة',
                  value: info?.area ?? '—',
                  icon: Icons.crop_free_rounded),
              const SizedBox(width: 10),
              _StatChip(
                  label: 'التأسيس',
                  value: info?.founded ?? '—',
                  icon: Icons.flag_rounded),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── حقول الهوية ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              if ((info?.nameOrigin ?? '').isNotEmpty)
                _IdentityRow(
                    icon: Icons.auto_awesome_rounded,
                    title: 'سبب التسمية',
                    text: info!.nameOrigin),
              if ((info?.location ?? '').isNotEmpty)
                _IdentityRow(
                    icon: Icons.place_rounded,
                    title: 'الموقع',
                    text: info!.location),
              if ((info?.administrative ?? '').isNotEmpty)
                _IdentityRow(
                    icon: Icons.account_balance_rounded,
                    title: 'التبعية الإدارية',
                    text: info!.administrative),
              if ((info?.nature ?? '').isNotEmpty)
                _IdentityRow(
                    icon: Icons.landscape_rounded,
                    title: 'طبيعة القرية',
                    text: info!.nature),
              if ((info?.famousFor ?? '').isNotEmpty)
                _IdentityRow(
                    icon: Icons.star_rounded,
                    title: 'اشتهرت بـ',
                    text: info!.famousFor),
            ],
          ),
        ),

        // ── النبذة ──
        if ((info?.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 1,
              shadowColor: kVillageProfileColor.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.menu_book_rounded,
                          size: 18, color: kVillageProfileColor),
                      const SizedBox(width: 8),
                      Text('نبذة عن القرية',
                          style: VillageOrnament.amiri(
                              size: 17, color: kVillageProfileColor)),
                    ]),
                    const SizedBox(height: 8),
                    Text(info!.description,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.9,
                            color: theme.colorScheme.onSurface)),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // ── أزرار الموقع ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if ((info?.mapUrl ?? '').isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.public_rounded, size: 18),
                    label: const Text('على خريطة جوجل'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: kVillageProfileColor,
                        side: BorderSide(
                            color: kVillageProfileColor.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () async {
                      final uri = Uri.tryParse(info!.mapUrl.trim());
                      if (uri != null) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text('خريطة القرية'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.villageMap),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 48),
          child: OrnamentDivider(),
        ),
      ],
    );
  }
}

/// شريحة إحصائية ذهبية (سكان/مساحة/تأسيس).
class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              kVillageProfileColor.withValues(alpha: 0.10),
              VillageOrnament.gold.withValues(alpha: 0.14),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: VillageOrnament.gold.withValues(alpha: 0.45)),
        ),
        child: Column(children: [
          Icon(icon, size: 18, color: kVillageProfileColor),
          const SizedBox(height: 5),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: kVillageProfileColor)),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

/// صف هوية: أيقونة + عنوان + نص.
class _IdentityRow extends StatelessWidget {
  const _IdentityRow(
      {required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shadowColor: kVillageProfileColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kVillageProfileColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: kVillageProfileColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: kVillageProfileColor)),
                  const SizedBox(height: 3),
                  Text(text,
                      style: const TextStyle(fontSize: 12.5, height: 1.7)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

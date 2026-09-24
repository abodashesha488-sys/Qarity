import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/village_content_models.dart';
import '../../services/village_content_service.dart';
import '../../widgets/qurity_app_bar.dart';
import '../../widgets/village_ornament.dart';
import 'village_content_admin.dart';

const Color kVillageHistoryColor = Color(0xFF5D4037);

/// «تاريخ القرية» — خط زمني ذهبي مرقّم لعصور القرية ومراحلها:
/// النشأة، الستينات، التسعينات، والحاضر.
class VillageHistoryScreen extends StatefulWidget {
  const VillageHistoryScreen({super.key});

  @override
  State<VillageHistoryScreen> createState() => _VillageHistoryScreenState();
}

class _VillageHistoryScreenState extends State<VillageHistoryScreen> {
  final VillageContentService _service = VillageContentService();
  late final Stream<List<HistoryEra>> _eras = _service.watchEras();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    canManageVillageContent().then((v) {
      if (mounted) setState(() => _isAdmin = v);
    });
  }

  Future<void> _manage() => manageVillageContent<HistoryEra>(
        context,
        title: 'عصور تاريخ القرية',
        accent: kVillageHistoryColor,
        stream: _eras,
        nameOf: (e) => e.title,
        subtitleOf: (e) => e.years,
        remove: (id) => _service.deleteDoc('village_history', id),
        formBuilder: (ctx, editing) => HistoryEraForm(editing: editing),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const QurityAppBar(
          title: 'تاريخ القرية', color: kVillageHistoryColor),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _manage,
              backgroundColor: kVillageHistoryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('إدارة'),
            )
          : null,
      body: StreamBuilder<List<HistoryEra>>(
        stream: _eras,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }
          final eras = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const VillageSectionHeader(
                accent: kVillageHistoryColor,
                title: 'تاريخ القرية',
                subtitle: 'رحلة أبودشيشة عبر الزمن… من النشأة إلى اليوم',
                icon: Icons.account_balance_rounded,
              ),
              const SizedBox(height: 10),
              if (eras.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.history_rounded,
                          size: 54,
                          color: kVillageHistoryColor.withValues(alpha: 0.35)),
                      const SizedBox(height: 10),
                      Text('لم يُضف محتوى تاريخي بعد',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                )
              else ...[
                for (var i = 0; i < eras.length; i++)
                  _TimelineNode(
                      era: eras[i], index: i, isLast: i == eras.length - 1),
              ],
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 48),
                child: OrnamentDivider(),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// عقدة الخط الزمني: رقم ذهبي + بطاقة العصر (صورة، سنوات، سرد).
class _TimelineNode extends StatelessWidget {
  const _TimelineNode(
      {required this.era, required this.index, required this.isLast});

  final HistoryEra era;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // العمود الزمني: رقم + خط
          SizedBox(
            width: 54,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [VillageOrnament.gold, Color(0xFFB8860B)],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: VillageOrnament.gold.withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            VillageOrnament.gold.withValues(alpha: 0.7),
                            VillageOrnament.gold.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // بطاقة العصر
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 18),
              child: Card(
                elevation: 1.5,
                shadowColor: kVillageHistoryColor.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (era.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18)),
                        child: CachedNetworkImage(
                          imageUrl: era.imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const SizedBox(),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(era.title,
                              style: VillageOrnament.amiri(
                                  size: 18, color: kVillageHistoryColor)),
                          if (era.years.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: VillageOrnament.gold
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: VillageOrnament.gold
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Text(era.years,
                                  style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: kVillageHistoryColor)),
                            ),
                          ],
                          if (era.narrative.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(era.narrative,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.85,
                                    color: theme.colorScheme.onSurface)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, delay: (60 * index).ms)
        .slideX(begin: 0.04, end: 0, duration: 350.ms, delay: (60 * index).ms);
  }
}

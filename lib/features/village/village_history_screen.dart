import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/village_content_models.dart';
import '../../services/village_content_service.dart';
import '../../widgets/qurity_app_bar.dart';
import 'village_content_admin.dart';
import 'village_ornament.dart';

const Color kVillageHistoryColor = Color(0xFF5D4037);

/// «تاريخ القرية» — خط زمني مزخرف لحقبات أبوديشيشة.
class VillageHistoryScreen extends StatefulWidget {
  const VillageHistoryScreen({super.key});

  @override
  State<VillageHistoryScreen> createState() => _VillageHistoryScreenState();
}

class _VillageHistoryScreenState extends State<VillageHistoryScreen> {
  final VillageContentService _service = VillageContentService();
  late final Stream<List<HistoryEra>> _stream = _service.watchEras();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initAdmin();
  }

  Future<void> _initAdmin() async {
    final admin = await canManageVillageContent();
    if (!mounted) return;
    setState(() => _isAdmin = admin);
    if (admin) {
      unawaited(_service.migrateLegacyIfNeeded().catchError((_) => 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const QurityAppBar(
          title: 'تاريخ القرية', color: kVillageHistoryColor),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'village_history_manage',
              backgroundColor: kVillageHistoryColor,
              foregroundColor: Colors.white,
              onPressed: () => manageVillageContent<HistoryEra>(
                context,
                title: 'حقبات التاريخ',
                accent: kVillageHistoryColor,
                stream: _stream,
                nameOf: (e) => e.title,
                subtitleOf: (e) => e.years,
                remove: (id) => _service.deleteDoc('village_history', id),
                formBuilder: (ctx, editing) => HistoryEraForm(editing: editing),
              ),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('إدارة الحقبات',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const VillageSectionHeader(
            accent: kVillageHistoryColor,
            title: 'تاريخ القرية',
            subtitle: 'حيث تبدأ حكاية أبوديشيشة — حقبة أثر حقبة، سطرًا سطراً في ذاكرة الوطن الصغير',
            icon: Icons.history_edu_rounded,
          ),
          const SizedBox(height: 18),
          StreamBuilder<List<HistoryEra>>(
            stream: _stream,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final eras = snap.data!;
              if (eras.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.auto_stories_rounded,
                          size: 52,
                          color: kVillageHistoryColor.withValues(alpha: 0.4)),
                      const SizedBox(height: 10),
                      Text('لم تُدوَّن حقبات بعد',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      if (_isAdmin)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('ابدأ من زر «إدارة الحقبات» ＋',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  const OrnamentDivider(),
                  const SizedBox(height: 10),
                  for (var i = 0; i < eras.length; i++)
                    _EraNode(
                      era: eras[i],
                      isFirst: i == 0,
                      isLast: i == eras.length - 1,
                      index: i,
                    ),
                  const SizedBox(height: 10),
                  const OrnamentDivider(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EraNode extends StatelessWidget {
  const _EraNode({
    required this.era,
    required this.isFirst,
    required this.isLast,
    required this.index,
  });
  final HistoryEra era;
  final bool isFirst;
  final bool isLast;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // عمود الخط الزمني + العقدة
            SizedBox(
              width: 42,
              child: Column(
                children: [
                  Container(
                      height: 2,
                      color: isFirst
                          ? Colors.transparent
                          : VillageOrnament.goldDark.withValues(alpha: 0.45)),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(colors: [
                        VillageOrnament.gold,
                        VillageOrnament.goldDark
                      ]),
                      border: Border.all(color: Colors.white, width: 2.4),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 6,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: Center(
                      child: Text('${index + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                    ),
                  ),
                  Expanded(
                      child: Container(
                          width: 2,
                          color: isLast
                              ? Colors.transparent
                              : VillageOrnament.goldDark
                                  .withValues(alpha: 0.45))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // بطاقة الحقبة
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: kVillageHistoryColor.withValues(alpha: 0.22)),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (era.imageUrl.isNotEmpty)
                        SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: CachedNetworkImage(
                              imageUrl: era.imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  const SizedBox.shrink()),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(era.title,
                                      style: VillageOrnament.amiri(
                                          size: 19,
                                          color: kVillageHistoryColor)),
                                ),
                                if (era.years.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFFFF8E1),
                                        borderRadius:
                                            BorderRadius.circular(9),
                                        border: Border.all(
                                            color: VillageOrnament.goldDark
                                                .withValues(alpha: 0.5))),
                                    child: Text(era.years,
                                        style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF8D6E00))),
                                  ),
                              ],
                            ),
                            if (era.narrative.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(era.narrative,
                                  style: TextStyle(
                                      fontSize: 13,
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
      ),
    ).animate(delay: (index * 60).ms).fadeIn(duration: 350.ms);
  }
}

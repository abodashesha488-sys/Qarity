import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/village_content_models.dart';
import '../../services/village_content_service.dart';
import '../../widgets/qurity_app_bar.dart';
import '../../widgets/village_ornament.dart';
import 'village_content_admin.dart';

const Color kVillageInstitutionsColor = Color(0xFF1565C0);

/// «منشآت القرية» — مدارس ومعاهد أزهرية وجمعية زراعية وبريد وصحة ومساجد.
class VillageInstitutionsScreen extends StatefulWidget {
  const VillageInstitutionsScreen({super.key});

  @override
  State<VillageInstitutionsScreen> createState() =>
      _VillageInstitutionsScreenState();
}

class _VillageInstitutionsScreenState extends State<VillageInstitutionsScreen> {
  final VillageContentService _service = VillageContentService();
  late final Stream<List<VillageInstitution>> _stream =
      _service.watchInstitutions();
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
          title: 'منشآت القرية', color: kVillageInstitutionsColor),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'village_inst_manage',
              backgroundColor: kVillageInstitutionsColor,
              foregroundColor: Colors.white,
              onPressed: () => manageVillageContent<VillageInstitution>(
                context,
                title: 'منشآت القرية',
                accent: kVillageInstitutionsColor,
                stream: _stream,
                nameOf: (n) => n.name,
                subtitleOf: (n) => InstitutionType.label(n.type),
                remove: (id) => _service.deleteDoc('village_institutions', id),
                formBuilder: (ctx, editing) =>
                    InstitutionForm(editing: editing),
              ),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('إدارة المنشآت',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const VillageSectionHeader(
            accent: kVillageInstitutionsColor,
            title: 'منشآت القرية',
            subtitle: 'مرافق أبوديشيشة: علمٌ وصحةٌ وبريدٌ وعبادةٌ وزراعة',
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<VillageInstitution>>(
            stream: _stream,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final items = snap.data!;
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'لم تُسجَّل منشآت بعد',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                );
              }
              final grouped = <String, List<VillageInstitution>>{};
              for (final i in items) {
                grouped.putIfAbsent(i.type, () => []).add(i);
              }
              final types =
                  InstitutionType.ordered.where(grouped.containsKey).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final t in types) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: InstitutionType.color(t)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                  color: InstitutionType.color(t)
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Icon(InstitutionType.icon(t),
                                size: 18, color: InstitutionType.color(t)),
                          ),
                          const SizedBox(width: 9),
                          Text(InstitutionType.label(t),
                              style: VillageOrnament.amiri(
                                  size: 18, color: InstitutionType.color(t))),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 10, left: 4),
                              child: Divider(
                                  color: InstitutionType.color(t)
                                      .withValues(alpha: 0.25)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (var i = 0; i < grouped[t]!.length; i++)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                        child: _InstitutionCard(item: grouped[t]![i], index: i),
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InstitutionCard extends StatelessWidget {
  const _InstitutionCard({required this.item, required this.index});
  final VillageInstitution item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = InstitutionType.color(item.type);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.32), width: 1.2),
      ),
      child: InkWell(
        onTap: () => _showDetail(context),
        child: Row(
          children: [
            Container(
              width: 64,
              color: color.withValues(alpha: 0.08),
              child: item.imageUrl.isEmpty
                  ? Icon(InstitutionType.icon(item.type),
                      size: 26, color: color.withValues(alpha: 0.6))
                  : CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      width: 64,
                      height: 78,
                      errorWidget: (_, __, ___) => Icon(
                          InstitutionType.icon(item.type),
                          size: 26,
                          color: color.withValues(alpha: 0.6))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 6, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 13.5)),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (item.location.isNotEmpty) ...[
                          Icon(Icons.place_rounded, size: 12, color: color),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(item.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (item.workingHours.isNotEmpty) ...[
                          const Icon(Icons.schedule_rounded,
                              size: 12, color: Colors.black45),
                          const SizedBox(width: 3),
                          Text(item.workingHours,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black54)),
                        ],
                        const Spacer(),
                        const Icon(Icons.chevron_left_rounded,
                            size: 16, color: Colors.black38),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 45).ms).fadeIn();
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        final color = InstitutionType.color(item.type);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(18),
            children: [
              if (item.imageUrls.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: PageView(
                    children: [
                      for (final u in item.imageUrls)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                                imageUrl: u,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => ColoredBox(
                                    color: color.withValues(alpha: 0.08),
                                    child: const Center(
                                        child: Icon(Icons.broken_image_rounded,
                                            color: Colors.black26)))),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(InstitutionType.icon(item.type), color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.name, style: VillageOrnament.amiri()),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(InstitutionType.label(item.type),
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: color)),
              const SizedBox(height: 12),
              const OrnamentDivider(),
              const SizedBox(height: 12),
              if (item.description.isNotEmpty)
                Text(item.description,
                    style: const TextStyle(fontSize: 13, height: 1.9)),
              const SizedBox(height: 10),
              if (item.location.isNotEmpty)
                _row(Icons.place_rounded, 'الموقع', item.location, color),
              if (item.workingHours.isNotEmpty)
                _row(Icons.schedule_rounded, 'المواعيد', item.workingHours,
                    color),
              if (item.phone.isNotEmpty)
                _row(Icons.phone_rounded, 'الهاتف', item.phone, color),
              if (item.phone.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13)),
                  onPressed: () => launchUrl(Uri.parse('tel://${item.phone}'),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: const Text('اتصال بالمنشأة',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إغلاق')),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(IconData icon, String label, String value, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            SizedBox(
                width: 72,
                child: Text('$label:',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black54))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700))),
          ],
        ),
      );
}

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/village_content_models.dart';
import '../../services/remote_push_service.dart';
import '../../services/village_extended_service.dart';
import '../../widgets/qurity_app_bar.dart';
import '../../widgets/village_ornament.dart';
import 'village_contribution_screen.dart';

/// «مراجعة مساهمات الأهالي» — شاشة إدارية لمراجعة مساهمات
/// الأرشيف الحي: اعتماد / رفض / تثبيت على الرئيسية / إشعار المساهم / حذف.
class VillageContributionsReviewScreen extends StatefulWidget {
  const VillageContributionsReviewScreen({super.key});

  @override
  State<VillageContributionsReviewScreen> createState() =>
      _VillageContributionsReviewScreenState();
}

class _VillageContributionsReviewScreenState
    extends State<VillageContributionsReviewScreen> {
  final VillageExtendedService _service = VillageExtendedService();
  String _status = 'pending'; // pending | approved | all

  Stream<List<VillageContribution>> get _stream => _status == 'pending'
      ? _service.watchPendingContributions()
      : _service.watchContributions();

  String get _adminUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  List<VillageContribution> _visible(List<VillageContribution> all) {
    if (_status == 'all') return all;
    if (_status == 'approved') {
      return all.where((c) => c.approvalStatus == 'approved').toList();
    }
    return all;
  }

  Future<void> _approve(VillageContribution c) async {
    await _service.approveContribution(c.id, _adminUid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم اعتماد المساهمة ✓'), backgroundColor: Colors.green));
    unawaited(_notifyContributor(c, approved: true));
  }

  /// رفض المساهمة (تبقى محفوظة بحالة rejected ولا تظهر للعامة).
  Future<void> _reject(VillageContribution c) async {
    await _service.rejectContribution(c.id, _adminUid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم رفض المساهمة'), backgroundColor: Colors.orange));
    unawaited(_notifyContributor(c, approved: false));
  }

  /// إشعار شخصي للمساهم بالنتيجة (يبحث عن fcmToken في وثيقة المستخدم).
  Future<void> _notifyContributor(VillageContribution c,
      {required bool approved}) async {
    if (c.userId.isEmpty) return;
    try {
      final udoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(c.userId)
          .get();
      final token = udoc.data()?['fcmToken'] as String?;
      if (token == null || token.isEmpty) return;
      await RemotePushService.sendToDevice(
        fcmToken: token,
        title: approved
            ? 'مساهمتك في أرشيف القرية 🗄️'
            : 'بخصوص مساهمتك في أرشيف القرية',
        body: approved
            ? 'تم اعتماد مساهمتك «${c.title}» — شكراً لمشاركتك!'
            : 'لم يتم نشر مساهمتك «${c.title}» هذه المرة. تواصل مع الإدارة للتفاصيل.',
        route: '/about',
        collection: 'village_contributions',
        itemId: c.id,
      );
    } catch (_) {}
  }

  Future<void> _delete(VillageContribution c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المساهمة؟'),
        content: Text('سيُحذف «${c.title}» نهائياً.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      await _service.deleteContribution(c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const QurityAppBar(
          title: 'مراجعة مساهمات الأهالي', color: kVillageContribColor),
      body: Column(
        children: [
          // فلاتر الحالة
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                for (final (key, label) in [
                  ('pending', 'قيد المراجعة'),
                  ('approved', 'المعتمدة'),
                  ('all', 'الكل'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(label,
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w800)),
                      selected: _status == key,
                      selectedColor:
                          kVillageContribColor.withValues(alpha: 0.18),
                      onSelected: (_) => setState(() => _status = key),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<VillageContribution>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2));
                }
                final items = _visible(snapshot.data ?? const []);
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 52,
                            color:
                                kVillageContribColor.withValues(alpha: 0.35)),
                        const SizedBox(height: 10),
                        Text(
                          _status == 'pending'
                              ? 'لا مساهمات بانتظار المراجعة'
                              : 'لا مساهمات هنا',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _ContributionReviewCard(
                    item: items[i],
                    onApprove: () => _approve(items[i]),
                    onReject: () => _reject(items[i]),
                    onDelete: () => _delete(items[i]),
                    onTogglePin: () => _service.pinContribution(
                        items[i].id, !items[i].pinOnHome),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة مراجعة مساهمة واحدة.
class _ContributionReviewCard extends StatelessWidget {
  const _ContributionReviewCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
    required this.onTogglePin,
  });

  final VillageContribution item;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = ContributionType.of(item.type);
    final pending = item.approvalStatus == 'pending';
    final rejected = item.approvalStatus == 'rejected';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: kVillageContribColor.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: item.pinOnHome
            ? BorderSide(
                color: VillageOrnament.gold.withValues(alpha: 0.8), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(type.icon, size: 17, color: type.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800)),
                      Text(
                          '${type.label} · ${item.userName.isNotEmpty ? item.userName : 'مساهم'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10.5,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                // شارة الحالة
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: (pending
                            ? Colors.orange
                            : rejected
                                ? Colors.red
                                : Colors.green)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pending
                        ? 'قيد المراجعة'
                        : rejected
                            ? 'مرفوضة'
                            : 'معتمدة',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: pending
                            ? Colors.orange
                            : rejected
                                ? Colors.red
                                : Colors.green),
                  ),
                ),
              ],
            ),
            if (item.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(item.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, height: 1.7)),
              ),
            if (item.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const SizedBox(),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (pending)
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 8)),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label:
                          const Text('اعتماد', style: TextStyle(fontSize: 12)),
                      onPressed: onApprove,
                    ),
                  ),
                if (pending) const SizedBox(width: 8),
                if (pending)
                  IconButton(
                    tooltip: 'رفض المساهمة',
                    icon: const Icon(Icons.close_rounded,
                        size: 19, color: Colors.orange),
                    onPressed: onReject,
                  ),
                if (item.approvalStatus == 'approved')
                  IconButton(
                    tooltip: item.pinOnHome
                        ? 'إلغاء التثبيت عن الرئيسية'
                        : 'تثبيت على الرئيسية',
                    icon: Icon(
                      item.pinOnHome
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      size: 19,
                      color: item.pinOnHome
                          ? VillageOrnament.gold
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onTogglePin,
                  ),
                IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 19, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

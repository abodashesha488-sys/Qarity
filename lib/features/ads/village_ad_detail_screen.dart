import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/contact_links.dart';
import '../../core/utils/relative_time.dart';
import '../../models/village_ad_model.dart';
import '../../services/share_service.dart';
import '../../services/village_ad_service.dart';
import '../../widgets/ad_photo_frame.dart';
import '../../widgets/owner_actions.dart';
import '../../widgets/qurity_app_bar.dart';
import 'village_ads_screen.dart';

/// صفحة تفاصيل الإعلان — كل صورة في مساحة معلومة يملؤها الرسم، والوصف غير
/// مقتطع، وأزرار تواصل، وتحكم لصاحب الإعلان (تعديل/حذف) فوق ما تملكه الإدارة
/// في اللوحة.
class VillageAdDetailScreen extends StatefulWidget {
  const VillageAdDetailScreen({super.key, this.service});

  /// قابل للحقن لاختبار الشاشة بلا Firebase (نمط المشروع).
  final VillageAdService? service;

  @override
  State<VillageAdDetailScreen> createState() => _VillageAdDetailScreenState();
}

class _VillageAdDetailScreenState extends State<VillageAdDetailScreen> {
  late final VillageAdService _service = widget.service ?? VillageAdService();
  VillageAd? _ad;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ad ??= ModalRoute.of(context)?.settings.arguments as VillageAd?;
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _edit(VillageAd ad) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => VillageAdFormSheet(
        userId: ad.userId,
        userName: ad.userName,
        existing: ad,
        service: _service,
      ),
    );
    if (ok != true || !mounted) return;
    final fresh = await _safeGet(ad.id);
    if (!mounted) return;
    setState(() => _ad = fresh ?? ad);
    _snack('تم حفظ التعديلات');
  }

  Future<bool> _delete(VillageAd ad) async {
    try {
      await _service.delete(ad.id);
      if (mounted) Navigator.pop(context);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<VillageAd?> _safeGet(String id) async {
    try {
      return await _service.getById(id);
    } catch (_) {
      return null;
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? kAdsDeleteRed : kVillageAdsColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ad = _ad;
    if (ad == null) {
      return Scaffold(
        appBar: const QurityAppBar(title: 'تفاصيل الإعلان'),
        body: Center(
          child: Text('انتهت صلاحية هذا الرابط — افتح الإعلان من صفحته.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
      );
    }
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      uid = null;
    }

    return Scaffold(
      appBar: QurityAppBar(
        title: ad.title,
        actions: [
          IconButton(
            key: const Key('ad-detail-share'),
            tooltip: 'مشاركة الإعلان',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => ShareService.shareText(
              title: '📢 ${ad.kindLabel}: ${ad.title}',
              body: [
                if (ad.businessName.isNotEmpty) ad.businessName,
                if (ad.description.isNotEmpty) ad.description,
                if (ad.location.isNotEmpty) 'المكان: ${ad.location}',
                if (ad.phone.isNotEmpty) 'تواصل: ${ad.phone}',
                '— من إعلانات قرية أبوديشيشة',
              ].join('\n'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          _header(theme, ad),
          if (ad.imageUrls.isNotEmpty) ..._images(ad),
          if (ad.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            _card(
              theme,
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle(theme, Icons.article_rounded, 'تفاصيل الإعلان'),
                    const SizedBox(height: 8),
                    Text(ad.description,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.75,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _card(
            theme,
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle(theme, Icons.info_outline_rounded, 'بيانات الإعلان'),
                  const SizedBox(height: 6),
                  _infoRow(theme, Icons.sell_rounded, 'النوع', ad.kindLabel),
                  _infoRow(theme, Icons.storefront_rounded, 'النشاط',
                      ad.businessName),
                  _infoRow(
                      theme, Icons.place_rounded, 'المكان', ad.location),
                  _infoRow(theme, Icons.phone_rounded, 'الهاتف', ad.phone),
                  _infoRow(theme, Icons.person_rounded, 'مقدّم الإعلان',
                      ad.userName),
                  _infoRow(theme, Icons.schedule_rounded, 'نُشر',
                      relativeTimeLabelAr(ad.createdAt)),
                ],
              ),
            ),
          ),
          if (ad.phone.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('ad-detail-call'),
                    onPressed: () => _launch('tel://${ad.phone}'),
                    style: FilledButton.styleFrom(
                        backgroundColor: kVillageAdsColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('اتصال',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('ad-detail-whatsapp'),
                    onPressed: () {
                      final u = egyptianWhatsAppUrl(ad.phone);
                      if (u != null) _launch(u);
                    },
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF128C7E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('واتساب',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          OwnerActions(
            keyTag: 'ad-detail',
            ownerId: ad.userId,
            currentUserId: uid ?? '',
            itemName: ad.title,
            editLabel: 'تعديل إعلاني',
            deleteLabel: 'حذف إعلاني',
            onEdit: () => _edit(ad),
            onDelete: () => _delete(ad),
          ),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme, VillageAd ad) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kVillageAdsColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: kVillageAdsColor.withValues(alpha: 0.32)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  color: kVillageAdsColor,
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(ad.kindIcon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ad.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(
                    [
                      ad.kindLabel,
                      if (ad.businessName.isNotEmpty) ad.businessName,
                    ].join(' · '),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: kVillageAdsColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// مساحة صورة معلومة الارتفاع بعرض الصفحة، يملؤها الرسم — فالإعلان يُقرأ
  /// بمساحاته لا بمقاس صورة صاحبه.
  List<Widget> _images(VillageAd ad) {
    final list = <Widget>[];
    for (var i = 0; i < ad.imageUrls.length; i++) {
      list.add(const SizedBox(height: 14));
      list.add(AdPhotoFrame(
        imageUrl: ad.imageUrls[i],
        height: kVillageAdDetailImageHeight,
        accent: kVillageAdsColor,
        radius: 18,
        icon: Icons.image_rounded,
      ));
      if (ad.imageUrls.length > 1) {
        list.add(Padding(
          padding: const EdgeInsets.only(top: 5, right: 2),
          child: Text('صورة ${i + 1} من ${ad.imageUrls.length}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ));
      }
    }
    return list;
  }

  Widget _card(ThemeData theme, Widget child) => Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
        ),
        child: child,
      );

  Widget _cardTitle(ThemeData theme, IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: kVillageAdsColor),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        ],
      );

  Widget _infoRow(ThemeData theme, IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: kVillageAdsColor),
          const SizedBox(width: 8),
          SizedBox(
              width: 96,
              child: Text('$label:',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

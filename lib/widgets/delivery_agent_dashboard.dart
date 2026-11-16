import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/utils/app_image_cache.dart';
import '../core/utils/contact_links.dart';
import '../core/utils/launch_link.dart';
import '../features/village/village_content_admin.dart';
import '../models/eshterili_model.dart';
import '../models/etsawaqli_model.dart';
import '../models/group_deal_model.dart';
import '../services/eshterili_service.dart';
import '../services/etsawaqli_service.dart';

/// لوحة ومنظومة المندوبين الموحدة لخدمات (صفقة اليوم - إشتريلي - إتسوقلي)
/// تتيح التحقق الفوري الشامل من كود الاستلام (4 أرقام) وتسليم البضائع ومتابعة التحصيل المالي
class DeliveryAgentDashboard extends StatefulWidget {
  const DeliveryAgentDashboard({super.key});

  @override
  State<DeliveryAgentDashboard> createState() => _DeliveryAgentDashboardState();
}

class _DeliveryAgentDashboardState extends State<DeliveryAgentDashboard> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _universalCodeCtrl = TextEditingController();

  final EshteriliService _eshteriliService = EshteriliService();
  final EtsawaqliService _etsawaqliService = EtsawaqliService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSearchingCode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _universalCodeCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────── المحرك الشامل للتحقق الفوري من الكود ─────────────────────────
  Future<void> _verifyUniversalCode() async {
    final code = _universalCodeCtrl.text.trim();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال كود الاستلام المكون من 4 أرقام', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }

    setState(() => _isSearchingCode = true);
    final agentUid = _auth.currentUser?.uid ?? 'delivery_agent';

    try {
      // 1. البحث في صفقات الجملة
      final dealParticipantQuery = await FirebaseFirestore.instance
          .collection('group_deal_participants')
          .where('claimCode', isEqualTo: code)
          .limit(1)
          .get();

      if (dealParticipantQuery.docs.isNotEmpty) {
        final pDoc = dealParticipantQuery.docs.first;
        final participant = DealParticipantModel.fromJson(pDoc.data(), pDoc.id);
        final dealSnap = await FirebaseFirestore.instance.collection('group_deals').doc(participant.dealId).get();
        final deal = dealSnap.exists ? GroupDealModel.fromJson(dealSnap.data()!, dealSnap.id) : null;

        setState(() => _isSearchingCode = false);
        if (!mounted) return;
        _showDealDeliveryDialog(participant, deal, agentUid, pDoc.reference);
        return;
      }

      // 2. البحث في خدمة إشتريلي
      final eshteriliQuery = await FirebaseFirestore.instance
          .collection('eshterili_orders')
          .where('claimCode', isEqualTo: code)
          .limit(1)
          .get();

      if (eshteriliQuery.docs.isNotEmpty) {
        final oDoc = eshteriliQuery.docs.first;
        final order = EshteriliOrder.fromJson(oDoc.data(), oDoc.id);

        setState(() => _isSearchingCode = false);
        if (!mounted) return;
        _showEshteriliDeliveryDialog(order, agentUid, oDoc.reference);
        return;
      }

      // 3. البحث في خدمة إتسوقلي
      final etsawaqliQuery = await FirebaseFirestore.instance
          .collection('etsawaqli_orders')
          .where('claimCode', isEqualTo: code)
          .limit(1)
          .get();

      if (etsawaqliQuery.docs.isNotEmpty) {
        final oDoc = etsawaqliQuery.docs.first;
        final order = EtsawaqliOrder.fromJson(oDoc.data(), oDoc.id);

        setState(() => _isSearchingCode = false);
        if (!mounted) return;
        _showEtsawaqliDeliveryDialog(order, agentUid, oDoc.reference);
        return;
      }

      setState(() => _isSearchingCode = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('الكود ($code) غير موجود في أي من خدمات الصفقات أو إشتريلي أو إتسوقلي', style: const TextStyle(fontFamily: 'Cairo')),
        ),
      );
    } catch (e) {
      setState(() => _isSearchingCode = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء التحقق: $e', style: const TextStyle(fontFamily: 'Cairo'))),
        );
      }
    }
  }

  void _showDealDeliveryDialog(
    DealParticipantModel participant,
    GroupDealModel? deal,
    String agentUid,
    DocumentReference ref,
  ) {
    final dealPrice = deal?.dealPrice ?? 0.0;
    final deposit = deal?.depositAmount ?? 0.0;
    final toCollect = participant.remainingOnDelivery(dealPrice, deposit);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('صفقة جملة — مطابقة الكود', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('العميل: ${participant.userName}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
            Text('الهاتف: ${participant.userPhone}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            Text('الصفقة: ${deal?.title ?? "صفقة اليوم"}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            Text('الكمية: ${participant.quantity} ${deal?.unitName ?? "حصة"}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            Text('طريقة الاستلام: ${participant.deliveryOption == "home" ? "توصيل منزلي" : "مقر التوزيع بالقرية"}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            if (participant.deliveryAddress.isNotEmpty)
              Text('العنوان: ${participant.deliveryAddress}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey)),
            const Divider(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المبلغ المطلوب تحصيله:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12)),
                  Text(
                    '${toCollect.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF16A34A), fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            onPressed: participant.isDelivered
                ? null
                : () async {
                    await ref.update({
                      'isDelivered': true,
                      'deliveredAt': FieldValue.serverTimestamp(),
                      'deliveredBy': agentUid,
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      _universalCodeCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF16A34A),
                          content: Text('تم توثيق تسليم الصفقة وتحصيل المبلغ بنجاح ✅', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      );
                    }
                  },
            child: Text(
              participant.isDelivered ? 'مسلَّم مسبقاً' : 'تأكيد التسليم والتحصيل ✅',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreviewDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: InteractiveViewer(
                child: AppImageCache.image(
                  url: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEshteriliDeliveryDialog(
    EshteriliOrder order,
    String agentUid,
    DocumentReference ref,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.delivery_dining_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('طلب إشتريلي — مطابقة الكود', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('العميل: ${order.userName}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
            Text('الهاتف: ${order.userPhone}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            Text('المشتريات: ${order.itemsDescription}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            if (order.deliveryAddress.isNotEmpty)
              Text('العنوان: ${order.deliveryAddress}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey)),
            if (order.receiptImageUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showImagePreviewDialog(context, order.receiptImageUrl, 'فاتورة المحل الورقية'),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: AppImageCache.image(
                          url: order.receiptImageUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('فاتورة المحل الأصلية 🧾', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Cairo')),
                            Text('انقر لمعاينة صورة الفاتورة مكبرة', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
                          ],
                        ),
                      ),
                      const Icon(Icons.zoom_in_rounded, size: 20, color: Color(0xFF2563EB)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () async {
                  final url = await pickAndUploadImage(context);
                  if (url != null && url.isNotEmpty) {
                    await ref.update({'receiptImageUrl': url});
                    if (mounted) {
                      Navigator.pop(context);
                      _showEshteriliDeliveryDialog(
                        order.copyWith(receiptImageUrl: url),
                        agentUid,
                        ref,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.receipt_long_rounded, size: 16),
                label: const Text('تصوير وإرفاق فاتورة المحل 🧾', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
            const Divider(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المبلغ المطلوب تحصيله:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12)),
                  Text(
                    order.totalAmount > 0
                        ? '${order.totalAmount.toStringAsFixed(0)} ج.م'
                        : 'حسب الفاتورة الفعلية',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2563EB), fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: order.status == EshteriliStatus.completed
                ? null
                : () async {
                    await ref.update({
                      'status': EshteriliStatus.completed.code,
                      'deliveredAt': FieldValue.serverTimestamp(),
                      'deliveredBy': agentUid,
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      _universalCodeCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF16A34A),
                          content: Text('تم توثيق تسليم طلب إشتريلي بنجاح ✅', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      );
                    }
                  },
            child: Text(
              order.status == EshteriliStatus.completed ? 'مسلَّم مسبقاً' : 'تأكيد التسليم والتحصيل ✅',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showEtsawaqliDeliveryDialog(
    EtsawaqliOrder order,
    String agentUid,
    DocumentReference ref,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.shopping_basket_rounded, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('تسوق إتسوقلي — مطابقة الكود', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('العميل: ${order.userName}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13)),
            Text('الهاتف: ${order.userPhone}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            Text('السوق: ${order.marketName} (${order.marketDay})', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            Text('عدد السلع: ${order.items.length} أصناف', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            if (order.deliveryAddress.isNotEmpty)
              Text('العنوان: ${order.deliveryAddress}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey)),
            const Divider(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('إجمالي الفاتورة المطلوب تحصيله:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12)),
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF16A34A), fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            onPressed: order.status == 'completed'
                ? null
                : () async {
                    await ref.update({
                      'status': 'completed',
                      'deliveredAt': FieldValue.serverTimestamp(),
                      'deliveredBy': agentUid,
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      _universalCodeCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF16A34A),
                          content: Text('تم توثيق تسليم فاتورة إتسوقلي بنجاح ✅', style: TextStyle(fontFamily: 'Cairo')),
                        ),
                      );
                    }
                  },
            child: Text(
              order.status == 'completed' ? 'مسلَّم مسبقاً' : 'تأكيد التسليم والتحصيل ✅',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.two_wheeler_rounded, color: Color(0xFFEA580C)),
            SizedBox(width: 8),
            Text(
              'منظومة المندوبين ومطابقة الاستلام 🛵',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          tabs: const [
            Tab(icon: Icon(Icons.groups_rounded, size: 18), text: 'صفقة اليوم'),
            Tab(icon: Icon(Icons.delivery_dining_rounded, size: 18), text: 'إشتريلي'),
            Tab(icon: Icon(Icons.shopping_basket_rounded, size: 18), text: 'إتسوقلي'),
          ],
        ),
      ),
      body: Column(
        children: [
          // شريط التحقق الفوري الموحد من كود الـ 4 أرقام
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _universalCodeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: Color(0xFFC2410C),
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: 'أدخل كود الاستلام (4 أرقام)',
                        hintStyle: TextStyle(fontSize: 12, fontFamily: 'Cairo', letterSpacing: 0, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        prefixIcon: Icon(Icons.vpn_key_rounded, color: Color(0xFFEA580C), size: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFC2410C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: _isSearchingCode ? null : _verifyUniversalCode,
                  icon: _isSearchingCode
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text(
                    'تحقق وتسليم',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGroupDealsTab(theme),
                _buildEshteriliTab(theme),
                _buildEtsawaqliTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── تبويب 1: صفقات اليوم ─────────────────────────
  Widget _buildGroupDealsTab(ThemeData theme) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('group_deal_participants')
          .where('isDelivered', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('لا توجد حجوزات صفقات معلقة بانتظار التسليم حالياً 🎉', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          );
        }

        final participants = docs.map((d) => DealParticipantModel.fromJson(d.data(), d.id)).toList();

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: participants.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final p = participants[idx];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'كود: ${p.claimCode}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD97706), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الكمية: ${p.quantity} حصص • ${p.deliveryOption == "home" ? "توصيل للمنزل (+10 ج)" : "استلام من المقر مجاناً"}',
                      style: const TextStyle(fontSize: 11.5, fontFamily: 'Cairo'),
                    ),
                    if (p.deliveryAddress.isNotEmpty)
                      Text('العنوان: ${p.deliveryAddress}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (p.userPhone.isNotEmpty) ...[
                          IconButton.filledTonal(
                            tooltip: 'اتصال',
                            icon: const Icon(Icons.phone, size: 18),
                            onPressed: () => launchPhoneCall(p.userPhone),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            tooltip: 'واتساب',
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            onPressed: () {
                              final wa = egyptianWhatsAppUrl(p.userPhone);
                              if (wa != null) launchWhatsAppUrl(wa);
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Spacer(),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.15),
                            foregroundColor: const Color(0xFF16A34A),
                          ),
                          onPressed: () {
                            _universalCodeCtrl.text = p.claimCode;
                            _verifyUniversalCode();
                          },
                          child: const Text('تسليم وتحصيل 🔑', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ───────────────────────── تبويب 2: إشتريلي ─────────────────────────
  Widget _buildEshteriliTab(ThemeData theme) {
    return StreamBuilder<List<EshteriliOrder>>(
      stream: _eshteriliService.watchAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allOrders = snapshot.data ?? [];
        final activeOrders = allOrders.where((o) => o.status == EshteriliStatus.inProgress).toList();

        if (activeOrders.isEmpty) {
          return const Center(
            child: Text('لا توجد طلبات إشتريلي جارية حالياً 🎉', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: activeOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final order = activeOrders[idx];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'كود: ${order.claimCode}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2563EB), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('العميل: ${order.userName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                    Text('الطلبات: ${order.itemsDescription}', style: const TextStyle(fontSize: 12, fontFamily: 'Cairo')),
                    if (order.deliveryAddress.isNotEmpty)
                      Text('العنوان: ${order.deliveryAddress}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
                    if (order.imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppImageCache.image(
                          url: order.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    if (order.receiptImageUrl.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _showImagePreviewDialog(context, order.receiptImageUrl, 'فاتورة المحل الأصلية'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFF16A34A)),
                              SizedBox(width: 4),
                              Text('مرفق فاتورة المحل الورقية 🧾 (انقر للمعاينة)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontFamily: 'Cairo')),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (order.userPhone.isNotEmpty) ...[
                          IconButton.filledTonal(
                            tooltip: 'اتصال بالعميل',
                            icon: const Icon(Icons.phone, size: 18),
                            onPressed: () => launchPhoneCall(order.userPhone),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            tooltip: 'واتساب',
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            onPressed: () {
                              final wa = egyptianWhatsAppUrl(order.userPhone);
                              if (wa != null) launchWhatsAppUrl(wa);
                            },
                          ),
                          const SizedBox(width: 6),
                        ],
                        IconButton.filledTonal(
                          tooltip: order.receiptImageUrl.isNotEmpty ? 'معاينة فاتورة المحل 🧾' : 'إرفاق فاتورة المحل 📷',
                          icon: Icon(order.receiptImageUrl.isNotEmpty ? Icons.receipt_long : Icons.add_a_photo_outlined, size: 18),
                          onPressed: () async {
                            if (order.receiptImageUrl.isNotEmpty) {
                              _showImagePreviewDialog(context, order.receiptImageUrl, 'فاتورة المحل الأصلية');
                            } else {
                              final url = await pickAndUploadImage(context);
                              if (url != null && url.isNotEmpty) {
                                await _eshteriliService.attachReceiptImage(order.id, url);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Color(0xFF16A34A),
                                      content: Text('تم إرفاق فاتورة المحل بنجاح ✅', style: TextStyle(fontFamily: 'Cairo')),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                        const Spacer(),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                            foregroundColor: const Color(0xFF2563EB),
                          ),
                          onPressed: () {
                            _universalCodeCtrl.text = order.claimCode;
                            _verifyUniversalCode();
                          },
                          child: const Text('تسليم وتحصيل 🔑', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ───────────────────────── تبويب 3: إتسوقلي ─────────────────────────
  Widget _buildEtsawaqliTab(ThemeData theme) {
    return StreamBuilder<List<EtsawaqliOrder>>(
      stream: _etsawaqliService.watchAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allOrders = snapshot.data ?? [];
        final activeOrders = allOrders.where((o) => o.status != 'completed' && o.status != 'cancelled').toList();

        if (activeOrders.isEmpty) {
          return const Center(
            child: Text('لا توجد فواتير تسوق معلقة حالياً 🎉', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: activeOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final order = activeOrders[idx];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(order.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'كود: ${order.claimCode}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF16A34A), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('العميل: ${order.userName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                    Text('السوق: ${order.marketName} (${order.marketDay})', style: const TextStyle(fontSize: 11.5, fontFamily: 'Cairo')),
                    Text('الأصناف: ${order.items.length} أصناف • الإجمالي: ${order.totalAmount.toStringAsFixed(0)} ج', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    if (order.deliveryAddress.isNotEmpty)
                      Text('العنوان: ${order.deliveryAddress}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (order.userPhone.isNotEmpty) ...[
                          IconButton.filledTonal(
                            tooltip: 'اتصال بالعميل',
                            icon: const Icon(Icons.phone, size: 18),
                            onPressed: () => launchPhoneCall(order.userPhone),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            tooltip: 'واتساب',
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            onPressed: () {
                              final wa = egyptianWhatsAppUrl(order.userPhone);
                              if (wa != null) launchWhatsAppUrl(wa);
                            },
                          ),
                        ],
                        const Spacer(),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.15),
                            foregroundColor: const Color(0xFF16A34A),
                          ),
                          onPressed: () {
                            _universalCodeCtrl.text = order.claimCode;
                            _verifyUniversalCode();
                          },
                          child: const Text('تسليم وتحصيل 🔑', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

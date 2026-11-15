import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/utils/contact_links.dart';
import '../../core/utils/launch_link.dart';
import '../../models/group_deal_model.dart';
import '../../services/group_deal_service.dart';
import '../../widgets/group_deal_delivery_screen.dart';

/// شاشة إدارة صفقات الجملة والحسابات المالية في لوحة تحكم الأدمن
class GroupDealsAdminScreen extends StatefulWidget {
  const GroupDealsAdminScreen({super.key});

  @override
  State<GroupDealsAdminScreen> createState() => _GroupDealsAdminScreenState();
}

class _GroupDealsAdminScreenState extends State<GroupDealsAdminScreen> {
  final GroupDealService _service = GroupDealService();
  String? _selectedDealId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة صفقات الجملة والمالية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'إضافة صفقة جملة جديدة',
            icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
            onPressed: () => _openDealFormDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<GroupDealModel>>(
        stream: _service.watchActiveDeals(),
        builder: (context, dealsSnap) {
          final deals = dealsSnap.data ?? [];
          if (dealsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (deals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('لا توجد صفقات جماعية مسجلة حالياً', style: TextStyle(fontFamily: 'Cairo')),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _openDealFormDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة أول صفقة جماعية', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ],
              ),
            );
          }

          final activeDeal = _selectedDealId != null
              ? deals.firstWhere((d) => d.id == _selectedDealId, orElse: () => deals.first)
              : deals.first;

          return StreamBuilder<List<DealParticipantModel>>(
            stream: _service.watchDealParticipants(activeDeal.id),
            builder: (context, participantsSnap) {
              final participants = participantsSnap.data ?? [];
              final finSummary = GroupDealFinancialSummary.calculate(activeDeal, participants);

              return ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  // 1. منتقي الصفقات الحالية
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: deals.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final d = deals[i];
                        final isSel = d.id == activeDeal.id;
                        return ChoiceChip(
                          label: Text(d.title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          selected: isSel,
                          onSelected: (_) => setState(() => _selectedDealId = d.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. بطاقة السجل المالي والوفورات الشاملة للصفقة
                  _buildFinancialLedgerCard(theme, activeDeal, finSummary),
                  const SizedBox(height: 14),

                  // 3. أزرار إجراءات الصفقة (تسليم / إيقاف / تعديل)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupDealDeliveryScreen(dealId: activeDeal.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.local_shipping_outlined),
                          label: const Text('فتح شاشة التسليم والمندوب', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'تعديل الصفقة',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openDealFormDialog(context, existing: activeDeal),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'حذف الصفقة',
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDeleteDeal(activeDeal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. جدول حجوزات المشتركين وتأكيد العربون
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'قائمة المشتركين (${participants.length})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                      Text(
                        'مؤكد: ${finSummary.confirmedCount} • معلق: ${finSummary.unconfirmedCount}',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (participants.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Text('لا توجد حجوزات مسجلة لهذه الصفقة بعد.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo')),
                    )
                  else
                    ...participants.map((p) => _buildParticipantTile(theme, activeDeal, p)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFinancialLedgerCard(
    ThemeData theme,
    GroupDealModel deal,
    GroupDealFinancialSummary fin,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102A22), Color(0xFF1B4D3E)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'السجل المالي للصفقة والأرباح الموفرة',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'وفر ${fin.savingsPerUnit.toStringAsFixed(0)} ج / ${deal.unitName}',
                  style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),

          // الوفر المالي لأهالي القرية (المكسب الموفر)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي المكاسب الموفرة لأهالي القرية:',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Cairo'),
                    ),
                    Text(
                      'مجموع فرق السعر عن السوق لكافة المشتركين',
                      style: TextStyle(color: Colors.white38, fontSize: 9, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
                Text(
                  '${fin.totalVillageSavings.toStringAsFixed(0)} جنيه',
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // الحركات المالية الأربعة الدقيقة
          Row(
            children: [
              Expanded(
                child: _buildFinSubBox(
                  'إجمالي المبيعات المؤكدة',
                  '${fin.totalConfirmedSales.toStringAsFixed(0)} ج',
                  Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFinSubBox(
                  'العربون المحصل',
                  '${fin.totalDepositsCollected.toStringAsFixed(0)} ج',
                  const Color(0xFF34D399),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFinSubBox(
                  'متبقي للتحصيل عند التسليم',
                  '${fin.totalRemainingToCollect.toStringAsFixed(0)} ج',
                  const Color(0xFFFBBF24),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFinSubBox(
                  'قيمة ما تم تسليمه فعلياً',
                  '${fin.totalDeliveredValue.toStringAsFixed(0)} ج',
                  const Color(0xFF60A5FA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinSubBox(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'Cairo')),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(
    ThemeData theme,
    GroupDealModel deal,
    DealParticipantModel p,
  ) {
    final deposit = p.depositRequired(deal.depositAmount);
    final remaining = p.remainingOnDelivery(deal.dealPrice, deal.depositAmount);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: p.isConfirmedByAdmin
              ? (p.isDelivered ? const Color(0xFF16A34A).withValues(alpha: 0.5) : const Color(0xFFD97706).withValues(alpha: 0.4))
              : Colors.orange.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: p.isConfirmedByAdmin
                      ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  child: Icon(
                    p.isConfirmedByAdmin ? Icons.check_circle_outline : Icons.pending_actions_rounded,
                    color: p.isConfirmedByAdmin ? const Color(0xFF16A34A) : Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(p.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'كود: ${p.claimCode}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'الكمية: ${p.quantity} ${deal.unitName} • الدفع: ${p.paymentMethod}',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                      ),
                      Text(
                        'العربون: ${deposit.toStringAsFixed(0)} ج • باقي عند الاستلام: ${remaining.toStringAsFixed(0)} ج',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'اتصال',
                      icon: const Icon(Icons.phone, size: 18, color: Colors.blue),
                      onPressed: () => launchPhoneCall(p.userPhone),
                    ),
                    IconButton(
                      tooltip: 'واتساب',
                      icon: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
                      onPressed: () {
                        final url = egyptianWhatsAppUrl(p.userPhone);
                        if (url != null) launchWhatsAppUrl(url);
                      },
                    ),
                  ],
                ),
                if (!p.isConfirmedByAdmin)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('تأكيد استلام العربون وإضافة للعداد', style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                    onPressed: () => _confirmDeposit(deal, p),
                  )
                else if (!p.isDelivered)
                  const Text('مؤكد • بانتظار التسليم ⏳', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontFamily: 'Cairo'))
                else
                  const Text('تم التسليم بنجاح ✅', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontFamily: 'Cairo')),
                IconButton(
                  tooltip: 'إلغاء الحجز',
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: () => _cancelBooking(deal, p),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeposit(GroupDealModel deal, DealParticipantModel p) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await _service.confirmDeposit(
      dealId: deal.id,
      participantId: p.id,
      quantity: p.quantity,
      adminUid: adminUid,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16A34A),
          content: Text('تم تأكيد عربون ${p.userName} وزيادة العداد بمقدار ${p.quantity} حصة بنجاح ✅'),
        ),
      );
    }
  }

  Future<void> _cancelBooking(GroupDealModel deal, DealParticipantModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إلغاء الحجز', style: TextStyle(fontFamily: 'Cairo')),
        content: Text('هل أنت متأكد من إلغاء حجز ${p.userName}؟', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await _service.cancelParticipant(
        dealId: deal.id,
        participantId: p.id,
        quantity: p.quantity,
        wasConfirmed: p.isConfirmedByAdmin,
      );
    }
  }

  Future<void> _confirmDeleteDeal(GroupDealModel deal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الصفقة نهائياً', style: TextStyle(fontFamily: 'Cairo')),
        content: Text('هل أنت متأكد من حذف صفقة "${deal.title}" وكافة حجوزاتها؟', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await _service.deleteDeal(deal.id);
      setState(() => _selectedDealId = null);
    }
  }

  Future<void> _openDealFormDialog(BuildContext context, {GroupDealModel? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final imageCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    final marketPriceCtrl = TextEditingController(text: existing?.marketPrice.toStringAsFixed(0) ?? '250');
    final dealPriceCtrl = TextEditingController(text: existing?.dealPrice.toStringAsFixed(0) ?? '180');
    final depositCtrl = TextEditingController(text: existing?.depositAmount.toStringAsFixed(0) ?? '50');
    final targetCtrl = TextEditingController(text: existing?.targetCount.toString() ?? '20');
    final unitCtrl = TextEditingController(text: existing?.unitName ?? 'كرتونة');
    const int daysLeft = 3;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          existing == null ? 'إضافة صفقة جملة جديدة' : 'تعديل الصفقة',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'اسم الصفقة (مثال: كرتونة زيت وزبدة جملة)', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'تفاصيل ومواصفات السلعة', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: imageCtrl,
                decoration: const InputDecoration(labelText: 'رابط صورة المنتج (URL)', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: marketPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'السعر بالسوق (ج)', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: dealPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سعر الجملة (ج)', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: depositCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'العربون (ج)', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'العدد المطلوب', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: unitCtrl,
                decoration: const InputDecoration(labelText: 'اسم الوحدة (كرتونة / شيكارة / حصة)', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;

              final mPrice = double.tryParse(marketPriceCtrl.text.trim()) ?? 0;
              final dPrice = double.tryParse(dealPriceCtrl.text.trim()) ?? 0;
              final dep = double.tryParse(depositCtrl.text.trim()) ?? 0;
              final target = int.tryParse(targetCtrl.text.trim()) ?? 1;

              if (existing == null) {
                final newDeal = GroupDealModel(
                  id: '',
                  title: title,
                  description: descCtrl.text.trim(),
                  imageUrl: imageCtrl.text.trim(),
                  marketPrice: mPrice,
                  dealPrice: dPrice,
                  depositAmount: dep,
                  targetCount: target,
                  unitName: unitCtrl.text.trim().isEmpty ? 'حصة' : unitCtrl.text.trim(),
                  endTime: DateTime.now().add(const Duration(days: daysLeft)),
                );
                await _service.createDeal(newDeal);
              } else {
                final updated = existing.copyWith(
                  title: title,
                  description: descCtrl.text.trim(),
                  imageUrl: imageCtrl.text.trim(),
                  marketPrice: mPrice,
                  dealPrice: dPrice,
                  depositAmount: dep,
                  targetCount: target,
                  unitName: unitCtrl.text.trim(),
                );
                await _service.updateDeal(updated);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ الصفقة', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

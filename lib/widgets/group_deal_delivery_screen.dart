import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/utils/contact_links.dart';
import '../core/utils/launch_link.dart';
import '../models/group_deal_model.dart';
import '../services/group_deal_service.dart';

/// شاشة تسليم صفقات الجملة لعامل التوصيل ومندوبي السوق بالقرية
class GroupDealDeliveryScreen extends StatefulWidget {
  const GroupDealDeliveryScreen({super.key, required this.dealId});

  final String dealId;

  @override
  State<GroupDealDeliveryScreen> createState() => _GroupDealDeliveryScreenState();
}

class _GroupDealDeliveryScreenState extends State<GroupDealDeliveryScreen> {
  final GroupDealService _service = GroupDealService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _codeCtrl = TextEditingController();
  bool _isVerifying = false;
  String _selectedTab = 'pending'; // pending / delivered / all

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyCode(GroupDealModel deal) async {
    final code = _codeCtrl.text.trim();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة كود الاستلام المكون من 4 أرقام')),
      );
      return;
    }

    setState(() => _isVerifying = true);
    final agentUid = _auth.currentUser?.uid ?? 'delivery_agent';
    final result = await _service.verifyAndDeliverByCode(
      dealId: widget.dealId,
      inputCode: code,
      deliveryAgentUid: agentUid,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result.isSuccess) {
      _codeCtrl.clear();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
              SizedBox(width: 8),
              Text('تم التسليم بنجاح', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
              const Divider(height: 18),
              if (result.participant != null) ...[
                Text(
                  'المستلم: ${result.participant!.userName}',
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
                Text(
                  'الكمية المسلمة: ${result.participant!.quantity} ${deal.unitName}',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                Text(
                  'المبلغ المطلوب تحصيله الآن: ${result.participant!.remainingOnDelivery(deal.dealPrice, deal.depositAmount).toStringAsFixed(0)} جنيه',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
              onPressed: () => Navigator.pop(context),
              child: const Text('تم التحصيل والتسليم', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(result.message, style: const TextStyle(fontFamily: 'Cairo')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('شاشة تسليم الحصص للمشتركين', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<GroupDealModel?>(
        stream: _service.watchDeal(widget.dealId),
        builder: (context, dealSnap) {
          final deal = dealSnap.data;
          if (deal == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<DealParticipantModel>>(
            stream: _service.watchDealParticipants(widget.dealId),
            builder: (context, participantsSnap) {
              final participants = participantsSnap.data ?? [];
              final confirmed = participants.where((p) => p.isConfirmedByAdmin).toList();
              final delivered = confirmed.where((p) => p.isDelivered).toList();
              final pending = confirmed.where((p) => !p.isDelivered).toList();

              final deliveredUnits = delivered.fold(0, (s, p) => s + p.quantity);
              final pendingUnits = pending.fold(0, (s, p) => s + p.quantity);
              final totalUnits = deliveredUnits + pendingUnits;

              return Column(
                children: [
                  // 1. لوحة الإحصائيات الفورية لعمليات التسليم
                  Container(
                    margin: const EdgeInsets.all(14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                          theme.colorScheme.surface,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          deal.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTallyItem('إجمالي المحجوز', '$totalUnits', theme.colorScheme.primary),
                            _buildTallyItem('تم التسليم ✅', '$deliveredUnits', const Color(0xFF16A34A)),
                            _buildTallyItem('بانتظار التسليم ⏳', '$pendingUnits', const Color(0xFFD97706)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. حقل إدخال كود الـ 4 أرقام السريع
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'أدخل كود الاستلام (4 أرقام) من العميل:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _codeCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 4,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 8,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '----',
                                  hintStyle: const TextStyle(letterSpacing: 8),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onSubmitted: (_) => _verifyCode(deal),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isVerifying ? null : () => _verifyCode(deal),
                              icon: _isVerifying
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.check_rounded),
                              label: const Text('تسليم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. أزرار تصفية القوائم
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: [
                              ButtonSegment(
                                value: 'pending',
                                label: Text('بانتظار التسليم (${pending.length})', style: const TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                              ),
                              ButtonSegment(
                                value: 'delivered',
                                label: Text('تم التسليم (${delivered.length})', style: const TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                              ),
                            ],
                            selected: {_selectedTab},
                            onSelectionChanged: (set) => setState(() => _selectedTab = set.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 4. قائمة المشتركين
                  Expanded(
                    child: () {
                      final displayList = _selectedTab == 'pending' ? pending : delivered;
                      if (displayList.isEmpty) {
                        return Center(
                          child: Text(
                            _selectedTab == 'pending'
                                ? 'تم تسليم كافة المشتركين بالكامل! 🎉'
                                : 'لم يتم تسليم أي حصة بعد.',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        itemCount: displayList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final p = displayList[i];
                          final remaining = p.remainingOnDelivery(deal.dealPrice, deal.depositAmount);

                          return Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: p.isDelivered
                                    ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                                    : const Color(0xFFD97706).withValues(alpha: 0.3),
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: p.isDelivered
                                      ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                                      : const Color(0xFFD97706).withValues(alpha: 0.15),
                                  child: Icon(
                                    p.isDelivered ? Icons.check : Icons.person_outline,
                                    color: p.isDelivered ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.userName,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'الكمية: ${p.quantity} ${deal.unitName} • المطلوب تحصيله: ${remaining.toStringAsFixed(0)} ج',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      if (p.isDelivered && p.deliveredAt != null)
                                        Text(
                                          'سُلمت بتاريخ: ${p.deliveredAt!.hour}:${p.deliveredAt!.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontFamily: 'Cairo'),
                                        ),
                                    ],
                                  ),
                                ),
                                if (!p.isDelivered) ...[
                                  IconButton(
                                    tooltip: 'اتصال هاتفي',
                                    icon: const Icon(Icons.phone_outlined, size: 20, color: Colors.blue),
                                    onPressed: () => launchPhoneCall(p.userPhone),
                                  ),
                                  IconButton(
                                    tooltip: 'مراسلة واتساب',
                                    icon: const Icon(Icons.chat_bubble_outline, size: 20, color: Color(0xFF25D366)),
                                    onPressed: () {
                                      final url = egyptianWhatsAppUrl(p.userPhone);
                                      if (url != null) launchWhatsAppUrl(url);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    }(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTallyItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, fontFamily: 'Cairo'),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontFamily: 'Cairo'),
        ),
      ],
    );
  }
}

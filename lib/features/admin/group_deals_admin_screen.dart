import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/app_image_cache.dart';
import '../../models/group_deal_model.dart';
import '../../services/group_deal_service.dart';
import '../../widgets/group_deal_delivery_screen.dart';
import '../village/village_content_admin.dart';

/// شاشة إدارة صفقات الجملة والحسابات المالية في لوحة تحكم الأدمن
/// تدعم إدارة صفقات متعددة في نفس الوقت، سجل الصفقات المنفذة، ورفع صور متعددة
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة صفقات الجملة والمالية',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.shopping_bag_outlined, size: 20), text: 'الصفقات الجارية 🛒'),
              Tab(icon: Icon(Icons.history_edu_rounded, size: 20), text: 'سجل الصفقات المنفذة 📜'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'إضافة صفقة جملة جديدة',
              icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
              onPressed: () => _openDealFormDialog(context),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildActiveDealsTab(theme),
            _buildExecutedDealsTab(theme),
          ],
        ),
      ),
    );
  }

  // =================== تبويب 1: الصفقات الجارية ===================
  Widget _buildActiveDealsTab(ThemeData theme) {
    return StreamBuilder<List<GroupDealModel>>(
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
                const Text('لا توجد صفقات جماعية جارية حالياً', style: TextStyle(fontFamily: 'Cairo')),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _openDealFormDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة صفقة جماعية جديدة', style: TextStyle(fontFamily: 'Cairo')),
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
                // 1. منتقي الصفقات الحالية (عند وجود أكثر من صفقة)
                Row(
                  children: [
                    const Icon(Icons.dashboard_customize_outlined, size: 18, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Text(
                      'الصفقات المفتوحة حالياً (${deals.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: deals.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final d = deals[i];
                      final isSel = d.id == activeDeal.id;
                      return ChoiceChip(
                        selectedColor: const Color(0xFFD97706).withValues(alpha: 0.2),
                        avatar: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: Icon(
                            isSel ? Icons.check_circle_rounded : Icons.local_fire_department_rounded,
                            size: 16,
                            color: isSel ? const Color(0xFFD97706) : Colors.grey,
                          ),
                        ),
                        label: Text(
                          '${d.title} (${d.currentCount}/${d.targetCount})',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
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
                        label: const Text(
                          'فتح شاشة التسليم والمندوب',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
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
                    child: Text(
                      'لا توجد حجوزات مسجلة لهذه الصفقة بعد.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                    ),
                  )
                else
                  for (final p in participants) _buildParticipantTile(theme, activeDeal, p),
              ],
            );
          },
        );
      },
    );
  }

  // =================== تبويب 2: سجل الصفقات المنفذة ===================
  Widget _buildExecutedDealsTab(ThemeData theme) {
    return StreamBuilder<List<GroupDealModel>>(
      stream: _service.watchExecutedDeals(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final executedDeals = snap.data ?? [];
        if (executedDeals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.task_alt_rounded, size: 54, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('لا توجد صفقات مكتملة أو سابقة في الأرشيف حتى الآن.', style: TextStyle(fontFamily: 'Cairo')),
                const SizedBox(height: 6),
                Text(
                  'الصفقات التي تكتمل أو تنتهي مدتها تظهر هنا تلقائياً لتوثيق المكاسب.',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                ),
              ],
            ),
          );
        }

        final totalVillageSavings = executedDeals.fold<double>(
          0.0,
          (sum, d) => sum + d.confirmedVillageSavings,
        );
        final totalUnitsDelivered = executedDeals.fold<int>(
          0,
          (sum, d) => sum + d.confirmedCount,
        );

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // بطاقة ملخص الأرشيف الشامل
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF047857)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: Color(0xFFFDE047), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'إجمالي وفورات الصفقات المنفذة لأهالي القرية',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('إجمالي ما وفره الأهالي', style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Cairo')),
                          const SizedBox(height: 4),
                          Text(
                            '${totalVillageSavings.toStringAsFixed(0)} ج',
                            style: const TextStyle(
                              color: Color(0xFFFDE047),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      Container(height: 36, width: 1, color: Colors.white24),
                      Column(
                        children: [
                          const Text('الصفقات المنفذة', style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Cairo')),
                          const SizedBox(height: 4),
                          Text(
                            '${executedDeals.length} صفقة',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      Container(height: 36, width: 1, color: Colors.white24),
                      Column(
                        children: [
                          const Text('الحصص المسلمة', style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Cairo')),
                          const SizedBox(height: 4),
                          Text(
                            '$totalUnitsDelivered حصة',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // قائمة الصفقات المنفذة
            for (final deal in executedDeals) _buildExecutedDealCard(theme, deal),
          ],
        );
      },
    );
  }

  Widget _buildExecutedDealCard(ThemeData theme, GroupDealModel deal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF16A34A).withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: deal.primaryImage.isNotEmpty
                        ? AppImageCache.image(
                            url: deal.primaryImage,
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                            errorWidget: (_, __, ___) => const Icon(Icons.inventory_2_outlined),
                          )
                        : const Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              deal.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              deal.isCompleted ? 'مكتملة ومسلمة ✅' : 'منتهية المدة',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'التصنيف: ${deal.category} • الوحدة: ${deal.unitName}',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildExecutedStat('سعر الجملة', '${deal.dealPrice.toStringAsFixed(0)} ج', Colors.green),
                _buildExecutedStat('المسلم فعلياً', '${deal.confirmedCount} من ${deal.targetCount}', Colors.blue),
                _buildExecutedStat('وفر الأهالي', '${deal.confirmedVillageSavings.toStringAsFixed(0)} ج', const Color(0xFFD97706)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupDealDeliveryScreen(dealId: deal.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list_alt_rounded, size: 18),
                    label: const Text('عرض المشتركين والتسليم', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'حذف من الأرشيف',
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _confirmDeleteDeal(deal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutedStat(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, fontFamily: 'Cairo')),
      ],
    );
  }

  // =================== بطاقة السجل المالي للصفقة ===================
  Widget _buildFinancialLedgerCard(
    ThemeData theme,
    GroupDealModel deal,
    GroupDealFinancialSummary fin,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'السجل المالي: ${deal.title}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.6)),
                ),
                child: Text(
                  'وفر القرية: ${fin.totalVillageSavings.toStringAsFixed(0)} ج',
                  style: const TextStyle(
                    color: Color(0xFF4ADE80),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // شبكة الإحصائيات المالية
          Row(
            children: [
              Expanded(
                child: _buildFinSubBox('العربين المحصلة', '${fin.totalDepositsCollected.toStringAsFixed(0)} ج', const Color(0xFF4ADE80)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFinSubBox('عربين معلقة', '${(fin.unconfirmedCount * deal.depositAmount).toStringAsFixed(0)} ج', Colors.orangeAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFinSubBox('قيمة البضاعة الإجمالية', '${fin.totalConfirmedSales.toStringAsFixed(0)} ج', const Color(0xFF60A5FA)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFinSubBox('المتبقي للتحصيل عند التسليم', '${fin.totalRemainingToCollect.toStringAsFixed(0)} ج', const Color(0xFFFBBF24)),
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

  // =================== بطاقة المشترك وتأكيد العربون ===================
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
                  backgroundColor: p.isDelivered
                      ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                      : (p.isConfirmedByAdmin ? const Color(0xFFD97706).withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15)),
                  child: Icon(
                    p.isDelivered
                        ? Icons.check_circle_rounded
                        : (p.isConfirmedByAdmin ? Icons.how_to_reg_rounded : Icons.pending_rounded),
                    color: p.isDelivered
                        ? const Color(0xFF16A34A)
                        : (p.isConfirmedByAdmin ? const Color(0xFFD97706) : Colors.orange),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                      ),
                      Text(
                        'الحصة: ${p.quantity} ${deal.unitName} • كود الاستلام: ${p.claimCode}',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
                if (p.userPhone.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone_outlined, color: Colors.green, size: 20),
                    onPressed: () => launchUrl(
                      Uri.parse('tel://${p.userPhone}'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
              ],
            ),
            const Divider(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'العربون: ${deposit.toStringAsFixed(0)} ج (${p.isConfirmedByAdmin ? "مستلم ✅" : "معلق ⏳"})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: p.isConfirmedByAdmin ? const Color(0xFF16A34A) : Colors.orange,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  'المتبقي للتسليم: ${remaining.toStringAsFixed(0)} ج',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!p.isConfirmedByAdmin)
                  Expanded(
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFF16A34A),
                      ),
                      onPressed: () => _service.confirmDeposit(
                        dealId: deal.id,
                        participantId: p.id,
                        quantity: p.quantity,
                        adminUid: FirebaseAuth.instance.currentUser?.uid ?? 'admin',
                      ),
                      child: const Text('تأكيد استلام العربون ✅', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                    ),
                  )
                else if (!p.isDelivered)
                  Expanded(
                    child: Text(
                      'العربون مؤكد — بانتظار استلام المشترك بكود [${p.claimCode}]',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFD97706), fontFamily: 'Cairo'),
                    ),
                  )
                else
                  const Expanded(
                    child: Text(
                      'تم تسليم الحصة بالكامل وإتمام الحساب ✅',
                      style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'إلغاء حجز هذا المشترك',
                  icon: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                  onPressed: () => _confirmCancelParticipant(deal, p),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancelParticipant(GroupDealModel deal, DealParticipantModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إلغاء حجز المشترك', style: TextStyle(fontFamily: 'Cairo')),
        content: Text('هل أنت متأكد من إلغاء حجز "${p.userName}" (${p.quantity} ${deal.unitName})؟ سيتم تعديل العدادات المالية تلقائياً.', style: const TextStyle(fontFamily: 'Cairo')),
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
        content: Text('هل أنت متأكد من حذف صفقة "${deal.title}" وكافة بياناتها؟', style: const TextStyle(fontFamily: 'Cairo')),
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

  // =================== نافذة إضافة / تعديل الصفقة ===================
  Future<void> _openDealFormDialog(BuildContext context, {GroupDealModel? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final marketPriceCtrl = TextEditingController(text: existing?.marketPrice.toStringAsFixed(0) ?? '250');
    final dealPriceCtrl = TextEditingController(text: existing?.dealPrice.toStringAsFixed(0) ?? '180');
    final depositCtrl = TextEditingController(text: existing?.depositAmount.toStringAsFixed(0) ?? '50');
    final targetCtrl = TextEditingController(text: existing?.targetCount.toString() ?? '20');

    // تصنيفات السلع ووحدات القياس
    String selectedCategory = existing?.category ?? GroupDealModel.supportedCategories.first;
    if (!GroupDealModel.supportedCategories.contains(selectedCategory)) {
      selectedCategory = 'أخرى';
    }
    final customCategoryCtrl = TextEditingController(
      text: selectedCategory == 'أخرى' ? (existing?.category ?? '') : '',
    );

    String selectedUnit = existing?.unitName ?? GroupDealModel.supportedUnits.first;
    if (!GroupDealModel.supportedUnits.contains(selectedUnit)) {
      selectedUnit = 'أخرى';
    }
    final customUnitCtrl = TextEditingController(
      text: selectedUnit == 'أخرى' ? (existing?.unitName ?? '') : '',
    );

    int daysLeft = 3;
    final List<String> imageUrls = List<String>.from(existing?.allImages ?? []);

    await showDialog(
      context: context,
      builder: (dlgContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(
              existing == null ? 'إضافة صفقة جملة جديدة' : 'تعديل الصفقة',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // اسم الصفقة
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم الصفقة (مثال: كرتونة زيت وزبدة بسعر الجملة)',
                        labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // اختيار تصنيف السلعة
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'تصنيف السلعة',
                        labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      ),
                      items: GroupDealModel.supportedCategories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    if (selectedCategory == 'أخرى') ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: customCategoryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اكتب تصنيف السلعة هنا',
                          labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // تفاصيل ومواصفات السلعة
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'تفاصيل ومواصفات السلعة',
                        labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // إدارة صور الصفقة (صور متعددة)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'صور الصفقة (${imageUrls.length})',
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final url = await pickAndUploadImage(context, current: '');
                            if (url != null && url.isNotEmpty) {
                              setDialogState(() {
                                imageUrls.add(url);
                              });
                            }
                          },
                          icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                          label: const Text('إضافة صورة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                        ),
                      ],
                    ),
                    if (imageUrls.isNotEmpty)
                      SizedBox(
                        height: 70,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: AppImageCache.image(
                                    url: imageUrls[idx],
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        imageUrls.removeAt(idx);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'يمكنك رفع صورة واحدة أو أكثر للمنتج لجذب المشتركين.',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 12),

                    // الأسعار والعربون
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: marketPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'السعر بالسوق (ج)',
                              labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: dealPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'سعر الجملة (ج)',
                              labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                            ),
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
                            decoration: const InputDecoration(
                              labelText: 'العربون المطلوب (ج)',
                              labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: targetCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'العدد المطلوب لاكتمال الحصة',
                              labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // وحدة القياس
                    DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'وحدة القياس / التعبئة',
                        labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      ),
                      items: GroupDealModel.supportedUnits.map((u) {
                        return DropdownMenuItem(
                          value: u,
                          child: Text(u, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedUnit = val);
                        }
                      },
                    ),
                    if (selectedUnit == 'أخرى') ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: customUnitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اكتب اسم الوحدة هنا',
                          labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // مدة العرض
                    DropdownButtonFormField<int>(
                      initialValue: daysLeft,
                      decoration: const InputDecoration(
                        labelText: 'مدة العرض بالأيام',
                        labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('يوم واحد', style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                        DropdownMenuItem(value: 2, child: Text('يومان', style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                        DropdownMenuItem(value: 3, child: Text('3 أيام', style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                        DropdownMenuItem(value: 5, child: Text('5 أيام', style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                        DropdownMenuItem(value: 7, child: Text('أسبوع (7 أيام)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                        DropdownMenuItem(value: 10, child: Text('10 أيام', style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                        DropdownMenuItem(value: 14, child: Text('أسبوعان (14 يوم)', style: TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => daysLeft = val);
                      },
                    ),
                  ],
                ),
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

                  final finalCategory = selectedCategory == 'أخرى' && customCategoryCtrl.text.trim().isNotEmpty
                      ? customCategoryCtrl.text.trim()
                      : selectedCategory;

                  final finalUnit = selectedUnit == 'أخرى' && customUnitCtrl.text.trim().isNotEmpty
                      ? customUnitCtrl.text.trim()
                      : selectedUnit;

                  if (existing == null) {
                    final newDeal = GroupDealModel(
                      id: '',
                      title: title,
                      category: finalCategory,
                      description: descCtrl.text.trim(),
                      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
                      imageUrls: imageUrls,
                      marketPrice: mPrice,
                      dealPrice: dPrice,
                      depositAmount: dep,
                      targetCount: target,
                      unitName: finalUnit,
                      endTime: DateTime.now().add(Duration(days: daysLeft)),
                    );
                    await _service.createDeal(newDeal);
                  } else {
                    final updated = existing.copyWith(
                      title: title,
                      category: finalCategory,
                      description: descCtrl.text.trim(),
                      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
                      imageUrls: imageUrls,
                      marketPrice: mPrice,
                      dealPrice: dPrice,
                      depositAmount: dep,
                      targetCount: target,
                      unitName: finalUnit,
                    );
                    await _service.updateDeal(updated);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('حفظ الصفقة', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          );
        },
      ),
    );
  }
}

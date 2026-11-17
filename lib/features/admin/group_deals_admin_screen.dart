import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/app_image_cache.dart';
import '../../core/utils/launch_link.dart';
import '../../models/eshterili_model.dart';
import '../../models/etsawaqli_model.dart';
import '../../models/group_deal_model.dart';
import '../../services/eshterili_service.dart';
import '../../services/etsawaqli_service.dart';
import '../../services/group_deal_service.dart';
import '../../services/share_service.dart';
import '../../widgets/commercial_receipt_dialog.dart';
import '../../widgets/delivery_agent_dashboard.dart';
import '../../widgets/group_deal_delivery_screen.dart';
import '../village/village_content_admin.dart';

/// شاشة الإدارة الشاملة للمنظومة التجارية والتسوق في لوحة تحكم القرية:
/// 1- صفقات الجملة (الصفقات الجارية + طلبات إعادة الطرح + أرشيف الوفورات)
/// 2- إشتريلي (طلبات الشراء الخاصة + التسعير + تعيين المندوب + تأكيد التسليم)
/// 3- إتسوقلي (فواتير كاشير الأسواق + تسعير السلع والخضروات + إدارة الأسواق والمواعيد)
class GroupDealsAdminScreen extends StatefulWidget {
  const GroupDealsAdminScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  State<GroupDealsAdminScreen> createState() => _GroupDealsAdminScreenState();
}

class _GroupDealsAdminScreenState extends State<GroupDealsAdminScreen> {
  final GroupDealService _dealService = GroupDealService();
  final EshteriliService _eshteriliService = EshteriliService();
  final EtsawaqliService _etsawaqliService = EtsawaqliService();

  // صفقات الجملة
  String? _selectedDealId;
  int _dealSubIndex = 0; // 0: جارية, 1: طلبات إعادة الطرح, 2: الأرشيف والوفورات

  // إشتريلي
  String _eshteriliFilter = 'الكل';

  // إتسوقلي
  int _etsawaqliSubIndex = 0; // 0: فواتير الأسواق, 1: كتالوج السلع والأسعار, 2: الأسواق والمواعيد
  String _etsawaqliCategoryFilter = 'الكل';
  String _etsawaqliStatusFilter = 'الكل';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tabContent = TabBarView(
      children: [
        _buildGroupDealsTab(theme),
        _buildEshteriliTab(theme),
        _buildEtsawaqliTab(theme),
      ],
    );

    if (widget.isEmbedded) {
      return DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // شريط تبويبات أنيق بدون خلفية خضراء تعلو أو تغطي على تبويبات مركز الأدوات
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      labelColor: const Color(0xFF16A34A),
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      indicatorColor: const Color(0xFF16A34A),
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12.5),
                      tabs: const [
                        Tab(icon: Icon(Icons.local_fire_department_rounded, size: 18), text: 'صفقات الجملة 🔥'),
                        Tab(icon: Icon(Icons.two_wheeler_rounded, size: 18), text: 'إشتريلي 🛵'),
                        Tab(icon: Icon(Icons.shopping_basket_rounded, size: 18), text: 'إتسوقلي 🧺'),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'تقرير الإيرادات والحصيلة المالية 📊',
                    icon: const Icon(Icons.analytics_rounded, size: 23, color: Color(0xFF2563EB)),
                    onPressed: () => _showRevenueReportDialog(context),
                  ),
                  IconButton(
                    tooltip: 'منظومة المندوبين ومطابقة الاستلام',
                    icon: const Icon(Icons.two_wheeler_rounded, size: 22, color: Color(0xFFEA580C)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DeliveryAgentDashboard()),
                    ),
                  ),
                  IconButton(
                    tooltip: 'إضافة صفقة جملة جديدة',
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 24, color: Color(0xFF16A34A)),
                    onPressed: () => _openDealFormDialog(context),
                  ),
                ],
              ),
            ),
            Expanded(child: tabContent),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          title: const Text(
            'إدارة الخدمات التجارية والتسوق',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(icon: Icon(Icons.local_fire_department_rounded, size: 20), text: 'صفقات الجملة 🔥'),
              Tab(icon: Icon(Icons.two_wheeler_rounded, size: 20), text: 'إشتريلي 🛵'),
              Tab(icon: Icon(Icons.shopping_basket_rounded, size: 20), text: 'إتسوقلي 🧺'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'تقرير الإيرادات والحصيلة المالية 📊',
              icon: const Icon(Icons.analytics_rounded, size: 25, color: Color(0xFF2563EB)),
              onPressed: () => _showRevenueReportDialog(context),
            ),
            IconButton(
              tooltip: 'منظومة المندوبين ومطابقة الاستلام',
              icon: const Icon(Icons.two_wheeler_rounded, size: 24, color: Color(0xFFEA580C)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeliveryAgentDashboard()),
              ),
            ),
            IconButton(
              tooltip: 'إضافة صفقة جملة جديدة',
              icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
              onPressed: () => _openDealFormDialog(context),
            ),
          ],
        ),
        body: tabContent,
      ),
    );
  }

  // =========================================================================
  // ========================== 1. صفقات الجملة ==============================
  // =========================================================================

  Widget _buildGroupDealsTab(ThemeData theme) {
    return Column(
      children: [
        // شريط التبديل الداخلي لصفقات الجملة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            children: [
              _buildSubTabChip(
                label: 'الصفقات الجارية 🛒',
                isSelected: _dealSubIndex == 0,
                onTap: () => setState(() => _dealSubIndex = 0),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _buildSubTabChip(
                label: 'طلبات فتح الصفقة 🔄',
                isSelected: _dealSubIndex == 1,
                onTap: () => setState(() => _dealSubIndex = 1),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _buildSubTabChip(
                label: 'الأرشيف والوفورات 📜',
                isSelected: _dealSubIndex == 2,
                onTap: () => setState(() => _dealSubIndex = 2),
                theme: theme,
              ),
            ],
          ),
        ),
        Expanded(
          child: _dealSubIndex == 0
              ? _buildActiveDealsView(theme)
              : _dealSubIndex == 1
                  ? _buildReopenRequestsView(theme)
                  : _buildExecutedDealsView(theme),
        ),
      ],
    );
  }

  Widget _buildSubTabChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  // الصفقات الجارية وحسابات كل صفقة
  Widget _buildActiveDealsView(ThemeData theme) {
    return StreamBuilder<List<GroupDealModel>>(
      stream: _dealService.watchActiveDeals(),
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
          stream: _dealService.watchDealParticipants(activeDeal.id),
          builder: (context, participantsSnap) {
            final participants = participantsSnap.data ?? [];
            final finSummary = GroupDealFinancialSummary.calculate(activeDeal, participants);

            return ListView(
              padding: const EdgeInsets.all(14),
              children: [
                // 1. منتقي الصفقات الحالية (عند وجود أكثر من صفقة)
                if (deals.length > 1) ...[
                  Row(
                    children: [
                      const Icon(Icons.layers_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'الصفقات المفتوحة حالياً (${deals.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: deals.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final d = deals[i];
                        final isSelected = d.id == activeDeal.id;
                        return ChoiceChip(
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedDealId = d.id),
                          avatar: d.primaryImage.isNotEmpty
                              ? ClipOval(
                                  child: AppImageCache.image(
                                    url: d.primaryImage,
                                    width: 22,
                                    height: 22,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(Icons.shopping_bag, size: 14),
                                  ),
                                )
                              : const Icon(Icons.shopping_bag, size: 14),
                          label: Text(
                            '${d.title} (${d.confirmedCount}/${d.targetCount})',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

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
                    Row(
                      children: [
                        Text(
                          'قائمة المشتركين (${participants.length})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                        if (participants.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _exportParticipantsManifest(activeDeal, participants),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.print_outlined, size: 13, color: Color(0xFF2563EB)),
                                  SizedBox(width: 4),
                                  Text(
                                    'كشف الحجز 📋',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
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

  void _exportParticipantsManifest(GroupDealModel deal, List<DealParticipantModel> participants) {
    final buffer = StringBuffer()
      ..writeln('📋 كشف حجز صفقة: ${deal.title}')
      ..writeln('▫️ الحصة: ${deal.dealPrice.toStringAsFixed(0)} ج / ${deal.unitName} (وفر ${deal.discountPercentage}%)')
      ..writeln('▫️ إجمالي الحصص المطلوبة: ${deal.confirmedCount} من ${deal.targetCount}')
      ..writeln('▫️ تاريخ الكشف: ${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}')
      ..writeln('══════════════════════════════');

    for (int i = 0; i < participants.length; i++) {
      final p = participants[i];
      final isHome = p.deliveryOption == 'home';
      final delivery = isHome ? 'توصيل منزلي (${p.deliveryAddress})' : 'استلام مقر القرية (مجاناً)';
      final totalAmount = (deal.dealPrice * p.quantity) + p.deliveryFee;
      final status = p.isDelivered
          ? 'تم التسليم بنجاح ✅'
          : (p.isConfirmedByAdmin ? 'حجز مؤكد ✅' : 'بانتظار التأكيد ⏳');
      buffer
        ..writeln('${i + 1}- ${p.userName} | 📞 ${p.userPhone}')
        ..writeln('   • الحصص: ${p.quantity} ${deal.unitName} | المبلغ: ${totalAmount.toStringAsFixed(0)} ج')
        ..writeln('   • الاستلام: $delivery')
        ..writeln('   • الحالة: $status (كود: ${p.claimCode})')
        ..writeln('------------------------------');
    }

    final text = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'كشف مشتركين: ${deal.title}',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11.5, height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('نسخ للحافظة 📋', style: TextStyle(fontFamily: 'Cairo')),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ كشف الحجز للحافظة بنجاح 📋', style: TextStyle(fontFamily: 'Cairo')),
                ),
              );
            },
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('مشاركة الكشف 📲', style: TextStyle(fontFamily: 'Cairo')),
            onPressed: () {
              Navigator.pop(ctx);
              ShareService.shareText(
                title: 'كشف حجز صفقة: ${deal.title}',
                body: text,
              );
            },
          ),
        ],
      ),
    );
  }

  // طلبات إعادة طرح الصفقات
  Widget _buildReopenRequestsView(ThemeData theme) {
    return StreamBuilder<List<GroupDealReopenRequest>>(
      stream: _dealService.watchReopenRequests(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 54, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('لا توجد طلبات لإعادة فتح صفقات منتهية حالياً.', style: TextStyle(fontFamily: 'Cairo')),
                const SizedBox(height: 6),
                Text(
                  'عندما يطلب الأهالي إعادة طرح صفقة اكتملت، ستظهر طلباتهم هنا لتوثيق رغباتهم.',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: Color(0xFFB45309), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'يوجد ${requests.length} طلب من أهالي القرية يطالبون بإعادة طرح صفقات جملة مكتملة أو منتهية. يمكنك إعادة طرح أي صفقة بنقرة واحدة.',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (final req in requests)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restart_alt_rounded, color: Color(0xFFD97706)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.dealTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'طالب الفتح: ${req.userName} • مطلوب: ${req.requestedQuantity} حصة',
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                            ),
                            if (req.userPhone.isNotEmpty)
                              Text(
                                'الهاتف: ${req.userPhone}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontFamily: 'Cairo'),
                              ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final deal = await _dealService.getDealById(req.dealId);
                          if (deal != null && context.mounted) {
                            _openDealFormDialog(context, existing: deal, isRelaunch: true);
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('الصفقة الأصلية غير موجودة.')),
                            );
                          }
                        },
                        child: const Text('إعادة طرح 🚀', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // أرشيف الصفقات المنفذة
  Widget _buildExecutedDealsView(ThemeData theme) {
    return StreamBuilder<List<GroupDealModel>>(
      stream: _dealService.watchExecutedDeals(),
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
          (acc, d) => acc + d.confirmedVillageSavings,
        );
        final totalUnitsDelivered = executedDeals.fold<int>(
          0,
          (acc, d) => acc + d.confirmedCount,
        );

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
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
                      Text(
                        deal.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
                      ),
                      Text(
                        'تصنيف: ${deal.category} • المستهدف: ${deal.targetCount} ${deal.unitName}',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'مكتملة ومسلمة ✅',
                    style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildExecutedStat('سعر الجملة', '${deal.dealPrice.toStringAsFixed(0)} ج', Colors.green),
                _buildExecutedStat('الحصص المنفذة', '${deal.confirmedCount} ${deal.unitName}', Colors.blue),
                _buildExecutedStat('وفر القرية', '${deal.confirmedVillageSavings.toStringAsFixed(0)} ج', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutedStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, fontFamily: 'Cairo'),
        ),
      ],
    );
  }

  // بطاقة الحسابات المالية للصفقة الجارية
  Widget _buildFinancialLedgerCard(ThemeData theme, GroupDealModel deal, GroupDealFinancialSummary fin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: deal.primaryImage.isNotEmpty
                      ? AppImageCache.image(
                          url: deal.primaryImage,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
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
                    Text(
                      deal.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
                    ),
                    Text(
                      'سعر الجملة: ${deal.dealPrice.toStringAsFixed(0)} ج (بدل ${deal.marketPrice.toStringAsFixed(0)} ج) • الوفر: ${deal.savingPerUnit.toStringAsFixed(0)} ج/${deal.unitName}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFinStatColumn('العربون المجمع', '${fin.totalDepositsCollected.toStringAsFixed(0)} ج', const Color(0xFF2563EB)),
              _buildFinStatColumn('إجمالي المبيعات', '${fin.totalConfirmedSales.toStringAsFixed(0)} ج', const Color(0xFF7C3AED)),
              _buildFinStatColumn('وفر الأهالي المحقق', '${fin.totalVillageSavings.toStringAsFixed(0)} ج', const Color(0xFF16A34A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo')),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color, fontFamily: 'Cairo'),
        ),
      ],
    );
  }

  Widget _buildParticipantTile(ThemeData theme, GroupDealModel deal, DealParticipantModel p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: p.isConfirmedByAdmin ? const Color(0xFF16A34A) : Colors.amber.shade700,
          child: Icon(
            p.isDelivered
                ? Icons.done_all_rounded
                : (p.isConfirmedByAdmin ? Icons.check_circle_outline : Icons.hourglass_top_rounded),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          p.userName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deal.depositAmount > 0
                  ? 'حجز ${p.quantity} ${deal.unitName} • العربون: ${p.depositRequired(deal.depositAmount).toStringAsFixed(0)} ج'
                  : 'حجز ${p.quantity} ${deal.unitName} • الإجمالي: ${(p.quantity * deal.dealPrice).toStringAsFixed(0)} ج',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
            ),
            if (p.userPhone.isNotEmpty)
              InkWell(
                onTap: () => launchPhoneCall(p.userPhone),
                child: Text(
                  '📞 ${p.userPhone}',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF2563EB)),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'طباعة ومشاركة الفاتورة',
              icon: const Icon(Icons.print_rounded, size: 20, color: Color(0xFF16A34A)),
              onPressed: () => CommercialReceiptDialog.showDealReceipt(context, deal: deal, participant: p),
            ),
            if (p.isDelivered)
              const Chip(
                label: Text('تم التسليم 📦', style: TextStyle(fontFamily: 'Cairo', fontSize: 10)),
                backgroundColor: Color(0xFFDCFCE7),
              )
            else if (!p.isConfirmedByAdmin)
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  await _dealService.confirmDeposit(
                    dealId: deal.id,
                    participantId: p.id,
                    quantity: p.quantity,
                    adminUid: FirebaseAuth.instance.currentUser?.uid ?? 'admin',
                  );
                },
                child: Text(deal.depositAmount > 0 ? 'تأكيد العربون' : 'تأكيد الحجز', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
              )
            else
              Chip(
                label: Text(deal.depositAmount > 0 ? 'عربون مؤكد' : 'حجز مؤكد', style: const TextStyle(fontFamily: 'Cairo', fontSize: 10)),
                backgroundColor: const Color(0xFFE0E7FF),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // ========================== 2. خدمة إشتريلي ==============================
  // =========================================================================

  Widget _buildEshteriliTab(ThemeData theme) {
    return Column(
      children: [
        // شريط تصفية حالات إشتريلي
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in ['الكل', 'بانتظار التسعير', 'جاري التنفيذ', 'مكتمل', 'ملغي'])
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      selected: _eshteriliFilter == filter,
                      label: Text(filter, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                      onSelected: (_) => setState(() => _eshteriliFilter = filter),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<EshteriliOrder>>(
            stream: _eshteriliService.watchAllOrders(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var orders = snap.data ?? [];
              if (_eshteriliFilter == 'بانتظار التسعير') {
                orders = orders.where((o) => o.status == EshteriliStatus.pendingPricing).toList();
              } else if (_eshteriliFilter == 'جاري التنفيذ') {
                orders = orders.where((o) => o.status == EshteriliStatus.inProgress || o.status == EshteriliStatus.pricedWaitingApproval).toList();
              } else if (_eshteriliFilter == 'مكتمل') {
                orders = orders.where((o) => o.status == EshteriliStatus.completed).toList();
              } else if (_eshteriliFilter == 'ملغي') {
                orders = orders.where((o) => o.status == EshteriliStatus.cancelled).toList();
              }

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.two_wheeler_outlined, size: 54, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('لا توجد طلبات توصيل مسجلة في هذا القسم.', style: TextStyle(fontFamily: 'Cairo')),
                      const SizedBox(height: 6),
                      Text(
                        'عندما يطلب الأهالي مشتريات خاصة، ستظهر هنا للتسعير وتعيين مندوب.',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: orders.length,
                itemBuilder: (context, i) => _buildEshteriliOrderCard(theme, orders[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEshteriliOrderCard(ThemeData theme, EshteriliOrder order) {
    Color statusColor;
    String statusLabel;
    switch (order.status) {
      case EshteriliStatus.pendingPricing:
        statusColor = const Color(0xFFD97706);
        statusLabel = 'بانتظار التسعير ⏳';
        break;
      case EshteriliStatus.pricedWaitingApproval:
        statusColor = const Color(0xFF2563EB);
        statusLabel = 'تم التسعير (بانتظار العميل) 📨';
        break;
      case EshteriliStatus.inProgress:
        statusColor = const Color(0xFF7C3AED);
        statusLabel = 'جاري الشراء والتوصيل 🛵';
        break;
      case EshteriliStatus.completed:
        statusColor = const Color(0xFF16A34A);
        statusLabel = 'تم التسليم بنجاح ✅';
        break;
      case EshteriliStatus.cancelled:
        statusColor = Colors.grey;
        statusLabel = 'طلب ملغي ❌';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ترويسة الطلب
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // معلومات العميل
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  order.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12),
                ),
                const Spacer(),
                if (order.userPhone.isNotEmpty)
                  InkWell(
                    onTap: () => launchPhoneCall(order.userPhone),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.call, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            order.userPhone,
                            style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // العنوان والمتجر
            if (order.deliveryAddress.isNotEmpty)
              Text(
                '📍 عنوان التوصيل: ${order.deliveryAddress}',
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
              ),
            if (order.storeOrArea.isNotEmpty)
              Text(
                '🏪 مكان الشراء المطلوب: ${order.storeOrArea}',
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
              ),
            const SizedBox(height: 8),

            // وصف المشتريات
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                order.itemsDescription,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),

            // التفاصيل المالية إن وجدت
            if (order.totalAmount > 0)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOrderFinSnippet('تكلفة السلع', '${order.itemCost.toStringAsFixed(0)} ج'),
                    _buildOrderFinSnippet('رسوم الخدمة', '${order.serviceFee.toStringAsFixed(0)} ج'),
                    _buildOrderFinSnippet('التوصيل', '${order.deliveryFee.toStringAsFixed(0)} ج'),
                    _buildOrderFinSnippet('الإجمالي', '${order.totalAmount.toStringAsFixed(0)} ج', isBold: true),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // أزرار الإجراءات حسب الحالة
            Row(
              children: [
                if (order.status == EshteriliStatus.pendingPricing)
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _openPriceEshteriliDialog(order),
                      icon: const Icon(Icons.price_change_outlined, size: 18),
                      label: const Text('تسعير وتعيين المندوب 💰', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    ),
                  ),
                if (order.status == EshteriliStatus.inProgress) ...[
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _openVerifyEshteriliDeliveryDialog(order),
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      label: const Text('تأكيد التسليم برمز العميل 🔑', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    ),
                  ),
                ],
                if (order.status != EshteriliStatus.completed && order.status != EshteriliStatus.cancelled) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'إلغاء الطلب',
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                    onPressed: () async {
                      await _eshteriliService.cancelOrder(order.id);
                    },
                  ),
                ],
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'طباعة ومشاركة الفاتورة',
                  icon: const Icon(Icons.print_rounded, size: 20, color: Color(0xFF2563EB)),
                  onPressed: () => CommercialReceiptDialog.showEshteriliReceipt(context, order: order),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderFinSnippet(String label, String value, {bool isBold = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 13 : 11.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? const Color(0xFF16A34A) : Colors.black87,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  // نافذة تسعير طلب إشتريلي
  Future<void> _openPriceEshteriliDialog(EshteriliOrder order) async {
    final costCtrl = TextEditingController(text: order.estimatedBudget > 0 ? order.estimatedBudget.toStringAsFixed(0) : '100');
    final serviceCtrl = TextEditingController(text: '20');
    final deliveryCtrl = TextEditingController(text: '15');
    final agentNameCtrl = TextEditingController(text: 'مندوب تطبيق أبودشيشة');
    final agentPhoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final c = double.tryParse(costCtrl.text.trim()) ?? 0;
          final s = double.tryParse(serviceCtrl.text.trim()) ?? 0;
          final d = double.tryParse(deliveryCtrl.text.trim()) ?? 0;
          final total = c + s + d;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(
              'تسعير طلب الشراء (${order.orderNumber})',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'تكلفة السلع الفعلية (ج)'),
                      onChanged: (_) => setDlgState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: serviceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'رسوم/عمولة الخدمة (ج)'),
                      onChanged: (_) => setDlgState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: deliveryCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'رسوم التوصيل للمنزل (ج)'),
                      onChanged: (_) => setDlgState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي الذي سيدفعه العميل:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(
                            '${total.toStringAsFixed(0)} ج',
                            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: agentNameCtrl,
                      decoration: const InputDecoration(labelText: 'اسم المندوب المسؤول'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: agentPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'رقم هاتف المندوب'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: 'ملاحظات للعميل أو الفاتورة'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                onPressed: () async {
                  await _eshteriliService.priceOrder(
                    orderId: order.id,
                    itemCost: c,
                    serviceFee: s,
                    deliveryFee: d,
                    assignedAgentName: agentNameCtrl.text.trim(),
                    assignedAgentPhone: agentPhoneCtrl.text.trim(),
                    notes: notesCtrl.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('اعتماد وإرسال التسعير للعميل 🚀', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          );
        },
      ),
    );
  }

  // نافذة تأكيد تسليم طلب إشتريلي برمز العميل
  Future<void> _openVerifyEshteriliDeliveryDialog(EshteriliOrder order) async {
    final codeCtrl = TextEditingController();
    String? errorText;

    await showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('تأكيد التسليم برمز العميل 🔑', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اطلب من العميل إظهار رمز الاستلام السري المكون من 4 أرقام من شاشته:',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: InputDecoration(
                  errorText: errorText,
                  counterText: '',
                  hintText: '••••',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
              onPressed: () async {
                final ok = await _eshteriliService.verifyAndDeliverOrder(
                  orderId: order.id,
                  inputCode: codeCtrl.text.trim(),
                  agentUid: FirebaseAuth.instance.currentUser?.uid ?? 'agent',
                );
                if (ok && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تأكيد تسليم الطلب بنجاح! ✅')),
                  );
                } else {
                  setDlgState(() => errorText = 'رمز الاستلام غير صحيح! تأكد من جهاز العميل.');
                }
              },
              child: const Text('تأكيد التسليم', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // ========================== 3. خدمة إتسوقلي ==============================
  // =========================================================================

  Widget _buildEtsawaqliTab(ThemeData theme) {
    return Column(
      children: [
        // شريط التبديل الداخلي لخدمة إتسوقلي
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            children: [
              _buildSubTabChip(
                label: 'فواتير الأسواق 🧾',
                isSelected: _etsawaqliSubIndex == 0,
                onTap: () => setState(() => _etsawaqliSubIndex = 0),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _buildSubTabChip(
                label: 'السلع والأسعار 🥕',
                isSelected: _etsawaqliSubIndex == 1,
                onTap: () => setState(() => _etsawaqliSubIndex = 1),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _buildSubTabChip(
                label: 'الأسواق والمواعيد 🏪',
                isSelected: _etsawaqliSubIndex == 2,
                onTap: () => setState(() => _etsawaqliSubIndex = 2),
                theme: theme,
              ),
            ],
          ),
        ),
        Expanded(
          child: _etsawaqliSubIndex == 0
              ? _buildEtsawaqliOrdersView(theme)
              : _etsawaqliSubIndex == 1
                  ? _buildEtsawaqliProductsView(theme)
                  : _buildEtsawaqliMarketsView(theme),
        ),
      ],
    );
  }

  // عرض فواتير وطلبات التسوق الأسبوعية
  Widget _buildEtsawaqliOrdersView(ThemeData theme) {
    return Column(
      children: [
        // تصفية حالات الفواتير
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in ['الكل', 'قيد الانتظار', 'جاري التجهيز', 'جاري التوصيل', 'مكتمل'])
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      selected: _etsawaqliStatusFilter == filter,
                      label: Text(filter, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                      onSelected: (_) => setState(() => _etsawaqliStatusFilter = filter),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<EtsawaqliOrder>>(
            stream: _etsawaqliService.watchAllOrders(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var orders = snap.data ?? [];
              if (_etsawaqliStatusFilter == 'قيد الانتظار') {
                orders = orders.where((o) => o.status == 'pending').toList();
              } else if (_etsawaqliStatusFilter == 'جاري التجهيز') {
                orders = orders.where((o) => o.status == 'in_preparation').toList();
              } else if (_etsawaqliStatusFilter == 'جاري التوصيل') {
                orders = orders.where((o) => o.status == 'delivering').toList();
              } else if (_etsawaqliStatusFilter == 'مكتمل') {
                orders = orders.where((o) => o.status == 'completed').toList();
              }

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_outlined, size: 54, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('لا توجد فواتير تسوق في هذا القسم.', style: TextStyle(fontFamily: 'Cairo')),
                      const SizedBox(height: 6),
                      Text(
                        'عند اشتراك الأهالي في التسوق من سوق الجمعة أو الأسواق الأخرى، تظهر فواتيرهم هنا.',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: orders.length,
                itemBuilder: (context, i) => _buildEtsawaqliOrderCard(theme, orders[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEtsawaqliOrderCard(ThemeData theme, EtsawaqliOrder order) {
    Color statusColor;
    String statusText;
    switch (order.status) {
      case 'pending':
        statusColor = const Color(0xFFD97706);
        statusText = 'قيد المراجعة والتجهيز ⏳';
        break;
      case 'in_preparation':
        statusColor = const Color(0xFF2563EB);
        statusText = 'جاري الشراء من السوق 🧺';
        break;
      case 'delivering':
        statusColor = const Color(0xFF7C3AED);
        statusText = 'في طريق التوصيل 🛵';
        break;
      case 'completed':
        statusColor = const Color(0xFF16A34A);
        statusText = 'تم التسليم بنجاح ✅';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'ملغي ❌';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(Icons.receipt_long_rounded, color: statusColor, size: 20),
        ),
        title: Row(
          children: [
            Text(
              order.invoiceNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${order.marketName} • العميل: ${order.userName}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11.5),
            ),
            Text(
              'إجمالي الفاتورة: ${order.totalAmount.toStringAsFixed(0)} ج (${order.items.length} أصناف)',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.userPhone.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('هاتف العميل: ${order.userPhone}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.call, size: 18, color: Color(0xFF2563EB)),
                        onPressed: () => launchPhoneCall(order.userPhone),
                      ),
                    ],
                  ),
                if (order.deliveryAddress.isNotEmpty)
                  Text(
                    '📍 عنوان التوصيل: ${order.deliveryAddress}',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                  ),
                const Divider(height: 16),
                const Text(
                  'تفاصيل أصناف المشتريات:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12),
                ),
                const SizedBox(height: 6),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('• ${item.productName} (${item.quantity} ${item.unit})', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                        Text('${item.totalPrice.toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('مجموع السلع:', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                    Text('${order.itemsSubtotal.toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('رسوم التسوق:', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                    Text('${order.serviceFee.toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('رسوم التوصيل:', style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                    Text('${order.deliveryFee.toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (order.status != 'completed') ...[
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _openVerifyEtsawaqliDeliveryDialog(order),
                          icon: const Icon(Icons.verified_outlined, size: 18),
                          label: const Text('تأكيد التسليم برمز العميل 🔑', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    PopupMenuButton<String>(
                      tooltip: 'تغيير حالة الفاتورة',
                      onSelected: (val) async {
                        await _etsawaqliService.updateOrderStatus(order.id, val);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'pending', child: Text('قيد الانتظار ⏳', style: TextStyle(fontFamily: 'Cairo', fontSize: 11))),
                        PopupMenuItem(value: 'in_preparation', child: Text('جاري الشراء 🧺', style: TextStyle(fontFamily: 'Cairo', fontSize: 11))),
                        PopupMenuItem(value: 'delivering', child: Text('في طريق التوصيل 🛵', style: TextStyle(fontFamily: 'Cairo', fontSize: 11))),
                        PopupMenuItem(value: 'completed', child: Text('مكتمل ✅', style: TextStyle(fontFamily: 'Cairo', fontSize: 11))),
                        PopupMenuItem(value: 'cancelled', child: Text('ملغي ❌', style: TextStyle(fontFamily: 'Cairo', fontSize: 11))),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.more_horiz),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'طباعة ومشاركة فاتورة الكاشير',
                      icon: const Icon(Icons.print_rounded, size: 20, color: Color(0xFF16A34A)),
                      onPressed: () => CommercialReceiptDialog.showEtsawaqliReceipt(context, order: order),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // نافذة تأكيد تسليم فاتورة إتسوقلي
  Future<void> _openVerifyEtsawaqliDeliveryDialog(EtsawaqliOrder order) async {
    final codeCtrl = TextEditingController();
    String? errorText;

    await showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('تأكيد تسليم المشتريات 🔑', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اطلب من العميل إظهار رمز الاستلام السري المكون من 4 أرقام من فاتورته:',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: InputDecoration(
                  errorText: errorText,
                  counterText: '',
                  hintText: '••••',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
              onPressed: () async {
                final ok = await _etsawaqliService.verifyAndDeliverOrder(
                  orderId: order.id,
                  inputCode: codeCtrl.text.trim(),
                  shopperUid: FirebaseAuth.instance.currentUser?.uid ?? 'shopper',
                );
                if (ok && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تأكيد تسليم فاتورة المشتريات بنجاح! ✅')),
                  );
                } else {
                  setDlgState(() => errorText = 'رمز الاستلام غير صحيح!');
                }
              },
              child: const Text('تأكيد التسليم', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  // عرض كتالوج السلع وتحديث الأسعار
  Widget _buildEtsawaqliProductsView(ThemeData theme) {
    return Column(
      children: [
        // تصفية التصنيفات مع زر إضافة صنف
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final cat in ['الكل', 'خضروات', 'فواكه', 'دواجن', 'لحوم', 'أسماك', 'ألبان وجبن'])
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            selected: _etsawaqliCategoryFilter == cat,
                            label: Text(cat, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                            onSelected: (_) => setState(() => _etsawaqliCategoryFilter = cat),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'إضافة صنف جديد للسوق',
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _openUpsertProductDialog(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<EtsawaqliProductItem>>(
            stream: _etsawaqliService.watchProducts(category: _etsawaqliCategoryFilter),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = snap.data ?? [];
              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.egg_outlined, size: 54, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('لا توجد سلع مسجلة في هذا التصنيف.', style: TextStyle(fontFamily: 'Cairo')),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _openUpsertProductDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة صنف جديد', style: TextStyle(fontFamily: 'Cairo')),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = products[i];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          p.category.isNotEmpty ? p.category[0] : '🛒',
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
                      ),
                      subtitle: Text(
                        'تصنيف: ${p.category} • وحدة البيع: ${p.unit}',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontFamily: 'Cairo'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${p.estimatedPrice.toStringAsFixed(0)} ج',
                              style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'تحديث السعر',
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _openUpsertProductDialog(context, existing: p),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // نافذة إضافة أو تعديل سلعة في إتسوقلي
  Future<void> _openUpsertProductDialog(BuildContext context, {EtsawaqliProductItem? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(text: existing?.estimatedPrice.toStringAsFixed(0) ?? '20');
    String selectedCat = existing?.category ?? 'خضروات';
    String selectedUnit = existing?.unit ?? 'كيلو';

    await showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            existing == null ? 'إضافة صنف جديد للسوق' : 'تحديث سعر الصنف',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم السلعة (مثال: طماطم بلدي طازة)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedCat,
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                  items: const [
                    DropdownMenuItem(value: 'خضروات', child: Text('خضروات', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'فواكه', child: Text('فواكه', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'دواجن', child: Text('دواجن', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'لحوم', child: Text('لحوم', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'أسماك', child: Text('أسماك', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'ألبان وجبن', child: Text('ألبان وجبن', style: TextStyle(fontFamily: 'Cairo'))),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedCat = val);
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedUnit,
                  decoration: const InputDecoration(labelText: 'وحدة القياس'),
                  items: const [
                    DropdownMenuItem(value: 'كيلو', child: Text('كيلو', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'نصف كيلو', child: Text('نصف كيلو', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'رابطة', child: Text('رابطة', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'كرتونة', child: Text('كرتونة', style: TextStyle(fontFamily: 'Cairo'))),
                    DropdownMenuItem(value: 'حبة', child: Text('حبة', style: TextStyle(fontFamily: 'Cairo'))),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedUnit = val);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'السعر التقديري المحدد (ج)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0;

                final item = EtsawaqliProductItem(
                  id: existing?.id ?? '',
                  name: name,
                  category: selectedCat,
                  unit: selectedUnit,
                  estimatedPrice: price,
                );

                await _etsawaqliService.upsertProduct(item);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ السلعة', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  // عرض الأسواق والمواعيد
  Widget _buildEtsawaqliMarketsView(ThemeData theme) {
    return StreamBuilder<List<EtsawaqliMarket>>(
      stream: _etsawaqliService.watchActiveMarkets(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final markets = snap.data ?? [];
        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: markets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final m = markets[i];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded, color: Color(0xFF16A34A), size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14),
                          ),
                        ),
                        IconButton(
                          tooltip: 'تعديل بيانات السوق والرسوم',
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _openEditMarketDialog(context, m),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Text('• موعد إغلاق الطلبات: ${m.cutoffTimeText}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11.5)),
                    Text('• موعد التوصيل للمنازل: ${m.deliveryTimeText}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11.5)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('رسوم الخدمة: ${m.serviceFee.toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 14),
                        Text('رسوم التوصيل: ${m.deliveryFee.toStringAsFixed(0)} ج', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold)),
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

  // نافذة تعديل السوق والرسوم
  Future<void> _openEditMarketDialog(BuildContext context, EtsawaqliMarket market) async {
    final nameCtrl = TextEditingController(text: market.name);
    final cutoffCtrl = TextEditingController(text: market.cutoffTimeText);
    final deliveryTimeCtrl = TextEditingController(text: market.deliveryTimeText);
    final serviceFeeCtrl = TextEditingController(text: market.serviceFee.toStringAsFixed(0));
    final deliveryFeeCtrl = TextEditingController(text: market.deliveryFee.toStringAsFixed(0));

    await showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('تعديل (${market.name})', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم السوق')),
              const SizedBox(height: 8),
              TextField(controller: cutoffCtrl, decoration: const InputDecoration(labelText: 'موعد إغلاق حجز الطلبات')),
              const SizedBox(height: 8),
              TextField(controller: deliveryTimeCtrl, decoration: const InputDecoration(labelText: 'موعد التوصيل للمنازل')),
              const SizedBox(height: 8),
              TextField(controller: serviceFeeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رسوم خدمة التسوق (ج)')),
              const SizedBox(height: 8),
              TextField(controller: deliveryFeeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رسوم التوصيل للمنزل (ج)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            onPressed: () async {
              final updated = market.copyWith(
                name: nameCtrl.text.trim(),
                cutoffTimeText: cutoffCtrl.text.trim(),
                deliveryTimeText: deliveryTimeCtrl.text.trim(),
                serviceFee: double.tryParse(serviceFeeCtrl.text.trim()) ?? market.serviceFee,
                deliveryFee: double.tryParse(deliveryFeeCtrl.text.trim()) ?? market.deliveryFee,
              );
              await _etsawaqliService.upsertMarket(updated);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ التعديلات', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  // =================== نافذة إضافة / تعديل الصفقة ===================
  Future<void> _openDealFormDialog(
    BuildContext context, {
    GroupDealModel? existing,
    bool isRelaunch = false,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final marketPriceCtrl = TextEditingController(text: existing?.marketPrice.toStringAsFixed(0) ?? '250');
    final dealPriceCtrl = TextEditingController(text: existing?.dealPrice.toStringAsFixed(0) ?? '180');
    final targetCtrl = TextEditingController(text: existing?.targetCount.toString() ?? '20');

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
              isRelaunch
                  ? 'إعادة طرح الصفقة الآن 🚀'
                  : (existing == null ? 'إضافة صفقة جملة جديدة' : 'تعديل الصفقة'),
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم الصفقة (مثال: كرتونة زيت وزبدة بسعر الجملة)',
                        labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'تصنيف السلعة', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                      items: [
                        for (final cat in GroupDealModel.supportedCategories)
                          DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCategory = val);
                      },
                    ),
                    if (selectedCategory == 'أخرى') ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: customCategoryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اكتب التصنيف المخصص',
                          labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: const InputDecoration(labelText: 'وحدة القياس والحصة', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                      items: [
                        for (final u in GroupDealModel.supportedUnits)
                          DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedUnit = val);
                      },
                    ),
                    if (selectedUnit == 'أخرى') ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: customUnitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'اكتب وحدة القياس المخصصة (مثال: شيكارة 50ك)',
                          labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'تفاصيل ومواصفات السلعة', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    ),
                    const SizedBox(height: 12),
                    const Text('صور الصفقة:', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 72,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          InkWell(
                            onTap: () async {
                              final url = await pickAndUploadImage(context);
                              if (url != null && url.isNotEmpty) {
                                setDialogState(() => imageUrls.add(url));
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 22),
                                  SizedBox(height: 2),
                                  Text('إضافة صورة', style: TextStyle(fontFamily: 'Cairo', fontSize: 9)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          for (int idx = 0; idx < imageUrls.length; idx++)
                            Stack(
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: idx == 0 ? const Color(0xFFD97706) : Colors.grey.shade300, width: idx == 0 ? 2 : 1),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: AppImageCache.image(
                                      url: imageUrls[idx],
                                      fit: BoxFit.cover,
                                      width: 68,
                                      height: 68,
                                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 20),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 8,
                                  child: InkWell(
                                    onTap: () => setDialogState(() => imageUrls.removeAt(idx)),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: marketPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'سعر السوق (ج)', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: dealPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'سعر الجملة (ج)', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'العدد المستهدف (حصة / كرتونة)', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: daysLeft,
                      decoration: const InputDecoration(labelText: 'مدة العرض بالأيام', labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
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
                  final target = int.tryParse(targetCtrl.text.trim()) ?? 1;

                  final finalCategory = selectedCategory == 'أخرى' && customCategoryCtrl.text.trim().isNotEmpty
                      ? customCategoryCtrl.text.trim()
                      : selectedCategory;

                  final finalUnit = selectedUnit == 'أخرى' && customUnitCtrl.text.trim().isNotEmpty
                      ? customUnitCtrl.text.trim()
                      : selectedUnit;

                  if (existing == null || isRelaunch) {
                    final newDeal = GroupDealModel(
                      id: '',
                      title: title,
                      category: finalCategory,
                      description: descCtrl.text.trim(),
                      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
                      imageUrls: imageUrls,
                      marketPrice: mPrice,
                      dealPrice: dPrice,
                      depositAmount: 0.0,
                      targetCount: target,
                      unitName: finalUnit,
                      endTime: DateTime.now().add(Duration(days: daysLeft)),
                    );
                    await _dealService.createDeal(newDeal);
                  } else {
                    final updated = existing.copyWith(
                      title: title,
                      category: finalCategory,
                      description: descCtrl.text.trim(),
                      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
                      imageUrls: imageUrls,
                      marketPrice: mPrice,
                      dealPrice: dPrice,
                      depositAmount: 0.0,
                      targetCount: target,
                      unitName: finalUnit,
                    );
                    await _dealService.updateDeal(updated);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(
                  isRelaunch ? 'إطلاق الصفقة الجديدة 🚀' : 'حفظ الصفقة',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteDeal(GroupDealModel deal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الصفقة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من رغبتك في حذف صفقة "${deal.title}"؟ سيتم حذف جميع الحجوزات المرتبطة بها.', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، احذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dealService.deleteDeal(deal.id);
      if (mounted) {
        setState(() => _selectedDealId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الصفقة بنجاح')),
        );
      }
    }
  }

  // =========================================================================
  // ==================== تقرير الإيرادات والحصيلة المالية ====================
  // =========================================================================

  void _showRevenueReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _computeFinancialStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final stats = snapshot.data ?? {};
                final totalRevenue = (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0;
                final totalGoods = (stats['totalGoods'] as num?)?.toDouble() ?? 0.0;
                final totalSavings = (stats['totalSavings'] as num?)?.toDouble() ?? 0.0;
                final totalOrders = (stats['totalOrders'] as num?)?.toInt() ?? 0;

                final dealSales = (stats['dealSales'] as num?)?.toDouble() ?? 0.0;
                final dealOrdersCount = (stats['dealOrdersCount'] as num?)?.toInt() ?? 0;
                final eshteriliItemsCost = (stats['eshteriliItemsCost'] as num?)?.toDouble() ?? 0.0;
                final eshteriliFees = (stats['eshteriliFees'] as num?)?.toDouble() ?? 0.0;
                final eshteriliCount = (stats['eshteriliCount'] as num?)?.toInt() ?? 0;
                final etsawaqliGoods = (stats['etsawaqliGoods'] as num?)?.toDouble() ?? 0.0;
                final etsawaqliFees = (stats['etsawaqliFees'] as num?)?.toDouble() ?? 0.0;
                final etsawaqliCount = (stats['etsawaqliCount'] as num?)?.toInt() ?? 0;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.analytics_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'تقرير الإيرادات والحصيلة المالية الشامل 📊',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF16A34A).withValues(alpha: 0.15),
                                    const Color(0xFF15803D).withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'صافي رسوم الخدمة والتوصيل للمنظومة والمندوبين',
                                    style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo'),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${totalRevenue.toStringAsFixed(0)} ج.م',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF16A34A),
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildFinancialMetricCol('إجمالي المبيعات', '${totalGoods.toStringAsFixed(0)} ج', const Color(0xFF2563EB)),
                                      _buildFinancialMetricCol('وفر أهالي القرية 🎉', '${totalSavings.toStringAsFixed(0)} ج', const Color(0xFFD97706)),
                                      _buildFinancialMetricCol('العمليات المنفذة', '$totalOrders طلب', Colors.black87),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildServiceFinancialCard(
                              title: 'صفقات الجملة بسعر التكلفة 🔥',
                              color: const Color(0xFFD97706),
                              icon: Icons.local_fire_department_rounded,
                              metrics: [
                                'العمليات المكتملة: $dealOrdersCount حصة',
                                'إجمالي قيمة الصفقات: ${dealSales.toStringAsFixed(0)} ج.م',
                                'إجمالي وفورات الأهالي: ${totalSavings.toStringAsFixed(0)} ج.م',
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildServiceFinancialCard(
                              title: 'خدمة إشتريلي (مندوب القرية) 🛵',
                              color: const Color(0xFF2563EB),
                              icon: Icons.delivery_dining_rounded,
                              metrics: [
                                'الطلبات المنفذة: $eshteriliCount طلبات',
                                'مشتريات البضائع: ${eshteriliItemsCost.toStringAsFixed(0)} ج.م',
                                'رسوم الخدمة والتوصيل: ${eshteriliFees.toStringAsFixed(0)} ج.م',
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildServiceFinancialCard(
                              title: 'خدمة إتسوقلي (سوق الجمعة والقرى) 🧺',
                              color: const Color(0xFF16A34A),
                              icon: Icons.shopping_basket_rounded,
                              metrics: [
                                'فواتير الأسواق: $etsawaqliCount فاتورة',
                                'مشتريات الخضار واللحوم: ${etsawaqliGoods.toStringAsFixed(0)} ج.م',
                                'رسوم التسوق والتوصيل: ${etsawaqliFees.toStringAsFixed(0)} ج.م',
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text('مشاركة وطباعة التقرير 🖨️', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () {
                                final text = StringBuffer()
                                  ..writeln('📊 ═════════════════════════════════')
                                  ..writeln('   تقرير الإيرادات والحصيلة المالية للمنظومة التجارية')
                                  ..writeln('        قرية أبودشيشة — منصة الخدمات')
                                  ..writeln('═════════════════════════════════')
                                  ..writeln('🗓️ التاريخ: ${DateTime.now().toLocal().toString().split(".")[0]}')
                                  ..writeln('---------------------------------')
                                  ..writeln('▫️ صافي رسوم الخدمة والتوصيل: ${totalRevenue.toStringAsFixed(0)} ج.م')
                                  ..writeln('▫️ إجمالي حجم المبيعات والبضائع: ${totalGoods.toStringAsFixed(0)} ج.م')
                                  ..writeln('▫️ إجمالي ما تم توفيره لأهالي القرية: ${totalSavings.toStringAsFixed(0)} ج.م 🎉')
                                  ..writeln('▫️ إجمالي العمليات والطلبات المنفذة: $totalOrders عملية')
                                  ..writeln('---------------------------------')
                                  ..writeln('1️⃣ صفقات الجملة:')
                                  ..writeln('   • الحصص: $dealOrdersCount حصة')
                                  ..writeln('   • المبيعات: ${dealSales.toStringAsFixed(0)} ج')
                                  ..writeln('   • الوفر: ${totalSavings.toStringAsFixed(0)} ج')
                                  ..writeln('2️⃣ خدمة إشتريلي:')
                                  ..writeln('   • الطلبات: $eshteriliCount طلب')
                                  ..writeln('   • المشتريات: ${eshteriliItemsCost.toStringAsFixed(0)} ج')
                                  ..writeln('   • الرسوم والتوصيل: ${eshteriliFees.toStringAsFixed(0)} ج')
                                  ..writeln('3️⃣ خدمة إتسوقلي:')
                                  ..writeln('   • الفواتير: $etsawaqliCount فاتورة')
                                  ..writeln('   • مشتريات السوق: ${etsawaqliGoods.toStringAsFixed(0)} ج')
                                  ..writeln('   • الرسوم والتوصيل: ${etsawaqliFees.toStringAsFixed(0)} ج')
                                  ..writeln('═════════════════════════════════');
                                ShareService.shareText(
                                  title: 'تقرير الإيرادات والحصيلة المالية',
                                  body: text.toString(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _computeFinancialStats() async {
    final firestore = FirebaseFirestore.instance;

    final dealsSnap = await firestore.collection('group_deals').get();
    final participantsSnap = await firestore.collection('deal_participants').where('isDelivered', isEqualTo: true).get();

    final dealsMap = <String, GroupDealModel>{};
    for (final d in dealsSnap.docs) {
      dealsMap[d.id] = GroupDealModel.fromJson(d.data(), d.id);
    }

    double dealSales = 0.0;
    double dealSavings = 0.0;
    int dealOrdersCount = 0;

    for (final pDoc in participantsSnap.docs) {
      final p = DealParticipantModel.fromJson(pDoc.data(), pDoc.id);
      final deal = dealsMap[p.dealId];
      if (deal != null) {
        dealSales += p.totalAmount(deal.dealPrice);
        dealSavings += p.quantity * deal.savingsPerUnit;
        dealOrdersCount += p.quantity;
      }
    }

    final eshteriliSnap = await firestore.collection('eshterili_orders').where('status', isEqualTo: 'completed').get();
    double eshteriliItemsCost = 0.0;
    double eshteriliFees = 0.0;
    final eshteriliCount = eshteriliSnap.docs.length;

    for (final doc in eshteriliSnap.docs) {
      final order = EshteriliOrder.fromJson(doc.data(), doc.id);
      eshteriliItemsCost += order.itemCost;
      eshteriliFees += (order.serviceFee + order.deliveryFee);
    }

    final etsawaqliSnap = await firestore.collection('etsawaqli_orders').where('status', isEqualTo: 'completed').get();
    double etsawaqliGoods = 0.0;
    double etsawaqliFees = 0.0;
    final etsawaqliCount = etsawaqliSnap.docs.length;

    for (final doc in etsawaqliSnap.docs) {
      final order = EtsawaqliOrder.fromJson(doc.data(), doc.id);
      etsawaqliGoods += order.itemsSubtotal;
      etsawaqliFees += (order.serviceFee + order.deliveryFee);
    }

    final totalRevenue = eshteriliFees + etsawaqliFees;
    final totalGoods = dealSales + eshteriliItemsCost + etsawaqliGoods;
    final totalSavings = dealSavings;
    final totalOrders = dealOrdersCount + eshteriliCount + etsawaqliCount;

    return {
      'totalRevenue': totalRevenue,
      'totalGoods': totalGoods,
      'totalSavings': totalSavings,
      'totalOrders': totalOrders,
      'dealSales': dealSales,
      'dealOrdersCount': dealOrdersCount,
      'eshteriliItemsCost': eshteriliItemsCost,
      'eshteriliFees': eshteriliFees,
      'eshteriliCount': eshteriliCount,
      'etsawaqliGoods': etsawaqliGoods,
      'etsawaqliFees': etsawaqliFees,
      'etsawaqliCount': etsawaqliCount,
    };
  }

  Widget _buildFinancialMetricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, fontFamily: 'Cairo')),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo')),
      ],
    );
  }

  Widget _buildServiceFinancialCard({
    required String title,
    required Color color,
    required IconData icon,
    required List<String> metrics,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color, fontFamily: 'Cairo')),
            ],
          ),
          const SizedBox(height: 8),
          for (final m in metrics)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 13, color: color),
                  const SizedBox(width: 6),
                  Text(m, style: const TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

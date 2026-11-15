import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/app_image_cache.dart';
import '../models/group_deal_model.dart';
import '../services/group_deal_service.dart';
import 'group_deal_detail_dialog.dart';

/// قسم صفقات الشراء الجماعي الفاخر داخل شاشة سوق القرية
class GroupDealMarketSection extends StatefulWidget {
  const GroupDealMarketSection({super.key});

  @override
  State<GroupDealMarketSection> createState() => _GroupDealMarketSectionState();
}

class _GroupDealMarketSectionState extends State<GroupDealMarketSection> {
  final GroupDealService _service = GroupDealService();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatCountdown(DateTime endTime) {
    final diff = endTime.difference(DateTime.now());
    if (diff.isNegative) return 'انتهى';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    if (days > 0) return '$days يوم و $hours س';
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<GroupDealModel>>(
      stream: _service.watchActiveDeals(),
      builder: (context, snapshot) {
        final deals = snapshot.data ?? [];
        if (deals.isEmpty) {
          return const SizedBox
              .shrink(); // يختفي تماماً إذا لم تكن هناك صفقات نشطة
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD97706), Color(0xFFB45309)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'صفقات الجملة للأهالي 🔥',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'وفر واشترك بسعر الجملة',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 165,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: deals.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  return _buildDealCard(context, theme, deals[i]);
                },
              ),
            ),
            const SizedBox(height: 6),
          ],
        );
      },
    );
  }

  Widget _buildDealCard(
      BuildContext context, ThemeData theme, GroupDealModel deal) {
    final countdown = _formatCountdown(deal.endTime);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      width: 295,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => GroupDealDetailSheet(dealId: deal.id),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 58,
                    height: 58,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: deal.imageUrl.isNotEmpty
                        ? AppImageCache.image(
                            url: deal.imageUrl,
                            fit: BoxFit.cover,
                            width: 58,
                            height: 58,
                            errorWidget: (_, __, ___) => const Icon(
                                Icons.inventory_2_outlined,
                                size: 28),
                          )
                        : const Icon(Icons.inventory_2_outlined, size: 28),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${deal.dealPrice.toStringAsFixed(0)} ج',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${deal.marketPrice.toStringAsFixed(0)} ج',
                            style: TextStyle(
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'وفر ${deal.savingsPerUnit.toStringAsFixed(0)} ج',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 12, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text(
                            countdown,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                                fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'اشترك ${deal.currentCount} من ${deal.targetCount}',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontFamily: 'Cairo'),
                ),
                Text(
                  deal.remainingCount > 0
                      ? 'باقي ${deal.remainingCount}'
                      : 'مكتملة 🎉',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: deal.remainingCount > 0
                        ? const Color(0xFFD97706)
                        : const Color(0xFF16A34A),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: deal.progressRatio,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  deal.progressRatio >= 1.0
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD97706),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'احجز حصتك الآن (عربون ${deal.depositAmount.toStringAsFixed(0)} ج) 👈',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

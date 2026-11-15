import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/app_image_cache.dart';
import '../models/group_deal_model.dart';
import '../models/village_alert.dart';
import '../services/alert_service.dart';
import '../services/alert_sound_service.dart';
import '../services/group_deal_service.dart';
import 'group_deal_detail_dialog.dart';

/// كارت داش بورد صفقات الشراء الجماعي بسعر الجملة في الشاشة الرئيسية
/// بضعف مساحة كارت الطقس السابق، مع الحفاظ الكامل على ربط التنبيهات العاجلة للقرية
class GroupDealHomeCard extends StatefulWidget {
  const GroupDealHomeCard({super.key});

  @override
  State<GroupDealHomeCard> createState() => _GroupDealHomeCardState();
}

class _GroupDealHomeCardState extends State<GroupDealHomeCard> {
  final AlertService _alerts = AlertService();
  final GroupDealService _dealService = GroupDealService();

  Timer? _countdownTimer;
  Timer? _breakingExpiryTimer;
  StreamSubscription<VillageAlert?>? _breakingSubscription;
  VillageAlert? _breaking;

  @override
  void initState() {
    super.initState();
    // تحديث عداد الثواني التنازلي كل ثانية
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // استمرار الاستماع للتنبيهات العاجلة من لوحة تحكم القرية
    _breakingSubscription =
        _alerts.watchLiveBreaking().listen(_onBreakingChanged);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _breakingExpiryTimer?.cancel();
    _breakingSubscription?.cancel();
    super.dispose();
  }

  void _onBreakingChanged(VillageAlert? breaking) {
    if (!mounted) return;
    _breakingExpiryTimer?.cancel();
    _breakingExpiryTimer = null;
    _breaking = breaking;

    if (breaking != null && breaking.mode == VillageAlertMode.sound) {
      final stamp = breaking.updatedAt?.millisecondsSinceEpoch ?? 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(AlertSound.ringOnce('alert_ring_breaking_$stamp'));
        }
      });
    }

    final expiresAt = breaking?.expiresAt;
    if (expiresAt != null) {
      final delay = expiresAt.difference(DateTime.now());
      if (delay > Duration.zero) {
        _breakingExpiryTimer = Timer(delay, () {
          if (!mounted) return;
          setState(() => _breaking = null);
        });
      }
    }
    setState(() {});
  }

  String _formatCountdown(DateTime endTime) {
    final now = DateTime.now();
    final diff = endTime.difference(now);
    if (diff.isNegative) return 'انتهى العرض';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (days > 0) {
      return '$days يوم و $hours س و $minutes د';
    }
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. إذا كان هناك تنبيه عاجل من الإدارة، نعرضه بأولوية قصوى
    if (_breaking != null) {
      return _buildBreakingBanner(context, _breaking!);
    }

    // 2. عرض الداش بورد الحي لصفقات الجملة
    return StreamBuilder<GroupDealModel?>(
      stream: _dealService.watchPrimaryFeaturedDeal(),
      builder: (context, snapshot) {
        final deal = snapshot.data;
        if (deal == null) {
          return _buildDefaultPlaceholderCard(context, theme);
        }
        return _buildDealDashboardCard(context, theme, deal);
      },
    );
  }

  Widget _buildDealDashboardCard(
    BuildContext context,
    ThemeData theme,
    GroupDealModel deal,
  ) {
    final countdown = _formatCountdown(deal.endTime);
    final isExpired = deal.isExpired;
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        elevation: 3,
        shadowColor: primaryColor.withValues(alpha: 0.18),
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => GroupDealDetailSheet(dealId: deal.id),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD97706)
                    .withValues(alpha: 0.45), // لمسة ذهبية فخمة
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // الشريط العلوي: شارة صفقات الجملة + العداد التنازلي
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFFB45309)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFD97706).withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'صفقة جملة 🔥',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? Colors.red.withValues(alpha: 0.12)
                            : primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isExpired
                              ? Colors.red.withValues(alpha: 0.3)
                              : primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: isExpired ? Colors.red : primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            countdown,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: isExpired ? Colors.red : primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // الوسط: صورة المنتج + التفاصيل والأسعار
                Row(
                  children: [
                    // صورة المنتج الفخمة
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 74,
                            height: 74,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: deal.imageUrl.isNotEmpty
                                ? AppImageCache.image(
                                    url: deal.imageUrl,
                                    fit: BoxFit.cover,
                                    width: 74,
                                    height: 74,
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 32,
                                      color: Colors.grey,
                                    ),
                                  )
                                : const Icon(Icons.inventory_2_outlined,
                                    size: 32, color: Colors.grey),
                          ),
                        ),
                        if (deal.savingsPerUnit > 0)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A)
                                    .withValues(alpha: 0.95),
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(14)),
                              ),
                              child: Text(
                                'وفر ${deal.savingsPerUnit.toStringAsFixed(0)} ج',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // اسم الصفقة والأسعار والوفر
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deal.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                '${deal.dealPrice.toStringAsFixed(0)} ج',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (deal.marketPrice > deal.dealPrice)
                                Text(
                                  '${deal.marketPrice.toStringAsFixed(0)} ج',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                    decoration: TextDecoration.lineThrough,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'عربون ${deal.depositAmount.toStringAsFixed(0)} ج',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            deal.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // الجزء السفلي: شريط التقدم التفاعلي وعدد الباقين
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'اشترك ${deal.currentCount} من ${deal.targetCount} ${deal.unitName}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          deal.remainingCount > 0
                              ? 'باقي ${deal.remainingCount} لتفعيل سعر الجملة!'
                              : 'اكتملت الصفقة بنجاح 🎉',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: deal.remainingCount > 0
                                ? const Color(0xFFD97706)
                                : const Color(0xFF16A34A),
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: deal.progressRatio,
                        minHeight: 7,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          deal.progressRatio >= 1.0
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultPlaceholderCard(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_bag_outlined,
                  color: theme.colorScheme.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'صفقات أبودشيشة الجماعية (بسعر الجملة)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ترقبوا انطلاق الصفقة القادمة لأهالي القرية بأفضل سعر جملة.',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakingBanner(BuildContext context, VillageAlert alert) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFB71C1C),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'تنبيه عاجل من إدارة القرية ⚠️',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

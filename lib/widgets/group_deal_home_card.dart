import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/app_image_cache.dart';
import '../models/group_deal_model.dart';
import '../models/village_alert.dart';
import '../services/alert_service.dart';
import '../services/alert_sound_service.dart';
import '../services/group_deal_service.dart';
import 'eshterili_order_sheet.dart';
import 'etsawaqli_market_sheet.dart';
import 'group_deal_detail_dialog.dart';

/// كارت خدمات الشراء والتسوق في الشاشة الرئيسية
/// بضعف مساحة كارت حكمة اليوم تماماً (125-130 بكسل) مع 3 تبويبات احترافية:
/// (صفقة اليوم 🔥 - إشتريلي 🛵 - إتسوقلي 🧺)
class GroupDealHomeCard extends StatefulWidget {
  const GroupDealHomeCard({super.key});

  @override
  State<GroupDealHomeCard> createState() => _GroupDealHomeCardState();
}

class _GroupDealHomeCardState extends State<GroupDealHomeCard> {
  final AlertService _alerts = AlertService();
  final GroupDealService _dealService = GroupDealService();

  int _selectedTab = 0; // 0: صفقة اليوم, 1: إشتريلي, 2: إتسوقلي
  int _currentDealIndex = 0;
  Timer? _countdownTimer;
  Timer? _breakingExpiryTimer;
  StreamSubscription<VillageAlert?>? _breakingSubscription;
  VillageAlert? _breaking;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    _breakingSubscription = _alerts.watchLiveBreaking().listen(_onBreakingChanged);
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
    final diff = endTime.difference(DateTime.now());
    if (diff.isNegative) return 'انتهى';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    if (days > 0) return '$days يوم و $hours س';
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. أولوية التنبيهات العاجلة للقرية
    if (_breaking != null) {
      return _buildBreakingBanner(context, _breaking!);
    }

    // 2. الكارت الرئيسي لخدمات القرية (بمساحة ضعف كارت حكمة اليوم ~ 125-130 بكسل)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: Container(
          constraints: const BoxConstraints(minHeight: 120, maxHeight: 132),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _getTabBorderColor(theme),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. شريط التبويبات الثلاثة المدمج والأنيق
              _buildTopTabsRow(theme),
              const SizedBox(height: 6),

              // 2. محتوى التبويب المختار متناسق بدقة لملء المساحة
              Expanded(
                child: _buildSelectedTabContent(context, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTabBorderColor(ThemeData theme) {
    switch (_selectedTab) {
      case 0:
        return const Color(0xFFD97706).withValues(alpha: 0.5); // ذهبي/برتقالي لصفقة اليوم
      case 1:
        return const Color(0xFF2563EB).withValues(alpha: 0.5); // أزرق لإشتريلي
      case 2:
        return const Color(0xFF16A34A).withValues(alpha: 0.5); // زمردي لإتسوقلي
      default:
        return theme.colorScheme.outline.withValues(alpha: 0.2);
    }
  }

  // ───────────────────────── شريط التبويبات الثلاثة ─────────────────────────
  Widget _buildTopTabsRow(ThemeData theme) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          _buildTabPill(
            index: 0,
            icon: Icons.local_fire_department_rounded,
            title: 'صفقة اليوم',
            activeColor: const Color(0xFFD97706),
          ),
          const SizedBox(width: 6),
          _buildTabPill(
            index: 1,
            icon: Icons.delivery_dining_rounded,
            title: 'إشتريلي',
            activeColor: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 6),
          _buildTabPill(
            index: 2,
            icon: Icons.shopping_basket_rounded,
            title: 'إتسوقلي',
            activeColor: const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required int index,
    required IconData icon,
    required String title,
    required Color activeColor,
  }) {
    final isSel = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSel ? activeColor : Colors.transparent,
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSel ? activeColor : Colors.grey),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.w900 : FontWeight.bold,
                    color: isSel ? activeColor : Colors.grey.shade600,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── محتوى التبويبات ─────────────────────────
  Widget _buildSelectedTabContent(BuildContext context, ThemeData theme) {
    switch (_selectedTab) {
      case 0:
        return _buildDealTabContent(context, theme);
      case 1:
        return _buildEshteriliTabContent(context, theme);
      case 2:
        return _buildEtsawaqliTabContent(context, theme);
      default:
        return const SizedBox.shrink();
    }
  }

  // 1. محتوى تبويب «صفقة اليوم»
  Widget _buildDealTabContent(BuildContext context, ThemeData theme) {
    return StreamBuilder<List<GroupDealModel>>(
      stream: _dealService.watchActiveDeals(),
      builder: (context, snap) {
        final deals = snap.data ?? [];
        if (deals.isEmpty) {
          return InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ترقبوا انطلاق صفقة الجملة القادمة قريباً 🔥', style: TextStyle(fontFamily: 'Cairo'))),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('صفقات الشراء الجماعي بسعر الجملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                      Text('لا توجد صفقة نشطة حالياً — تابعنا للعرض القادم', style: TextStyle(fontSize: 10.5, color: Colors.grey, fontFamily: 'Cairo')),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final safeIdx = _currentDealIndex.clamp(0, deals.length - 1);
        final deal = deals[safeIdx];
        final countdown = _formatCountdown(deal.endTime);

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            if (deals.length > 1 && details.primaryVelocity != null) {
              if (details.primaryVelocity! < 0) {
                setState(() => _currentDealIndex = (_currentDealIndex + 1) % deals.length);
              } else if (details.primaryVelocity! > 0) {
                setState(() => _currentDealIndex = (_currentDealIndex - 1 + deals.length) % deals.length);
              }
            }
          },
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => GroupDealDetailSheet(initialDealId: deal.id),
              );
            },
            child: Row(
              children: [
                // صورة الصفقة مع شارة الوفر
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 62,
                    height: 62,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: deal.primaryImage.isNotEmpty
                        ? AppImageCache.image(
                            url: deal.primaryImage,
                            width: 62,
                            height: 62,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(Icons.inventory_2_outlined, size: 28),
                          )
                        : const Icon(Icons.inventory_2_outlined, size: 28),
                  ),
                ),
                const SizedBox(width: 8),

                // التفاصيل
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              deal.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, fontFamily: 'Cairo'),
                            ),
                          ),
                          if (deals.length > 1) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _currentDealIndex = (_currentDealIndex + 1) % deals.length;
                                      });
                                    },
                                    child: const Icon(Icons.chevron_left_rounded, size: 14, color: Color(0xFFD97706)),
                                  ),
                                  Text(
                                    '${safeIdx + 1}/${deals.length}',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontFamily: 'Cairo'),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _currentDealIndex = (_currentDealIndex - 1 + deals.length) % deals.length;
                                      });
                                    },
                                    child: const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFFD97706)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${deal.dealPrice.toStringAsFixed(0)} ج',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (deal.marketPrice > deal.dealPrice)
                            Text(
                              '${deal.marketPrice.toStringAsFixed(0)} ج',
                              style: const TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: Colors.grey, fontFamily: 'Cairo'),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'وفر ${deal.savingsPerUnit.toStringAsFixed(0)} ج',
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'اشترك ${deal.currentCount} من ${deal.targetCount}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 11, color: Color(0xFFD97706)),
                              const SizedBox(width: 2),
                              Text(
                                countdown,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontFamily: 'Cairo'),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '• احجز 👈',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontFamily: 'Cairo'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. محتوى تبويب «إشتريلي»
  Widget _buildEshteriliTabContent(BuildContext context, ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const EshteriliOrderSheet(),
        );
      },
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('إشتريلي — مندوب القرية 🛵', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
                    Spacer(),
                    Text('طلب جديد 👈', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontFamily: 'Cairo')),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'اطلب أي مشتريات من داخل أو برة القرية ومندوبنا يشتريها ويوصلها لباب بيتك.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant, height: 1.3, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. محتوى تبويب «إتسوقلي»
  Widget _buildEtsawaqliTabContent(BuildContext context, ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const EtsawaqliMarketSheet(),
        );
      },
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF15803D)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('إتسوقلي — تسوق سوق الجمعة 🧺', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo')),
                    Spacer(),
                    Text('اشترك وتسوق 👈', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontFamily: 'Cairo')),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'مندوبة تتسوق لكِ خضار وفاكهة ولحوم السوق طازة بفاتورة كاشير معتمدة حتى باب البيت.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant, height: 1.3, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── كارت التنبيه العاجل الأصفر ─────────────────────────
  Widget _buildBreakingBanner(BuildContext context, VillageAlert alert) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColors = isDark
        ? const [Color(0xFF451A03), Color(0xFF78350F)]
        : const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)];

    final borderColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFEAB308);
    final headerTextColor = isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
    final messageTextColor = isDark ? const Color(0xFFFEF9C3) : const Color(0xFF78350F);
    final hintTextColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);

    final now = DateTime.now();
    final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'م' : 'ص'}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        shadowColor: borderColor.withValues(alpha: 0.25),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showAlertDialog(context, alert),
          child: Container(
            constraints: const BoxConstraints(minHeight: 120, maxHeight: 132),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgColors,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: borderColor,
                width: 1.6,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'أبودشيشة • $timeStr',
                      style: TextStyle(color: headerTextColor, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 3),
                          Text('تنبيه عاجل ⚠️', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                    Text(
                      'إدارة القرية 📢',
                      style: TextStyle(color: headerTextColor, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '« ${alert.message} »',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: messageTextColor,
                    height: 1.4,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_outlined, size: 13, color: hintTextColor),
                    const SizedBox(width: 3),
                    Text(
                      'اضغط لعرض كامل التنبيه 👈',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: hintTextColor, fontFamily: 'Cairo'),
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

  void _showAlertDialog(BuildContext context, VillageAlert alert) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text('تنبيه عاجل من إدارة القرية', style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Cairo', fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            alert.message,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Cairo', height: 1.6),
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً، فهمت', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

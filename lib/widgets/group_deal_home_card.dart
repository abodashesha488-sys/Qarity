import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/app_image_cache.dart';
import '../features/market/available_group_deals_screen.dart';
import '../models/group_deal_model.dart';
import '../models/village_alert.dart';
import '../services/alert_service.dart';
import '../services/alert_sound_service.dart';
import '../services/group_deal_service.dart';
import 'eshterili_order_sheet.dart';
import 'etsawaqli_market_sheet.dart';

/// كارت خدمات الشراء والتسوق في الشاشة الرئيسية
/// بتصميم عالمي جذاب وتفاعلي مع خلفيات مخصصة لكل خدمة
/// وتكبير خطوط التبويبات وأزرار الإجراءات السريعة:
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
  int _activeDealsCount = 0;
  Timer? _countdownTimer;
  Timer? _dealsAutoCycleTimer;
  Timer? _breakingExpiryTimer;
  StreamSubscription<VillageAlert?>? _breakingSubscription;
  VillageAlert? _breaking;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // تتابع تلقائي متسلسل بين صفقات اليوم كل 4 ثوانٍ
    _dealsAutoCycleTimer =
        Timer.periodic(const Duration(milliseconds: 4000), (_) {
      if (!mounted || _selectedTab != 0) return;
      if (_activeDealsCount > 1) {
        setState(() {
          _currentDealIndex = (_currentDealIndex + 1) % _activeDealsCount;
        });
      }
    });

    _breakingSubscription =
        _alerts.watchLiveBreaking().listen(_onBreakingChanged);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _dealsAutoCycleTimer?.cancel();
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
    if (days > 0) return '$days ي و $hours س';
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Color _getAccentColor() {
    switch (_selectedTab) {
      case 0:
        return const Color(0xFFD97706); // برتقالي عنبري دافئ لصفقة اليوم
      case 1:
        return const Color(0xFF2563EB); // أزرق ملوكي كهربائي لإشتريلي
      case 2:
        return const Color(0xFF16A34A); // أخضر زمردي نضر لإتسوقلي
      default:
        return const Color(0xFFD97706);
    }
  }

  List<Color> _getCardGradientColors(bool isDark) {
    switch (_selectedTab) {
      case 0:
        // صفقة اليوم: عنبر شروق الشمس / برونز غامق
        return isDark
            ? const [Color(0xFF2B1705), Color(0xFF1A0E03)]
            : const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)];
      case 1:
        // إشتريلي: أزرق سماوي نقي / كحلي كهربائي
        return isDark
            ? const [Color(0xFF091E3B), Color(0xFF040F20)]
            : const [Color(0xFFF0F7FF), Color(0xFFDBEAFE)];
      case 2:
        // إتسوقلي: زمرد الحقول الأخضر / غابات عميقة
        return isDark
            ? const [Color(0xFF052713), Color(0xFF02140A)]
            : const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)];
      default:
        return isDark
            ? const [Color(0xFF1F2937), Color(0xFF111827)]
            : const [Colors.white, Color(0xFFF3F4F6)];
    }
  }

  Color _getCardBorderColor(bool isDark) {
    switch (_selectedTab) {
      case 0:
        return isDark
            ? const Color(0xFFF59E0B)
            : const Color(0xFFF59E0B).withValues(alpha: 0.55);
      case 1:
        return isDark
            ? const Color(0xFF3B82F6)
            : const Color(0xFF3B82F6).withValues(alpha: 0.55);
      case 2:
        return isDark
            ? const Color(0xFF22C55E)
            : const Color(0xFF22C55E).withValues(alpha: 0.55);
      default:
        return Colors.transparent;
    }
  }

  IconData _getWatermarkIcon() {
    switch (_selectedTab) {
      case 0:
        return Icons.local_fire_department_rounded;
      case 1:
        return Icons.delivery_dining_rounded;
      case 2:
        return Icons.shopping_basket_rounded;
      default:
        return Icons.local_fire_department_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 1. أولوية التنبيهات العاجلة للقرية
    if (_breaking != null) {
      return _buildBreakingBanner(context, _breaking!);
    }

    final accentColor = _getAccentColor();

    // 2. الكارت الرئيسي لخدمات القرية بخلفيات مخصصة وتصميم عالمي
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        elevation: isDark ? 1 : 2.5,
        shadowColor: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          constraints: const BoxConstraints(minHeight: 146, maxHeight: 156),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getCardGradientColors(isDark),
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getCardBorderColor(isDark),
              width: 1.6,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // 1. أيقونة الخلفية المائية الدالة على طبيعة الخدمة (Watermark Motif)
              Positioned(
                bottom: -10,
                left: -6,
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Icon(
                      _getWatermarkIcon(),
                      key: ValueKey<int>(_selectedTab),
                      size: 96,
                      color:
                          accentColor.withValues(alpha: isDark ? 0.09 : 0.07),
                    ),
                  ),
                ),
              ),

              // 2. الهيكل الرئيسي: شريط التبويبات الكبير + محتوى التبويب المختار
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // شريط التبويبات الثلاثة المطور بخطوط كبيرة وواضحة
                    _buildTopTabsRow(theme, isDark),
                    const SizedBox(height: 8),

                    // محتوى التبويب مع انتقال حركي سلس
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: KeyedSubtree(
                          key: ValueKey<int>(_selectedTab),
                          child:
                              _buildSelectedTabContent(context, theme, isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── شريط التبويبات المطور والمكبر ─────────────────────────
  Widget _buildTopTabsRow(ThemeData theme, bool isDark) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          _buildTabPill(
            index: 0,
            icon: Icons.local_fire_department_rounded,
            title: 'صفقة اليوم',
            activeColor: const Color(0xFFD97706),
            isDark: isDark,
          ),
          const SizedBox(width: 4),
          _buildTabPill(
            index: 1,
            icon: Icons.delivery_dining_rounded,
            title: 'إشتريلي',
            activeColor: const Color(0xFF2563EB),
            isDark: isDark,
          ),
          const SizedBox(width: 4),
          _buildTabPill(
            index: 2,
            icon: Icons.shopping_basket_rounded,
            title: 'إتسوقلي',
            activeColor: const Color(0xFF16A34A),
            isDark: isDark,
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
    required bool isDark,
  }) {
    final isSel = _selectedTab == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = index),
          borderRadius: BorderRadius.circular(9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSel
                  ? (isDark
                      ? activeColor.withValues(alpha: 0.28)
                      : Colors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isSel ? activeColor : Colors.transparent,
                width: 1.4,
              ),
              boxShadow: isSel && !isDark
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16.5,
                  color: isSel
                      ? activeColor
                      : (isDark ? Colors.white60 : Colors.grey.shade600),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
                      color: isSel
                          ? activeColor
                          : (isDark ? Colors.white70 : Colors.grey.shade700),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── محتوى التبويبات ─────────────────────────
  Widget _buildSelectedTabContent(
      BuildContext context, ThemeData theme, bool isDark) {
    switch (_selectedTab) {
      case 0:
        return _buildDealTabContent(context, theme, isDark);
      case 1:
        return _buildEshteriliTabContent(context, theme, isDark);
      case 2:
        return _buildEtsawaqliTabContent(context, theme, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // 1. محتوى تبويب «صفقة اليوم»
  Widget _buildDealTabContent(
      BuildContext context, ThemeData theme, bool isDark) {
    return StreamBuilder<List<GroupDealModel>>(
      stream: _dealService.watchActiveDeals(),
      builder: (context, snap) {
        final deals = snap.data ?? [];
        _activeDealsCount = deals.length;
        if (deals.isEmpty) {
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AvailableGroupDealsScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.inventory_2_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'صفقات الشراء الجماعي بسعر الجملة والتكلفة 🔥',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              fontFamily: 'Cairo'),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'اضغط هنا لاستعراض تفاصيل المبادرة وسجل الصفقات السابقة 👈',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final safeIdx = _currentDealIndex.clamp(0, deals.length - 1);
        final deal = deals[safeIdx];
        final countdown = _formatCountdown(deal.endTime);
        final progress = deal.targetCount > 0
            ? (deal.currentCount / deal.targetCount).clamp(0.0, 1.0)
            : 0.0;

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            if (deals.length > 1 && details.primaryVelocity != null) {
              if (details.primaryVelocity! < 0) {
                setState(() =>
                    _currentDealIndex = (_currentDealIndex + 1) % deals.length);
              } else if (details.primaryVelocity! > 0) {
                setState(() => _currentDealIndex =
                    (_currentDealIndex - 1 + deals.length) % deals.length);
              }
            }
          },
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AvailableGroupDealsScreen(
                      initialHighlightDealId: deal.id),
                ),
              );
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<String>(deal.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      // صورة الصفقة مع شارة وفر التكلفة
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            border: Border.all(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.4),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: deal.primaryImage.isNotEmpty
                              ? AppImageCache.image(
                                  url: deal.primaryImage,
                                  width: 66,
                                  height: 66,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 30),
                                )
                              : const Icon(Icons.inventory_2_outlined,
                                  size: 30),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // تفاصيل الصفقة
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. عنوان الصفقة + ترقيم التتابع
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    deal.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                                if (deals.length > 1) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD97706)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(deals.length,
                                              (dotIdx) {
                                            final isDotActive =
                                                dotIdx == safeIdx;
                                            return AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 1),
                                              width: isDotActive ? 7 : 3,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: isDotActive
                                                    ? const Color(0xFFD97706)
                                                    : const Color(0xFFD97706)
                                                        .withValues(
                                                            alpha: 0.28),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            );
                                          }),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${safeIdx + 1}/${deals.length}',
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD97706),
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),

                            // 2. الأسعار وشارة الوفر
                            Row(
                              children: [
                                Text(
                                  '${deal.dealPrice.toStringAsFixed(0)} ج',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFD97706),
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (deal.marketPrice > deal.dealPrice)
                                  Text(
                                    '${deal.marketPrice.toStringAsFixed(0)} ج',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'وفر ${deal.savingsPerUnit.toStringAsFixed(0)} ج',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF16A34A),
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // 3. شريط التقدم المرئي والعداد التنازلي
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 4,
                                          backgroundColor: Colors.grey
                                              .withValues(alpha: 0.2),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(Color(0xFFD97706)),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'حجز ${deal.currentCount} من ${deal.targetCount} حصة',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer_outlined,
                                        size: 12, color: Color(0xFFD97706)),
                                    const SizedBox(width: 2),
                                    Text(
                                      countdown,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFD97706),
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '• تفاصيل 👈',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF16A34A),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 2. محتوى تبويب «إشتريلي»
  Widget _buildEshteriliTabContent(
      BuildContext context, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          // أيقونة الخدمة البارزة
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.delivery_dining_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(width: 10),

          // الوصف وأزرار الإجراء السريع
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'إشتريلي — مندوب القرية السريع 🛵',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'مندوب سريع لشراء طلباتك وروشتاتك من داخل أو خارج القرية مع فاتورة المحل والدفع عند الاستلام.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? Colors.white70
                        : Colors.black87.withValues(alpha: 0.75),
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),

                // زرا الإجراء السريع
                Row(
                  children: [
                    // زر طلب شراء جديد
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              const EshteriliOrderSheet(initialView: 1),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_shopping_cart_rounded,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'طلب شراء جديد ➕',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // زر متابعة طلباتي
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              const EshteriliOrderSheet(initialView: 2),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF2563EB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                const Color(0xFF2563EB).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_rounded,
                                size: 12, color: Color(0xFF2563EB)),
                            SizedBox(width: 4),
                            Text(
                              'متابعة طلباتي 📦',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2563EB),
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
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

  // 3. محتوى تبويب «إتسوقلي»
  Widget _buildEtsawaqliTabContent(
      BuildContext context, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          // أيقونة الخدمة البارزة
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.shopping_basket_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(width: 10),

          // الوصف وأزرار الإجراء السريع
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'إتسوقلي — تسوق سوق الجمعة والقرى 🧺',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'شروة خضار وفاكهة ولحوم السوق طازجة بأفضل أسعار السوق وبدون وسيط حتى باب البيت.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? Colors.white70
                        : Colors.black87.withValues(alpha: 0.75),
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),

                // زرا الإجراء السريع
                Row(
                  children: [
                    // زر قائمة المشتريات
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              const EtsawaqliMarketSheet(initialView: 1),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF16A34A)
                                  .withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.checklist_rounded,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'قائمة المشتريات 🧺',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // زر سجل العمليات
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              const EtsawaqliMarketSheet(initialView: 2),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF16A34A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                const Color(0xFF16A34A).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history_rounded,
                                size: 12, color: Color(0xFF16A34A)),
                            SizedBox(width: 4),
                            Text(
                              'سجل العمليات 📜',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF16A34A),
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
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

  // ───────────────────────── كارت التنبيه العاجل الأصفر ─────────────────────────
  Widget _buildBreakingBanner(BuildContext context, VillageAlert alert) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColors = isDark
        ? const [Color(0xFF451A03), Color(0xFF78350F)]
        : const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)];

    final borderColor =
        isDark ? const Color(0xFFF59E0B) : const Color(0xFFEAB308);
    final headerTextColor =
        isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
    final messageTextColor =
        isDark ? const Color(0xFFFEF9C3) : const Color(0xFF78350F);
    final hintTextColor =
        isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);

    final now = DateTime.now();
    final timeStr =
        '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'م' : 'ص'}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        elevation: 2.5,
        shadowColor: borderColor.withValues(alpha: 0.25),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showAlertDialog(context, alert),
          child: Container(
            constraints: const BoxConstraints(minHeight: 146, maxHeight: 156),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgColors,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: 1.6,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'أبودشيشة • $timeStr',
                      style: TextStyle(
                          color: headerTextColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 12, color: Colors.white),
                          SizedBox(width: 3),
                          Text('تنبيه عاجل ⚠️',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                    Text(
                      'إدارة القرية 📢',
                      style: TextStyle(
                          color: headerTextColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '« ${alert.message} »',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: messageTextColor,
                    height: 1.4,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_outlined,
                        size: 14, color: hintTextColor),
                    const SizedBox(width: 3),
                    Text(
                      'اضغط لعرض كامل التنبيه 👈',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: hintTextColor,
                          fontFamily: 'Cairo'),
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
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text('تنبيه عاجل من إدارة القرية',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                    fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            alert.message,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
                height: 1.6),
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً، فهمت',
                style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/utils/app_image_cache.dart';
import '../../models/group_deal_model.dart';
import '../../services/group_deal_service.dart';
import '../../services/share_service.dart';
import '../../widgets/group_deal_detail_dialog.dart';

/// 🛒 شاشة صفقات الشراء الجماعي بسعر الجملة والتكلفة
///
/// تعرض نبذة تعريفية راقية ومحترفة عن فلسفة الخدمة وأهدافها للقرية،
/// وقائمة عمودية بالصفقات المتاحة حالياً ككروت مستقلة كل صفقة في سطر مستقل،
/// وعند النقر على أي صفقة تُفتح تفاصيلها وإمكانية الحجز الكاملة.
class AvailableGroupDealsScreen extends StatefulWidget {
  const AvailableGroupDealsScreen({
    super.key,
    this.initialHighlightDealId,
    this.service,
    this.initialExpandIntro = false,
  });

  /// معرف الصفقة المراد تمييزها أو فتحها عند الدخول
  final String? initialHighlightDealId;

  /// خدمة الصفقات (تسمح بالحقن للاختبارات)
  final GroupDealService? service;

  /// حالة فتح كارت النبذة التعريفية افتراضياً (افتراضياً مطوي لتوفير المساحة)
  final bool initialExpandIntro;

  @override
  State<AvailableGroupDealsScreen> createState() => _AvailableGroupDealsScreenState();
}

class _AvailableGroupDealsScreenState extends State<AvailableGroupDealsScreen> {
  late final GroupDealService _service;
  String _selectedCategory = 'الكل';
  int _activeTab = 0; // 0: الصفقات المتاحة حالياً, 1: الصفقات المنفذة السابقة
  late bool _isIntroExpanded;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GroupDealService();
    _isIntroExpanded = widget.initialExpandIntro;
  }

  void _openDealDetails(BuildContext context, GroupDealModel deal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroupDealDetailSheet(initialDealId: deal.id),
    );
  }

  void _shareAppDeals() {
    ShareService.shareText(
      title: 'صفقات الشراء الجماعي بقرية أبودشيشة 🔥',
      body: '📢 انضم لصفقات الشراء الجماعي بسعر الجملة والتكلفة في قرية أبودشيشة! سلع تموينية وغذائية بأسعار الموردين بدون أي وسيط تجاري، مع حجز مجاني واستلام مباشر من مقر القرية أو للبيت. حمّل التطبيق واستفد من الوفر المالي لكل أسرة.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'صفقات اليوم بسعر الجملة 🔥',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'مبادرة الشراء الجماعي والتكلفة لأهالي قرية أبودشيشة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10.5,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'مشاركة المبادرة مع الجيران',
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareAppDeals,
          ),
        ],
      ),
      body: StreamBuilder<List<GroupDealModel>>(
        stream: _service.watchActiveDeals(),
        builder: (context, activeSnapshot) {
          final activeDeals = activeSnapshot.data ?? [];

          return StreamBuilder<List<GroupDealModel>>(
            stream: _service.watchExecutedDeals(),
            builder: (context, executedSnapshot) {
              final executedDeals = executedSnapshot.data ?? [];

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
                children: [
                  // 1. نبذة مختصرة عن الصفحة والخدمة في إطار وتنسيق محترف وحديث
                  _buildIntroHeroCard(context, theme, activeDeals),

                  const SizedBox(height: 18),

                  // 2. شريط التبديل بين الصفقات النشطة وأرشيف الصفقات المنفذة
                  _buildSubTabsRow(theme, activeDeals.length, executedDeals.length),

                  const SizedBox(height: 14),

                  // 3. عرض الصفقات المتاحة أو المنفذة
                  if (_activeTab == 0) ...[
                    _buildActiveDealsSection(context, theme, activeDeals, activeSnapshot.connectionState),
                  ] else ...[
                    _buildExecutedDealsSection(context, theme, executedDeals, executedSnapshot.connectionState),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ───────────────────────── 1. النبذة التعريفية الراقية القابلة للطي ─────────────────────────
  Widget _buildIntroHeroCard(
    BuildContext context,
    ThemeData theme,
    List<GroupDealModel> activeDeals,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF381502),
                    const Color(0xFF1E1308),
                  ]
                : [
                    const Color(0xFFFFFBEB),
                    const Color(0xFFFEF3C7),
                  ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          border: Border.all(
            color: const Color(0xFFD97706).withValues(alpha: isDark ? 0.4 : 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD97706).withValues(alpha: isDark ? 0.2 : 0.1),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _isIntroExpanded = !_isIntroExpanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الرأس الدائم مع زر التبديل القابل للطي
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFFB45309)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD97706).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مبادرة صفقات القرية بسعر الجملة والتكلفة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            'قوة الشراء الجماعي لخدمة أهالي قرية أبودشيشة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10.5,
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // كبسولة إشارة الفتح والطي
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFD97706).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isIntroExpanded ? 'طي' : 'تفاصيل',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            _isIntroExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: const Color(0xFFD97706),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // المحتوى القابل للطي
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Divider(
                        color: const Color(0xFFD97706).withValues(alpha: 0.25),
                        height: 1,
                      ),
                      const SizedBox(height: 10),

                      // الفقرة التعريفية المنسقة
                      Text(
                        'مبادرة مجتمعية تنظمها القرية للتفاوض والتعاقد المباشر مع كبار الموردين والمصانع على سلع تموينية وغذائية أساسية عالية الجودة، لتصل لكل بيت بالقرية بسعر التكلفة الحقيقي بدون أي وسيط تجاري أو هوامش ربح، مع توفير مالي حقيقي لكل أسرة.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          height: 1.5,
                          color: isDark ? Colors.grey.shade300 : const Color(0xFF451A03),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // شبكة مميزات الخدمة الأربعة
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFeaturePill(
                            icon: Icons.price_check_rounded,
                            title: 'سعر جملة وتكلفة',
                            subtitle: 'وفر يصل إلى 35%',
                            color: const Color(0xFFD97706),
                            isDark: isDark,
                          ),
                          _buildFeaturePill(
                            icon: Icons.how_to_reg_rounded,
                            title: 'حجز مجاني بدون عربون',
                            subtitle: 'الدفع عند الاستلام',
                            color: const Color(0xFF16A34A),
                            isDark: isDark,
                          ),
                          _buildFeaturePill(
                            icon: Icons.local_shipping_rounded,
                            title: 'استلام مقر أو منزلي',
                            subtitle: 'مقر مجاناً / بيت +10ج',
                            color: const Color(0xFF2563EB),
                            isDark: isDark,
                          ),
                          _buildFeaturePill(
                            icon: Icons.verified_user_rounded,
                            title: 'جودة ومعاينة مسبقة',
                            subtitle: 'حق الفحص قبل الدفع',
                            color: const Color(0xFF7C3AED),
                            isDark: isDark,
                          ),
                        ],
                      ),

                      if (activeDeals.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFF16A34A)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'يوجد حالياً ${activeDeals.length} صفقة جارية ومتاحة للحجز الفوري — لا تفوت الفرصة!',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  crossFadeState: _isIntroExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 280),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width - 60) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9.5,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── 2. أزرار التبديل الفرعية ─────────────────────────
  Widget _buildSubTabsRow(ThemeData theme, int activeCount, int executedCount) {
    return Row(
      children: [
        Expanded(
          child: _buildSubTabButton(
            title: 'الصفقات المتاحة حالياً 🔥',
            count: activeCount,
            isSelected: _activeTab == 0,
            color: const Color(0xFFD97706),
            onTap: () => setState(() => _activeTab = 0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSubTabButton(
            title: 'أرشيف المنفذة سابقاً 📜',
            count: executedCount,
            isSelected: _activeTab == 1,
            color: theme.colorScheme.primary,
            onTap: () => setState(() => _activeTab = 1),
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabButton({
    required String title,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ───────────────────────── 3. قائمة الصفقات المتاحة النشطة ─────────────────────────
  Widget _buildActiveDealsSection(
    BuildContext context,
    ThemeData theme,
    List<GroupDealModel> deals,
    ConnectionState state,
  ) {
    if (state == ConnectionState.waiting && deals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (deals.isEmpty) {
      return _buildEmptyDealsState(
        theme: theme,
        title: 'لا توجد صفقات شراء جماعي نشطة حالياً',
        subtitle: 'يقوم فريق المبادرة بالتفاوض على صفقات وسلع جديدة مع كبار الموردين وستطرح قريباً جداً للأهالي 🔥',
      );
    }

    // تصفية التصنيفات إذا رغب المستخدم
    final categories = {'الكل', ...deals.map((d) => d.category)};
    final filteredDeals = _selectedCategory == 'الكل'
        ? deals
        : deals.where((d) => d.category == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // تصفية بالتصنيفات إن وُجد أكثر من تصنيف
        if (categories.length > 2) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: FilterChip(
                    label: Text(cat, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: const Color(0xFFD97706).withValues(alpha: 0.18),
                    checkmarkColor: const Color(0xFFD97706),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الصفقات المتاحة للحجز (${filteredDeals.length})',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            const Row(
              children: [
                Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFFD97706)),
                SizedBox(width: 4),
                Text(
                  'اضغط على الكارت للتفاصيل والحجز',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: Color(0xFFD97706)),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        // كروت الصفقات المستقلة — كل كارت في سطر مستقل
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredDeals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            return _buildSingleDealCard(context, theme, filteredDeals[index]);
          },
        ),
      ],
    );
  }

  // كارت صفقة مستقل كامل السطر بتصميم عصري ومتناسق
  Widget _buildSingleDealCard(
    BuildContext context,
    ThemeData theme,
    GroupDealModel deal,
  ) {
    final isHighlighted = widget.initialHighlightDealId == deal.id;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      elevation: isHighlighted ? 4 : 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => _openDealDetails(context, deal),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHighlighted
                  ? const Color(0xFFD97706)
                  : const Color(0xFFD97706).withValues(alpha: 0.28),
              width: isHighlighted ? 2.0 : 1.2,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. رأس الكارت: التصنيف + عداد الوقت + شارة الوفر
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      deal.category,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // عداد الوقت التنازلي التفاعلي المخصص
                  _DealCountdownWidget(endTime: deal.endTime),
                  const SizedBox(width: 6),
                  // نسبة الخصم
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'خصم ${deal.discountPercentage}%',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 2. جسم الكارت: الصورة + اسم الصفقة + مقارنة الأسعار
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة السلعة
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 82,
                      height: 82,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: deal.primaryImage.isNotEmpty
                          ? KeyedSubtree(
                              key: ValueKey<String>('active_deal_img_${deal.id}'),
                              child: AppImageCache.image(
                                url: deal.primaryImage,
                                width: 82,
                                height: 82,
                                fit: BoxFit.cover,
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 36,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.inventory_2_outlined,
                              size: 36,
                              color: Color(0xFFD97706),
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // تفاصيل الأسعار والاسم
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'الوحدة: ${deal.unitName}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // مقارنة السعر في جملة وسوق
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${deal.dealPrice.toStringAsFixed(0)} ج',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (deal.marketPrice > deal.dealPrice) ...[
                              Text(
                                '${deal.marketPrice.toStringAsFixed(0)} ج بالسوق',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'وفر ${deal.savingsPerUnit.toStringAsFixed(0)} ج',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 3. شريط تقدم اكتمال الحصص والشحنة
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: deal.progressRatio,
                  minHeight: 7,
                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    deal.remainingCount <= 3 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'اشترك ${deal.currentCount} من ${deal.targetCount} ${deal.unitName}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    deal.remainingCount > 0
                        ? 'متبقي ${deal.remainingCount} حصة فقط لاكتمال الشحنة 🔥'
                        : '🎉 اكتملت الحصص وجارٍ التجهيز والتوزيع!',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: deal.remainingCount > 0 ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // 4. السطر السفلي وزر الإجراء
              Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 4),
                  const Text(
                    'حجز مجاني بدون أي عربون',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.5,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _openDealDetails(context, deal),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                    label: const Text(
                      'التفاصيل والحجز 👈',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── 4. قسم الصفقات السابقة والمنفذة ─────────────────────────
  Widget _buildExecutedDealsSection(
    BuildContext context,
    ThemeData theme,
    List<GroupDealModel> executedDeals,
    ConnectionState state,
  ) {
    if (state == ConnectionState.waiting && executedDeals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (executedDeals.isEmpty) {
      return _buildEmptyDealsState(
        theme: theme,
        title: 'لا توجد صفقات منفذة سابقة بالأرشيف حتى الآن',
        subtitle: 'ستظهر هنا كافة الصفقات التي اكتملت واستلمها أهالي القرية بنجاح.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'أرشيف الصفقات السابقة الناجحة (${executedDeals.length})',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            const Text(
              'يمكنك طلب إعادة طرح أي صفقة 🔄',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: executedDeals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final deal = executedDeals[i];
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.25),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: deal.primaryImage.isNotEmpty
                          ? KeyedSubtree(
                              key: ValueKey<String>('exec_deal_img_${deal.id}'),
                              child: AppImageCache.image(
                                url: deal.primaryImage,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'تم توريد ${deal.currentCount} ${deal.unitName} • بسعر ${deal.dealPrice.toStringAsFixed(0)} ج',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'إجمالي وفر الأهالي: ${deal.totalVillageSavings.toStringAsFixed(0)} جنيه',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _openDealDetails(context, deal),
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text(
                      'طلب طرحها',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyDealsState({
    required ThemeData theme,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.5,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// ودجت عداد تنازلي ذاتي التحديث لا يتسبب في إعادة بناء الشاشة أو وميض صور الصفقات
class _DealCountdownWidget extends StatefulWidget {
  const _DealCountdownWidget({required this.endTime});

  final DateTime endTime;

  @override
  State<_DealCountdownWidget> createState() => _DealCountdownWidgetState();
}

class _DealCountdownWidgetState extends State<_DealCountdownWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(DateTime endTime) {
    final diff = endTime.difference(DateTime.now());
    if (diff.isNegative) return 'انتهى الوقت';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    if (days > 0) return '$days يوم و $hours س';
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.endTime.difference(DateTime.now());
    final isUrgent = diff.inHours < 24 && !diff.isNegative;
    final countdown = _format(widget.endTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isUrgent
            ? const Color(0xFFDC2626).withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: isUrgent
            ? Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUrgent ? Icons.local_fire_department_rounded : Icons.timer_outlined,
            size: 13,
            color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 4),
          Text(
            isUrgent ? 'ينتهي قريباً: $countdown' : countdown,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }
}


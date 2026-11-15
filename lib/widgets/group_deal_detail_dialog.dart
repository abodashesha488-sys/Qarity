import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/utils/app_image_cache.dart';
import '../models/group_deal_model.dart';
import '../services/admin_service.dart';
import '../services/group_deal_service.dart';
import '../services/share_service.dart';
import '../services/user_service.dart';
import 'group_deal_delivery_screen.dart';

class GroupDealDetailSheet extends StatefulWidget {
  const GroupDealDetailSheet({super.key, required this.dealId});

  final String dealId;

  @override
  State<GroupDealDetailSheet> createState() => _GroupDealDetailSheetState();
}

class _GroupDealDetailSheetState extends State<GroupDealDetailSheet> {
  final GroupDealService _service = GroupDealService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedQuantity = 1;
  String _paymentMethod = 'مندوب القرية';
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _notesCtrl;
  bool _isSubmitting = false;
  bool _isBookingOpen = false;
  bool _isAdminOrAgent = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _initUserData();
  }

  Future<void> _initUserData() async {
    final profile = await _userService.getCurrentUser();
    if (profile != null && mounted) {
      _nameCtrl.text = profile.name;
      _phoneCtrl.text = profile.phone ?? '';
    }
    final uid = _auth.currentUser?.uid;
    final isAdmin = uid != null ? await AdminService().isAdminUser(uid) : false;
    if (mounted) {
      setState(() => _isAdminOrAgent = isAdmin);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _shareWithNeighbors(GroupDealModel deal) {
    ShareService.shareContent(
      title: '🔥 فرصة شراء جماعي بسعر الجملة: ${deal.title}',
      details: {
        'السعر في السوق': '${deal.marketPrice.toStringAsFixed(0)} جنيه',
        'سعر الجملة': '${deal.dealPrice.toStringAsFixed(0)} جنيه',
        'وفر في الحصة': '${deal.savingsPerUnit.toStringAsFixed(0)} جنيه',
        'الكمية المستهدفة': '${deal.targetCount} ${deal.unitName}',
      },
      imageUrls:
          deal.imageUrl.trim().isNotEmpty ? [deal.imageUrl.trim()] : const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = _auth.currentUser?.uid ?? '';

    return StreamBuilder<GroupDealModel?>(
      stream: _service.watchDeal(widget.dealId),
      builder: (context, snapshot) {
        final deal = snapshot.data;
        if (deal == null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return StreamBuilder<DealParticipantModel?>(
          stream: _service.watchUserBooking(deal.id, uid),
          builder: (context, bookingSnap) {
            final userBooking = bookingSnap.data;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  18,
                  14,
                  18,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // مقبض السحب
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // عنوان النافذة وزر الإغلاق
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFD97706).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.groups_rounded,
                              color: Color(0xFFD97706), size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'صفقات أبودشيشة الجماعية',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              Text(
                                'شراء جماعي بسعر الجملة للأهالي',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isAdminOrAgent)
                          IconButton(
                            tooltip: 'شاشة تسليم المشتركين',
                            icon: const Icon(Icons.local_shipping_outlined,
                                color: Color(0xFF16A34A)),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      GroupDealDeliveryScreen(dealId: deal.id),
                                ),
                              );
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // 1. تفاصيل الصفقة والمنتج
                    _buildDealHeader(theme, deal),
                    const SizedBox(height: 14),

                    // 2. حالة حجز المستخدم إذا كان مشتركاً بالفعل
                    if (userBooking != null) ...[
                      _buildUserClaimCodeCard(theme, deal, userBooking),
                      const SizedBox(height: 14),
                    ] else if (_isBookingOpen) ...[
                      _buildBookingForm(theme, deal, uid),
                      const SizedBox(height: 14),
                    ],

                    // 3. أزرار الإجراءات
                    if (userBooking == null && !_isBookingOpen) ...[
                      FilledButton.icon(
                        icon: const Icon(Icons.how_to_reg_rounded),
                        label: Text(
                          deal.isAvailableForBooking
                              ? 'احجز حصتك الآن بسعر الجملة'
                              : (deal.remainingCount <= 0
                                  ? 'اكتملت الصفقة'
                                  : 'العرض منتهي'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: deal.isAvailableForBooking
                              ? theme.colorScheme.primary
                              : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: deal.isAvailableForBooking
                            ? () => setState(() => _isBookingOpen = true)
                            : null,
                      ),
                      const SizedBox(height: 10),
                    ],

                    // زر المشاركة مع الجيران عبر واتساب
                    OutlinedButton.icon(
                      icon: const Icon(Icons.share_rounded,
                          color: Color(0xFF25D366)),
                      label: const Text(
                        'شارك مع جيرانك لتكتمل الصفقة 🔥',
                        style: TextStyle(
                          color: Color(0xFF1B4D3E),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                            color:
                                const Color(0xFF25D366).withValues(alpha: 0.6),
                            width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _shareWithNeighbors(deal),
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

  Widget _buildDealHeader(ThemeData theme, GroupDealModel deal) {
    return Container(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: deal.imageUrl.isNotEmpty
                      ? AppImageCache.image(
                          url: deal.imageUrl,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.inventory_2_outlined, size: 36),
                        )
                      : const Icon(Icons.inventory_2_outlined, size: 36),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${deal.dealPrice.toStringAsFixed(0)} جنيه',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${deal.marketPrice.toStringAsFixed(0)} ج',
                          style: TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'وفر ${deal.savingsPerUnit.toStringAsFixed(0)} جنيه لكل ${deal.unitName} (خصم ${deal.discountPercentage}%)',
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
              ),
            ],
          ),
          if (deal.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              deal.description,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'Cairo'),
            ),
          ],
          const SizedBox(height: 12),
          // العداد ونسبة التقدم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المشتركون: ${deal.currentCount} من ${deal.targetCount}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo'),
              ),
              Text(
                deal.remainingCount > 0
                    ? 'باقي ${deal.remainingCount} وتصل الشحنة'
                    : 'اكتملت الحصة المطلوبة ✅',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: deal.remainingCount > 0
                      ? const Color(0xFFD97706)
                      : const Color(0xFF16A34A),
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: deal.progressRatio,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                deal.progressRatio >= 1.0
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFD97706),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserClaimCodeCard(
    ThemeData theme,
    GroupDealModel deal,
    DealParticipantModel booking,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD97706).withValues(alpha: 0.15),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD97706), width: 1.8),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                booking.isDelivered
                    ? Icons.check_circle_rounded
                    : (booking.isConfirmedByAdmin
                        ? Icons.vpn_key_rounded
                        : Icons.pending_rounded),
                color: booking.isDelivered
                    ? const Color(0xFF16A34A)
                    : (booking.isConfirmedByAdmin
                        ? const Color(0xFFD97706)
                        : Colors.orange),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                booking.isDelivered
                    ? 'تم تسليم حصتك بنجاح ✅'
                    : (booking.isConfirmedByAdmin
                        ? 'حجزك مؤكد — كود الاستلام الخاص بك:'
                        : 'طلبك قيد المراجعة وتأكيد العربون ⏳'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: booking.isDelivered
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFB45309),
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // كود الـ 4 أرقام بالأرقام الكبيرة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFD97706).withValues(alpha: 0.4),
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < booking.claimCode.length; i++) ...[
                  Container(
                    width: 38,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD97706)),
                    ),
                    child: Text(
                      booking.claimCode[i],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                  if (i < booking.claimCode.length - 1)
                    const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            booking.isDelivered
                ? 'استلمت: ${booking.quantity} ${deal.unitName} • شكراً لمشاركتك معنا!'
                : 'قدم هذا الكود المكون من 4 أرقام لمندوب القرية عند الاستلام لتأكيد الحصة.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 8),

          // تفاصيل الحجز المالية للمشترك
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'الحصة: ${booking.quantity} ${deal.unitName}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo'),
                ),
                Text(
                  'العربون: ${booking.depositRequired(deal.depositAmount).toStringAsFixed(0)} ج',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo'),
                ),
                Text(
                  'المتبقي للتسليم: ${booking.remainingOnDelivery(deal.dealPrice, deal.depositAmount).toStringAsFixed(0)} ج',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingForm(ThemeData theme, GroupDealModel deal, String uid) {
    final deposit = _selectedQuantity * deal.depositAmount;
    final total = _selectedQuantity * deal.dealPrice;
    final remaining = _selectedQuantity * (deal.dealPrice - deal.depositAmount);

    return Container(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              const Text(
                'استمارة الاشتراك وحجز الحصة',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo'),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => setState(() => _isBookingOpen = false),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // الاسم
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'الاسم ثلاثي',
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),

          // رقم الهاتف
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'رقم الهاتف للتواصل وتأكيد الحجز',
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // عداد الكمية
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الكمية المطلوبة:',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _selectedQuantity > 1
                          ? () => setState(() => _selectedQuantity--)
                          : null,
                    ),
                    Text(
                      '$_selectedQuantity ${deal.unitName}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: _selectedQuantity < deal.remainingCount
                          ? () => setState(() => _selectedQuantity++)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // طريقة دفع العربون
          const Text(
            'طريقة دفع العربون المبدئي:',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('الدفع لمندوب القرية',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                selected: _paymentMethod == 'مندوب القرية',
                onSelected: (_) =>
                    setState(() => _paymentMethod = 'مندوب القرية'),
              ),
              ChoiceChip(
                label: const Text('تحويل محفظة (فودافون كاش / إنستاباي)',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11)),
                selected: _paymentMethod == 'محفظة إلكترونية',
                onSelected: (_) =>
                    setState(() => _paymentMethod = 'محفظة إلكترونية'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // الحسبة المالية للحجز
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFD97706).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('العربون المطلوب لتأكيد الجدية:',
                        style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                    Text('${deposit.toStringAsFixed(0)} جنيه',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                            fontFamily: 'Cairo')),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('المتبقي للدفع عند استلام الحصة:',
                        style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                    Text('${remaining.toStringAsFixed(0)} جنيه',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontFamily: 'Cairo')),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي قيمة الصفقة:',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo')),
                    Text('${total.toStringAsFixed(0)} جنيه',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // زر تأكيد الحجز
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSubmitting ? null : () => _submitBooking(deal, uid),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('تأكيد الحجز وتوليد كود الاستلام 🔑',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBooking(GroupDealModel deal, String uid) async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى إدخال الاسم ورقم الهاتف لتأكيد الحجز')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final code = await _service.bookDeal(
        dealId: deal.id,
        userId: uid,
        userName: name,
        userPhone: phone,
        quantity: _selectedQuantity,
        paymentMethod: _paymentMethod,
        notes: _notesCtrl.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isBookingOpen = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text('تم تسجيل حجزك بنجاح! كود استلامك هو: $code'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحجز: $e')),
        );
      }
    }
  }
}

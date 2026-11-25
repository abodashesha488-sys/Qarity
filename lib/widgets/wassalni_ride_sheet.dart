import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/contact_links.dart';
import '../core/utils/launch_link.dart';
import '../core/utils/phone_validator.dart';
import '../models/wassalni_model.dart';
import '../services/user_service.dart';
import '../services/wassalni_service.dart';
import 'order_progress_stepper.dart';

const Color _kWassalniAccent = Color(0xFF7C3AED);
const Color _kWassalniDark = Color(0xFF5B21B6);

/// 🚖 نافذة خدمة «وصّلني» الحديثة للمستخدم
///
/// مخصصة لطلب سيارة ملاكي خاصة أو توك توك للمشاوير والتوصيل:
/// 1. الشاشة الرئيسية: نبذة عصرية قابلة للطي + أزرار "اطلب رحلة الآن" و"متابعة رحلاتي".
/// 2. شاشة حجز الرحلة: اختيار المركبة (توك توك / سيارة خاصة)، نقاط الانطلاق والوصول السريعة،
///    الموعد، الذهاب والعودة، مع جدول وضوح التكلفة قبل الحجز.
/// 3. شاشة متابعة الرحلات: كروت ملخصة + شاشة تفاصيل بتتبع حي وتواصل مباشر مع السائق.
class WassalniRideSheet extends StatefulWidget {
  const WassalniRideSheet({
    super.key,
    this.initialView = 0,
    this.service,
    this.userService,
    this.currentUserId,
    this.initialExpandIntro = false,
  });

  final int initialView; // 0: الرئيسية, 1: طلب رحلة, 2: متابعة رحلاتي
  final WassalniService? service;
  final UserService? userService;
  final String? currentUserId;
  final bool initialExpandIntro;

  @override
  State<WassalniRideSheet> createState() => _WassalniRideSheetState();
}

class _WassalniRideSheetState extends State<WassalniRideSheet> {
  late final WassalniService _service = widget.service ?? WassalniService();
  late final UserService _userService = widget.userService ?? UserService();

  late int _currentView = widget.initialView;
  late bool _isIntroExpanded = widget.initialExpandIntro;
  bool _isSubmitting = false;

  WassalniVehicleType _vehicleType = WassalniVehicleType.tuktuk;
  bool _isRoundTrip = false;
  bool _isImmediate = true;
  int _passengersCount = 1;

  final TextEditingController _pickupCtrl = TextEditingController();
  final TextEditingController _dropoffCtrl = TextEditingController();
  final TextEditingController _scheduleCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  static const List<String> _quickPickups = [
    'وسط القرية (أبوديشيشة)',
    'المسجد الكبير',
    'كوبري القرية',
    'المركز الطبي الخيري',
    'أول البلد',
  ];

  static const List<String> _quickDropoffs = [
    'بلقاس',
    'المعصرة',
    'الستاموني',
    'مستشفى بلقاس',
    'المنصورة',
    'محطة القطار',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          if (_nameCtrl.text.isEmpty) _nameCtrl.text = user.name;
          if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = user.phone ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropoffCtrl.dispose();
    _scheduleCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _resolveUserId() {
    if (widget.currentUserId != null) return widget.currentUserId!;
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : _kWassalniAccent,
      ),
    );
  }

  Future<void> _submitRide() async {
    final uid = _resolveUserId();
    if (uid.isEmpty) {
      _showMsg('يرجى تسجيل الدخول أولاً لطلب رحلة «وصّلني»', isError: true);
      return;
    }

    final pickup = _pickupCtrl.text.trim();
    final dropoff = _dropoffCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (pickup.isEmpty || dropoff.isEmpty) {
      _showMsg('يرجى تحديد مكان الانطلاق والوجهة المطلوبة', isError: true);
      return;
    }
    if (name.isEmpty) {
      _showMsg('يرجى إدخال الاسم', isError: true);
      return;
    }
    final phoneError = PhoneValidator.validate(phone);
    if (phoneError != null) {
      _showMsg(phoneError, isError: true);
      return;
    }

    final scheduleText = _isImmediate
        ? 'الآن فوراً'
        : (_scheduleCtrl.text.trim().isEmpty
            ? 'موعد يحدده العميل'
            : _scheduleCtrl.text.trim());

    setState(() => _isSubmitting = true);
    try {
      await _service.createRide(
        userId: uid,
        userName: name,
        userPhone: PhoneValidator.normalize(phone) ?? phone,
        vehicleType: _vehicleType,
        pickupLocation: pickup,
        dropoffLocation: dropoff,
        isRoundTrip: _isRoundTrip,
        scheduledTimeText: scheduleText,
        passengersCount: _passengersCount,
        notes: _notesCtrl.text.trim(),
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        _pickupCtrl.clear();
        _dropoffCtrl.clear();
        _scheduleCtrl.clear();
        _notesCtrl.clear();
        setState(() {
          _isSubmitting = false;
          _currentView = 2;
        });
        _showMsg('تم إرسال طلب رحلتك بنجاح! جاري تخصيص أقرب سائق 🚖');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showMsg('تعذر إرسال الطلب: $e', isError: true);
      }
    }
  }

  void _rebookRide(WassalniRide ride) {
    setState(() {
      _vehicleType = ride.vehicleType;
      _pickupCtrl.text = ride.pickupLocation;
      _dropoffCtrl.text = ride.dropoffLocation;
      _isRoundTrip = ride.isRoundTrip;
      _passengersCount = ride.passengersCount;
      _notesCtrl.text = ride.notes;
      if (ride.userName.isNotEmpty) _nameCtrl.text = ride.userName;
      if (ride.userPhone.isNotEmpty) _phoneCtrl.text = ride.userPhone;
      _currentView = 1;
    });
    _showMsg('تم تعبئة بيانات الرحلة السابقة — راجعها واضغط تأكيد 🔄');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = _resolveUserId();
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF141821) : const Color(0xFFF8FAFC),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.89,
        child: Column(
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildCurrentView(theme, uid),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentView(ThemeData theme, String uid) {
    switch (_currentView) {
      case 1:
        return _buildNewRideView(theme);
      case 2:
        return _buildMyRidesView(theme, uid);
      default:
        return _buildLandingView(theme, uid);
    }
  }

  // ───────────────────────── 1. الشاشة الرئيسية ─────────────────────────
  Widget _buildLandingView(ThemeData theme, String uid) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kWassalniAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_taxi_rounded,
                    color: _kWassalniAccent, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'خدمة «وصّلني» 🚖',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16.5,
                      ),
                    ),
                    Text(
                      'سيارة ملاكي خاصة أو توك توك تحت طلبك في أي وقت',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // كارت تعريفي قابل للطي
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Color(0xFF2E1065), Color(0xFF170B3B)]
                          : const [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    border: Border.all(
                      color: _kWassalniAccent.withValues(
                          alpha: isDark ? 0.45 : 0.55),
                      width: 1.4,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () =>
                        setState(() => _isIntroExpanded = !_isIntroExpanded),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_kWassalniAccent, _kWassalniDark],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.local_taxi_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'مشاوير القرية والمدن المجاورة بأمان',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    Text(
                                      'توك توك سريع 🛺 · سيارة ملاكي مريحة 🚗',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: _kWassalniAccent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _kWassalniAccent.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isIntroExpanded ? 'إخفاء' : 'التفاصيل',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _kWassalniAccent,
                                      ),
                                    ),
                                    Icon(
                                      _isIntroExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: _kWassalniAccent,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox(width: double.infinity),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                Text(
                                  'احجز سيارة ملاكي خاصة أو توك توك في ثوانٍ مع متابعة فورية لحالة الرحلة وبيانات السائق:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.55,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _FeatureChip(
                                        icon: Icons.electric_rickshaw_rounded,
                                        label: 'توك توك فوري داخل القرية'),
                                    _FeatureChip(
                                        icon: Icons.directions_car_rounded,
                                        label: 'سيارة خاصة للمشاوير الطويلة'),
                                    _FeatureChip(
                                        icon: Icons.verified_user_rounded,
                                        label: 'سائقون موثوقون من أبناء القرية'),
                                    _FeatureChip(
                                        icon: Icons.schedule_rounded,
                                        label: 'حجز فوري أو لموعد مسبق'),
                                  ],
                                ),
                              ],
                            ),
                            crossFadeState: _isIntroExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 240),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // اختيار سريع بنوع المركبة ينقل مباشرة لنموذج الحجز
                Row(
                  children: [
                    Expanded(
                      child: _VehicleQuickCard(
                        icon: Icons.electric_rickshaw_rounded,
                        title: 'اطلب توك توك 🛺',
                        subtitle: 'سريع وموفر للمشوار القريب',
                        color: const Color(0xFFD97706),
                        onTap: () => setState(() {
                          _vehicleType = WassalniVehicleType.tuktuk;
                          _currentView = 1;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _VehicleQuickCard(
                        icon: Icons.directions_car_rounded,
                        title: 'سيارة خاصة 🚗',
                        subtitle: 'مريحة ومكيفة للمدن والعائلات',
                        color: _kWassalniAccent,
                        onTap: () => setState(() {
                          _vehicleType = WassalniVehicleType.privateCar;
                          _currentView = 1;
                        }),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // الزر الرئيسي: اطلب رحلة الآن
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => setState(() => _currentView = 1),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kWassalniAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 22),
                    label: const Text(
                      'اطلب رحلة جديدة الآن',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // زر متابعة رحلاتي
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _currentView = 2),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kWassalniAccent,
                      side: const BorderSide(color: _kWassalniAccent, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.route_rounded, size: 20),
                    label: const Text(
                      'متابعة رحلاتي وسجل التوصيل 📍',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── 2. استمارة حجز رحلة ─────────────────────────
  Widget _buildNewRideView(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'رجوع',
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => setState(() => _currentView = 0),
              ),
              const Expanded(
                child: Text(
                  'حجز رحلة «وصّلني» 🚖',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // بطاقة وضوح التكلفة والضمان
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kWassalniAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _kWassalniAccent.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_user_rounded,
                              color: _kWassalniAccent, size: 19),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'أمان ووضوح قبل الانطلاق 🛡️',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                color: _kWassalniDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '• سائقون موثوقون ومعروفون بالقرية · تسعيرة عادلة تُعرض لك مع بيانات السائق قبل التحرك · الدفع نقداً عند الوصول.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // اختيار نوع المركبة
                const Text(
                  'اختر وسيلة التوصيل:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: WassalniVehicleType.values.map((vt) {
                    final selected = _vehicleType == vt;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                            end: vt == WassalniVehicleType.tuktuk ? 6 : 0,
                            start: vt == WassalniVehicleType.privateCar ? 6 : 0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() => _vehicleType = vt),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? _kWassalniAccent.withValues(alpha: 0.12)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? _kWassalniAccent
                                    : theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.4),
                                width: selected ? 1.8 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  vt == WassalniVehicleType.privateCar
                                      ? Icons.directions_car_rounded
                                      : Icons.electric_rickshaw_rounded,
                                  color: selected
                                      ? _kWassalniAccent
                                      : theme.colorScheme.onSurfaceVariant,
                                  size: 26,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  vt.labelArabic,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: selected
                                        ? _kWassalniAccent
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  vt.capacityHint,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // نقطة الانطلاق + اقتراحات سريعة
                TextField(
                  controller: _pickupCtrl,
                  decoration: InputDecoration(
                    labelText: 'من أين تتحرك؟ (نقطة الانطلاق) *',
                    hintText: 'مثال: أمام المسجد الكبير / شارع داير الناحية',
                    prefixIcon: const Icon(Icons.my_location_rounded,
                        color: Color(0xFF16A34A)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _quickPickups
                      .map((loc) => ActionChip(
                            label: Text(loc, style: const TextStyle(fontSize: 10.5)),
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                setState(() => _pickupCtrl.text = loc),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 12),

                // الوجهة + اقتراحات سريعة
                TextField(
                  controller: _dropoffCtrl,
                  decoration: InputDecoration(
                    labelText: 'إلى أين تتجه؟ (الوجهة المطلوبة) *',
                    hintText: 'مثال: موقف بلقاس / مستشفى بلقاس / المنصورة',
                    prefixIcon: const Icon(Icons.location_on_rounded,
                        color: _kWassalniAccent),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _quickDropoffs
                      .map((loc) => ActionChip(
                            label: Text(loc, style: const TextStyle(fontSize: 10.5)),
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                setState(() => _dropoffCtrl.text = loc),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 14),

                // خيارات التوقيت والاتجاه
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('الآن فوراً ⚡'),
                        selected: _isImmediate,
                        onSelected: (v) => setState(() => _isImmediate = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('موعد مسبق 🕒'),
                        selected: !_isImmediate,
                        onSelected: (v) => setState(() => _isImmediate = false),
                      ),
                    ),
                  ],
                ),
                if (!_isImmediate) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _scheduleCtrl,
                    decoration: InputDecoration(
                      labelText: 'الموعد المطلوب (اليوم والساعة)',
                      hintText: 'مثال: غداً الساعة 7:30 صباحاً',
                      prefixIcon: const Icon(Icons.schedule_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // ذهاب وعودة + عدد الركاب
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('ذهاب وعودة',
                            style: TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700)),
                        value: _isRoundTrip,
                        onChanged: (v) => setState(() => _isRoundTrip = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('الركاب:',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _passengersCount > 1
                              ? () => setState(() => _passengersCount--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded,
                              size: 20),
                        ),
                        Text('$_passengersCount',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 14)),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _passengersCount < 6
                              ? () => setState(() => _passengersCount++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              size: 20),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // بيانات التواصل
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'الاسم *',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف *',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات إضافية (اختياري)',
                    hintText: 'مثال: يوجد شنط سفر / بجوار محل كذا...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitRide,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kWassalniAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(
                      _isSubmitting
                          ? 'جاري إرسال طلب الرحلة...'
                          : 'تأكيد طلب «وصّلني» 🚖',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── 3. متابعة رحلاتي ─────────────────────────
  Widget _buildMyRidesView(ThemeData theme, String uid) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'رجوع',
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => setState(() => _currentView = 0),
              ),
              const Expanded(
                child: Text(
                  'رحلاتي في «وصّلني» 📍',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _currentView = 1),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('رحلة جديدة'),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: uid.isEmpty
              ? const Center(
                  child: Text('يرجى تسجيل الدخول لمتابعة رحلاتك'),
                )
              : StreamBuilder<List<WassalniRide>>(
                  stream: _service.watchMyRides(uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final rides = snapshot.data ?? [];
                    if (rides.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_taxi_outlined,
                                  size: 56,
                                  color:
                                      _kWassalniAccent.withValues(alpha: 0.45)),
                              const SizedBox(height: 12),
                              const Text(
                                'لا توجد رحلات مسجلة بعد',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed: () =>
                                    setState(() => _currentView = 1),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _kWassalniAccent,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('اطلب أول رحلة الآن'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: rides.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _buildRideCard(theme, rides[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRideCard(ThemeData theme, WassalniRide ride) {
    final isCancelled = ride.status == WassalniStatus.cancelled;
    final isCompleted = ride.status == WassalniStatus.completed;
    final statusColor = isCancelled
        ? Colors.red
        : isCompleted
            ? const Color(0xFF16A34A)
            : _kWassalniAccent;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRideDetail(ride),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ride.status.labelArabic,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    ride.rideNumber,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${ride.vehicleType.labelArabic} · ${ride.pickupLocation} ← ${ride.dropoffLocation}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'الموعد: ${ride.scheduledTimeText}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (ride.effectiveFare > 0)
                    Text(
                      '${ride.effectiveFare.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF16A34A),
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
              if (!isCancelled) ...[
                const SizedBox(height: 10),
                OrderProgressStepper(
                  activeColor: statusColor,
                  nodeRadius: 10,
                  dividerWidth: 14,
                  fontSize: 8.5,
                  steps: [
                    const OrderProgressStep(label: 'الطلب', isDone: true),
                    OrderProgressStep(
                      label: 'السائق',
                      isDone: ride.status.index >= WassalniStatus.accepted.index,
                    ),
                    OrderProgressStep(
                      label: 'التحرك',
                      isDone: ride.status.index >= WassalniStatus.onTrip.index,
                    ),
                    OrderProgressStep(
                      label: 'الوصول',
                      isDone: ride.status == WassalniStatus.completed,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRideDetail(WassalniRide ride) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تفاصيل الرحلة ${ride.rideNumber}',
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text('المركبة: ${ride.vehicleType.labelArabic}'),
              Text('الانطلاق: ${ride.pickupLocation}'),
              Text('الوجهة: ${ride.dropoffLocation}'),
              Text('الموعد: ${ride.scheduledTimeText}'),
              if (ride.isRoundTrip) const Text('نوع الرحلة: ذهاب وعودة'),
              if (ride.driverName.isNotEmpty) ...[
                const Divider(height: 20),
                Text(
                  'السائق المخصص: ${ride.driverName}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (ride.vehicleInfo.isNotEmpty)
                  Text('المركبة: ${ride.vehicleInfo}'),
                if (ride.driverPhone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => launchContactUrl(
                            Uri(scheme: 'tel', path: ride.driverPhone)
                                .toString(),
                            unavailable: 'لا يمكن الاتصال على هذا الجهاز.',
                            failed: 'تعذّر بدء المكالمة.',
                          ),
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: const Text('اتصال بالسائق'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF128C7E),
                          ),
                          onPressed: () {
                            final wa = egyptianWhatsAppUrl(ride.driverPhone);
                            if (wa != null) {
                              launchContactUrl(
                                wa,
                                unavailable: 'واتساب غير متاح على هذا الجهاز.',
                                failed: 'تعذّر فتح واتساب.',
                              );
                            }
                          },
                          icon: const Icon(Icons.chat_rounded, size: 18),
                          label: const Text('واتساب'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _rebookRide(ride);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة نفس الرحلة 🔄'),
                    ),
                  ),
                  if (ride.status == WassalniStatus.searching) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _service.cancelRide(ride.id);
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('إلغاء الطلب'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _kWassalniAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kWassalniAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _kWassalniAccent),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: _kWassalniAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleQuickCard extends StatelessWidget {
  const _VehicleQuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

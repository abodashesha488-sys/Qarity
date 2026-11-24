import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_image_cache.dart';
import '../../../services/admin_service.dart';
import '../../../services/user_presence_service.dart';
import '../../../services/user_service.dart';

// ── مؤشرات الإحصائيات في الهيدر (المتواجدون حالياً 🟢 وإجمالي المسجلين 🔴) ──
// حصرية بالكامل للمدير العام (admin) والأدمن المساعد (assistant_admin) فقط لا غير

class HeaderStatsButtons extends StatefulWidget {
  const HeaderStatsButtons({super.key});

  @override
  State<HeaderStatsButtons> createState() => _HeaderStatsButtonsState();
}

class _HeaderStatsButtonsState extends State<HeaderStatsButtons> {
  bool _canViewStats = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final uid = UserService().currentUserId;
    if (uid == null || uid.isEmpty) return;

    // فحص الكاش السريع من ملف المستخدم أولاً
    final user = await UserService().getUser(uid);
    final role = user?.role;
    if (role == 'admin' || role == 'assistant_admin') {
      if (mounted) setState(() => _canViewStats = true);
      return;
    }
    final isAdmin = await AdminService().isAdminUser(uid);
    if (mounted && isAdmin) {
      setState(() => _canViewStats = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // تظهر فقط وحصرياً للمدير العام والأدمن المساعد
    if (!_canViewStats) return const SizedBox.shrink();

    return const OverflowBox(
      minHeight: 0,
      maxHeight: 120,
      minWidth: 0,
      maxWidth: 160,
      alignment: Alignment.topLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OnlineUsersHeaderButton(),
          SizedBox(height: 4),
          _TotalUsersHeaderButton(),
        ],
      ),
    );
  }
}

class _OnlineUsersHeaderButton extends StatelessWidget {
  const _OnlineUsersHeaderButton();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: UserPresenceService.instance.onlineUsersStream,
      initialData: 1,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 1;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _handleOnlineHeaderTap(context, count),
            child: Container(
              height: 27,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF2ECC71).withValues(alpha: 0.6),
                  width: 0.9,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x38000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _PulsingDot(color: Color(0xFF00E676), size: 7.5),
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 3.5),
                  Text(
                    'متصل',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TotalUsersHeaderButton extends StatelessWidget {
  const _TotalUsersHeaderButton();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: UserPresenceService.instance.totalUsersStream,
      initialData: 19,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 19;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showTotalUsersDetails(context, count),
            child: Container(
              height: 27,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.6),
                  width: 0.9,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x38000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7.5,
                    height: 7.5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5252),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x99FF5252),
                          blurRadius: 5,
                          spreadRadius: 0.8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 3.5),
                  Text(
                    'عضو',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({
    required this.color,
    this.size = 8.0,
  });

  final Color color;
  final double size;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.22).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.75),
                  blurRadius: 5 * _scaleAnimation.value,
                  spreadRadius: 1 * _scaleAnimation.value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _handleOnlineHeaderTap(BuildContext context, int count) async {
  HapticFeedback.lightImpact();
  final uid = UserService().currentUserId;
  bool isAuthorizedAdmin = false;
  if (uid != null && uid.isNotEmpty) {
    // فحص الكاش السريع أولاً ثم التحقق الأمني
    final cachedUser = await UserService().getUser(uid);
    final role = cachedUser?.role;
    if (role == 'admin' || role == 'assistant_admin') {
      isAuthorizedAdmin = true;
    } else {
      isAuthorizedAdmin = await AdminService().isAdminUser(uid);
    }
  }
  if (!context.mounted) return;
  if (isAuthorizedAdmin) {
    _showOnlineUsersAdminSheet(context);
  }
}

void _showOnlineUsersAdminSheet(BuildContext context) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final isDark = theme.brightness == Brightness.dark;
      final maxSheetHeight = MediaQuery.of(ctx).size.height * 0.82;

      return Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1E26) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // شريط السحب العلوي
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // رأس اللوحة: العنوان + شارة الأدمن العام
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sensors_rounded,
                    color: Color(0xFF2ECC71),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المتواجدون الآن بالتطبيق',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'قائمة حية للمتصلين لحظة بلحظة',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                // شارة الأدمن العام الحصرية
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1C40F).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF1C40F).withValues(alpha: 0.6),
                      width: 0.9,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: Color(0xFFF1C40F),
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'المدير العام',
                        style: TextStyle(
                          color: Color(0xFFF1C40F),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // قائمة المستخدمين الحية المتصلين الآن
            Expanded(
              child: StreamBuilder<List<OnlineUserInfo>>(
                stream: UserPresenceService.instance.onlineUsersListStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 48,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'لا يوجد مستخدمون متواجدون حالياً',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final memberCount = users.where((u) => !u.isGuest).length;
                  final guestCount = users.where((u) => u.isGuest).length;

                  return Column(
                    children: [
                      // شريط إحصائي مصغر للأعضاء والزوار
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF4F6F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildOnlineStatMiniBadge(
                              label: 'الإجمالي',
                              count: users.length,
                              color: const Color(0xFF2ECC71),
                              icon: Icons.people_alt_rounded,
                            ),
                            Container(
                                width: 1,
                                height: 18,
                                color: Colors.grey.withValues(alpha: 0.3)),
                            _buildOnlineStatMiniBadge(
                              label: 'أعضاء مسجلون',
                              count: memberCount,
                              color: const Color(0xFF3498DB),
                              icon: Icons.person_rounded,
                            ),
                            Container(
                                width: 1,
                                height: 18,
                                color: Colors.grey.withValues(alpha: 0.3)),
                            _buildOnlineStatMiniBadge(
                              label: 'زوار',
                              count: guestCount,
                              color: const Color(0xFF95A5A6),
                              icon: Icons.devices_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // قائمة كروت المستخدمين
                      Expanded(
                        child: ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final u = users[index];
                            return _OnlineUserItemCard(
                              user: u,
                              isDark: isDark,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تُحدث هذه القائمة لحظياً وتلقائياً فور فتح التطبيق أو إغلاقه.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildOnlineStatMiniBadge({
  required String label,
  required int count,
  required Color color,
  required IconData icon,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(
        '$label: ',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      Text(
        '$count',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );
}

class _OnlineUserItemCard extends StatelessWidget {
  const _OnlineUserItemCard({
    required this.user,
    required this.isDark,
  });

  final OnlineUserInfo user;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final photo = user.photoUrl ?? '';
    final hasPhoto = photo.isNotEmpty;
    final isGuest = user.isGuest;

    final Color badgeColor;
    final String badgeText = user.roleLabel;
    if (isGuest) {
      badgeColor = const Color(0xFF7F8C8D);
    } else if (user.role == 'admin') {
      badgeColor = const Color(0xFFF1C40F);
    } else if (user.role == 'assistant_admin') {
      badgeColor = const Color(0xFFE67E22);
    } else if (user.role == 'medical_admin') {
      badgeColor = const Color(0xFFE91E63);
    } else if (user.role == 'seller') {
      badgeColor = const Color(0xFF9B59B6);
    } else {
      badgeColor = const Color(0xFF2ECC71);
    }

    // المنصة (أندرويد / آيفون / ويب)
    final IconData platformIcon;
    final plat = (user.platform ?? '').toLowerCase();
    if (plat.contains('ios') || plat.contains('macos')) {
      platformIcon = Icons.apple;
    } else if (plat.contains('android')) {
      platformIcon = Icons.android_rounded;
    } else {
      platformIcon = Icons.language_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242833) : const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.role == 'admin'
              ? const Color(0xFFF1C40F).withValues(alpha: 0.35)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05)),
          width: user.role == 'admin' ? 1.2 : 0.8,
        ),
      ),
      child: Row(
        children: [
          // الصورة مع نقطة الاتصال الخضراء
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isGuest
                      ? (isDark ? Colors.white12 : Colors.grey.shade200)
                      : (isDark
                          ? const Color(0xFF1E3A2F)
                          : const Color(0xFFE8F5E9)),
                  border: Border.all(
                    color: user.role == 'admin'
                        ? const Color(0xFFF1C40F)
                        : (isGuest
                            ? Colors.transparent
                            : const Color(0xFF2ECC71).withValues(alpha: 0.5)),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: hasPhoto
                      ? AppImageCache.image(
                          url: photo,
                          errorWidget: (_, __, ___) => _buildAvatarFallback(),
                        )
                      : _buildAvatarFallback(),
                ),
              ),
              // نقطة التواجد اللحظية النابضة في ركن الصورة
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF242833) : Colors.white,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x6600E676),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // الاسم والدور
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: user.role == 'admin'
                              ? const Color(0xFFF1C40F)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                    if (user.role == 'admin') ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFF1C40F),
                        size: 15,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.35),
                          width: 0.7,
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(platformIcon,
                        size: 12,
                        color: isDark ? Colors.white54 : Colors.black45),
                    const SizedBox(width: 3),
                    Text(
                      _formatLastActive(user.lastActive),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // شارة "متصل الآن"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingDot(color: Color(0xFF00E676), size: 6.5),
                SizedBox(width: 4),
                Text(
                  'نشط',
                  style: TextStyle(
                    color: Color(0xFF2ECC71),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    if (user.isGuest) {
      return const Center(
        child: Icon(
          Icons.person_outline_rounded,
          color: Colors.grey,
          size: 22,
        ),
      );
    }
    final letter =
        user.name.trim().isNotEmpty ? user.name.trim().substring(0, 1) : 'ع';
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2ECC71),
        ),
      ),
    );
  }

  String _formatLastActive(DateTime? time) {
    if (time == null) return 'الآن';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 45) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    return 'منذ ${diff.inHours} س';
  }
}

void _showTotalUsersDetails(BuildContext context, int count) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final isDark = theme.brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E222A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Color(0xFFFF5252),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أعضاء مجتمع القرية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'إجمالي الحسابات المسجلة بالتطبيق',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5252),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x99FF5252),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'سجل في المنصة حتى الآن $count عضواً من أهالي وشباب قرية أبوديشيشة.',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'يتجدد هذا الرقم تلقائياً ومباشرة مع تسجيل أي عضو جديد أو عند تحديث الحسابات.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'حسناً',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

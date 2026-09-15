part of 'admin_dashboard.dart';

// ═══════════════════════════ Overview ═══════════════════════════
class _OverviewPage extends StatelessWidget {
  const _OverviewPage({
    required this.stats,
    required this.pendingCounts,
    required this.isLoading,
    required this.totalPending,
    required this.onOpenReview,
    required this.onOpenUsers,
    required this.onOpenReports,
  });

  final Map<String, int> stats;
  final Map<String, int> pendingCounts;
  final bool isLoading;
  final int totalPending;
  final void Function(String cat) onOpenReview;
  final VoidCallback onOpenUsers;
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WelcomeHeader(isLoading: isLoading, users: stats['users'] ?? 0),
          const SizedBox(height: 16),
          const _AlertControlCard(),
          const SizedBox(height: 12),
          const _AlertControlCard(breaking: true),
          const SizedBox(height: 16),
          if (totalPending > 0)
            _PendingAlert(
                    count: totalPending, onTap: () => onOpenReview('news'))
                .animate()
                .fadeIn()
                .slideY(begin: 0.1),
          const SizedBox(height: 16),
          Text('الإحصائيات',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          isLoading
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              : GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _StatCard(
                        label: 'المستخدمون',
                        value: stats['users'] ?? 0,
                        icon: Icons.people_rounded,
                        color: Colors.teal,
                        onTap: onOpenUsers),
                    _StatCard(
                        label: 'الأخبار',
                        value: stats['news'] ?? 0,
                        icon: Icons.newspaper_rounded,
                        color: Colors.blue,
                        onTap: () => onOpenReview('news')),
                    _StatCard(
                        label: 'المنتجات',
                        value: stats['market_products'] ?? 0,
                        icon: Icons.store_rounded,
                        color: Colors.deepPurple,
                        onTap: () => onOpenReview('market_products')),
                    _StatCard(
                        label: 'المنشورات',
                        value: stats['forum_posts'] ?? 0,
                        icon: Icons.forum_rounded,
                        color: Colors.brown,
                        onTap: () => onOpenReview('forum_posts')),
                    _StatCard(
                        label: 'العزاء',
                        value: stats['obituaries'] ?? 0,
                        icon: Icons.volunteer_activism_rounded,
                        color: Colors.indigo,
                        onTap: () => onOpenReview('obituaries')),
                    _StatCard(
                        label: 'المناسبات',
                        value: stats['occasions'] ?? 0,
                        icon: Icons.celebration_rounded,
                        color: Colors.teal,
                        onTap: () => onOpenReview('occasions')),
                  ],
                ),
          const SizedBox(height: 16),
          Text('المراجعة السريعة',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _AdminDashboardScreenState._cats)
                ActionChip(
                  avatar: Icon(c.icon,
                      size: 16,
                      color: (pendingCounts[c.collection] ?? 0) > 0
                          ? Colors.red
                          : c.color),
                  label: Text(c.label),
                  backgroundColor: (pendingCounts[c.collection] ?? 0) > 0
                      ? theme.colorScheme.errorContainer.withValues(alpha: 0.4)
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  onPressed: () => onOpenReview(c.collection),
                ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpenReports,
            icon: const Icon(Icons.insights_rounded),
            label: const Text('عرض التقارير والإحصائيات'),
          ),
          const SizedBox(height: 24),
          _ActivityPreview(),
        ],
      ),
    );
  }
}

/// بطاقة «التنبيه العاجل» — يديرها الأدمن من لوحة التحكم:
/// نص حر + تفعيل/إيقاف. عند التفعيل يُرسَل إشعار فوري لجميع المشتركين
/// في `village_alerts`، وتعود الشاشة الرئيسية لعرض «حكمة اليوم» عند الإيقاف.
/// تُستخدم أيضاً للخبر العاجل (breaking=true) بألوان صفراء/زرقاء.
class _AlertControlCard extends StatefulWidget {
  const _AlertControlCard({this.breaking = false});
  final bool breaking;

  @override
  State<_AlertControlCard> createState() => _AlertControlCardState();
}

class _AlertControlCardState extends State<_AlertControlCard> {
  final AlertService _service = AlertService();
  final TextEditingController _controller = TextEditingController();
  VillageAlert _alert = const VillageAlert();
  bool _loading = true;
  bool _busy = false;

  bool get _breaking => widget.breaking;
  Color get _accent =>
      _breaking ? const Color(0xFFF9A825) : const Color(0xFFC62828);
  Color get _onActive =>
      _breaking ? const Color(0xFF0D47A1) : Colors.white;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final alert =
          _breaking ? await _service.getBreaking() : await _service.getAlert();
      if (!mounted) return;
      setState(() {
        _alert = alert;
        _controller.text = alert.message;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enable() async {
    if (_busy) return;
    if (_controller.text.trim().isEmpty) {
      setState(() {});
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
          content: Text('اكتب نص التنبيه أولاً'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _busy = true);
    try {
      if (_breaking) {
        await _service.enableBreaking(_controller.text);
      } else {
        await _service.enableAlert(_controller.text);
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
          content: Text('✅ مُفعَّل وأُرسل إشعاراً لجميع المستخدمين'),
          backgroundColor: Color(0xFF6F4E37)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
            content: Text('خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_breaking) {
        await _service.disableBreaking();
      } else {
        await _service.disableAlert();
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
          content: Text('تم الإيقاف — عادت المساحة لما قبل التفعيل'),
          backgroundColor: Colors.blueGrey));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
            content: Text('خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final red = _accent;
    if (_loading) {
      return const SizedBox(
          height: 90,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            red.withValues(alpha: _alert.isActive ? 0.16 : 0.06),
            theme.colorScheme.surface,
          ],
        ),
        border: Border.all(
            color: red.withValues(alpha: _alert.isActive ? 0.5 : 0.25),
            width: _alert.isActive ? 1.4 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(_breaking
                        ? Icons.bolt_rounded
                        : Icons.campaign_rounded,
                    color: red, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    _breaking ? 'الخبر العاجل للقرية' : 'تنبيه القرية العاجل',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _alert.isActive
                        ? red
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _alert.isActive ? 'مُفعَّل الآن' : 'غير مُفعَّل',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: _alert.isActive
                          ? _onActive
                          : theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _alert.isActive
                ? 'يظهر أعلى الشاشة الرئيسية لكل المستخدمين + أُرسل كإشعار فوري.'
                : (_breaking
                    ? 'عند عدم وجود خبر يظهر «طقس القرية» أعلى الرئيسية.'
                    : 'عند عدم وجود تنبيه يظهر «حكمة اليوم» تلقائياً أعلى الرئيسية.'),
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            minLines: 2,
            maxLength: 240,
            enabled: !_busy,
            onChanged: (_) {
              if (_alert.isActive) setState(() {});
            },
            decoration: InputDecoration(
              hintText: _breaking
                  ? 'مثال: سوق الأحد مفتوح غدًا حتى المغرب — الدخول مجاني من الجهة البحرية'
                  : 'مثال: انقطاع المياه غدًا من 8 ص حتى 12 ظ — ادخروا حاجتكم',
              hintStyle:
                  theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              counterText: '',
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: red.withValues(alpha: 0.4))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: red.withValues(alpha: 0.4))),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          if (_alert.isActive &&
              _controller.text.trim() != _alert.message) ...[
            const SizedBox(height: 6),
            Text('النص المُفعَّل حالياً: «${_alert.message}»',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: red, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: red,
                      foregroundColor: _onActive,
                      padding: const EdgeInsets.symmetric(vertical: 13)),
                  onPressed: _busy ? null : _enable,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(_alert.isActive
                          ? Icons.refresh_rounded
                          : Icons.notifications_active_rounded,
                          size: 18),
                  label: Text(_alert.isActive ? 'تحديث وإعادة إرسال' : 'تفعيل وإرسال إشعار',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              if (_alert.isActive) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueGrey,
                      side: const BorderSide(color: Colors.blueGrey),
                      padding: const EdgeInsets.symmetric(vertical: 13)),
                  onPressed: _busy ? null : _disable,
                  icon: const Icon(Icons.notifications_off_rounded, size: 17),
                  label: const Text('إيقاف'),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.isLoading, required this.users});
  final bool isLoading;
  final int users;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مرحباً بك 👋',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('إدارة كاملة لمحتوى القرية في مكان واحد',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingAlert extends StatelessWidget {
  const _PendingAlert({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.pending_actions_rounded,
                  color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text('لديك $count عنصر بانتظار المراجعة والموافقة',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onErrorContainer)),
              ),
              Icon(Icons.chevron_left_rounded, color: theme.colorScheme.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: color, size: 14),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value',
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900, color: color)),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('آخر النشاطات',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: AdminService().getActivityLogStream(limit: 6),
          builder: (context, snapshot) {
            final log = snapshot.data ?? [];
            if (log.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('لا يوجد نشاط بعد',
                    style: TextStyle(color: Colors.grey)),
              );
            }
            return Column(
              children: log
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.3))),
                          leading: Icon(_actionIcon(e['action']),
                              color: _actionColor(e['action'], theme)),
                          title: Text(
                              '${_actionLabel(e['action'])}: ${e['targetTitle'] ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  static IconData _actionIcon(dynamic action) {
    switch (action) {
      case 'approve':
        return Icons.check_circle_rounded;
      case 'reject':
        return Icons.cancel_rounded;
      case 'delete':
        return Icons.delete_rounded;
      case 'publish':
        return Icons.publish_rounded;
      case 'set_role':
      case 'remove_admin':
        return Icons.shield_rounded;
      case 'enable_user':
        return Icons.toggle_on_rounded;
      case 'disable_user':
        return Icons.toggle_off_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  static Color _actionColor(dynamic action, ThemeData theme) {
    switch (action) {
      case 'approve':
      case 'publish':
        return const Color(0xFF6F4E37);
      case 'reject':
        return Colors.orange;
      case 'delete':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

  static String _actionLabel(dynamic action) {
    switch (action) {
      case 'approve':
        return 'موافقة';
      case 'reject':
        return 'رفض';
      case 'delete':
        return 'حذف';
      case 'publish':
        return 'نشر';
      case 'set_role':
        return 'تغيير دور';
      case 'remove_admin':
        return 'إزالة إدارة';
      case 'enable_user':
        return 'تفعيل حساب';
      case 'disable_user':
        return 'تعطيل حساب';
      default:
        return '$action';
    }
  }
}

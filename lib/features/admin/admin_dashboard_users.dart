part of 'admin_dashboard.dart';

// ═══════════════════════════ Users (إدارة الأدوار) ═══════════════════════════
class _UsersPage extends StatefulWidget {
  const _UsersPage({
    required this.adminService,
    required this.currentUid,
    required this.onUpdated,
  });
  final AdminService adminService;
  final String? currentUid;
  final VoidCallback onUpdated;

  @override
  State<_UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<_UsersPage> {
  final TextEditingController _search = TextEditingController();
  String _filter = 'all';

  static const _roleOptions = <String, (String, Color, IconData)>{
    'user': ('مستخدم', Colors.teal, Icons.person_rounded),
    'seller': ('بائع', Colors.deepPurple, Icons.store_rounded),
    'moderator': ('مشرف', Colors.orange, Icons.verified_user_rounded),
    'medical_admin': ('مدير المركز الطبي', Color(0xFF00897B), Icons.medical_services_rounded),
    'admin': ('مدير عام', Color(0xFF1565C0), Icons.admin_panel_settings_rounded),
  };

  static const _filters = <(String, String)>[
    ('all', 'الكل'),
    ('user', 'مستخدمون'),
    ('seller', 'بائعون'),
    ('moderator', 'مشرفون'),
    ('medical_admin', 'مدير طبي'),
    ('admin', 'مدراء'),
    ('disabled', 'معطّلون'),
  ];

  late final Stream<List<Map<String, dynamic>>> _usersStream =
      widget.adminService.getAllUsersStream();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        final sellers = all.where((u) => (u['role'] ?? '') == 'seller').length;
        final managers = all
            .where((u) => ['admin', 'medical_admin', 'moderator'].contains((u['role'] ?? '')))
            .length;
        final disabled = all.where((u) => u['isActive'] == false).length;

        final q = _search.text.trim().toLowerCase();
        var filtered = all.where((u) {
          final role = (u['role'] ?? 'user').toString();
          final off = u['isActive'] == false;
          if (_filter == 'disabled' && !off) return false;
          if (_filter != 'all' && _filter != 'disabled' && role != _filter) return false;
          if (q.isEmpty) return true;
          return (u['name']?.toString().toLowerCase().contains(q) ?? false) ||
              (u['email']?.toString().toLowerCase().contains(q) ?? false);
        }).toList();
        if (q.isNotEmpty && _filter == 'all') {
          filtered = all
              .where((u) =>
                  (u['name']?.toString().toLowerCase().contains(q) ?? false) ||
                  (u['email']?.toString().toLowerCase().contains(q) ?? false))
              .toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _miniStat(theme, 'المستخدمون', '${all.length}', Colors.teal),
                  const SizedBox(width: 8),
                  _miniStat(theme, 'البائعون', '$sellers', Colors.deepPurple),
                  const SizedBox(width: 8),
                  _miniStat(theme, 'المسؤولون', '$managers', Colors.blue),
                  const SizedBox(width: 8),
                  _miniStat(theme, 'معطّلون', '$disabled',
                      disabled > 0 ? theme.colorScheme.error : Colors.grey),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو البريد...',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: q.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _search.clear())
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final (id, label) = _filters[i];
                  final selected = _filter == id;
                  return ChoiceChip(
                    label: Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: selected ? Colors.white : null)),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = id),
                    selectedColor: theme.colorScheme.primary,
                  );
                },
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text('لا يوجد مستخدمون مطابقون',
                          style: TextStyle(color: Colors.grey[600])))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _userCard(theme, filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _miniStat(ThemeData theme, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: color, fontSize: 16)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _userCard(ThemeData theme, Map<String, dynamic> u) {
    final uid = u['id'] as String;
    final role = (u['role'] ?? 'user').toString();
    final sellerType = (u['sellerType'] ?? '').toString();
    final disabled = u['isActive'] == false;
    final isSelf = uid == widget.currentUid;
    final opt = _roleOptions[role] ?? _roleOptions['user']!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: disabled
                ? theme.colorScheme.error.withValues(alpha: 0.4)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: opt.$2.withValues(alpha: 0.14),
                  child: Icon(opt.$3, color: opt.$2, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${u['name']?.toString() ?? 'بدون اسم'}${isSelf ? ' (أنت)' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(u['email']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.shield_rounded,
                      color: theme.colorScheme.primary, size: 20),
                  tooltip: 'إدارة الحساب',
                  onPressed: () => _manage(context, u),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _badge(opt.$1, opt.$2),
                if (role == 'seller' && sellerType.isNotEmpty)
                  _badge(_typeLabel(sellerType), Colors.brown),
                if (disabled) _badge('معطّل', theme.colorScheme.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: color)),
      );

  static String _typeLabel(String t) {
    for (final e in SellerType.values) {
      if (e.name == t) return e.label;
    }
    return t;
  }

  // ───────────────────── لوحة إدارة الحساب ─────────────────────
  Future<void> _manage(BuildContext context, Map<String, dynamic> u) async {
    final uid = u['id'] as String;
    final role = (u['role'] ?? 'user').toString();
    final name = u['name']?.toString() ?? '';
    final email = u['email']?.toString() ?? '';
    final sellerType = (u['sellerType'] ?? '').toString();
    final active = u['isActive'] != false;
    final isSelf = uid == widget.currentUid;
    final service = widget.adminService;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.isEmpty ? 'مستخدم' : name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16)),
                          Text(email,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded)),
                  ],
                ),
              ),
              if (isSelf)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                        'هذا حسابك — تغيير الدور معطّل لحمايتك من قفل الصلاحيات.',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Text('الدور والصلاحيات',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(ctx).colorScheme.primary)),
              ),
              RadioGroup<String>(
                groupValue: role,
                onChanged: (v) async {
                  if (v == null || isSelf) return;
                  await service.setUserRole(uid, v);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _snack('تم تعيين الدور: ${_roleOptions[v]!.$1}');
                  widget.onUpdated();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final e in _roleOptions.entries)
                      RadioListTile<String>(
                        value: e.key,
                        dense: true,
                        title: Text(e.value.$1,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(_roleHint(e.key),
                            style: const TextStyle(fontSize: 11)),
                        secondary: Icon(e.value.$3,
                            size: 18, color: e.value.$2),
                      ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Text('نوع البائع (حدود رفع الصور)',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(ctx).colorScheme.secondary)),
              ),
              RadioGroup<String>(
                groupValue: sellerType.isEmpty ? null : sellerType,
                onChanged: (v) async {
                  if (v == null) return;
                  await service.updateUserAccess(uid, sellerType: v);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _snack('تم تحديث نوع البائع: ${_typeLabel(v)}');
                  widget.onUpdated();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final t in SellerType.values)
                      RadioListTile<String>(
                        value: t.name,
                        dense: true,
                        title: Text(t.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: Text('حتى ${t.maxImages} صور',
                            style: const TextStyle(fontSize: 11)),
                        secondary: Icon(t.icon, size: 18),
                      ),
                  ],
                ),
              ),
              const Divider(),
              SwitchListTile(
                secondary: Icon(
                    active ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                    color: active ? const Color(0xFF6F4E37) : Colors.grey),
                title: const Text('الحساب مفعّل',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    active ? 'يمكنه استخدام التطبيق' : 'معطّل — لن يستطيع الوصول',
                    style: const TextStyle(fontSize: 11)),
                value: active && !isSelf,
                onChanged: isSelf
                    ? null
                    : (v) async {
                        await service.setUserActive(uid, v);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _snack(v ? 'تم تفعيل الحساب' : 'تم تعطيل الحساب');
                        widget.onUpdated();
                      },
              ),
              const Divider(),
              if (!isSelf)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _confirmDelete(context, uid, name);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('حذف المستخدم نهائياً'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _roleHint(String role) {
    switch (role) {
      case 'user':
        return 'تصفح وإضافة محتوى (يُنشر بعد الموافقة)';
      case 'seller':
        return 'فتح متجر ورفع منتجات بعدد صور حسب نوعه';
      case 'moderator':
        return 'مراجعة محتوى الأخبار/السوق/المنتدى';
      case 'medical_admin':
        return 'إدارة المركز الطبي ومراجعة العيادات/الصيدليات/بنك الدم';
      case 'admin':
        return 'كل الصلاحيات + تعيين الأدوار';
      default:
        return '';
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _confirmDelete(
      BuildContext context, String uid, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المستخدم'),
        content: Text('هل أنت متأكد من حذف "$name"؟ لا يمكن التراجع.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await widget.adminService.deleteItem('users', uid);
        widget.onUpdated();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('خطأ: $e')));
        }
      }
    }
  }
}

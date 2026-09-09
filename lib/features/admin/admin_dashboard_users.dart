part of 'admin_dashboard.dart';

// ═══════════════════════════ Users ═══════════════════════════
class _UsersPage extends StatelessWidget {
  const _UsersPage({
    required this.adminService,
    required this.currentUid,
    required this.onUpdated,
  });
  final AdminService adminService;
  final String? currentUid;
  final VoidCallback onUpdated;

  static const _roleOptions = <String, (String, Color)>{
    'user': ('مستخدم', Colors.teal),
    'seller': ('بائع', Colors.deepPurple),
    'moderator': ('مشرف', Colors.orange),
    'medical_admin': ('مدير المركز الطبي', Color(0xFF00897B)),
    'admin': ('مدير', Color(0xFF1565C0)),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: adminService.getAllUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(
              child: Text('لا يوجد مستخدمون',
                  style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final u = users[i];
            final uid = u['id'] as String;
            final role = (u['role'] ?? 'user').toString();
            final sellerType = (u['sellerType'] ?? '').toString();
            final isSelf = uid == currentUid;
            final label = _roleOptions[role]?.$1 ?? 'مستخدم';
            final color = _roleOptions[role]?.$2 ?? Colors.teal;
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.35)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Text(
                      ((u['name']?.toString() ?? '؟').isNotEmpty)
                          ? u['name'].toString().substring(0, 1)
                          : '؟',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, color: color)),
                ),
                title: Text(u['name']?.toString() ?? 'بدون اسم',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                    isSelf
                        ? '${u['email'] ?? ''} • $label (أنت)'
                        : '${u['email'] ?? ''} • $label'
                            '${sellerType.isNotEmpty ? ' • ${_typeLabel(sellerType)}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: Icon(Icons.shield_rounded,
                      color: theme.colorScheme.primary),
                  tooltip: 'إدارة الدور',
                  onPressed: () => _manage(context, uid, role,
                      u['name']?.toString() ?? '', sellerType),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _typeLabel(String t) {
    for (final e in SellerType.values) {
      if (e.name == t) return e.label;
    }
    return t;
  }

  Future<void> _manage(BuildContext context, String uid, String currentRole,
      String name, String currentType) async {
    final service = adminService;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('إدارة: $name',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('الدور',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(ctx).colorScheme.primary)),
              ),
              const SizedBox(height: 4),
              RadioGroup<String>(
                groupValue: currentRole,
                onChanged: (v) async {
                  if (v == null) return;
                  await service.setUserRole(uid, v);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم تعيين الدور: ${_roleOptions[v]!.$1}')));
                  }
                  onUpdated();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final e in _roleOptions.entries)
                      RadioListTile<String>(
                        value: e.key,
                        title: Text(e.value.$1),
                      ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('نوع البائع',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(ctx).colorScheme.secondary)),
              ),
              const SizedBox(height: 4),
              RadioGroup<String>(
                groupValue: currentType.isEmpty ? null : currentType,
                onChanged: (v) async {
                  if (v == null) return;
                  await service.updateUserAccess(uid, sellerType: v);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تحديث نوع البائع')));
                  }
                  onUpdated();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final t in SellerType.values)
                      RadioListTile<String>(
                        value: t.name,
                        title: Text('${t.label} • حتى ${t.maxImages} صور'),
                        secondary: Icon(t.icon, size: 18),
                      ),
                  ],
                ),
              ),
              const Divider(),
              if (uid != currentUid)
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _confirmDelete(context, uid, name);
                  },
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red),
                  label: const Text('حذف المستخدم',
                      style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
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
        await adminService.deleteItem('users', uid);
        onUpdated();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('خطأ: $e')));
        }
      }
    }
  }
}

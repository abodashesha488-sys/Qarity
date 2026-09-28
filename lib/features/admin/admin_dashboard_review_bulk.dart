part of 'admin_dashboard.dart';

// ════════════════ التحديد المتعدد (مستخرج من المراجعة) ════════════════
//
// منطق التحديد الجماعي (select / bulk-approve / bulk-reject / bulk-delete) —
// كان مدمجاً مع قائمة المراجعة في ملف واحد بـ 1100 سطر. هذا الجزء يحوي
// الحالة والشريط الفرعي والأزرار فقط؛ القائمة نفسها تبقى في
// admin_dashboard_review.dart وتتعامل مع هذا المزيج عبر callbacks.
//
// الحماية الذاتية: الإجراءات تُمرر كلها إلى نفس onAction المركزي في
// AdminDashboardScreen الذي يتحقق من الدور (بوابة AdminGuard على المسار
// + قواعد Firestore خلف كل كتابة)، ولا يملك هذا الجزء صلاحية كتابة مباشرة.

/// المفتاح المركّب للتحديد: `مجموعة::معرّف` — في القائمة الموحّدة قد يتكرر
/// نفس المعرّف في مجموعات مختلفة، فلا بد لكل عنصر أن يحمل مجموعته معه.
String selectionKey(Map<String, dynamic> item) {
  final collection = (item['_collection'] as String?)?.isNotEmpty == true
      ? item['_collection'] as String
      : '';
  return '$collection::${item['id']}';
}

/// امتداد يضيف حالة التحديد المتعدد إلى شاشة المراجعة.
///
/// يُستخدم كـ mixin على `_ReviewPageState` حتى تبقى حالة الاختيار محلية
/// للتبويب (لا تتسرب إلى تبويبات أخرى) ولا تحتاج لتمريرها عبر البناء.
mixin _ReviewBulkMixin on State<_ReviewPage> {
  final Set<String> selectedIds = {};
  bool isSelectionMode = false;

  void toggleSelection(Map<String, dynamic> item) {
    final key = selectionKey(item);
    setState(() {
      if (selectedIds.contains(key)) {
        selectedIds.remove(key);
        if (selectedIds.isEmpty) isSelectionMode = false;
      } else {
        selectedIds.add(key);
        isSelectionMode = true;
      }
    });
  }

  void clearSelection() {
    setState(() {
      selectedIds.clear();
      isSelectionMode = false;
    });
  }

  /// تنفيذ إجراء جماعي على كل العناصر المحددة. يطلب تأكيداً أولاً،
  /// وسبب رفض إلزامي (notes) كي يصل لمقدم المحتوى.
  Future<void> bulkAction(String action) async {
    if (selectedIds.isEmpty) return;

    final confirm = await _confirmBulkDialog(action);
    if (confirm != true) return;
    if (!mounted) return;

    final notes = action == 'reject'
        ? await widget.notesProvider(context, isReject: true)
        : null;
    if (action == 'reject' && (notes == null || notes.isEmpty)) return;

    for (final key in selectedIds) {
      final separator = key.indexOf('::');
      final collection = separator < 0
          ? widget.selected
          : (key.substring(0, separator).isEmpty
              ? widget.selected
              : key.substring(0, separator));
      final id = separator < 0 ? key : key.substring(separator + 2);
      try {
        await widget.onAction(collection, id, action);
      } catch (_) {
        // نكمل بقية العناصر حتى لو فشل أحدها (قواعد ترفضه مثلاً)
      }
    }

    clearSelection();
    widget.onItemChanged();
  }

  Future<bool?> _confirmBulkDialog(String action) {
    final verb = action == 'approve'
        ? 'الموافقة على'
        : action == 'reject'
            ? 'رفض'
            : 'حذف';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد $verb الجماعي'),
        content: Text(
            'سيتم $verb ${selectedIds.length} عنصر. هل أنت متأكد؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: action == 'delete' ? Colors.red : null),
            child: Text(action == 'approve'
                ? 'موافقة'
                : action == 'reject'
                    ? 'رفض'
                    : 'حذف'),
          ),
        ],
      ),
    );
  }

  /// شريط التحديد الفرعي: عدد المحدد + أزرار موافقة/رفض/حذف/إلغاء.
  Widget buildSelectionToolbar(ThemeData theme) {
    return Row(
      children: [
        Text('${selectedIds.length} محدد',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _bulkBtn('موافقة', Icons.check_rounded, const Color(0xFF6F4E37),
                    () => bulkAction('approve')),
                const SizedBox(width: 8),
                _bulkBtn('رفض', Icons.close_rounded, Colors.orange,
                    () => bulkAction('reject')),
                const SizedBox(width: 8),
                _bulkBtn('حذف', Icons.delete_rounded, Colors.red,
                    () => bulkAction('delete')),
                const SizedBox(width: 8),
                _bulkBtn('إلغاء', Icons.clear_rounded, Colors.grey,
                    clearSelection),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bulkBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

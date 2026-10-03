import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// صفا «تعديل / حذف» الموحّد لإضافة مستخدم في شاشات التفاصيل.
///
/// لا يُرسم شيء لمن ليس صاحب الإضافة (ولا لمن لا إضافة له أصلًا بمعرّف فارغ)،
/// و`isAdmin` توسّع الرؤية للإدارة حيث يسمح قسمها بذلك نصًا (الإعلانات والمحامين
/// والاستشارات). الحذف يمرّ بتأكيد صريح ثم شريط نتيجة صادق: نجاحٌ يذكر الاسم،
/// ورفضٌ يقول «تحقّق من الصلاحيات» — ولا رسالة نجاح على مسار فشل.
class OwnerActions extends StatefulWidget {
  const OwnerActions({
    super.key,
    required this.ownerId,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
    this.editLabel = 'تعديل',
    this.deleteLabel = 'حذف',
    this.isAdmin = false,
    this.itemName = '',
    this.keyTag,
  });

  final String ownerId;
  final String currentUserId;
  final VoidCallback onEdit;

  /// ينفّذ الحذف ويعيد `true` عند نجاح مؤكد. يرمِ استثناءً أو يعيد `false` عند
  /// الرفض، والعنصر يتكفّل بالإبلاغ.
  final Future<bool> Function() onDelete;

  final String editLabel;
  final String deleteLabel;
  final bool isAdmin;

  /// اسم العنصر في نصّي التأكيد والنجاح («سيُحذف «…» نهائيًا»).
  final String itemName;

  /// لاحق لمفاتيح الاختبار عند وجود أكثر من صف في شجرة واحدة.
  final String? keyTag;

  @visibleForTesting
  static bool canManage(String ownerId, String currentUserId, bool isAdmin) =>
      isAdmin || (ownerId.isNotEmpty && currentUserId == ownerId);

  @override
  State<OwnerActions> createState() => _OwnerActionsState();
}

class _OwnerActionsState extends State<OwnerActions> {
  bool _busy = false;

  Key _k(String suffix) =>
      ValueKey<String>('${widget.keyTag ?? 'owner'}-$suffix');

  Future<void> _confirmAndDelete() async {
    final messenger = ScaffoldMessenger.of(context);
    final item = widget.itemName.trim();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف ${item.isEmpty ? 'الإضافة' : '«$item»'}'),
        content: Text(item.isEmpty
            ? 'سيُحذف هذا العنصر نهائيًا ولن يظهر لأحد.'
            : 'سيُحذف «$item» نهائيًا ولن يظهر لأحد.'),
        actions: [
          TextButton(
            key: _k('delete-cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            key: _k('delete-confirm'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true || _busy) return;
    setState(() => _busy = true);
    bool deleted = false;
    try {
      deleted = await widget.onDelete();
    } catch (_) {
      deleted = false;
    }
    if (mounted) setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(
      content: Text(deleted
          ? (item.isEmpty ? 'تم الحذف' : 'تم حذف «$item»')
          : 'تعذّر الحذف — تحقّق من الصلاحيات أو من الاتصال ثم أعد المحاولة.'),
      backgroundColor: deleted ? AppColors.primary : AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!OwnerActions.canManage(
        widget.ownerId, widget.currentUserId, widget.isAdmin)) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: _k('edit'),
            onPressed: _busy ? null : widget.onEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(widget.editLabel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            key: _k('delete'),
            onPressed: _busy ? null : _confirmAndDelete,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: Text(widget.deleteLabel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}

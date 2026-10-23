import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../core/constants/app_colors.dart';
import '../core/utils/helpers.dart';

/// خدمة الإشراف وحماية المستخدمين (مطابقة لشروط Google Play للمحتوى المنشأ بواسطة المستخدمين UGC)
/// توفر: الإبلاغ عن المحتوى المسيء وحظر المستخدمين المزعجين محلياً.
class ModerationService {
  ModerationService._();
  static final ModerationService instance = ModerationService._();

  static const String _kBlockedUsersKey = 'ugc_blocked_user_ids';

  Set<String>? _cachedBlockedIds;

  /// قائمة معرفات المستخدمين المحظورين محلياً
  Future<Set<String>> getBlockedUserIds() async {
    if (_cachedBlockedIds != null) return _cachedBlockedIds!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kBlockedUsersKey) ?? <String>[];
      _cachedBlockedIds = list.toSet();
      return _cachedBlockedIds!;
    } catch (_) {
      return <String>{};
    }
  }

  /// هل المستخدم محظور؟
  bool isUserBlockedSync(String userId) {
    return _cachedBlockedIds?.contains(userId) ?? false;
  }

  /// حظر مستخدم
  Future<void> blockUser({
    required BuildContext context,
    required String userId,
    required String userName,
    VoidCallback? onBlocked,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حظر $userName؟'),
        content: const Text(
          'عند حظر هذا المستخدم، لن تظهر لك أي منشورات أو تعليقات منشورة بواسطته.\n'
          'يمكنك دائماً إلغاء الحظر لاحقاً.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('تأكيد الحظر', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final set = await getBlockedUserIds();
      set.add(userId);
      await prefs.setStringList(_kBlockedUsersKey, set.toList());
      _cachedBlockedIds = set;

      if (context.mounted) {
        AppHelpers.showToast('تم حظر المستخدم ولن تظهر لك منشوراته');
      }
      onBlocked?.call();
    } catch (e) {
      if (context.mounted) {
        AppHelpers.showToast('تعذر الحظر: $e', isError: true);
      }
    }
  }

  /// إلغاء حظر مستخدم
  Future<void> unblockUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final set = await getBlockedUserIds();
      set.remove(userId);
      await prefs.setStringList(_kBlockedUsersKey, set.toList());
      _cachedBlockedIds = set;
    } catch (_) {}
  }

  /// إرسال بلاغ عن محتوى مسيء
  Future<void> reportContent({
    required BuildContext context,
    required String targetType, // 'forum_post' | 'comment' | 'product' | 'chat'
    required String targetId,
    required String authorId,
    required String authorName,
    String? contentSnippet,
  }) async {
    final reasons = [
      'محتوى مسيء أو غير لائق أخلاقياً',
      'إزعاج، احتيال أو بريد عشوائي (Spam)',
      'معلومات مضللة أو إشاعات',
      'خطاب كراهية، تنمر أو مضايقة',
      'انتهاك للخصوصية أو نشر بيانات شخصية',
      'أخرى',
    ];

    String? selectedReason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.report_problem_rounded, color: AppColors.error, size: 22),
              SizedBox(width: 8),
              Text('إبلاغ عن محتوى مسيء'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سيتم مراجعة هذا البلاغ بواسطة مشرفي التطبيق لحماية المجتمع ومطابقة إرشادات النشر.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'سبب الإبلاغ:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ...reasons.map(
                  (r) => RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(r, style: const TextStyle(fontSize: 13)),
                    value: r,
                    // ignore: deprecated_member_use
                    groupValue: selectedReason,
                    // ignore: deprecated_member_use
                    onChanged: (val) => setDialogState(() => selectedReason = val),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('إرسال البلاغ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedReason == null) return;

    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await FirebaseFirestore.instance.collection('reports').add({
        'targetType': targetType,
        'targetId': targetId,
        'authorId': authorId,
        'authorName': authorName,
        'contentSnippet': contentSnippet ?? '',
        'reason': selectedReason,
        'reporterId': currentUid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تم استلام البلاغ'),
            content: const Text(
              'شكراً لك على حرصك. تم إرسال البلاغ إلى فريق الإشراف وسيقوم بمراجعته فوراً واتخاذ الإجراء اللازم.',
              style: TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppHelpers.showToast('تعذر إرسال البلاغ: $e', isError: true);
      }
    }
  }

  /// زر الخيارات الإشرافية المدمج (إبلاغ / حظر)
  Widget buildMoreOptionsButton({
    required BuildContext context,
    required String targetType,
    required String targetId,
    required String authorId,
    required String authorName,
    String? contentSnippet,
    VoidCallback? onBlocked,
    Color? iconColor,
  }) {
    String? currentUid;
    try {
      currentUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      currentUid = null;
    }
    // لا يظهر خيار الإبلاغ أو الحظر لنفس صاحب المنشور
    if (currentUid != null && currentUid == authorId) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      tooltip: 'خيارات أخرى',
      icon: Icon(Icons.more_vert_rounded, size: 20, color: iconColor),
      onSelected: (value) {
        if (value == 'report') {
          reportContent(
            context: context,
            targetType: targetType,
            targetId: targetId,
            authorId: authorId,
            authorName: authorName,
            contentSnippet: contentSnippet,
          );
        } else if (value == 'block') {
          blockUser(
            context: context,
            userId: authorId,
            userName: authorName,
            onBlocked: onBlocked,
          );
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_rounded, color: AppColors.error, size: 18),
              SizedBox(width: 8),
              Text('إبلاغ عن المحتوى', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              Icon(Icons.block_rounded, color: Colors.grey, size: 18),
              SizedBox(width: 8),
              Text('حظر هذا المستخدم', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

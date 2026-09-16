import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_update_service.dart';

/// مدة تجاهل التحديث الاختياري بعد الضغط على «لاحقًا».
const Duration kUpdateSnooze = Duration(hours: 24);

/// حوارات التحديث الموحّدة — تُستدعى من الإقلاع، الإعدادات، والقائمة الجانبية.
class UpdateDialogs {
  UpdateDialogs._();

  /// فحص صامت عند الإقلاع — لا يزعج المستخدم إلا عند وجود شيء حقيقي،
  /// ويحترم «لاحقًا» بتجاهل التحديث الاختياري لمدة 24 ساعة لكل إصدار.
  static Future<void> runStartupCheck(BuildContext context) async {
    try {
      final res = await AppUpdateService().check();
      if (res == null || !context.mounted) return;
      final (info, status) = res;
      if (status == UpdateStatus.upToDate) return;
      if (status == UpdateStatus.available) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final last =
              prefs.getInt('update_snooze_${info.androidBuild}') ?? 0;
          final elapsed =
              DateTime.now().millisecondsSinceEpoch - last;
          if (elapsed < kUpdateSnooze.inMilliseconds) return;
        } catch (_) {}
        if (!context.mounted) return;
      }
      await _show(context, info, status);
    } catch (_) {}
  }

  static Future<void> _snooze(int build) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'update_snooze_$build', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// فحص يدوي من الإعدادات/القائمة — يعطي ردًا دائمًا مسموعًا للمستخدم.
  static Future<void> runManualCheck(BuildContext context) async {
    final scaffold = ScaffoldMessenger.maybeOf(context);
    try {
      final res = await AppUpdateService().check();
      if (!context.mounted) return;
      if (res == null) {
        scaffold?.showSnackBar(const SnackBar(
            content: Text('التحديثات على هذا الجهاز تصل تلقائيًا'),
            backgroundColor: Color(0xFF6F4E37)));
        return;
      }
      final (info, status) = res;
      if (status == UpdateStatus.upToDate) {
        scaffold?.showSnackBar(const SnackBar(
            content: Text('✅ أنت على أحدث إصدار'),
            backgroundColor: Color(0xFF00897B)));
        return;
      }
      await _show(context, info, status);
    } catch (_) {
      scaffold?.showSnackBar(const SnackBar(
          content: Text('تعذر التحقق الآن — تحقق من الإنترنت'),
          backgroundColor: Colors.orange));
    }
  }

  static Future<void> _show(
      BuildContext context, AppVersionInfo info, UpdateStatus status) {
    final mandatory =
        status == UpdateStatus.forced || status == UpdateStatus.maintenance;
    final (icon, color, title) = switch (status) {
      UpdateStatus.maintenance => (
          Icons.construction_rounded,
          const Color(0xFFEF6C00),
          'التطبيق قيد الصيانة'
        ),
      UpdateStatus.forced => (
          Icons.error_rounded,
          const Color(0xFFC62828),
          'تحديث إلزامي'
        ),
      _ => (
          Icons.system_update_alt_rounded,
          const Color(0xFF1565C0),
          info.androidVersion.isEmpty
              ? 'تحديث جديد متوفر'
              : 'تحديث جديد — إصدار ${info.androidVersion}'
        ),
    };
    final body = status == UpdateStatus.maintenance
        ? (info.maintenanceMessage.isNotEmpty
            ? info.maintenanceMessage
            : 'نعمل على تحسين التطبيق الآن، سنعود بعد قليل إن شاء الله.')
        : (info.message.isNotEmpty
            ? info.message
            : 'صدرت نسخة جديدة من التطبيق تحمل تحسينات وإصلاحات.');

    return showDialog<void>(
      context: context,
      barrierDismissible: !mandatory,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 17)),
            ),
          ],
        ),
        content: Text(body,
            style: const TextStyle(
                fontSize: 13.5, height: 1.7, fontWeight: FontWeight.w600)),
        actions: [
          if (!mandatory)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _snooze(info.androidBuild);
              },
              child: const Text('لاحقًا'),
            ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 13),
            ),
            onPressed: status == UpdateStatus.maintenance
                ? () => Navigator.pop(ctx)
                : () async {
                    Navigator.pop(ctx);
                    final url = info.androidUrl.trim();
                    if (url.isEmpty) return;
                    try {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
            icon: status == UpdateStatus.maintenance
                ? const Icon(Icons.check_rounded, size: 18)
                : const Icon(Icons.download_rounded, size: 18),
            label: Text(
                status == UpdateStatus.maintenance
                    ? 'حسنًا'
                    : 'تنزيل التحديث',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

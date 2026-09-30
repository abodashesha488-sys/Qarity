import 'package:flutter/material.dart';

import '../core/utils/helpers.dart';
import '../services/update_service.dart';

/// تنفيذ التحديث بعد أن يوافق المستخدم على الحوار: تنزيل بمؤشّر تقدّم، ثم طلب
/// إذن «تثبيت من هذا المصدر» إن كان ناقصًا، ثم فتح مثبّت أندرويد.
///
/// مسار واحد تمرّ منه الفحوصات الثلاثة (الإقلاع، بطاقة الإعدادات، درج الرئيسية)
/// حتى لا يكتفي زر «تحديث الآن» بإغلاق الحوار بلا أي إجراء.
class UpdateFlow {
  UpdateFlow._();

  static bool _inFlight = false;

  /// `service` seam للاختبارات بلا شبكة ولا قناة أصل — الإنتاج يمرّره null.
  static Future<void> install(
    BuildContext context,
    UpdateInfo info, {
    UpdateService? service,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    final updates = service ?? UpdateService();
    try {
      final result = await showDialog<UpdateInstallResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            DownloadProgressDialog(apkUrl: info.apkUrl, service: updates),
      );

      if (result == null || !result.isSuccess) {
        AppHelpers.showToast('تعذر تنزيل التحديث. حاول مرة أخرى.', isError: true);
        return;
      }

      final apkPath = result.apkPath;
      if (apkPath == null) {
        AppHelpers.showToast('تعذر تنزيل التحديث.', isError: true);
        return;
      }

      AppHelpers.showToast('جاري فتح مثبت التطبيقات...');

      if (!await updates.canInstallPackages()) {
        AppHelpers.showToast(
          'يتوجب عليك السماح بتثبيت التطبيقات من هذا المصدر.',
          isError: true,
        );
        await updates.openInstallPermissionSettings();
        if (!await updates.canInstallPackages()) {
          AppHelpers.showToast(
            'لم يتم منح الإذن. يمكنك محاولة التحديث لاحقاً من الإعدادات.',
            isError: true,
          );
          return;
        }
      }

      final install = await updates.installApk(apkPath);
      if (!install.isSuccess) {
        AppHelpers.showToast(
          'لم يتم التثبيت. يمكنك محاولة التحديث لاحقاً.',
          isError: true,
        );
      }
    } finally {
      _inFlight = false;
    }
  }
}

/// نافذة التقدّم — تُغلق نفسها عند انتهاء التنزيل وتعيد نتيجة الخدمة.
class DownloadProgressDialog extends StatefulWidget {
  final String apkUrl;
  final UpdateService service;

  const DownloadProgressDialog({
    super.key,
    required this.apkUrl,
    required this.service,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  late final UpdateService _service = widget.service;
  final ValueNotifier<int> _receivedNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int?> _totalNotifier = ValueNotifier<int?>(null);
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    final result = await _service
        .downloadAndInstall(widget.apkUrl, (received, total) {
          if (!mounted) return;
          _receivedNotifier.value = received;
          _totalNotifier.value = total;
        })
        .catchError((Object e) => UpdateInstallResult.failure(e.toString()));

    if (!mounted || _completed) return;
    _completed = true;
    Navigator.pop(context, result);
  }

  @override
  void dispose() {
    _receivedNotifier.dispose();
    _totalNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _receivedNotifier,
      builder: (context, received, _) {
        final total = _totalNotifier.value;
        final downloaded = (received / (1024 * 1024)).toStringAsFixed(1);
        final progressText = total != null && total > 0
            ? '$downloaded MB / ${(total / (1024 * 1024)).toStringAsFixed(1)} MB '
                '(${(received / total * 100).round()}%)'
            : '$downloaded MB';
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'جاري تنزيل التحديث...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
              ),
            ],
          ),
          content: Text(progressText, style: const TextStyle(fontSize: 14)),
        );
      },
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

enum DialogResult { updateNow, later }

class UpdateInfo {
  final int versionCode;
  final String versionName;
  final String apkUrl;
  final bool forceUpdate;
  final String releaseNotes;

  const UpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    required this.forceUpdate,
    required this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> j) => UpdateInfo(
        versionCode: j['versionCode'] as int? ?? 0,
        versionName: j['versionName'] as String? ?? '',
        apkUrl: j['apkUrl'] as String? ?? '',
        forceUpdate: j['forceUpdate'] as bool? ?? false,
        releaseNotes: j['releaseNotes'] as String? ?? '',
      );
}

class UpdateService {
  static const String _updateUrl =
      'https://raw.githubusercontent.com/abodashesha488-sys/Qarity/main/update.json';
  static const Duration _headerTimeout = Duration(seconds: 10);
  static const Duration _streamReadTimeout = Duration(seconds: 30);
  static const String _apkFileName = 'Qarity_update.apk';
  static const String _channel = 'com.qarity/update';

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<UpdateInfo?> fetchUpdateInfo() async {
    if (!_isAndroid) return null;
    try {
      final response = await http
          .get(Uri.parse(_updateUrl))
          .timeout(_headerTimeout);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final info = UpdateInfo.fromJson(json);
      if (info.versionCode <= 0 || info.apkUrl.isEmpty) return null;
      return info;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isUpdateAvailable() async {
    if (!_isAndroid) return false;
    try {
      final pkg = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(pkg.buildNumber) ?? 0;
      final info = await fetchUpdateInfo();
      if (info == null) return false;
      return info.versionCode > currentBuild;
    } catch (_) {
      return false;
    }
  }

  Future<UpdateInfo?> getUpdateInfo() async {
    if (!_isAndroid) return null;
    try {
      final pkg = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(pkg.buildNumber) ?? 0;
      final info = await fetchUpdateInfo();
      if (info == null) return null;
      if (info.versionCode <= currentBuild) return null;
      return info;
    } catch (_) {
      return null;
    }
  }

  Future<UpdateInstallResult> downloadAndInstall(
    String apkUrl,
    void Function(int received, int? total) onProgress,
  ) async {
    final sw = Stopwatch()..start();
    debugPrint('[UPDATE] download start at ${sw.elapsed.inMilliseconds}ms');
    if (apkUrl.isEmpty) {
      debugPrint('[UPDATE][ERROR] type=empty_url');
      return UpdateInstallResult.failure('URL فارغ');
    }
    if (!_isAndroid) {
      debugPrint('[UPDATE][ERROR] type=not_android');
      return UpdateInstallResult.failure('غير مدعوم على هذا الجهاز');
    }

    debugPrint('[UPDATE] URL = $apkUrl');

    Directory cacheDir;
    try {
      cacheDir = await getTemporaryDirectory();
      debugPrint('[UPDATE] cacheDir = ${cacheDir.path} at ${sw.elapsed.inMilliseconds}ms');
    } catch (e, st) {
      debugPrint('[UPDATE][ERROR] type=get_temp_dir message=$e');
      debugPrint('[UPDATE][ERROR] stack=$st');
      return UpdateInstallResult.failure('تعذر الوصول للتخزين المؤقت');
    }

    if (cacheDir.path.isEmpty) {
      debugPrint('[UPDATE][ERROR] type=empty_cache_dir');
      return UpdateInstallResult.failure('تعذر العثور على مجلد التخزين المؤقت');
    }

    final File apkFile = File('${cacheDir.path}/$_apkFileName');
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(apkUrl));
      debugPrint('[UPDATE] request created at ${sw.elapsed.inMilliseconds}ms');
      debugPrint('[UPDATE] waiting for response...');
      final streamedResponse =
          await client.send(request).timeout(_headerTimeout);
      debugPrint('[UPDATE] response received at ${sw.elapsed.inMilliseconds}ms');
      debugPrint('[UPDATE] status = ${streamedResponse.statusCode}');
      debugPrint('[UPDATE] contentLength = ${streamedResponse.contentLength}');

      if (streamedResponse.statusCode != 200) {
        await _deleteFile(apkFile);
        debugPrint('[UPDATE][ERROR] type=bad_status status=${streamedResponse.statusCode}');
        return UpdateInstallResult.failure(
            'فشل التحميل: رمز الحالة ${streamedResponse.statusCode}');
      }

      final int? totalBytes = streamedResponse.contentLength;

      debugPrint('[UPDATE] opening file at ${sw.elapsed.inMilliseconds}ms');
      final sink = apkFile.openWrite();
      int receivedBytes = 0;
      bool completed = false;

      try {
        debugPrint('[UPDATE] starting stream read at ${sw.elapsed.inMilliseconds}ms');
        await for (final chunk
            in streamedResponse.stream.timeout(_streamReadTimeout)) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          debugPrint('[UPDATE] progress: received=$receivedBytes total=$totalBytes at ${sw.elapsed.inMilliseconds}ms');
          onProgress(receivedBytes, totalBytes);
        }
        await sink.flush();
        await sink.close();
        completed = true;
        debugPrint('[UPDATE] stream completed at ${sw.elapsed.inMilliseconds}ms');
        debugPrint('[UPDATE] file closed at ${sw.elapsed.inMilliseconds}ms');
      } on TimeoutException {
        await sink.flush();
        await sink.close();
        await _deleteFile(apkFile);
        debugPrint('[UPDATE][ERROR] type=stream_timeout at ${sw.elapsed.inMilliseconds}ms');
        return UpdateInstallResult.failure('انتهت مهلة التنزيل');
      } catch (e, st) {
        await sink.flush();
        await sink.close();
        await _deleteFile(apkFile);
        debugPrint('[UPDATE][ERROR] type=stream_write message=$e');
        debugPrint('[UPDATE][ERROR] stack=$st');
        return UpdateInstallResult.failure('فشل أثناء كتابة الملف');
      }

      if (!completed || !await apkFile.exists() || await apkFile.length() == 0) {
        await _deleteFile(apkFile);
        debugPrint('[UPDATE][ERROR] type=empty_file');
        return UpdateInstallResult.failure('الملف فارغ أو تالف');
      }

      debugPrint('[UPDATE] calling installApk at ${sw.elapsed.inMilliseconds}ms');
      return UpdateInstallResult.success(apkFile.path);
    } on TimeoutException {
      await _deleteFile(apkFile);
      debugPrint('[UPDATE][ERROR] type=header_timeout at ${sw.elapsed.inMilliseconds}ms');
      return UpdateInstallResult.failure('انتهت مهلة الاتصال');
    } catch (e, st) {
      await _deleteFile(apkFile);
      debugPrint('[UPDATE][ERROR] type=send_error message=$e');
      debugPrint('[UPDATE][ERROR] stack=$st');
      return UpdateInstallResult.failure('تعذر تنزيل التحديث');
    } finally {
      client.close();
      debugPrint('[UPDATE] client closed at ${sw.elapsed.inMilliseconds}ms');
    }
  }

  Future<UpdateInstallResult> installApk(String apkPath) async {
    try {
      const channel = MethodChannel(_channel);
      await channel.invokeMethod('installApk', {
        'apkPath': apkPath,
      });
      return UpdateInstallResult.success(apkPath);
    } on PlatformException catch (e) {
      return UpdateInstallResult.failure(e.message ?? 'فشل التثبيت');
    } catch (e) {
      return UpdateInstallResult.failure(e.toString());
    }
  }

  Future<bool> canInstallPackages() async {
    try {
      const channel = MethodChannel(_channel);
      final result = await channel.invokeMethod('canInstallPackages');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> openInstallPermissionSettings() async {
    try {
      const channel = MethodChannel(_channel);
      await channel.invokeMethod('openInstallPermissionSettings');
    } catch (_) {}
  }

  Future<void> _deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  static Future<DialogResult> showUpdateDialog(
    BuildContext context,
    UpdateInfo info,
  ) async {
    final mandatory = info.forceUpdate;
    return await showDialog<DialogResult>(
      context: context,
      barrierDismissible: !mandatory,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.system_update_alt_rounded,
                color: Color(0xFF1565C0), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'يتوفر تحديث جديد',
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 17),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'يتوفر إصدار جديد من التطبيق: ${info.versionName}',
                style: const TextStyle(
                    fontSize: 13.5, height: 1.7, fontWeight: FontWeight.w600),
              ),
              if (info.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  info.releaseNotes,
                  style: const TextStyle(
                      fontSize: 12.5, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!mandatory)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, DialogResult.later);
              },
              child: const Text('لاحقًا'),
            ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 13),
            ),
            onPressed: () {
              Navigator.pop(ctx, DialogResult.updateNow);
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text(
              'تحديث الآن',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ) ?? DialogResult.later;
  }
}

class UpdateInstallResult {
  final bool isSuccess;
  final String? apkPath;
  final String? errorMessage;

  UpdateInstallResult._({
    required this.isSuccess,
    this.apkPath,
    this.errorMessage,
  });

  factory UpdateInstallResult.success(String apkPath) => UpdateInstallResult._(
        isSuccess: true,
        apkPath: apkPath,
      );

  factory UpdateInstallResult.failure(String errorMessage) =>
      UpdateInstallResult._(
        isSuccess: false,
        errorMessage: errorMessage,
      );
}

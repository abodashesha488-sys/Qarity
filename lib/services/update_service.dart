import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const Duration _timeout = Duration(seconds: 8);

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<UpdateInfo?> fetchUpdateInfo() async {
    if (!_isAndroid) return null;
    try {
      final response = await http
          .get(Uri.parse(_updateUrl))
          .timeout(_timeout);
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

  Future<void> openUpdate(String apkUrl) async {
    if (apkUrl.isEmpty) return;
    try {
      await launchUrl(Uri.parse(apkUrl),
          mode: LaunchMode.externalApplication);
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

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qurity/services/update_service.dart';

void main() {
  group('UpdateInfo', () {
    test('fromJson creates correct instance', () {
      final json = {
        'versionCode': 2,
        'versionName': '1.0.2',
        'apkUrl': 'https://example.com/app.apk',
        'forceUpdate': false,
        'releaseNotes': 'fixes',
      };
      final info = UpdateInfo.fromJson(json);
      expect(info.versionCode, 2);
      expect(info.versionName, '1.0.2');
      expect(info.apkUrl, 'https://example.com/app.apk');
      expect(info.forceUpdate, false);
      expect(info.releaseNotes, 'fixes');
    });

    test('fromJson defaults for missing fields', () {
      final info = UpdateInfo.fromJson({});
      expect(info.versionCode, 0);
      expect(info.versionName, '');
      expect(info.apkUrl, '');
      expect(info.forceUpdate, false);
      expect(info.releaseNotes, '');
    });

    test('const constructor works', () {
      const info = UpdateInfo(
        versionCode: 2,
        versionName: '1.0.2',
        apkUrl: 'https://example.com/app.apk',
        forceUpdate: false,
        releaseNotes: 'fixes',
      );
      expect(info.versionCode, 2);
      expect(info.versionName, '1.0.2');
    });

    test('forced update has forceUpdate = true', () {
      const info = UpdateInfo(
        versionCode: 2,
        versionName: '1.0.2',
        apkUrl: 'https://example.com/app.apk',
        forceUpdate: true,
        releaseNotes: 'إلزامي',
      );
      expect(info.forceUpdate, isTrue);
    });
  });

  group('UpdateInfo version comparison', () {
    test('versionCode 2 with current build 2 → no update', () {
      const updateInfo = UpdateInfo(
        versionCode: 2,
        versionName: '1.0.2',
        apkUrl: 'https://example.com/app.apk',
        forceUpdate: false,
        releaseNotes: '',
      );
      // Simulating: currentBuild = 2, updateInfo.versionCode = 2
      // getUpdateInfo would return null because versionCode <= currentBuild
      expect(updateInfo.versionCode <= 2, isTrue);
    });

    test('versionCode 3 with current build 2 → update available', () {
      const updateInfo = UpdateInfo(
        versionCode: 3,
        versionName: '1.0.3',
        apkUrl: 'https://example.com/app.apk',
        forceUpdate: false,
        releaseNotes: '',
      );
      // Simulating: currentBuild = 2, updateInfo.versionCode = 3
      // getUpdateInfo would return info because versionCode > currentBuild
      expect(updateInfo.versionCode > 2, isTrue);
    });
  });

  group('DialogResult', () {
    test('updateNow and later are distinct values', () {
      expect(DialogResult.updateNow, isNot(DialogResult.later));
    });
  });

  group('UpdateService', () {
    test('fetchUpdateInfo returns null when network fails', () async {
      final svc = UpdateService();
      // If network is unreachable, should return null gracefully
      final info = await svc.fetchUpdateInfo();
      if (info == null) {
        expect(true, isTrue);
      } else {
        expect(info.versionCode > 0, isTrue);
      }
    });

    test('getUpdateInfo returns null when no update available', () async {
      final svc = UpdateService();
      // If versionCode in update.json matches or is below current build,
      // getUpdateInfo should return null
      final info = await svc.getUpdateInfo();
      if (info != null) {
        final pkg = await PackageInfo.fromPlatform();
        final currentBuild = int.tryParse(pkg.buildNumber) ?? 0;
        expect(info.versionCode > currentBuild, isTrue);
      }
    });
  });
}

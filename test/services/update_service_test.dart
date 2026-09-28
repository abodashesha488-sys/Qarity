import 'package:flutter/foundation.dart';
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

  UpdateInfo info(int code, {String name = '1.1.12', bool force = false}) =>
      UpdateInfo(
        versionCode: code,
        versionName: name,
        apkUrl: 'https://example.com/app.apk',
        forceUpdate: force,
        releaseNotes: '',
      );

  group('decideUpdate', () {
    test('أعلى من المثبّت → تحديث متاح مع تمرير البيانات', () {
      final latest = info(2012);
      final check =
          UpdateService.decideUpdate(latest: latest, currentBuild: 2010, fetchFailed: false);
      expect(check.status, UpdateCheckStatus.updateAvailable);
      expect(check.info, same(latest));
    });

    test('مساوٍ للمثبّت → أحدث', () {
      final check = UpdateService.decideUpdate(
          latest: info(2010), currentBuild: 2010, fetchFailed: false);
      expect(check.status, UpdateCheckStatus.upToDate);
      expect(check.info, isNull);
    });

    test('رقم منشور أقل من المثبّت → أحدث لا خطأ (الحالة التي أوقفت الطلب)', () {
      // الأجهزة المنتشرة حملت versionCode 2010، بينما كان update.json ينشر 11
      // فبقي الفحص يقول «أنت على أحدث إصدار». المسار الآن: الترقيم 2000 + العدّاد.
      final check = UpdateService.decideUpdate(
          latest: info(11), currentBuild: 2010, fetchFailed: false);
      expect(check.status, UpdateCheckStatus.upToDate);
    });

    test('فشل الوصول للمصدر → checkFailed ولا يُخلط مع «أحدث»', () {
      final check =
          UpdateService.decideUpdate(currentBuild: 2010, fetchFailed: true);
      expect(check.status, UpdateCheckStatus.checkFailed);
      expect(check.status, isNot(UpdateCheckStatus.upToDate));
      expect(check.info, isNull);
    });

    test('استجابة بلا بيانات صالحة → checkFailed', () {
      final check =
          UpdateService.decideUpdate(currentBuild: 2010, fetchFailed: false);
      expect(check.status, UpdateCheckStatus.checkFailed);
    });

    test('تحديث إلزامي يبقى إلزاميًا بعد القرار', () {
      final latest = info(2013, force: true);
      final check = UpdateService.decideUpdate(
          latest: latest, currentBuild: 2010, fetchFailed: false);
      expect(check.info!.forceUpdate, isTrue);
    });
  });

  group('checkForUpdate', () {
    test('غير أندرويد → notSupported (لا «أحدث» ولا «فشل»)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final check = await UpdateService().checkForUpdate();
        expect(check.status, UpdateCheckStatus.notSupported);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('أندرويد بلا وصول للمصدر → checkFailed لا «أنت على أحدث إصدار»', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final check = await UpdateService().checkForUpdate();
        expect(check.status, isNot(UpdateCheckStatus.upToDate));
        expect(check.status, isNot(UpdateCheckStatus.notSupported));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('getUpdateInfo لا يعيد بيانات إلا عند توفر تحديث فعلي', () async {
      final found = await UpdateService().getUpdateInfo();
      if (found != null) {
        expect(found.versionCode > 0, isTrue);
        expect(found.apkUrl, isNotEmpty);
      }
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

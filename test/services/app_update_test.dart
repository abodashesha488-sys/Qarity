import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/services/app_update_service.dart';

void main() {
  AppVersionInfo v({
    int build = 3,
    int min = 1,
    bool maintenance = false,
  }) =>
      AppVersionInfo(
          androidVersion: '1.0.$build',
          androidBuild: build,
          minBuild: min,
          androidUrl: 'https://x/app.apk',
          maintenance: maintenance);

  group('compareSemver', () {
    test('numeric segments — 1.0.10 beats 1.0.2', () {
      expect(AppUpdateService.compareSemver('1.0.10', '1.0.2'), greaterThan(0));
      expect(AppUpdateService.compareSemver('1.0.2', '1.0.10'), lessThan(0));
      expect(AppUpdateService.compareSemver('1.0.2', '1.0.2'), 0);
      expect(AppUpdateService.compareSemver('1.1.0', '1.0.99'), greaterThan(0));
      expect(AppUpdateService.compareSemver('2.0.0', '1.99.99'), greaterThan(0));
    });
  });

  group('computeStatus', () {
    test('maintenance overrides everything', () {
      expect(
          AppUpdateService.computeStatus(
              currentBuild: 99, v: v(maintenance: true)),
          UpdateStatus.maintenance);
    });
    test('up to date when build >= latest', () {
      expect(AppUpdateService.computeStatus(currentBuild: 3, v: v()),
          UpdateStatus.upToDate);
      expect(AppUpdateService.computeStatus(currentBuild: 9, v: v()),
          UpdateStatus.upToDate);
    });
    test('optional update when newer build exists', () {
      expect(AppUpdateService.computeStatus(currentBuild: 2, v: v()),
          UpdateStatus.available);
    });
    test('forced update when below minBuild', () {
      expect(AppUpdateService.computeStatus(currentBuild: 1, v: v(min: 2)),
          UpdateStatus.forced);
    });
    test('unknown current build never nags', () {
      expect(AppUpdateService.computeStatus(currentBuild: 0, v: v()),
          UpdateStatus.upToDate);
    });
  });

  group('AppUpdateService storage', () {
    test('save then fetch round-trips fields', () async {
      final svc = AppUpdateService(FakeFirebaseFirestore());
      await svc.save(v(build: 5));
      final got = await svc.fetch();
      expect(got, isNotNull);
      expect(got!.androidBuild, 5);
      expect(got.androidVersion, '1.0.5');
      expect(got.androidUrl, 'https://x/app.apk');
      expect(got.maintenance, false);
    });
    test('fetch returns null when not published', () async {
      final svc = AppUpdateService(FakeFirebaseFirestore());
      expect(await svc.fetch(), isNull);
    });
  });
}

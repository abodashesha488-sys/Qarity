import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/navigator_key.dart';
import 'package:qurity/services/update_service.dart';
import 'package:qurity/widgets/update_flow.dart';

/// كل ملف يطرح حوار «يتوفر تحديث جديد» يجب أن يقرأ نتيجة الحوار: نتيجة مهملة
/// تعني زرًا ميتًا (وهي العلّة التي بلّغ عنها المستخدم).
const _kDialogDefinitionFile = 'lib/services/update_service.dart';

/// بديل للخدمة بلا شبكة وبلا قناة أصل: `getTemporaryDirectory` لا يُستكمل أبدًا
/// داخل fake-async، فمسار التنزيل الحقيقي لا يُختبر هنا — المقاس هو ما يفعله
/// المسار بالنتيجة.
class _FakeUpdateService extends UpdateService {
  _FakeUpdateService({
    required this.downloadResult,
    this.installResult,
    this.permissions = const [],
  });

  final UpdateInstallResult downloadResult;
  final UpdateInstallResult? installResult;

  /// نتائج `canInstallPackages` بالترتيب (نفس الإذن يُسأل مرّتين عند الرفض).
  final List<bool> permissions;

  int downloadCalls = 0;
  int permissionCalls = 0;
  int settingsOpens = 0;
  final List<String> installCalls = [];

  @override
  Future<UpdateInstallResult> downloadAndInstall(
    String apkUrl,
    void Function(int received, int? total) onProgress,
  ) async {
    downloadCalls++;
    return downloadResult;
  }

  @override
  Future<bool> canInstallPackages() async {
    final value = permissionCalls < permissions.length
        ? permissions[permissionCalls]
        : true;
    permissionCalls++;
    return value;
  }

  @override
  Future<void> openInstallPermissionSettings() async {
    settingsOpens++;
  }

  @override
  Future<UpdateInstallResult> installApk(String apkPath) async {
    installCalls.add(apkPath);
    return installResult ?? UpdateInstallResult.success(apkPath);
  }
}

void main() {
  const info = UpdateInfo(
    versionCode: 2016,
    versionName: '1.1.16',
    apkUrl: 'https://example.com/Qarity.apk',
    forceUpdate: false,
    releaseNotes: 'اختبار',
  );

  Future<void> pumpHost(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: SizedBox.expand()),
      ),
    );
  }

  /// يقدّم الزمن حتى يُستنفَد شرط الإنهاء: انطباق الحوار يحتاج مدة انتقال،
  /// فالضخّ بلا زمن يترك الرحلة معلّقة.
  Future<void> driveUntil(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 40 && !done(); i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// الأشرطة العربية تصطف في طابور `ScaffoldMessenger` (أربعة ثوانٍ لكلٍّ)،
  /// فبلوغ الشريط الأخير يحتاج زمنًا حقيقيًا لا مجرد إطار.
  Future<void> driveUntilText(WidgetTester tester, String needle) async {
    for (var i = 0; i < 300 && find.textContaining(needle).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  test('عقد المصدر: كل استدعاء لحوار التحديث يقرأ نتيجة «تحديث الآن»', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path == _kDialogDefinitionFile) continue;
      final src = entity.readAsStringSync();
      if (!src.contains('showUpdateDialog(')) continue;
      if (!src.contains('DialogResult.updateNow')) offenders.add(path);
    }
    expect(offenders, isEmpty,
        reason: 'حوار تحديث نتيجته مهملة = زر ميت: ${offenders.join(', ')}');
  });

  testWidgets('«تحديث الآن» يُنزّل ثم يفتح المثبّت بالملف المنزل',
      (tester) async {
    await pumpHost(tester);
    final service =
        _FakeUpdateService(downloadResult: UpdateInstallResult.success('/tmp/Qarity_update.apk'));

    var finished = false;
    UpdateFlow.install(navigatorKey.currentContext!, info, service: service)
        .whenComplete(() => finished = true);

    await tester.pump();
    expect(find.text('جاري تنزيل التحديث...'), findsOneWidget);

    await driveUntil(tester, () => finished);
    expect(finished, isTrue, reason: 'لم تكتمل رحلة التحديث');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('جاري تنزيل التحديث...'), findsNothing);
    expect(service.downloadCalls, 1);
    expect(service.installCalls, ['/tmp/Qarity_update.apk']);
  });

  testWidgets('فشل التنزيل يبلّغ شريطًا عربيًا صريحًا ولا يفتح المثبّت',
      (tester) async {
    await pumpHost(tester);
    final service =
        _FakeUpdateService(downloadResult: UpdateInstallResult.failure('انتهت مهلة التنزيل'));

    var finished = false;
    UpdateFlow.install(navigatorKey.currentContext!, info, service: service)
        .whenComplete(() => finished = true);

    await tester.pump();
    expect(find.text('جاري تنزيل التحديث...'), findsOneWidget);

    await driveUntil(tester, () => finished);
    expect(finished, isTrue);
    await tester.pump();
    expect(find.textContaining('تعذر تنزيل التحديث'), findsOneWidget);
    expect(service.installCalls, isEmpty);
  });

  testWidgets('رفض المثبّت للتاريخ نفسه يبلّغ ولا يبتلع السبب', (tester) async {
    await pumpHost(tester);
    final service = _FakeUpdateService(
      downloadResult: UpdateInstallResult.success('/tmp/Qarity_update.apk'),
      installResult: UpdateInstallResult.failure('INSTALL_FAILED_VERSION_DOWNGRADE'),
    );

    var finished = false;
    UpdateFlow.install(navigatorKey.currentContext!, info, service: service)
        .whenComplete(() => finished = true);

    await tester.pump();
    await driveUntil(tester, () => finished);
    expect(finished, isTrue);
    expect(service.installCalls, ['/tmp/Qarity_update.apk']);

    // الشريط الأخير في الطابور: «جاري فتح المثبّت» ثم سبب عدم التثبيت.
    await driveUntilText(tester, 'لم يتم التثبيت');
    expect(find.textContaining('لم يتم التثبيت'), findsOneWidget);
  });

  testWidgets('بلا إذن تثبيت يُفتح مسار الأذن ولا يُستدعى المثبّت',
      (tester) async {
    await pumpHost(tester);
    final service = _FakeUpdateService(
      downloadResult: UpdateInstallResult.success('/tmp/Qarity_update.apk'),
      permissions: [false, false],
    );

    var finished = false;
    UpdateFlow.install(navigatorKey.currentContext!, info, service: service)
        .whenComplete(() => finished = true);

    await tester.pump();
    await driveUntil(tester, () => finished);
    expect(finished, isTrue);
    await driveUntilText(tester, 'لم يتم منح الإذن');

    expect(service.settingsOpens, 1);
    expect(service.installCalls, isEmpty);
    expect(find.textContaining('لم يتم منح الإذن'), findsOneWidget);
  });

  testWidgets('ضغطة مزدوجة لا تفتح تنزيلين متوازيين', (tester) async {
    await pumpHost(tester);
    final service =
        _FakeUpdateService(downloadResult: UpdateInstallResult.failure('خلل'));

    final ctx = navigatorKey.currentContext!;
    var done = false;
    UpdateFlow.install(ctx, info, service: service).whenComplete(() => done = true);
    UpdateFlow.install(ctx, info, service: service);

    await tester.pump();
    expect(find.text('جاري تنزيل التحديث...'), findsOneWidget);

    await driveUntil(tester, () => done);
    expect(service.downloadCalls, 1);
  });
}

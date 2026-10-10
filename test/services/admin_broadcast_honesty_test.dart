import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// طلب المستخدم الحرفي: «في لوحة التحكم " تبويب الإرسال " يجب ان تقوم هذه الخدمة
/// بارسال رسالة لكل مستخدمين التطبيق، كل شيء مصمم بهذه الصفحة ولكنها لا تنفذ
/// المطلوب ولا يظهر إشعار إذاعي كما خططنا له لكافة المستخدمين».
///
/// العلّتان كانتا في طبقة Dart لا في عامل Vercel (العامل يردّ أصلًا بأكواد JSON
/// معلَّمة، و`all_users` ضمن قائمة المواضيع المقبولة عنده): `_post` كان يتخلّى
/// عن `http.Response` ولا يقرأ `statusCode` ويبتلع كل استثناء، فالواجهة كانت
/// تطبع «تم إرسال الإشعار الإذاعي» على 401 و403 و400 و500 وعلى Timeout وعلى
/// انقطاع الشبكة تمامًا؛ و`broadcastToAllUsers` كان يعلن `bool alert = true`
/// ثم يمرّر `alert: true` حرفيًا فيلغي مفتاح «تنبيه عاجل».
///
/// لذلك يثبت هذا الملف الأمرين معًا: عقد مصدر سطرًا بسطر على الملفَّين، و**بلا**
/// أي عقد يُفنَّد بتعليق عربي — فالتعليقات في هذا المشروع تسمّي النص المحظور
/// حرفيًا ( `{ok:false, error:'fcm_failed'}` عند :147، و«Colors.red» و«خطأ: $e»
/// و«try/catch» في صفحة الإرسال)، فكل negation مقصوص على منطقة الكود وحدها.
void main() {
  String src(String path) => File(path).readAsStringSync();

  /// مقطع مغلق بين وسمين حرفيين — يرمي StateError لا expect لأنه يُنفَّذ وقت
  /// تحميل الملف خارج منطقة الاختبار.
  String slice(String text, String from, String to) {
    final a = text.indexOf(from);
    final b = text.indexOf(to);
    if (a < 0 || b < 0 || b <= a) {
      throw StateError('مقطع مفقود: $from .. $to');
    }
    return text.substring(a, b);
  }

  /// عدد ورود نص حرفي — `split` لا `RegExp.escape` (غير مؤكَّد في هذا SDK)
  /// و`allMatches` ملك `RegExp` لا `String`.
  int count(String text, String pattern) => text.split(pattern).length - 1;

  group('طبقة الخدمة: نتيجة مغلوبة لا استثناء', () {
    late final String service;
    late final String post;
    late final String broadcast;

    setUpAll(() {
      service = src('lib/services/remote_push_service.dart');
      post = slice(service,
          'static Future<PushSendResult> _post(', 'static String? _workerErrorOf');
      broadcast = slice(service, 'static Future<PushSendResult> broadcastToAllUsers(',
          'static Future<void> sendToTokens({');
    });

    test('التسعة حالات مُسمّاة سطرًا بسطر (لا حالة تُسقط Exhaustiveness)', () {
      for (final status in [
        'sent',
        'noEndpoint',
        'noSession',
        'timeout',
        'network',
        'rejected',
        'badRequest',
        'serverFailed',
        'badResponse',
      ]) {
        expect(service, contains('  $status,'));
      }
    });

    test('`isSent` مشتق من الحالة لا من الرمي', () {
      expect(
          service, contains('bool get isSent => status == PushSendStatus.sent;'));
    });

    test('_post يعيد PushSendResult ولا يرمي: خمسة حراس const', () {
      expect(service, contains('static Future<PushSendResult> _post('));
      expect(post, contains('return const PushSendResult(PushSendStatus.noEndpoint);'));
      expect(count(post, 'return const PushSendResult(PushSendStatus.noSession);'),
          equals(2));
      expect(post, contains('return const PushSendResult(PushSendStatus.timeout);'));
      expect(post, contains('return const PushSendResult(PushSendStatus.network);'));
      expect(post, contains('} on TimeoutException {'));
    });

    test('رموز الوضع تُترجم واحدًا لواحد داخل _post وحده', () {
      expect(post, contains('final workerError = _workerErrorOf(response.body);'));
      expect(post, contains('final code = response.statusCode;'));
      expect(post, contains('if (code >= 200 && code < 300) {'));
      expect(post, contains('if (code == 401 || code == 403) {'));
      expect(post, contains('if (code == 400) {'));
      expect(post, contains('if (code >= 500) {'));
      expect(post, contains('PushSendStatus.sent, statusCode: code'));
      expect(post, contains('PushSendStatus.rejected'));
      expect(post, contains('PushSendStatus.badRequest'));
      expect(post, contains('PushSendStatus.serverFailed'));
      expect(post, contains('PushSendStatus.badResponse'));
    });

    test('200 بلا error كنجاح، و200 مع error كإخفاق خادمي', () {
      expect(post, contains('if (workerError != null) {'));
      expect(post, contains('return PushSendResult(PushSendStatus.serverFailed,'));
      expect(post, contains('return PushSendResult(PushSendStatus.sent, statusCode: code);'));
    });

    test('العامل يُقرأ مفتاح error من JSON فقط، وغير JSON لا يُفسَّر', () {
      expect(service, contains('static String? _workerErrorOf(String body) {'));
      expect(service, contains("if (decoded is Map && decoded['error'] is String) {"));
    });

    test('البثّ يستهدف all_users ويمرّر alert المُرسل لا حرفيًا', () {
      expect(broadcast, contains("topic: 'all_users',"));
      expect(broadcast, contains('alert: alert,'));
      // النص القديم الذي كان يلغي المفتاح: لا يعود أبدًا.
      expect(service, isNot(contains('التنبيهات الإذاعية')));
    });

    test('نقطتا best-effort بقيتا Future<void> (لا كسر لأي مُنادٍ)', () {
      expect(service, contains('static Future<void> notifyAdmins(String collection) async {'));
      expect(service, contains('static Future<void> notifyLikeOwner({'));
    });
  });

  group('واجهة لوحة التحكم: لا نجاح على مسار فاشل', () {
    late final String page;

    setUpAll(() {
      page = src('lib/features/admin/admin_dashboard_broadcast.dart');
    });

    test('النتيجة تُقرأ من الناتج، ولا try/catch كان فرعًا ميتًا', () {
      expect(page,
          contains('final result = await RemotePushService.broadcastToAllUsers('));
      expect(page, contains('alert: _sendAlert,'));
      expect(page, isNot(contains('try {')));
      expect(page, isNot(contains('} catch (e) {')));
      expect(page, isNot(contains("Text('\u062e\u0637\u0623: \$e'")));
    });

    test('النجاح يُطبع على isSent وحده، والشريط يُفرَّغ قبله', () {
      expect(page,
          contains('final messenger = ScaffoldMessenger.of(context)..clearSnackBars();'));
      expect(page, contains('if (result.isSent) {'));
      expect(page, contains('messenger.showSnackBar('));
      expect(page, contains('setState(() => _isSending = false);'));
    });

    test('تسع عبارات فشل مستقلة — بـswitch expression لا بخرائط خام', () {
      expect(page, contains('String _broadcastFailureText(PushSendResult result) {'));
      expect(page, contains("const prefix = '\u0644\u0645 \u064a\u064f\u0631\u0633\u0644 \u0627\u0644\u0625\u0634\u0639\u0627\u0631 \u2014 ';"));
      expect(page, contains(r"return '$prefix$reason';"));
      expect(page, contains('final reason = switch (result.status) {'));
      for (final status in [
        'sent',
        'noEndpoint',
        'noSession',
        'timeout',
        'network',
        'rejected',
        'badRequest',
        'serverFailed',
        'badResponse',
      ]) {
        expect(page, contains('PushSendStatus.$status =>'));
      }
      expect(count(page, 'PushSendStatus.sent =>'), equals(1));
    });

    test('لا أرقام داخلية في الشريط: رمز الوضع وخيط العامل خارج الواجهة', () {
      expect(page, isNot(contains('result.statusCode')));
      expect(page, isNot(contains('result.workerError')));
      expect(page, isNot(contains('statusCode')));
      expect(page, isNot(contains('workerError')));
    });

    test('مفتاح «تنبيه عاجل» يحدّد النص واللون معًا', () {
      expect(page, contains('SwitchListTile('));
      expect(page, contains('_sendAlert'));
      expect(page, contains("'\u062a\u0645 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0625\u0634\u0639\u0627\u0631 \u0627\u0644\u0625\u0630\u0627\u0639\u064a \u0644\u062c\u0645\u064a\u0639 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645\u064a\u0646\${_sendAlert ? ' (\u062a\u0646\u0628\u064a\u0647 \u0639\u0627\u062c\u0644)' : ''}'"));
    });
  });
}

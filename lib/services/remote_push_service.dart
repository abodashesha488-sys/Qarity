import 'dart:convert';

import 'package:http/http.dart' as http;

/// يرسل طلب push إلى Vercel Worker (`api/push.js`) ليوصل FCM إلى كل
/// الأجهزة المشتركة في topic محدد.
///
/// يعمل فقط إذا تم ضبط كلا القيمتين وقت البناء:
/// ```
/// flutter build web \
///   --dart-define=PUSH_ENDPOINT=https://qarity-push.vercel.app/api/push \
///   --dart-define=PUSH_SHARED_SECRET=<same-secret-as-vercel-env>
/// ```
/// وإلا فإن إرسال Push يُتخطى بصمت (لن يؤثر على بقية التطبيق).
class RemotePushService {
  RemotePushService._();

  static const String endpoint = String.fromEnvironment('PUSH_ENDPOINT');
  static const String sharedSecret = String.fromEnvironment('PUSH_SHARED_SECRET');

  /// هل الإعداد مكتمل؟ (يستخدم للاختبار ولتفعيل/تعطيل الواجهة)
  static bool get isConfigured => endpoint.isNotEmpty && sharedSecret.isNotEmpty;

  /// أرسل إشعار FCM لـ topic. فشل الشبكة يُبتلع (best-effort).
  static Future<void> send({
    required String topic,
    required String title,
    required String body,
    String? route,
  }) async {
    if (!isConfigured) return;
    try {
      await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer $sharedSecret',
            },
            body: jsonEncode({
              'topic': topic,
              'title': title,
              'body': body,
              if (route != null) 'route': route,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // لا يُطاح الاستثناء — الإشعارات أفضل-جهد.
    }
  }
}

/// خريطة مجموعة Firestore → Topic FCM الخاص بها.
/// تُستخدم في `AdminService` عند الموافقة/النشر.
const Map<String, String> kPushTopicForCollection = {
  'news': 'village_news',
  'obituaries': 'village_obituaries',
  'occasions': 'village_occasions',
  'market_products': 'village_market',
  'forum_posts': 'village_forum',
  'service_requests': 'village_services',
  'shops': 'village_market',
  'village_clinics': 'village_medical',
  'pharmacies': 'village_medical',
  'medical_center_clinics': 'village_medical',
  'blood_requests': 'village_medical',
  'blood_donors': 'village_medical',
};

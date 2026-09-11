import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// يرسل طلب دفع إشعارات إلى Vercel Worker (`api/push.js`).
///
/// المصادقة الآن **بدون أي سر في البناء**: نُرفق Firebase ID Token للمستخدم
/// المسجّل حالياً، والخادم يتحقق منه ثم من دوره (`admin` / `medical_admin`)
/// في Firestore قبل الإرسال.
///
/// العنوان الافتراضي مضمّن في الكود؛ يمكن تجاوزه فقط عند الحاجة:
/// `--dart-define=PUSH_ENDPOINT=https://...` (اختياري تماماً).
class RemotePushService {
  RemotePushService._();

  static const String endpoint = String.fromEnvironment(
    'PUSH_ENDPOINT',
    defaultValue: 'https://qarity.vercel.app/api/push',
  );

  /// أرسل إشعار FCM إلى topic — best-effort (أخطاء الشبكة تُبتلع بصمت).
  /// يُتخطى بهدوء إذا لم يكن هناك مستخدم مسجّل دخوله (المتلقي لا يرسل أصلاً).
  static Future<void> send({
    required String topic,
    required String title,
    required String body,
    String? route,
  }) =>
      _post({'topic': topic}, title, body, route);

  /// إشعار شخصي لجهاز محدد عبر FCM registration token
  /// (مثلاً: إخطار صاحب المحتوى عند الموافقة على منشوره أو رفضه).
  static Future<void> sendToDevice({
    required String fcmToken,
    required String title,
    required String body,
    String? route,
  }) {
    if (fcmToken.isEmpty) return Future.value();
    return _post({'token': fcmToken}, title, body, route);
  }

  static Future<void> _post(
      Map<String, dynamic> target, String title, String body, String? route) async {
    if (endpoint.isEmpty) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) return;
      await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              ...target,
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
  'service_providers': 'village_services',
  'shops': 'village_market',
  'village_clinics': 'village_medical',
  'pharmacies': 'village_medical',
  'medical_center_clinics': 'village_medical',
  'blood_requests': 'village_medical',
  'blood_donors': 'village_medical',
};

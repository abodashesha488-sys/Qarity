import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// نتيجة محاولة الدفع إلى العامل — **لا تُرمى الاستثناءات أبدًا**.
enum PushSendStatus {
  /// العامل ردّ 2xx: الرسالة قُبلت وأُرسلت إلى FCM.
  sent,

  /// `PUSH_ENDPOINT` فارغ — لا وجه للإرسال أصلًا.
  noEndpoint,

  /// لا مستخدم مسجّل دخوله أو لا ID Token — المتلقي هنا هو المُرسل.
  noSession,

  /// مهلة الثواني الثماني.
  timeout,

  /// فشل شبكة (DNS/انقطاع/عدم وصول للعامل).
  network,

  /// العامل رفض المصادقة أو الدور (401 / 403).
  rejected,

  /// العامل رفض الطلب بـ400 — موضوع غير مسموح أو نص ناقص.
  badRequest,

  /// العامل أو FCM فشل (5xx).
  serverFailed,

  /// ردّ ليس JSON معروفًا — لا يُبلَّغ كنجاح.
  badResponse,
}

/// ما يعيده `_post`: الحالة + رمز الوضع + نص خطأ العامل الخام إن وُجد.
class PushSendResult {
  const PushSendResult(this.status, {this.statusCode, this.workerError});

  final PushSendStatus status;
  final int? statusCode;

  /// مفتاح `error` الذي ردّ به العامل (`missing_id_token` / `forbidden_role` /
  /// `invalid_topic` / `fcm_failed` …) — يُقرأ للواجهات الصادقة وللتشخيص.
  final String? workerError;

  bool get isSent => status == PushSendStatus.sent;
}

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

  /// أرسل إشعار FCM إلى topic — لا يرمي استثناءً أبدًا، بل يعيد الحالة.
  /// المتصفحون على `await` دون قراءة النتيجة يحتفظون بسلوك أفضل-جهد السابق؛
  /// من يريد الإبلاغ الصادق (كلوحة التحكم) يقرأ `PushSendResult`.
  /// عند تمرير collection+itemId يصبح النقر على الإشعار موجهاً للعنصر نفسه.
  /// `alert: true` يطلب من الخادم أولوية قصوى + صوت + اهتزاز (تنبيه عاجل).
  static Future<PushSendResult> send({
    required String topic,
    required String title,
    required String body,
    String? route,
    String? collection,
    String? itemId,
    bool alert = false,
  }) =>
      _post({'topic': topic}, title, body, route,
          collection: collection, itemId: itemId, alert: alert);

  /// إشعار شخصي لجهاز محدد عبر FCM registration token
  /// (مثلاً: إخطار صاحب المحتوى عند الموافقة على منشوره أو رفضه).
  static Future<PushSendResult> sendToDevice({
    required String fcmToken,
    required String title,
    required String body,
    String? route,
    String? collection,
    String? itemId,
  }) {
    if (fcmToken.isEmpty) {
      return Future.value(
          const PushSendResult(PushSendStatus.badRequest, workerError: 'empty_token'));
    }
    return _post({'token': fcmToken}, title, body, route,
        collection: collection, itemId: itemId);
  }

  /// نقطة الخروج الوحيدة إلى عامل Vercel. **لا ترمي أبدًا**: كل عطل يُترجم
  /// إلى `PushSendStatus` + رمز الوضع + مفتاح `error` الذي ردّ به العامل،
  /// حتى لا تستطيع أي واجهة أن تطبع «تم الإرسال» على مسار فاشل.
  static Future<PushSendResult> _post(
      Map<String, dynamic> target, String title, String body, String? route,
      {String? collection, String? itemId, bool alert = false}) async {
    if (endpoint.isEmpty) {
      return const PushSendResult(PushSendStatus.noEndpoint);
    }
    final http.Response response;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return const PushSendResult(PushSendStatus.noSession);
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        return const PushSendResult(PushSendStatus.noSession);
      }
      response = await http
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
              if (collection != null && collection.isNotEmpty)
                'collection': collection,
              if (itemId != null && itemId.isNotEmpty) 'itemId': itemId,
              if (alert) 'alert': true,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      return const PushSendResult(PushSendStatus.timeout);
    } catch (_) {
      return const PushSendResult(PushSendStatus.network);
    }

    final workerError = _workerErrorOf(response.body);
    final code = response.statusCode;
    if (code >= 200 && code < 300) {
      // العامل قد يردّ 200 مع `{ok:false, error:'fcm_failed'}` أو بثrottled —
      // فلا يُبلَّغ أي ردّ فيه مفتاح خطأ صريح كنجاح كامل.
      if (workerError != null) {
        return PushSendResult(PushSendStatus.serverFailed,
            statusCode: code, workerError: workerError);
      }
      return PushSendResult(PushSendStatus.sent, statusCode: code);
    }
    if (code == 401 || code == 403) {
      return PushSendResult(PushSendStatus.rejected,
          statusCode: code, workerError: workerError);
    }
    if (code == 400) {
      return PushSendResult(PushSendStatus.badRequest,
          statusCode: code, workerError: workerError);
    }
    if (code >= 500) {
      return PushSendResult(PushSendStatus.serverFailed,
          statusCode: code, workerError: workerError);
    }
    return PushSendResult(PushSendStatus.badResponse,
        statusCode: code, workerError: workerError);
  }

  /// مفتاح `error` في ردّ العامل إن كان JSONًا يحويه، وإلا null.
  static String? _workerErrorOf(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // ردّ غير JSON (بوابة/HTML) — المعالجة في رمز الوضع وحده.
    }
    return null;
  }

  /// إخطار الأدمن (ومدير المركز الطبي للطلبات الطبية) بأن طلباً جديداً
  /// بانتظار الموافقة. تُرسل المجموعة فقط — النصوص والحد المعدني يحددهما
  /// الخادم. best-effort: لا يعطّل الإرسال الرئيسي أبداً.
  static Future<void> notifyAdmins(String collection) async {
    if (endpoint.isEmpty || !kAdminNotifyCollections.contains(collection)) {
      return;
    }
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
              'action': 'admin_notify',
              'collection': collection,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// إخطار صاحب محتوى قابل للإعجاب (حالياً: منشور المنتدى) بأن أحدهم أعجب
  /// به. التوصيل بالكامل **خادمي** عبر عامل Vercel: قواعد Firestore ترفض
  /// أن يكتب مستخدم إشعاراً موجّهاً لمستخدم آخر، فالعامل يستخدم admin SDK
  /// الذي يتجاوزها بأمان، ويتحقق أن المُرسل فعلًا داخل `likedBy` قبل الإرسال.
  /// best-effort: لا يعطّل الإعجاب أبدًا، ويتخطى بهدوء دون مستخدم مسجّل.
  static Future<void> notifyLikeOwner({
    required String collection,
    required String itemId,
  }) async {
    if (endpoint.isEmpty || !kUserNotifyCollections.contains(collection)) {
      return;
    }
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
              'action': 'user_notify',
              'collection': collection,
              'itemId': itemId,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // الإشعارات أفضل-جهد
    }
  }

  /// إرسال إشعار إذاعي (Broadcast) لجميع المستخدمين — يرسل عبر Topic
  /// "all_users" الذي يشترك فيه كل مستخدم عند إكمال ملفه وعند فتح الرئيسية.
  /// يمكن للأدمن استخدامه لإرسال إعلانات عاجلة لجميع المستخدمين حتى لو كان
  /// التطبيق مغلقاً.
  ///
  /// `alert` تُمرَّر كما استلمها المٌستدعي — فمفتاح «تنبيه عاجل» في لوحة
  /// التحكم يعني فعليًا صوتًا + اهتزازًا + أولوية قصوى، ولا يعني ذلك سِرًّا
  /// عندما يُطفأ. الحالة المعادة تُقرأ في اللوحة لتُبلَّغ بصدق.
  static Future<PushSendResult> broadcastToAllUsers({
    required String title,
    required String body,
    String? route,
    String? collection,
    String? itemId,
    bool alert = true,
  }) =>
      // Topic "all_users" الذي يشترك فيه جميع المستخدمين عند إكمال الملف
      // وعند كل فتح للشاشة الرئيسية.
      send(
        topic: 'all_users',
        title: title,
        body: body,
        route: route,
        collection: collection,
        itemId: itemId,
        alert: alert,
      );

  /// إرسال إشعار لمجموعة مستخدمين محددة عبر FCM tokens
  static Future<void> sendToTokens({
    required List<String> tokens,
    required String title,
    required String body,
    String? route,
    String? collection,
    String? itemId,
    bool alert = true,
  }) async {
    if (tokens.isEmpty || endpoint.isEmpty) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) return;

      // نرسل دفعات من 500 توكن كحد أقصى (حد FCM)
      const batchSize = 500;
      for (var i = 0; i < tokens.length; i += batchSize) {
        final batch = tokens.skip(i).take(batchSize).toList();
        final target = {'tokens': batch};
        await _post(target, title, body, route,
            collection: collection, itemId: itemId, alert: true);
      }
    } catch (_) {
      // لا يُطاح الاستثناء — الإشعارات أفضل-جهد.
    }
  }
}

/// المجموعات التي تستدعي موافقة الأدمن — أي إرسال منها يفعّل إخطار اللوحة.
const Set<String> kAdminNotifyCollections = {
  'news',
  'market_products',
  'obituaries',
  'occasions',
  'forum_posts',
  'shops',
  'buy_requests',
  'donations',
  'phone_directory',
  'service_providers',
  'lost_items',
  'village_ads',
  'lawyers',
  'legal_consultations',
  'seller_requests',
  'village_clinics',
  'pharmacies',
  'medical_labs',
  'optical_shops',
  'blood_requests',
  'blood_donors',
  'medical_center_clinics',
  'village_contributions',
};

/// المجموعات التي يدعمها إجراء `user_notify` (إخطار صاحب المحتوى بالإعجاب).
/// قائمة بيضاء مزدوجة (عميل + خادم) كطبقة دفاع إضافية — مثل kAdminNotifyCollections.
const Set<String> kUserNotifyCollections = {
  'forum_posts',
};

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
  'lost_items': 'village_services',
  'village_ads': 'village_market',
  'lawyers': 'village_services',
  // `legal_consultations` عمدًا بلا موضوع: نص السؤال يصل القرية كاملة في
  // الإشعار، والاستشارة قد تحمل تفاصيل شخصية — تُنشر داخل التبويب فقط.
  'shops': 'village_market',
  'village_clinics': 'village_medical',
  'pharmacies': 'village_medical',
  'medical_labs': 'village_medical',
  'optical_shops': 'village_medical',
  'medical_center_clinics': 'village_medical',
  'blood_requests': 'village_medical',
  'blood_donors': 'village_medical',
};

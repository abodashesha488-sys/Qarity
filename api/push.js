// Vercel Serverless Function — بوابة إرسال إشعارات FCM لأهل القرية.
//
// الأمان (بدون أي سر في البناء):
//   1) يطلب التطبيق `Authorization: Bearer <Firebase ID Token>` لتسجيل الدخول الحالي.
//   2) نتحقق من التوكن بـ firebase-admin (وأنه لم يُلغَ).
//   3) نقرأ users/{uid} من Firestore ونقبل فقط إذا role == 'admin' أو 'medical_admin'.
//   => أي شخص غير أدمن مسجّل دخول لا يستطيع إرسال أي إشعار، ولا يوجد secret
//      ليُضبط أو يُسرّب أو يُدوَّر.
//
// متغيّر Vercel المطلوب الوحيد:
//   FIREBASE_SERVICE_ACCOUNT : نص JSON لمفتاح حساب الخدمة (أو Base64 منه).
//
// مثال الاستدعاء (يُنشئه تلقائياً lib/services/remote_push_service.dart):
//   POST https://qarity.vercel.app/api/push
//   Authorization: Bearer <idToken>
//   { "topic": "village_news", "title": "📰 خبر جديد", "body": "...", "route": "/news" }

import admin from 'firebase-admin';

const ALLOWED_ROLES = ['admin', 'medical_admin'];

// أنواع الطلبات التي تستدعي موافقة الأدمن — النصوص تُبنى هنا حصراً
// (لا يقبل الخادم نصاً من العميل في وضع admin_notify، فلا حقن أو سبام).
// medical:true => يُبلَّغ بها مدير المركز الطبي أيضاً.
const PENDING_KINDS = {
  news: { t: '📰 خبر جديد بانتظار المراجعة', b: 'أرسل أحد الأهالي خبراً جديداً للوحة التحكم.' },
  market_products: { t: '🛒 منتج جديد بانتظار المراجعة', b: 'أضاف بائع منتجاً جديداً للسوق.' },
  obituaries: { t: '⚰️ نعي جديد بانتظار المراجعة', b: 'تم إرسال نعي جديد لسجل العزاء.' },
  occasions: { t: '🎉 مناسبة جديدة بانتظار المراجعة', b: 'أضاف أحد الأهالي مناسبة جديدة.' },
  forum_posts: { t: '💬 منشور جديد بانتظار المراجعة', b: 'منشور جديد في المنتدى.' },
  shops: { t: '🏬 طلب إنشاء محل بانتظار المراجعة', b: 'أنشأ أحد الأهالي محلاً جديداً في السوق.' },
  buy_requests: { t: '📥 طلب سلعة جديد بانتظار المراجعة', b: 'طلب أحد الأهالي سلعة جديدة.' },
  donations: { t: '🎁 عرض تبرع جديد بانتظار المراجعة', b: 'أضاف أحد الأهالي عرض تبرع.' },
  phone_directory: { t: '📞 جهة اتصال جديدة بانتظار المراجعة', b: 'طلب إضافة جديد لدليل الهاتف.' },
  service_providers: { t: '🧰 إضافة جديدة بدليل الخدمات', b: 'إضافة جديدة في دليل الخدمات بانتظار المراجعة.' },
  seller_requests: { t: '🏪 طلب بائعية جديد', b: 'قدّم أحد الأهالي طلباً لفتح متجر.' },
  village_clinics: { t: '🏥 عيادة جديدة بانتظار المراجعة', b: 'إضافة جديدة لعيادات القرية.', medical: true },
  pharmacies: { t: '💊 صيدلية جديدة بانتظار المراجعة', b: 'إضافة جديدة لصيدليات القرية.', medical: true },
  medical_labs: { t: '🧪 معمل تحاليل جديد بانتظار المراجعة', b: 'إضافة جديدة لمعامل التحاليل.', medical: true },
  blood_requests: { t: '🩸 طلب تبرع دم جديد', b: 'طلب تبرع دم جديد يحتاج موافقتك.', medical: true },
  blood_donors: { t: '❤️ تسجيل متبرع جديد', b: 'متبرع جديد بانتظار الموافقة.', medical: true },
  medical_center_clinics: { t: '🏥 عيادة مركزية جديدة بانتظار موافقتك', b: 'مدير المركز الطبي أضاف عيادة جديدة للمركز الخيري.' },
};

let appReady = false;

function ensureAdmin() {
  if (appReady) return;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) throw new Error('FIREBASE_SERVICE_ACCOUNT env var is missing');
  let credential;
  try {
    credential = JSON.parse(raw);
  } catch {
    const decoded = Buffer.from(raw, 'base64').toString('utf8');
    credential = JSON.parse(decoded);
  }
  admin.initializeApp({
    credential: admin.credential.cert(credential),
    projectId: credential.project_id,
  });
  admin.firestore(); // تُهيّأ مرة واحدة هنا
  appReady = true;
}

// السماح بكل origins لأن الاستدعاء من تطبيق Flutter (وليس متصفح).
function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

export default async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });

  try { ensureAdmin(); } catch (e) {
    return res.status(500).json({ error: 'admin_init_failed', message: e.message });
  }

  // 1) التحقق من هوية المرسل عبر Firebase ID Token
  const auth = req.headers['authorization'] || '';
  const idToken = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  if (!idToken) return res.status(401).json({ error: 'missing_id_token' });

  let decoded;
  try {
    decoded = await admin.auth().verifyIdToken(idToken, /* checkRevoked */ true);
  } catch {
    return res.status(401).json({ error: 'invalid_id_token' });
  }

  const body = req.body || {};

  // ────────── وضع إخطار الأدمن بطلب جديد يحتاج موافقة ──────────
  // مسموح لأي مستخدم مسجّل دخول (هذا وضع الإرسال من شاشات الإضافة).
  // الحماية: مجموعة نصية مسموحة فقط + نص ثابت من الخادم + حد معدل
  // 3 دقائق لكل نوع، فلا يمكن إغراق الأدمن برسائل عشوائية.
  if (body.action === 'admin_notify') {
    const kind = PENDING_KINDS[String(body.collection || '')];
    if (!kind) return res.status(400).json({ error: 'unknown_collection' });
    try {
      const rlRef = admin
        .firestore()
        .collection('push_rate')
        .doc(`admin_notify_${body.collection}`);
      const now = Date.now();
      const snap = await rlRef.get();
      if (snap.exists && now - (snap.data()?.at ?? 0) < 3 * 60 * 1000) {
        return res.status(200).json({ ok: true, throttled: true });
      }
      await rlRef.set({ at: now, by: decoded.uid }, { merge: true });

      const roles = kind.medical ? ['admin', 'medical_admin'] : ['admin'];
      const usersSnap = await admin
        .firestore()
        .collection('users')
        .where('role', 'in', roles)
        .get();

      const seen = new Set();
      const messages = [];
      for (const d of usersSnap.docs) {
        const tok = d.data()?.fcmToken;
        if (!tok || seen.has(tok)) continue;
        seen.add(tok);
        const role = d.data()?.role;
        messages.push({
          token: tok,
          notification: { title: kind.t, body: kind.b },
          data: {
            route:
              role === 'medical_admin' && kind.medical ? '/medical' : '/admin',
          },
          android: {
            priority: 'high',
            notification: { channelId: 'qarity_channel', color: '#1565C0' },
          },
        });
      }
      if (messages.length === 0) {
        return res
          .status(200)
          .json({ ok: true, sent: 0, reason: 'no_admin_tokens' });
      }
      const resp = await admin.messaging().sendEach(messages);
      return res
        .status(200)
        .json({ ok: true, sent: resp.successCount, failed: resp.failureCount });
    } catch (e) {
      return res
        .status(500)
        .json({ error: 'admin_notify_failed', message: e?.message });
    }
  }

  // 2) التحقق من الدور من Firestore (المصدر الوحيد للحقيقة)
  let role;
  try {
    const userDoc = await admin.firestore().collection('users').doc(decoded.uid).get();
    role = userDoc.exists ? userDoc.data()?.role : undefined;
  } catch (e) {
    return res.status(500).json({ error: 'role_lookup_failed', message: e?.message });
  }
  if (!ALLOWED_ROLES.includes(role)) {
    return res.status(403).json({ error: 'forbidden_role' });
  }

  // 3) التحقق من الحمولة ثم الإرسال: إلى topic (جماعي) أو token (شخصي)
  const { topic, token, title, route, data } = body;
  const text = (body.body || '').toString();
  if ((!topic && !token) || !title) {
    return res.status(400).json({ error: 'topic_or_token_and_title_required' });
  }
  if (topic && !/^village_[a-z_]+$/.test(String(topic))) {
    return res.status(400).json({ error: 'invalid_topic' });
  }

  const base = {
    notification: { title: String(title), body: String(text).slice(0, 400) },
    data: {
      ...(data || {}),
      route: route ? String(route) : '',
    },
    android: {
      priority: 'high',
      notification: { channelId: 'qarity_channel', color: '#1B5E20' },
    },
  };

  try {
    const target = token ? { token: String(token) } : { topic };
    const id = await admin.messaging().send({...base, ...target});
    return res.status(200).json({ ok: true, id });
  } catch (e) {
    return res.status(500).json({ error: 'fcm_failed', message: e?.message || String(e) });
  }
}

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
  const body = req.body || {};
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

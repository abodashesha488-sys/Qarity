// Vercel Serverless Function — بدل Firebase Cloud Functions.
// يستقبل طلب POST من تطبيق Flutter عند موافقة الأدمن/النشر، ثم يرسل
// FCM v1 notification إلى Topic محدد باستخدام Service Account (بدون خطة Blaze).
//
// المتطلبات (Environment Variables في Vercel):
//   FIREBASE_SERVICE_ACCOUNT  : نص JSON كامل لملف خدمة الحساب من Firebase Console
//   PUSH_SHARED_SECRET        : سر مشترك يضعه الأدمن أيضاً في build-time بـ
//                               --dart-define=PUSH_SHARED_SECRET=<same-secret>
//
// مثال الاستدعاء من Flutter:
//   POST https://qarity-push.vercel.app/api/push
//   Authorization: Bearer <PUSH_SHARED_SECRET>
//   { "topic": "village_news", "title": "📰 خبر جديد", "body": "...", "route": "/news" }

import admin from 'firebase-admin';

let appReady = false;

function ensureAdmin() {
  if (appReady) return;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) throw new Error('FIREBASE_SERVICE_ACCOUNT env var is missing');
  // قد يُخزَّن JSON كسلسلة أو Base64
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
  appReady = true;
}

// السماح بكل origins لأن الاستدعاء من تطبيق موبايل (وليس من متصفح).
function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

export default async function handler(req, res) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });

  const secret = process.env.PUSH_SHARED_SECRET;
  const auth = req.headers['authorization'] || '';
  const bearer = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  if (!secret || bearer !== secret) {
    return res.status(401).json({ error: 'unauthorized' });
  }

  try { ensureAdmin(); } catch (e) {
    return res.status(500).json({ error: 'admin_init_failed', message: e.message });
  }

  const body = req.body || {};
  const { topic, title, route, data } = body;
  const message = (body.body || '').toString();
  if (!topic || !title) {
    return res.status(400).json({ error: 'topic_and_title_required' });
  }
  if (!/^village_[a-z_]+$/.test(String(topic))) {
    return res.status(400).json({ error: 'invalid_topic' });
  }

  try {
    const id = await admin.messaging().send({
      topic,
      notification: { title: String(title), body: String(message).slice(0, 400) },
      data: {
        ...(data || {}),
        route: route ? String(route) : '',
      },
      android: {
        priority: 'high',
        notification: { channelId: 'qarity_channel', color: '#1B5E20' },
      },
    });
    return res.status(200).json({ ok: true, id });
  } catch (e) {
    return res.status(500).json({ error: 'fcm_failed', message: e?.message || String(e) });
  }
}

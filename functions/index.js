const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Helper to send notification to a topic
async function sendToTopic(topic, title, body, extraData = {}) {
  const message = {
    notification: { title, body },
    data: { ...extraData, topic },
    topic,
  };
  try {
    const response = await admin.messaging().send(message);
    console.log(`✅ Sent notification to ${topic}:`, response);
  } catch (error) {
    console.error(`❌ Error sending to ${topic}:`, error);
  }
}

// News notification
exports.sendNewsNotification = functions.firestore
  .document('news/{newsId}')
  .onCreate(async (snap, context) => {
    const news = snap.data();
    const title = '📰 خبر جديد من القرية';
    const body = news.title || 'خبر جديد';
    await sendToTopic('village_news', title, body, {
      route: '/news',
      type: 'news',
      newsId: context.params.newsId,
    });
  });

// Obituary notification
exports.sendObituaryNotification = functions.firestore
  .document('obituaries/{obituaryId}')
  .onCreate(async (snap, context) => {
    const obituary = snap.data();
    const title = '⚰️ تعزية';
    const body = `انتقل إلى رحمة الله: ${obituary.name || 'شخص'}`;
    await sendToTopic('village_obituaries', title, body, {
      route: '/obituaries',
      type: 'obituary',
      obituaryId: context.params.obituaryId,
    });
  });

// Occasion notification
exports.sendOccasionNotification = functions.firestore
  .document('occasions/{occasionId}')
  .onCreate(async (snap, context) => {
    const occasion = snap.data();
    const title = '🎉 مناسبة جديدة';
    const body = occasion.title || 'مناسبة جديدة';
    await sendToTopic('village_occasions', title, body, {
      route: '/occasions',
      type: 'occasion',
      occasionId: context.params.occasionId,
    });
  });

// Product notification
exports.sendProductNotification = functions.firestore
  .document('market_products/{productId}')
  .onCreate(async (snap, context) => {
    const product = snap.data();
    const title = '🛒 منتج جديد في السوق';
    const body = product.name || 'منتج جديد';
    await sendToTopic('village_market', title, body, {
      route: '/market',
      type: 'product',
      productId: context.params.productId,
    });
  });

// Forum post notification
exports.sendForumPostNotification = functions.firestore
  .document('forum_posts/{postId}')
  .onCreate(async (snap, context) => {
    const post = snap.data();
    const title = '💬 منشور جديد في المنتدى';
    const body = post.content || 'منشور جديد';
    await sendToTopic('village_forum', title, body, {
      route: '/forum',
      type: 'forum',
      postId: context.params.postId,
    });
  });

// Service request notification
exports.sendServiceRequestNotification = functions.firestore
  .document('service_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const request = snap.data();
    const title = '🔔 طلب خدمة جديد';
    const body = request.type || 'طلب خدمة';
    await sendToTopic('village_services', title, body, {
      route: '/services',
      type: 'service',
      requestId: context.params.requestId,
    });
  });


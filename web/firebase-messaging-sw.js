// Firebase Web Push background handler — يشغّل notificationswhen the app is
// closed/foreground-backgrounded on web (PWA). Registered automatically by
// Firebase Messaging's getToken() (requires this exact filename at site root).
// iOS rule: web push notifications require iOS 16.4+ AND the app added to the
// Home Screen (standalone PWA). Config values are the PUBLIC web config only
// (same block as web/index.html) — no private keys live here or in the client.
importScripts(
    'https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts(
    'https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBdb-hIYycWkXUXpHQCe1jxx0i0xvmjwy0',
  authDomain: 'abudshisha.firebaseapp.com',
  projectId: 'abudshisha',
  storageBucket: 'abudshisha.firebasestorage.app',
  messagingSenderId: '339029236820',
  appId: '1:339029236820:web:0774967e360d021caba1c1',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notif = payload.notification || {};
  const data = payload.data || {};
  self.registration.showNotification(notif.title || 'قرية أبوديشيشة', {
    body: notif.body || '',
    icon: 'icons/Icon-192.png',
    badge: 'icons/Icon-192.png',
    tag: 'qarity-push',
    data: { route: data.route || '', collection: data.collection || '', itemId: data.itemId || '' },
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    self.clients
        .matchAll({ type: 'window', includeUncontrolled: true })
        .then((clientList) => {
          for (const client of clientList) {
            if ('focus' in client) return client.focus();
          }
          return self.clients.openWindow('./');
        }),
  );
});

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../core/utils/navigator_key.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(

    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const channel = AndroidNotificationChannel(
      'qarity_channel',
      'إشعارات قرية أبوديشيشة',
      description: 'إشعارات الأخبار والتعازي والمناسبات والسوق',
      importance: Importance.high,
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // التشغيل البارد: التطبيق كان مغلقاً تماماً وفُتح بالضغط على إشعار.
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _openRoute(initialMessage.data['route'] as String?);
      }
    } catch (_) {}

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  // ───────────────── فتح المسار القادم من إشعار ─────────────────
  // قد يصل الطلب قبل أن يصبح الـ Navigator جاهزاً (أثناء الإقلاع)، لذا
  // نخزّن المسار المبدئي ونحاول الانتقال بإعادة محاولات قصيرة.
  static String? _pendingRoute;
  static bool _navigating = false;

  static void _openRoute(String? route) {
    if (route == null || route.isEmpty || route == '/') return;
    _pendingRoute = route;
    _drainPendingRoute();
  }

  static void _drainPendingRoute() {
    if (_navigating) return;
    if (_pendingRoute == null) return;
    _navigating = true;
    _tryNavigate(_pendingRoute!, 0);
  }

  static Future<void> _tryNavigate(String route, int attempt) async {
    // انتظر حتى يتوفّر Navigator (يحدث بعد runApp بلمحة).
    final context = navigatorKey.currentContext;
    if (context == null) {
      if (attempt >= 20) {
        _pendingRoute = null;
        _navigating = false;
        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
      _tryNavigate(route, attempt + 1);
      return;
    }
    // إن كان المسار ما زال معلّقاً (لم يُلغَ أو يُستبدل) انتقل إليه مرة واحدة.
    if (_pendingRoute == route) {
      _pendingRoute = null;
      try {
        Navigator.pushNamed(context, route);
      } catch (_) {
        // مسار غير معروف — تجاهل بأمان.
      }
    }
    _navigating = false;
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (_) {
      debugPrint('Failed to save FCM token');
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    debugPrint('📨 Background notification: ${message.notification?.title}');
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'qarity_channel',
          'إشعارات قرية أبوديشيشة',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF1B5E20),
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: message.data['route'],
    );
  }

  static Future<void> _handleNotificationOpen(RemoteMessage message) async {
    _openRoute(message.data['route'] as String?);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    _openRoute(response.payload);
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to: $topic');
    } catch (_) {
      debugPrint('❌ Failed to subscribe to topic');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (_) {}
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'qarity_channel',
          'إشعارات قرية أبوديشيشة',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}

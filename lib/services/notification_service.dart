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

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToFirestore);
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
    final route = message.data['route'];
    if (route == null) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;
    // ignore: use_build_context_synchronously
    Navigator.pushNamed(context, route);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    final route = response.payload;
    if (route == null) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;
    Navigator.pushNamed(context, route);
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

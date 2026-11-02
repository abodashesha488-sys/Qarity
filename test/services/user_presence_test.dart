import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/services/user_presence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserPresenceService tests', () {
    test('default streams return valid initial fallback values', () async {
      final service = UserPresenceService.instance;

      // onlineUsersStream emits fallback >= 1
      final initialOnline = await service.onlineUsersStream.first;
      expect(initialOnline, greaterThanOrEqualTo(1));

      // totalUsersStream emits fallback >= 19
      final initialTotal = await service.totalUsersStream.first;
      expect(initialTotal, greaterThanOrEqualTo(19));
    });

    test('online status can be observed and lifecycle handled safely', () {
      final service = UserPresenceService.instance;
      expect(service.isOnline, isFalse);

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(service.isOnline, isFalse);
    });

    test('OnlineUserInfo parses model data correctly with role and guest flags', () {
      final user = OnlineUserInfo.fromMap('user_123', {
        'userId': 'user_123',
        'userName': 'أحمد إبراهيم',
        'userPhoto': 'https://example.com/photo.jpg',
        'userRole': 'admin',
        'isGuest': false,
        'platform': 'android',
      });

      expect(user.sessionId, equals('user_123'));
      expect(user.userId, equals('user_123'));
      expect(user.name, equals('أحمد إبراهيم'));
      expect(user.photoUrl, equals('https://example.com/photo.jpg'));
      expect(user.isAdmin, isTrue);
      expect(user.roleLabel, equals('مدير عام'));
      expect(user.isGuest, isFalse);

      final guest = OnlineUserInfo.fromMap('guest_456', {
        'isGuest': true,
        'platform': 'ios',
      });

      expect(guest.name, equals('زائر للتطبيق'));
      expect(guest.photoUrl, isNull);
      expect(guest.isAdmin, isFalse);
      expect(guest.roleLabel, equals('زائر'));
      expect(guest.isGuest, isTrue);
    });

    test('onlineUsersListStream emits non-null stream without crashes', () async {
      final service = UserPresenceService.instance;
      final users = await service.onlineUsersListStream.first;
      expect(users, isA<List<OnlineUserInfo>>());
    });
  });
}

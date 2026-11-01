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
  });
}

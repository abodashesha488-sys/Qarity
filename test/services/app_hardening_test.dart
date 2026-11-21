import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/phone_validator.dart';
import 'package:qurity/services/user_presence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhoneValidator Tests', () {
    test('validates correct Egyptian mobile numbers', () {
      expect(PhoneValidator.isValidEgyptianPhone('01012345678'), isTrue);
      expect(PhoneValidator.isValidEgyptianPhone('01123456789'), isTrue);
      expect(PhoneValidator.isValidEgyptianPhone('01234567890'), isTrue);
      expect(PhoneValidator.isValidEgyptianPhone('01512345678'), isTrue);
      expect(PhoneValidator.isValidEgyptianPhone('+201012345678'), isTrue);
      expect(PhoneValidator.isValidEgyptianPhone('00201012345678'), isTrue);
      expect(PhoneValidator.isValidEgyptianPhone('010 1234 5678'), isTrue);
      expect(PhoneValidator.isValidEgyptianPhone('010-1234-5678'), isTrue);
      expect(PhoneValidator.isValidEgyptianPhone('٠١٠١٢٣٤٥٦٧٨'), isTrue);
    });

    test('rejects invalid mobile numbers', () {
      expect(PhoneValidator.isValidEgyptianPhone(null), isFalse);
      expect(PhoneValidator.isValidEgyptianPhone(''), isFalse);
      expect(PhoneValidator.isValidEgyptianPhone('123'), isFalse);
      expect(PhoneValidator.isValidEgyptianPhone('01312345678'), isFalse); // 013 is landline (Banha), not mobile
      expect(PhoneValidator.isValidEgyptianPhone('01412345678'), isFalse); // 014 doesn't exist
      expect(PhoneValidator.isValidEgyptianPhone('0101234567'), isFalse); // 10 digits
      expect(PhoneValidator.isValidEgyptianPhone('010123456789'), isFalse); // 12 digits
      expect(PhoneValidator.isValidEgyptianPhone('010abcdefgh'), isFalse);
    });

    test('normalizes numbers to standard 01xxxxxxxxx format', () {
      expect(PhoneValidator.normalize('+201012345678'), equals('01012345678'));
      expect(PhoneValidator.normalize('00201123456789'), equals('01123456789'));
      expect(PhoneValidator.normalize('012-3456-7890'), equals('01234567890'));
      expect(PhoneValidator.normalize('٠١٥١٢٣٤٥٦٧٨'), equals('01512345678'));
    });

    test('form validator produces clear arabic messages', () {
      expect(PhoneValidator.validate(null), equals('رقم الهاتف مطلوب'));
      expect(PhoneValidator.validate(''), equals('رقم الهاتف مطلوب'));
      expect(PhoneValidator.validate('123'),
          contains('يرجى إدخال رقم محمول مصري صحيح'));
      expect(PhoneValidator.validate('01012345678'), isNull);
    });
  });

  group('UserPresenceService memoized stream tests', () {
    test('shared streams return consistent broadcast instances', () {
      final service = UserPresenceService.instance;
      final stream1 = service.onlineUsersStream;
      final stream2 = service.onlineUsersStream;

      // Streams are memoized
      expect(identical(stream1, stream2), isTrue);

      final total1 = service.totalUsersStream;
      final total2 = service.totalUsersStream;
      expect(identical(total1, total2), isTrue);
    });
  });

  group('Security & Secrets Hygiene Contract', () {
    test('api/push.js must not contain hardcoded secret fallback keys', () {
      final file = File('api/push.js');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();

      expect(content.contains('OjJA1hedgYv_idsy5jGpFoD6V3s'), isFalse,
          reason: 'Cloudinary API secret must never be committed in code');
      expect(content.contains('cloudinary_not_configured'), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/constants/app_config.dart';
import 'package:qurity/models/market_extra_models.dart';
import 'package:qurity/models/medical_models.dart';

void main() {
  group('Security & AppConfig', () {
    test('imgbbApiKey does not expose hardcoded secret fallback', () {
      expect(AppConfig.imgbbApiKey, isA<String>());
      // Default should be empty string unless passed via dart-define
      expect(AppConfig.imgbbApiKey.contains('5adf17954a21d7d9146824fde7061c6d'), isFalse);
    });
  });

  group('BloodType Medical Compatibility Matrix', () {
    test('O- is universal donor but universal receiver only from O-', () {
      expect(BloodType.oNeg.compatibleDonorTypes, [BloodType.oNeg]);
      expect(BloodType.oNeg.canReceiveFrom(BloodType.oNeg), isTrue);
      expect(BloodType.oNeg.canReceiveFrom(BloodType.oPos), isFalse);
      expect(BloodType.oNeg.canReceiveFrom(BloodType.aPos), isFalse);

      for (final type in BloodType.values) {
        expect(type.canReceiveFrom(BloodType.oNeg), isTrue,
            reason: '${type.code} must be able to receive from universal donor O-');
      }
    });

    test('AB+ is universal recipient', () {
      for (final type in BloodType.values) {
        expect(BloodType.abPos.canReceiveFrom(type), isTrue,
            reason: 'AB+ must be able to receive from ${type.code}');
      }
      expect(BloodType.abPos.compatibleDonorTypes.length, 8);
    });

    test('A+ recipient compatibility', () {
      expect(BloodType.aPos.canReceiveFrom(BloodType.aPos), isTrue);
      expect(BloodType.aPos.canReceiveFrom(BloodType.aNeg), isTrue);
      expect(BloodType.aPos.canReceiveFrom(BloodType.oPos), isTrue);
      expect(BloodType.aPos.canReceiveFrom(BloodType.oNeg), isTrue);

      expect(BloodType.aPos.canReceiveFrom(BloodType.bPos), isFalse);
      expect(BloodType.aPos.canReceiveFrom(BloodType.bNeg), isFalse);
      expect(BloodType.aPos.canReceiveFrom(BloodType.abPos), isFalse);
    });

    test('compatibleSummary formats code list in Arabic', () {
      expect(BloodType.oNeg.compatibleSummary, 'O-');
      expect(BloodType.oPos.compatibleSummary, 'O+، O-');
    });
  });

  group('Donation Financial Transparency Goals', () {
    test('Donation without targetAmount has no financial goal', () {
      const d = Donation(
        id: 'd1',
        userId: 'u1',
        userName: 'أحمد',
        title: 'ملابس شتوية',
      );
      expect(d.hasFinancialGoal, isFalse);
      expect(d.progressRatio, 0.0);
      expect(d.progressPercent, 0);
      expect(d.remainingAmount, 0.0);
    });

    test('Donation with targetAmount calculates progress and remaining correctly', () {
      const d = Donation(
        id: 'd2',
        userId: 'u2',
        userName: 'لجنة الزكاة',
        title: 'مساهمة عملية جراحية',
        targetAmount: 10000,
        collectedAmount: 6500,
        supervisorName: 'أ. محمد إبراهيم',
      );
      expect(d.hasFinancialGoal, isTrue);
      expect(d.progressRatio, 0.65);
      expect(d.progressPercent, 65);
      expect(d.remainingAmount, 3500.0);
      expect(d.supervisorName, 'أ. محمد إبراهيم');
    });

    test('Donation progressRatio clamps to 1.0 even if collected exceeds target', () {
      const d = Donation(
        id: 'd3',
        userId: 'u3',
        userName: 'فاعل خير',
        title: 'كفالة أيتام',
        targetAmount: 5000,
        collectedAmount: 6000,
      );
      expect(d.progressRatio, 1.0);
      expect(d.progressPercent, 100);
      expect(d.remainingAmount, 0.0);
    });

    test('Donation roundtrips targetAmount and supervisorName in JSON', () {
      const d = Donation(
        id: 'd4',
        userId: 'u4',
        userName: 'لجنة المسجد',
        title: 'ترميم وتجهيز',
        targetAmount: 20000,
        collectedAmount: 5000,
        supervisorName: 'الحاج رمضان',
      );
      final json = d.toJson();
      expect(json['targetAmount'], 20000.0);
      expect(json['collectedAmount'], 5000.0);
      expect(json['supervisorName'], 'الحاج رمضان');

      final revived = Donation.fromJson(json, 'd4');
      expect(revived.targetAmount, 20000.0);
      expect(revived.collectedAmount, 5000.0);
      expect(revived.supervisorName, 'الحاج رمضان');
      expect(revived.hasFinancialGoal, isTrue);
      expect(revived.progressPercent, 25);
    });
  });
}


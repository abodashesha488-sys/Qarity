import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/group_deal_model.dart';
import 'package:qurity/services/group_deal_service.dart';

void main() {
  group('GroupDealModel Tests', () {
    test('Calculates financial savings and percentages accurately', () {
      final deal = GroupDealModel(
        id: 'deal_1',
        title: 'كرتونة زيت تمويني',
        description: 'كرتونة زيت ممتازة',
        imageUrl: 'https://example.com/oil.jpg',
        marketPrice: 300.0,
        dealPrice: 240.0,
        depositAmount: 50.0,
        targetCount: 20,
        currentCount: 15,
        endTime: DateTime.now().add(const Duration(days: 2)),
      );

      expect(deal.savingsPerUnit, 60.0);
      expect(deal.discountPercentage, 20); // (60 / 300) * 100 = 20%
      expect(deal.totalVillageSavings,
          900.0); // 15 * 60 = 900 LE saved for village
      expect(deal.totalDealValue, 3600.0); // 15 * 240 = 3600 LE
      expect(deal.totalDepositsCollected, 750.0); // 15 * 50 = 750 LE
      expect(deal.totalRemainingToCollect, 2850.0); // 15 * (240 - 50) = 2850 LE
      expect(deal.progressRatio, 0.75); // 15 / 20 = 75%
      expect(deal.remainingCount, 5); // 20 - 15 = 5
      expect(deal.isAvailableForBooking, isTrue);
    });

    test('Serialization to/from json preserves all properties', () {
      final now = DateTime.now();
      final deal = GroupDealModel(
        id: 'deal_test',
        title: 'شيكارة أرز جملة',
        description: 'أرز بلدي فاخر',
        imageUrl: 'https://example.com/rice.jpg',
        marketPrice: 700.0,
        dealPrice: 550.0,
        depositAmount: 100.0,
        targetCount: 50,
        currentCount: 10,
        endTime: now.add(const Duration(days: 5)),
        unitName: 'شيكارة',
      );

      final json = deal.toJson();
      final reconstructed = GroupDealModel.fromJson(json, 'deal_test');

      expect(reconstructed.id, 'deal_test');
      expect(reconstructed.title, 'شيكارة أرز جملة');
      expect(reconstructed.marketPrice, 700.0);
      expect(reconstructed.dealPrice, 550.0);
      expect(reconstructed.depositAmount, 100.0);
      expect(reconstructed.targetCount, 50);
      expect(reconstructed.currentCount, 10);
      expect(reconstructed.unitName, 'شيكارة');
    });
  });

  group('DealParticipantModel Tests', () {
    test('Calculates participant deposit, total, and balance accurately', () {
      const participant = DealParticipantModel(
        id: 'p_1',
        dealId: 'deal_1',
        userId: 'user_123',
        userName: 'أحمد محمود',
        userPhone: '01012345678',
        quantity: 3,
        claimCode: '5842',
      );

      expect(participant.depositRequired(50.0), 150.0); // 3 * 50 = 150 LE
      expect(participant.totalAmount(240.0), 720.0); // 3 * 240 = 720 LE
      expect(participant.remainingOnDelivery(240.0, 50.0),
          570.0); // 3 * 190 = 570 LE
    });

    test('Serialization of participant preserves claimCode and statuses', () {
      const participant = DealParticipantModel(
        id: 'p_test',
        dealId: 'deal_10',
        userId: 'u_1',
        userName: 'محمود السيد',
        userPhone: '01123456789',
        quantity: 2,
        claimCode: '9123',
        isConfirmedByAdmin: true,
        isDelivered: true,
      );

      final json = participant.toJson();
      final restored = DealParticipantModel.fromJson(json, 'p_test');

      expect(restored.claimCode, '9123');
      expect(restored.isConfirmedByAdmin, isTrue);
      expect(restored.isDelivered, isTrue);
      expect(restored.quantity, 2);
    });
  });

  group('GroupDealFinancialSummary Tests', () {
    test('Calculates full financial balance sheet for deal and participants',
        () {
      final deal = GroupDealModel(
        id: 'deal_1',
        title: 'كرتونة تموين',
        description: 'زيت وسكر',
        imageUrl: '',
        marketPrice: 500.0,
        dealPrice: 400.0, // 100 LE saving
        depositAmount: 100.0,
        targetCount: 10,
        currentCount: 8,
        endTime: DateTime.now().add(const Duration(days: 1)),
      );

      final participants = [
        const DealParticipantModel(
          id: 'p1',
          dealId: 'deal_1',
          userId: 'u1',
          userName: 'علي',
          userPhone: '010',
          quantity: 2,
          claimCode: '1111',
          isConfirmedByAdmin: true,
          isDelivered: true,
        ),
        const DealParticipantModel(
          id: 'p2',
          dealId: 'deal_1',
          userId: 'u2',
          userName: 'حسن',
          userPhone: '011',
          quantity: 3,
          claimCode: '2222',
          isConfirmedByAdmin: true,
        ),
        const DealParticipantModel(
          id: 'p3',
          dealId: 'deal_1',
          userId: 'u3',
          userName: 'إبراهيم',
          userPhone: '012',
          quantity: 2,
          claimCode: '3333',
        ),
      ];

      final summary = GroupDealFinancialSummary.calculate(deal, participants);

      expect(summary.confirmedCount, 5); // 2 + 3 = 5
      expect(summary.unconfirmedCount, 2); // 2
      expect(summary.deliveredCount, 2); // 2
      expect(summary.pendingDeliveryCount, 3); // 3
      expect(summary.savingsPerUnit, 100.0);
      expect(summary.totalVillageSavings, 500.0); // 5 * 100
      expect(summary.totalConfirmedSales, 2000.0); // 5 * 400
      expect(summary.totalDepositsCollected, 500.0); // 5 * 100
      expect(summary.totalRemainingToCollect, 1500.0); // 5 * 300
      expect(summary.totalDeliveredValue, 800.0); // 2 * 400
    });
  });

  group('GroupDealService Generator Tests', () {
    test('generateClaimCode creates 4-digit code between 1000 and 9999', () {
      for (int i = 0; i < 50; i++) {
        final code = GroupDealService.generateClaimCode();
        expect(code.length, 4);
        final numVal = int.tryParse(code);
        expect(numVal, isNotNull);
        expect(numVal! >= 1000 && numVal <= 9999, isTrue);
      }
    });
  });
}

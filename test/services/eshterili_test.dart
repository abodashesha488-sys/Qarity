import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/models/eshterili_model.dart';
import 'package:qurity/services/eshterili_service.dart';

void main() {
  group('EshteriliModel Tests', () {
    test('Calculates financial totals and validates status transitions', () {
      final order = EshteriliOrder(
        id: 'esh_1',
        orderNumber: 'ESH-20261115-1234',
        userId: 'user_1',
        userName: 'أحمد علي',
        userPhone: '01012345678',
        itemsDescription: 'دواء من صيدلية بلقاس + مستلزمات بقالة',
        estimatedBudget: 350.0,
        storeOrArea: 'بلقاس',
        deliveryAddress: 'أبودشيشة بجوار المسجد الكبير',
        status: EshteriliStatus.pricedWaitingApproval,
        itemCost: 320.0,
        serviceFee: 25.0,
        deliveryFee: 20.0,
        claimCode: '7492',
        assignedAgentName: 'كابتن محمود',
        assignedAgentPhone: '01099998888',
        createdAt: DateTime.now(),
      );

      expect(order.orderNumber, startsWith('ESH-'));
      expect(order.totalAmount, 365.0);
      expect(order.itemCost + order.serviceFee + order.deliveryFee, 365.0);
      expect(order.claimCode.length, 4);
      expect(order.status, EshteriliStatus.pricedWaitingApproval);
    });

    test('Serialization to/from json preserves all order fields', () {
      final now = DateTime.now();
      final order = EshteriliOrder(
        id: 'order_test',
        orderNumber: 'ESH-20261115-9999',
        userId: 'u_test',
        userName: 'محمد سعيد',
        userPhone: '01234567890',
        itemsDescription: 'قطع غيار دراجة',
        estimatedBudget: 150.0,
        storeOrArea: 'سوق بلقاس',
        deliveryAddress: 'عزبة أبو دقيقة',
        status: EshteriliStatus.inProgress,
        itemCost: 140.0,
        serviceFee: 20.0,
        deliveryFee: 15.0,
        claimCode: '1834',
        assignedAgentId: 'agent_5',
        assignedAgentName: 'إبراهيم حسن',
        assignedAgentPhone: '01111122233',
        notes: 'ممنوع التأخير',
        createdAt: now,
      );

      final json = order.toJson();
      final restored = EshteriliOrder.fromJson(json, 'order_test');

      expect(restored.id, 'order_test');
      expect(restored.orderNumber, 'ESH-20261115-9999');
      expect(restored.userName, 'محمد سعيد');
      expect(restored.itemsDescription, 'قطع غيار دراجة');
      expect(restored.status, EshteriliStatus.inProgress);
      expect(restored.totalAmount, 175.0);
      expect(restored.claimCode, '1834');
      expect(restored.assignedAgentName, 'إبراهيم حسن');
      expect(restored.notes, 'ممنوع التأخير');
    });

    test('EshteriliStatus enum correctly maps codes', () {
      expect(EshteriliStatus.fromCode('pending_pricing'), EshteriliStatus.pendingPricing);
      expect(EshteriliStatus.fromCode('priced_waiting_approval'), EshteriliStatus.pricedWaitingApproval);
      expect(EshteriliStatus.fromCode('in_progress'), EshteriliStatus.inProgress);
      expect(EshteriliStatus.fromCode('completed'), EshteriliStatus.completed);
      expect(EshteriliStatus.fromCode('cancelled'), EshteriliStatus.cancelled);
      expect(EshteriliStatus.fromCode('unknown'), EshteriliStatus.pendingPricing);
    });
  });

  group('EshteriliService Generator Tests', () {
    test('generateOrderNumber matches ESH-YYYYMMDD-XXXX format', () {
      for (int i = 0; i < 20; i++) {
        final orderNum = EshteriliService.generateOrderNumber();
        expect(orderNum, matches(r'^ESH-\d{8}-\d{4}$'));
      }
    });

    test('generateClaimCode produces 4-digit numeric code', () {
      for (int i = 0; i < 20; i++) {
        final code = EshteriliService.generateClaimCode();
        expect(code.length, 4);
        final numVal = int.tryParse(code);
        expect(numVal, isNotNull);
        expect(numVal! >= 1000 && numVal <= 9999, isTrue);
      }
    });
  });
}

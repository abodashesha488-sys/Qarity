import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/notification_deeplink.dart';

void main() {
  group('NotificationDeepLink', () {
    test('encode builds route|collection|itemId', () {
      expect(NotificationDeepLink.encode('/news', 'news', 'abc'),
          '/news|news|abc');
    });

    test('decode parses a valid deep link', () {
      final d = NotificationDeepLink.decode('/market|market_products|p1');
      expect(d, isNotNull);
      expect(d!.route, '/market');
      expect(d.collection, 'market_products');
      expect(d.itemId, 'p1');
      expect(d.toArgs(), {'route': '/market', 'collection': 'market_products', 'id': 'p1'});
    });

    test('decode returns null for plain route (backward compatible)', () {
      expect(NotificationDeepLink.decode('/news'), isNull);
      expect(NotificationDeepLink.decode('/a|b'), isNull);
      expect(NotificationDeepLink.decode(''), isNull);
      expect(NotificationDeepLink.decode(null), isNull);
    });

    test('decode rejects empty collection/id segments', () {
      expect(NotificationDeepLink.decode('/news||'), isNull);
    });
  });
}

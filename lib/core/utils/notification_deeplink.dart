/// ترميز/فك صيغة التوجيه العميق الموحّدة للإشعارات: `route|collection|itemId`.
/// تُستعمل في حِمل الإشعار المحلي، ومسار صندوق الوارد، وموجّه `/open`.
class NotificationDeepLink {
  NotificationDeepLink._();
  static const String sep = '|';

  static String encode(String route, String collection, String itemId) =>
      '$route$sep$collection$sep$itemId';

  static NotificationRoute? decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final parts = payload.split(sep);
    if (parts.length >= 3 && parts[1].isNotEmpty && parts[2].isNotEmpty) {
      return NotificationRoute(
          route: parts[0], collection: parts[1], itemId: parts[2]);
    }
    return null;
  }
}

class NotificationRoute {
  final String route;
  final String collection;
  final String itemId;
  const NotificationRoute(
      {required this.route,
      required this.collection,
      required this.itemId});

  Map<String, dynamic> toArgs() =>
      {'route': route, 'collection': collection, 'id': itemId};
}

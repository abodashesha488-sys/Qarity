import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../core/constants/promo_placements.dart';
import '../models/promo_model.dart';

/// خدمة الإعلانات الدعائية — القراءة عامة، الكتابة للأدمن (في القواعد).
class PromoService {
  final FirebaseFirestore _firestore;
  PromoService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('promos');

  Stream<List<Promo>> watchAll() {
    return _col.snapshots().map((s) {
      final list = s.docs.map((d) => Promo.fromJson(d.data(), d.id)).toList();
      list.sort((a, b) => b.endsAt.compareTo(a.endsAt));
      return list;
    });
  }

  Future<String> create(Promo promo) async {
    final ref = await _col.add(promo.toJson());
    return ref.id;
  }

  Future<void> update(Promo promo) async {
    await _col.doc(promo.id).update(promo.copyWith(version: promo.version + 1).toJson());
  }

  Future<void> setActive(Promo promo, bool value) async {
    await _col.doc(promo.id).update({'isActive': value});
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}

/// متتبّع موقع المستخدم الحالي داخل التطبيق (لمطابقة أماكن الإعلانات).
class PromoLocation extends ChangeNotifier {
  PromoLocation._();
  static final PromoLocation instance = PromoLocation._();

  String _key = '';
  String get currentKey => _key;

  void update(String key) {
    if (_key == key) return;
    _key = key;
    notifyListeners();
  }
}

/// مراقب ملاحق للتنقّل يحدّث PromoLocation عند كل تغيير في الشاشة العلوية.
class PromoRouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> _stack = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _sync();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.removeWhere((r) => r == route);
    _sync();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.removeWhere((r) => r == route);
    _sync();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _stack.removeWhere((r) => r == oldRoute);
    if (newRoute != null) _stack.add(newRoute);
    _sync();
  }

  void _sync() {
    // الشاشة العلوية فقط هي المعنية — أي شاشة غير مستهدفة توقف الظهور.
    for (var i = _stack.length - 1; i >= 0; i--) {
      final route = _stack[i];
      final name = route.settings.name;
      if (name == null || name.isEmpty) continue;
      PromoLocation.instance.update(
          promoKeyForRoute(name, route.settings.arguments));
      return;
    }
  }
}

/// المراقب الوحيد المسجّل في MaterialApp.
final PromoRouteObserver promoRouteObserver = PromoRouteObserver();

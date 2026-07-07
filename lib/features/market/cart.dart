import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/data_models.dart';

class Cart extends ChangeNotifier {
  Cart._privateConstructor();
  static final Cart instance = Cart._privateConstructor();

  static const String _cartKey = 'cart_items';

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  Future<void> init() async {
    try {
      await _loadCart();
    } catch (e) {
      debugPrint('Cart init failed: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
    }
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cartKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        for (final item in jsonList) {
          try {
            final product = MarketProduct.fromJson(item['product'] as Map<String, dynamic>, '');
            _items.add(CartItem(product: product, quantity: item['quantity'] as int));
          } catch (e) {
            debugPrint('Failed to parse cart item: $e');
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load cart: $e');
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _items.map((item) {
        final productJson = _marketProductToJson(item.product);
        return <String, dynamic>{
          'product': productJson,
          'quantity': item.quantity,
        };
      }).toList();
      await prefs.setString(_cartKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Failed to save cart: $e');
    }
  }

  static Map<String, dynamic> _marketProductToJson(MarketProduct product) {
    final json = product.toJson();
    final result = <String, dynamic>{};
    for (final entry in json.entries) {
      final value = entry.value;
      if (value is DateTime) {
        result[entry.key] = value.toIso8601String();
      } else if (value is Timestamp) {
        result[entry.key] = value.millisecondsSinceEpoch;
      } else {
        result[entry.key] = value;
      }
    }
    return result;
  }

  void add(MarketProduct product) {
    final idx = _items.indexWhere((c) => c.product.id == product.id);
    if (idx >= 0) {
      _items[idx].quantity += 1;
    } else {
      _items.add(CartItem(product: product));
    }
    _saveCart();
    notifyListeners();
  }

  void remove(MarketProduct product) {
    _items.removeWhere((c) => c.product.id == product.id);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(MarketProduct product, int quantity) {
    final idx = _items.indexWhere((c) => c.product.id == product.id);
    if (idx >= 0) {
      if (quantity <= 0) {
        _items.removeAt(idx);
      } else {
        _items[idx].quantity = quantity;
      }
      _saveCart();
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  int get totalItems => _items.fold(0, (s, i) => s + i.quantity);

  int get distinctItemCount => _items.length;

  double get totalPrice =>
      _items.fold(0.0, (s, i) => s + i.quantity * i.product.effectivePrice);

  bool get isEmpty => _items.isEmpty;

  bool contains(MarketProduct product) {
    return _items.any((c) => c.product.id == product.id);
  }
}
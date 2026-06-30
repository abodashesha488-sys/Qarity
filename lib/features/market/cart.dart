import 'dart:convert';
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
    await _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cartKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      for (final item in jsonList) {
        final product = MarketProduct.fromJson(item['product'] as Map<String, dynamic>, '');
        _items.add(CartItem(product: product, quantity: item['quantity'] as int));
      }
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _items.map((item) => {
      'product': item.product.toJson(),
      'quantity': item.quantity,
    }).toList();
    await prefs.setString(_cartKey, json.encode(jsonList));
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

  double get totalPrice =>
      _items.fold(0.0, (s, i) => s + i.quantity * i.product.effectivePrice);

  bool get isEmpty => _items.isEmpty;

  bool contains(MarketProduct product) {
    return _items.any((c) => c.product.id == product.id);
  }
}
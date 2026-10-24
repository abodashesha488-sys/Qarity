import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// عنصر المفضلة الموحّد لكافة محتويات التطبيق
class FavoriteItem {
  final String id;
  final String targetId;
  final String collection; // products, news, technicians, teachers, lawyers, crops, shops, ads
  final String title;
  final String subtitle;
  final String imageUrl;
  final String route;
  final Map<String, dynamic> arguments;
  final DateTime createdAt;

  const FavoriteItem({
    required this.id,
    required this.targetId,
    required this.collection,
    required this.title,
    this.subtitle = '',
    this.imageUrl = '',
    required this.route,
    this.arguments = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetId': targetId,
        'collection': collection,
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'route': route,
        'arguments': arguments,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      collection: json['collection'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      route: json['route'] as String? ?? '',
      arguments: (json['arguments'] as Map<String, dynamic>?) ?? const {},
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// التسمية العربية لقسم المفضلة
  String get collectionLabel {
    switch (collection) {
      case 'products':
        return 'منتجات السوق';
      case 'news':
        return 'الأخبار';
      case 'technicians':
        return 'فنيون وحرفيون';
      case 'teachers':
        return 'المعلمون';
      case 'lawyers':
        return 'المحامون';
      case 'crops':
        return 'دليل المحاصيل';
      case 'shops':
        return 'المحلات';
      case 'ads':
        return 'إعلانات القرية';
      default:
        return 'أخرى';
    }
  }

  /// الأيقونة التعبيرية المناسبة لكل قسم
  String get collectionIcon {
    switch (collection) {
      case 'products':
        return '🛒';
      case 'news':
        return '📰';
      case 'technicians':
        return '🛠️';
      case 'teachers':
        return '🎓';
      case 'lawyers':
        return '⚖️';
      case 'crops':
        return '🌾';
      case 'shops':
        return '🏪';
      case 'ads':
        return '📢';
      default:
        return '⭐';
    }
  }
}

/// خدمة إدارة المفضلة المركزية في التطبيق
class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  final ValueNotifier<List<FavoriteItem>> favoritesNotifier =
      ValueNotifier<List<FavoriteItem>>([]);

  bool _initialized = false;

  String get _storageKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'user_favorites_$uid';
  }

  /// تهيئة الخدمة وتحميل قائمة المفضلة المخزنة
  Future<void> init() async {
    if (_initialized) return;
    await reload();
    _initialized = true;
  }

  /// إعادة قراءة المفضلة من التخزين المحلي
  Future<void> reload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final items = decoded
            .map((e) => FavoriteItem.fromJson(e as Map<String, dynamic>))
            .toList();
        // الأحدث أولاً
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        favoritesNotifier.value = items;
      } else {
        favoritesNotifier.value = [];
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Favorites reload error: $e');
    }
  }

  /// هل العنصر موجود في المفضلة؟
  bool isFavorite(String targetId, String collection) {
    return favoritesNotifier.value
        .any((item) => item.targetId == targetId && item.collection == collection);
  }

  /// إضافة أو إزالة عنصر من المفضلة
  Future<bool> toggleFavorite(FavoriteItem item) async {
    await init();
    final current = List<FavoriteItem>.from(favoritesNotifier.value);
    final index = current.indexWhere((it) =>
        it.targetId == item.targetId && it.collection == item.collection);

    bool nowFavorite;
    if (index >= 0) {
      current.removeAt(index);
      nowFavorite = false;
    } else {
      current.insert(0, item);
      nowFavorite = true;
    }

    favoritesNotifier.value = current;
    await _persist(current);
    return nowFavorite;
  }

  /// حذف عنصر محدد من المفضلة
  Future<void> removeFavorite(String targetId, String collection) async {
    await init();
    final current = List<FavoriteItem>.from(favoritesNotifier.value);
    final beforeCount = current.length;
    current.removeWhere(
        (it) => it.targetId == targetId && it.collection == collection);
    if (current.length != beforeCount) {
      favoritesNotifier.value = current;
      await _persist(current);
    }
  }

  /// جلب عناصر قسم معين أو الكل
  List<FavoriteItem> getFavorites([String? collection]) {
    final all = favoritesNotifier.value;
    if (collection == null || collection.isEmpty || collection == 'all') {
      return all;
    }
    return all.where((it) => it.collection == collection).toList();
  }

  /// حفظ القائمة في SharedPreferences
  Future<void> _persist(List<FavoriteItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      if (kDebugMode) debugPrint('Favorites persist error: $e');
    }
  }

  /// مسح المفضلة بالكامل
  Future<void> clearAll() async {
    favoritesNotifier.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

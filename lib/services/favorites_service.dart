import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  FavoritesService._() {
    _initAuthListener();
  }
  static final FavoritesService instance = FavoritesService._();

  final ValueNotifier<List<FavoriteItem>> favoritesNotifier =
      ValueNotifier<List<FavoriteItem>>([]);

  bool _initialized = false;
  String? _lastLoadedUid;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String? get _currentUid {
    if (!_isFirebaseReady) return null;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  void _initAuthListener() {
    if (!_isFirebaseReady) return;
    try {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        final currentUid = user?.uid ?? 'guest';
        if (_lastLoadedUid != currentUid) {
          _lastLoadedUid = currentUid;
          reload();
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Favorites auth listener error: $e');
    }
  }

  String get _storageKey {
    final uid = _currentUid ?? 'guest';
    return 'user_favorites_$uid';
  }

  /// تهيئة الخدمة وتحميل قائمة المفضلة المخزنة
  Future<void> init() async {
    final currentUid = _currentUid ?? 'guest';
    if (_initialized && _lastLoadedUid == currentUid) return;
    _lastLoadedUid = currentUid;
    await reload();
    _initialized = true;
  }

  /// إعادة قراءة المفضلة من التخزين المحلي والمزامنة مع حساب المستخدم في فيربيز
  Future<void> reload() async {
    List<FavoriteItem> localItems = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        localItems = decoded
            .map((e) => FavoriteItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        localItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        favoritesNotifier.value = localItems;
      } else {
        favoritesNotifier.value = [];
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Favorites local reload error: $e');
    }

    // مزامنة فورية مع سحابة حساب المستخدم إن كان مسجل دخول وفيربيز جاهز
    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty && _isFirebaseReady) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['favorites'] is List) {
            final remoteRaw = data['favorites'] as List;
            final remoteItems = remoteRaw
                .map((e) => FavoriteItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();

            final map = <String, FavoriteItem>{};
            for (final item in remoteItems) {
              map['${item.collection}::${item.targetId}'] = item;
            }
            for (final item in localItems) {
              map.putIfAbsent('${item.collection}::${item.targetId}', () => item);
            }
            final merged = map.values.toList();
            merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            favoritesNotifier.value = merged;

            final prefs = await SharedPreferences.getInstance();
            final rawMerged = jsonEncode(merged.map((e) => e.toJson()).toList());
            await prefs.setString(_storageKey, rawMerged);

            if (merged.length > remoteItems.length) {
              await _syncToRemote(uid, merged);
            }
          } else if (localItems.isNotEmpty) {
            await _syncToRemote(uid, localItems);
          }
        } else if (localItems.isNotEmpty) {
          await _syncToRemote(uid, localItems);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Favorites remote reload error: $e');
      }
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

  /// حفظ القائمة في SharedPreferences وسحابة حساب المستخدم في فيربيز
  Future<void> _persist(List<FavoriteItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      if (kDebugMode) debugPrint('Favorites persist local error: $e');
    }

    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty) {
      await _syncToRemote(uid, items);
    }
  }

  /// مزامنة المفضلة مع وثيقة المستخدم في Firestore
  Future<void> _syncToRemote(String uid, List<FavoriteItem> items) async {
    if (!_isFirebaseReady) return;
    try {
      final jsonList = items.map((e) => e.toJson()).toList();
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'favorites': jsonList,
        'favoritesUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('Favorites sync to Firestore error: $e');
    }
  }

  /// مسح المفضلة بالكامل
  Future<void> clearAll() async {
    favoritesNotifier.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    final uid = _currentUid;
    if (uid != null && uid.isNotEmpty) {
      await _syncToRemote(uid, []);
    }
  }
}

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _prefsKeyProducts = 'cache_products';
  static const _prefsKeyNews = 'cache_news';
  static const _prefsKeyPosts = 'cache_posts';
  static const _prefsKeyUser = 'cache_user_';
  static const _prefsTsSuffix = '_ts';

  static Future<SharedPreferences> get _instance => SharedPreferences.getInstance();

  static Future<void> saveProducts(List<Map<String, dynamic>> data) => _write(_prefsKeyProducts, data);
  static Future<List<Map<String, dynamic>>?> getProducts({Duration maxAge = const Duration(hours: 2)}) => _read(_prefsKeyProducts, maxAge);

  static Future<void> saveNews(List<Map<String, dynamic>> data) => _write(_prefsKeyNews, data);
  static Future<List<Map<String, dynamic>>?> getNews({Duration maxAge = const Duration(hours: 2)}) => _read(_prefsKeyNews, maxAge);

  static Future<void> saveForumPosts(List<Map<String, dynamic>> data) => _write(_prefsKeyPosts, data);
  static Future<List<Map<String, dynamic>>?> getForumPosts({Duration maxAge = const Duration(hours: 2)}) => _read(_prefsKeyPosts, maxAge);

  static Future<void> saveUser(String uid, Map<String, dynamic> data) => _writeSingle('$_prefsKeyUser$uid', data);

  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final raw = await _readRaw('$_prefsKeyUser$uid');
    if (raw == null) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }
  static Future<void> invalidateProducts() => _invalidate(_prefsKeyProducts);
  static Future<void> invalidateNews() => _invalidate(_prefsKeyNews);
  static Future<void> invalidateForumPosts() => _invalidate(_prefsKeyPosts);
  static Future<void> invalidateUser(String uid) => _invalidate('$_prefsKeyUser$uid');

  static Future<void> _write(String key, List<Map<String, dynamic>> data) async {
    final prefs = await _instance;
    final normalized = _normalizeListForCache(data);
    await prefs.setString(key, json.encode(normalized));
    await prefs.setInt('$key$_prefsTsSuffix', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> _writeSingle(String key, Map<String, dynamic> data) async {
    final prefs = await _instance;
    final normalized = _normalizeMapForCache(data);
    await prefs.setString(key, json.encode(normalized));
    await prefs.setInt('$key$_prefsTsSuffix', DateTime.now().millisecondsSinceEpoch);
  }

  static dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is FieldValue) {
      return null;
    }
    if (value is Map) {
      return _normalizeMapForCache(Map<String, dynamic>.from(value));
    }
    if (value is List) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }

  static List<Map<String, dynamic>> _normalizeListForCache(List<Map<String, dynamic>> list) {
    return list.map(_normalizeMapForCache).toList();
  }

  static Map<String, dynamic> _normalizeMapForCache(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      result[entry.key] = _normalizeValue(entry.value);
    }
    return result;
  }

  static Future<List<Map<String, dynamic>>?> _read(String key, Duration maxAge) async {
    final raw = await _readRaw(key);
    if (raw == null) return null;
    try {
      final decoded = List<Map<String, dynamic>>.from(json.decode(raw));
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _readRaw(String key) async {
    final prefs = await _instance;
    final ts = prefs.getInt('$key$_prefsTsSuffix');
    if (ts != null) {
      final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
      if (age > const Duration(hours: 2)) {
        await prefs.remove(key);
        await prefs.remove('$key$_prefsTsSuffix');
        return null;
      }
    }
    return prefs.getString(key);
  }

  static Future<void> _invalidate(String key) async {
    final prefs = await _instance;
    await prefs.remove(key);
    await prefs.remove('$key$_prefsTsSuffix');
  }
}

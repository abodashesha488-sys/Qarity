import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheKeys {
  static const products = 'cache_products';
  static const news = 'cache_news';
  static const forumPosts = 'cache_posts';
  static const obituaries = 'cache_obituaries';
  static const occasions = 'cache_occasions';
  static const emergency = 'cache_emergency';
  static const phone = 'cache_phone';
  static const village = 'cache_village';
  static const shops = 'cache_shops';
  static const donations = 'cache_donations';
  static const buyRequests = 'cache_buy_requests';
  static const medical = 'cache_medical';
}

class CacheService {
  static const _prefsTsSuffix = '_ts';

  static final Map<String, Duration> _ttls = {
    CacheKeys.products: const Duration(hours: 2),
    CacheKeys.news: const Duration(hours: 2),
    CacheKeys.forumPosts: const Duration(hours: 2),
    CacheKeys.obituaries: const Duration(minutes: 30),
    CacheKeys.occasions: const Duration(hours: 1),
    CacheKeys.emergency: const Duration(hours: 24),
    CacheKeys.phone: const Duration(hours: 4),
    CacheKeys.village: const Duration(hours: 24),
    CacheKeys.shops: const Duration(hours: 4),
    CacheKeys.donations: const Duration(hours: 1),
    CacheKeys.buyRequests: const Duration(minutes: 30),
    CacheKeys.medical: const Duration(hours: 4),
  };

  static const _prefsKeyUser = 'cache_user_';

  static Future<SharedPreferences> get _instance => SharedPreferences.getInstance();

  static Duration _ttlFor(String key) => _ttls[key] ?? const Duration(hours: 2);

  static Future<void> saveProducts(List<Map<String, dynamic>> data) => saveList(CacheKeys.products, data);
  static Future<List<Map<String, dynamic>>?> getProducts({Duration maxAge = const Duration(hours: 2)}) => getList(CacheKeys.products, maxAge: maxAge);

  static Future<void> saveNews(List<Map<String, dynamic>> data) => saveList(CacheKeys.news, data);
  static Future<List<Map<String, dynamic>>?> getNews({Duration maxAge = const Duration(hours: 2)}) => getList(CacheKeys.news, maxAge: maxAge);

  static Future<void> saveForumPosts(List<Map<String, dynamic>> data) => saveList(CacheKeys.forumPosts, data);
  static Future<List<Map<String, dynamic>>?> getForumPosts({Duration maxAge = const Duration(hours: 2)}) => getList(CacheKeys.forumPosts, maxAge: maxAge);

  static Future<void> saveObituaries(List<Map<String, dynamic>> data) => saveList(CacheKeys.obituaries, data);
  static Future<List<Map<String, dynamic>>?> getObituaries({Duration maxAge = const Duration(minutes: 30)}) => getList(CacheKeys.obituaries, maxAge: maxAge);

  static Future<void> saveOccasions(List<Map<String, dynamic>> data) => saveList(CacheKeys.occasions, data);
  static Future<List<Map<String, dynamic>>?> getOccasions({Duration maxAge = const Duration(hours: 1)}) => getList(CacheKeys.occasions, maxAge: maxAge);

  static Future<void> saveEmergencyContacts(List<Map<String, dynamic>> data) => saveList(CacheKeys.emergency, data);
  static Future<List<Map<String, dynamic>>?> getEmergencyContacts({Duration maxAge = const Duration(hours: 24)}) => getList(CacheKeys.emergency, maxAge: maxAge);

  static Future<void> savePhoneDirectory(List<Map<String, dynamic>> data) => saveList(CacheKeys.phone, data);
  static Future<List<Map<String, dynamic>>?> getPhoneDirectory({Duration maxAge = const Duration(hours: 4)}) => getList(CacheKeys.phone, maxAge: maxAge);

  static Future<void> saveVillageInfo(Map<String, dynamic> data) => saveSingle(CacheKeys.village, data);
  static Future<Map<String, dynamic>?> getVillageInfo({Duration maxAge = const Duration(hours: 24)}) => getSingle(CacheKeys.village, maxAge: maxAge);

  static Future<void> saveShops(List<Map<String, dynamic>> data) => saveList(CacheKeys.shops, data);
  static Future<List<Map<String, dynamic>>?> getShops({Duration maxAge = const Duration(hours: 4)}) => getList(CacheKeys.shops, maxAge: maxAge);

  static Future<void> saveDonations(List<Map<String, dynamic>> data) => saveList(CacheKeys.donations, data);
  static Future<List<Map<String, dynamic>>?> getDonations({Duration maxAge = const Duration(hours: 1)}) => getList(CacheKeys.donations, maxAge: maxAge);

  static Future<void> saveBuyRequests(List<Map<String, dynamic>> data) => saveList(CacheKeys.buyRequests, data);
  static Future<List<Map<String, dynamic>>?> getBuyRequests({Duration maxAge = const Duration(minutes: 30)}) => getList(CacheKeys.buyRequests, maxAge: maxAge);

  static Future<void> saveMedical(List<Map<String, dynamic>> data) => saveList(CacheKeys.medical, data);
  static Future<List<Map<String, dynamic>>?> getMedical({Duration maxAge = const Duration(hours: 4)}) => getList(CacheKeys.medical, maxAge: maxAge);

  static Future<void> saveUser(String uid, Map<String, dynamic> data) => saveSingle('$_prefsKeyUser$uid', data);

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

  static Future<void> invalidateProducts() => _invalidate(CacheKeys.products);
  static Future<void> invalidateNews() => _invalidate(CacheKeys.news);
  static Future<void> invalidateForumPosts() => _invalidate(CacheKeys.forumPosts);
  static Future<void> invalidateObituaries() => _invalidate(CacheKeys.obituaries);
  static Future<void> invalidateOccasions() => _invalidate(CacheKeys.occasions);
  static Future<void> invalidateEmergencyContacts() => _invalidate(CacheKeys.emergency);
  static Future<void> invalidatePhoneDirectory() => _invalidate(CacheKeys.phone);
  static Future<void> invalidateVillageInfo() => _invalidate(CacheKeys.village);
  static Future<void> invalidateShops() => _invalidate(CacheKeys.shops);
  static Future<void> invalidateDonations() => _invalidate(CacheKeys.donations);
  static Future<void> invalidateBuyRequests() => _invalidate(CacheKeys.buyRequests);
  static Future<void> invalidateMedical() => _invalidate(CacheKeys.medical);
  static Future<void> invalidateUser(String uid) => _invalidate('$_prefsKeyUser$uid');

  static Future<void> saveList(String key, List<Map<String, dynamic>> data) async {
    final prefs = await _instance;
    final normalized = _normalizeListForCache(data);
    await prefs.setString(key, json.encode(normalized));
    await prefs.setInt('$key$_prefsTsSuffix', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<List<Map<String, dynamic>>?> getList(String key, {Duration? maxAge}) async {
    final raw = await _readRaw(key, maxAge ?? _ttlFor(key));
    if (raw == null) return null;
    try {
      final decoded = List<Map<String, dynamic>>.from(json.decode(raw));
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSingle(String key, Map<String, dynamic> data) async {
    final prefs = await _instance;
    final normalized = _normalizeMapForCache(data);
    await prefs.setString(key, json.encode(normalized));
    await prefs.setInt('$key$_prefsTsSuffix', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<Map<String, dynamic>?> getSingle(String key, {Duration? maxAge}) async {
    final raw = await _readRaw(key, maxAge ?? _ttlFor(key));
    if (raw == null) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> invalidate(String key) => _invalidate(key);

  static Future<void> clearAll() async {
    final prefs = await _instance;
    final keys = prefs.getKeys();
    final cacheKeys = keys.where((k) => k.startsWith('cache_')).toList();
    for (final key in cacheKeys) {
      await prefs.remove(key);
    }
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

  static Future<String?> _readRaw(String key, [Duration maxAge = const Duration(hours: 2)]) async {
    final prefs = await _instance;
    final ts = prefs.getInt('$key$_prefsTsSuffix');
    if (ts != null) {
      final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
      if (age > maxAge) {
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

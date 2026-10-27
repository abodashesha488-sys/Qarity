import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_themes.dart';

/// يخزّن اختيارين مستقلين: **العائلة** (ألوان المظهر) و**الوضع** (فاتح/داكن)،
/// فأي تركيبة منهما يختار المستخدم تبقى سارية من أول إقلاع بلا إعادة تشغيل.
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _darkKey = 'dark_mode';

  /// مفتاح المعرّف المجمّد منذ أول حفظ: لو تغيّر النص تقرأ كل الأجهزة العائلة
  /// الافتراضية فينقلب مظهر من اختار سابقًا. [AppThemes.ofId] يسقط إلى
  /// الأخضر البيئي لأي قيمة مجهولة (عائلة حُذفت)، فلا قائمة فارغة ولا تعذّر.
  static const String _familyKey = 'theme_family_id';
  static const String _customThemesKey = 'custom_theme_families_json';

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  AppThemeFamily _family = AppThemes.greenEco;
  AppThemeFamily get family => _family;

  final List<AppThemeFamily> _customFamilies = [];
  List<AppThemeFamily> get customFamilies => List.unmodifiable(_customFamilies);

  /// يُنادى مرة واحدة قبل `runApp`، فيكتب العائلة في [AppColors] قبل أن تُبنى
  /// أي شاشة، فلا يرى المستخدم الأخضر ثم يقفز إلى التراكوتا.
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode =
        (prefs.getBool(_darkKey) ?? false) ? ThemeMode.dark : ThemeMode.light;
    _loadCustomFamilies(prefs);
    final savedId = prefs.getString(_familyKey);
    final customMatch =
        _customFamilies.where((f) => f.id == savedId).firstOrNull;
    if (customMatch != null) {
      _family = customMatch;
    } else {
      _family = AppThemes.ofId(savedId);
    }
    AppThemes.select(_family);
  }

  void _loadCustomFamilies(SharedPreferences prefs) {
    _customFamilies.clear();
    final list = prefs.getStringList(_customThemesKey) ?? [];
    for (final raw in list) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _customFamilies.add(AppThemeFamily.fromJson(map));
      } catch (_) {}
    }
  }

  Future<void> saveCustomTheme(AppThemeFamily family) async {
    final prefs = await SharedPreferences.getInstance();
    _customFamilies.removeWhere((f) => f.id == family.id);
    _customFamilies.add(family);
    final encoded =
        _customFamilies.map((f) => jsonEncode(f.toJson())).toList();
    await prefs.setStringList(_customThemesKey, encoded);
    await setFamily(family);
  }

  Future<void> deleteCustomTheme(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _customFamilies.removeWhere((f) => f.id == id);
    final encoded =
        _customFamilies.map((f) => jsonEncode(f.toJson())).toList();
    await prefs.setStringList(_customThemesKey, encoded);
    if (_family.id == id) {
      await setFamily(AppThemes.greenEco);
    } else {
      notifyListeners();
    }
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
    await prefs.setBool(_darkKey, value);
    notifyListeners();
  }

  Future<void> setFamily(AppThemeFamily family) async {
    final prefs = await SharedPreferences.getInstance();
    _family = family;
    await prefs.setString(_familyKey, family.id);
    // الكتابة في AppColors قبل notifyListeners: ما يصل إلى إعادة البناء يجب أن
    // يجد القيم الجديدة لا القديمة، وإلا ترسم الشجرة عائلة نصفها قديم.
    AppThemes.select(family);
    notifyListeners();
  }

  Future<void> toggleTheme() async => setDarkMode(!isDarkMode);
}

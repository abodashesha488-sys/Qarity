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

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  AppThemeFamily _family = AppThemes.greenEco;
  AppThemeFamily get family => _family;

  /// يُنادى مرة واحدة قبل `runApp`، فيكتب العائلة في [AppColors] قبل أن تُبنى
  /// أي شاشة، فلا يرى المستخدم الأخضر ثم يقفز إلى التراكوتا.
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode =
        (prefs.getBool(_darkKey) ?? false) ? ThemeMode.dark : ThemeMode.light;
    _family = AppThemes.ofId(prefs.getString(_familyKey));
    AppThemes.select(_family);
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

import 'package:flutter/material.dart';

import 'app_themes.dart';

/// واجهة مختصرة على [AppThemes] — أبقيتها للقراءة الخلفية فقط.
///
/// الثيم لم يعد ثابتًا: المستخدم يختار عائلته من «تخصيص مظهر التطبيق» في
/// الإعدادات، فقيمة `AppTheme.lightTheme` الآن هي **الثيم المبني على العائلة
/// المختارة لحظتها** لا مجموعة أرقام مجمّدة. الملفات التي كانت تشير إليها
/// (والاختبارات التي ترسم شاشات فوق `AppTheme.lightTheme`) تعمل كما هي بلا
/// تعديل، وأي كود جديد يفضّل `AppThemes` المباشرة.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => AppThemes.lightTheme;
  static ThemeData get darkTheme => AppThemes.darkTheme;
}

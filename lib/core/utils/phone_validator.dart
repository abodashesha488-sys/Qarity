/// مساعد التحقق وتنسيق أرقام الهواتف المحمولة في جمهورية مصر العربية
class PhoneValidator {
  PhoneValidator._();

  // النمط القياسي للهاتف المحمول المصري: 11 رقماً تبدأ بـ 010 أو 011 أو 012 أو 015
  // يدعم بادئة مصر الدولية +20 أو 0020 اختيارياً
  static final RegExp _egyptianMobileRegex =
      RegExp(r'^(?:\+?20|0020)?0?(1[0125][0-9]{8})$');

  /// يتحقق مما إذا كان النص يمثل رقم محمول مصري صحيح
  static bool isValidEgyptianPhone(String? phone) {
    if (phone == null) return false;
    final cleaned = _cleanDigits(phone);
    return _egyptianMobileRegex.hasMatch(cleaned);
  }

  /// ينسق رقم الهاتف إلى الصيغة القياسية النظيفة الموحدة (01xxxxxxxxx)
  /// إذا كان الرقم غير مصري أو غير صالح يعيد الرقم منظفاً من المسافات
  static String? normalize(String? phone) {
    if (phone == null) return null;
    final cleaned = _cleanDigits(phone);
    final match = _egyptianMobileRegex.firstMatch(cleaned);
    if (match != null && match.groupCount >= 1) {
      return '0${match.group(1)}';
    }
    return cleaned;
  }

  /// دالة تحقق جاهزة لحقول الإدخال [TextFormField.validator]
  static String? validate(String? value, {bool isRequired = true}) {
    final v = value?.trim();
    if (v == null || v.isEmpty) {
      return isRequired ? 'رقم الهاتف مطلوب' : null;
    }
    if (!isValidEgyptianPhone(v)) {
      return 'يرجى إدخال رقم محمول مصري صحيح (11 رقماً يبدأ بـ 010 أو 011 أو 012 أو 015)';
    }
    return null;
  }

  static String _cleanDigits(String text) {
    // تحويل الأرقام العربية/الفارسية إن وجدت إلى أرقام إنجليزية
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var result = text.trim();
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], i.toString());
    }
    // حذف المسافات والشرطات والأقواس
    return result.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
  }
}

/// مفتاح ترتيب أبجدي عربي: يوحّد صور الألف والهمزة والتاء المربوطة والألف
/// المقصورة، ويزيل التشكيل والتطويل، فيقع «أحمد» و«احمد» و«إبراهيم» و«ابراهيم»
/// في مواضعها الصحيحة بدل أن تسبقها صور الهمزة في جدول اليوني كود.
String arabicSortKey(String input) {
  final out = StringBuffer();
  for (final r in input.runes) {
    // التشكيل وعلامات القرآن والتطويل: لا دخل لها في الترتيب.
    if ((r >= 0x064B && r <= 0x065F) || r == 0x0640 || r == 0x0670) continue;
    if ((r >= 0x0610 && r <= 0x061A) || (r >= 0x06D6 && r <= 0x06ED)) continue;
    switch (r) {
      case 0x0622: // آ
      case 0x0623: // أ
      case 0x0625: // إ
      case 0x0671: // ٱ
        out.writeCharCode(0x0627); // ا
        break;
      case 0x0624: // ؤ
        out.writeCharCode(0x0648); // و
        break;
      case 0x0626: // ئ
      case 0x0649: // ى
      case 0x06CC: // ی
        out.writeCharCode(0x064A); // ي
        break;
      case 0x0629: // ة
        out.writeCharCode(0x0647); // ه
        break;
      default:
        out.writeCharCode(r);
    }
  }
  return out.toString().trim().toLowerCase();
}

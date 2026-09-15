/// بناء رابط واتساب مصري موحّد من أي صيغة رقم.
/// يعالج: 01xxx / +20xxx / 20xxx / 0020xxx / مسافات وشرطات.
/// يعيد null إذا لم يوجد رقم صالح.
String? egyptianWhatsAppUrl(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  final local = digits.replaceAll(RegExp(r'^0+'), '');
  if (local.length < 8) return null;
  final full = digits.startsWith('00')
      ? digits.substring(2)
      : (digits.startsWith('20') ? digits : '20$local');
  return 'https://wa.me/$full';
}


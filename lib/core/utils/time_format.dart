/// تنسيق الوقت للمستخدم بصيغة 12 ساعة وبعبارات عربية واضحة.
String formatTime12(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour < 12 ? 'صباحًا' : 'مساءً';
  return '$hour:$minute $period';
}

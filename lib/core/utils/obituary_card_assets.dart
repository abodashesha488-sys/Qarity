/// أصول بطاقة العزاء: مصدر واحد لمسارات صور azaa ولمفاتيح الخلفيات المختارة.
/// يُخزَّن المفتاح وحده في المستند، فلا يتحول تغيير أسماء الملفات إلى سجلات مكسورة،
/// وأي مفتاح مجهول يسقط إلى الافتراضي بدل محاولة رسم أصل غير موجود.
const String kObituaryDeceasedFallbackAsset = 'assets/images/azaa 0.jpeg';

const Map<String, String> kObituaryCardBackgrounds = {
  'azaa1': 'assets/images/azaa 1.jpeg',
  'azaa2': 'assets/images/azaa 2.jpeg',
  'azaa3': 'assets/images/azaa 3.jpeg',
  'azaa4': 'assets/images/azaa 4.jpeg',
};

const String kDefaultObituaryCardBackground = 'azaa1';

/// ترتيب العرض في نموذج الإضافة، مع تسمية عربية لكل خيار.
const List<String> kObituaryCardBackgroundKeys = ['azaa1', 'azaa2', 'azaa3', 'azaa4'];
const List<String> kObituaryCardBackgroundLabels = [
  'البطاقة الأولى',
  'البطاقة الثانية',
  'البطاقة الثالثة',
  'البطاقة الرابعة',
];

String obituaryCardAssetFor(String? key) =>
    kObituaryCardBackgrounds[key] ??
    kObituaryCardBackgrounds[kDefaultObituaryCardBackground]!;

import '../../widgets/gender_selector.dart';

/// مجموعات النوع في لوحة المستخدمين. «بلا نوع» مجموعة حقيقية لا حشو: الحسابات
/// التي أُنشئت قبل أن يصير النوع إلزاميًا لا ذكرًا ولا أنثى، فدمجها داخل
/// إحداهما يكذب على المراجع، واستبعادها من العرض يُفقدها عند كل فلترة.
const String kGenderGroupMale = 'male';
const String kGenderGroupFemale = 'female';
const String kGenderGroupNone = 'none';

/// ترتيب ظهور المجموعات ثابت لا يتبع الفرز المختار، فتُقرأ الشاشة بنفس الشكل
/// في كل مرة.
const List<String> kGenderGroupOrder = [
  kGenderGroupMale,
  kGenderGroupFemale,
  kGenderGroupNone,
];

const Map<String, String> kGenderGroupLabels = {
  kGenderGroupMale: 'الرجال',
  kGenderGroupFemale: 'النساء',
  kGenderGroupNone: 'بلا نوع',
};

/// رتبة الدور داخل مجموعة النوع: الأدمن بمختلف أنواعه أولًا، ثم البائعون، ثم
/// المستخدمون.
const Map<String, int> kUserRoleRank = {
  'admin': 0,
  'assistant_admin': 1,
  'medical_admin': 2,
  'agricultural_admin': 3,
  'moderator': 4,
  'seller': 5,
};

int userRoleRank(String role) => kUserRoleRank[role] ?? 6;

/// أي مجموعة ينتمي إليها هذا المستند؟ القيم هي نصوص الملف الشخصي نفسها
/// (`kGenderMale`/`kGenderFemale`)، فلا مصدر ثانٍ للنوع في التطبيق.
String genderGroupOf(Map<String, dynamic> user) {
  final g = (user['gender'] ?? '').toString().trim();
  if (g == kGenderMale) return kGenderGroupMale;
  if (g == kGenderFemale) return kGenderGroupFemale;
  return kGenderGroupNone;
}

int genderGroupRank(String group) => kGenderGroupOrder.indexOf(group);

/// `all` تعني بلا تضييق، لا نوعًا رابعًا — فالشرائط الثلاثة لا تتنافى مع الأدوار.
bool genderFilterMatches(String filter, Map<String, dynamic> user) =>
    filter == 'all' || genderGroupOf(user) == filter;

/// مجموعة الأدوار «الكل» تصير جنسيةً حين يُختار نوع: الضغطة تعني «كل الرجال» أو
/// «كل النساء»، والاسم يجب أن يقوله لا أن يُستنتج.
String genderAwareAllLabel(String genderFilter) {
  switch (genderFilter) {
    case kGenderGroupMale:
      return 'كل الرجال';
    case kGenderGroupFemale:
      return 'كل النساء';
    default:
      return 'الكل';
  }
}

/// مقارنة القائمة كاملة: النوع أولًا ثم رتبة الدور ثم `withinGroup` (الفرز
/// المختار: الأحدث/الأقدم/الاسم/البريد). لا تُعرض القائمة إلا بها.
int compareUsersForList(Map<String, dynamic> a, Map<String, dynamic> b,
    int Function(Map<String, dynamic>, Map<String, dynamic>) withinGroup) {
  final gender = genderGroupRank(genderGroupOf(a))
      .compareTo(genderGroupRank(genderGroupOf(b)));
  if (gender != 0) return gender;
  final rank = userRoleRank((a['role'] ?? 'user').toString())
      .compareTo(userRoleRank((b['role'] ?? 'user').toString()));
  if (rank != 0) return rank;
  return withinGroup(a, b);
}

/// وسم النوع على بطاقة المستخدم: القيمة المحفوظة كما هي («ذكر»/«أنثى»)، و«بلا
/// نوع» للحسابات التي أُنشئت قبل أن يصير النوع إلزاميًا. لا تُشتق تسمية جديدة
/// هنا كي لا يحمل في اللوحة اسمان للنوع الواحد.
String userGenderBadgeLabel(Map<String, dynamic> user) {
  final g = (user['gender'] ?? '').toString().trim();
  return g.isEmpty ? kGenderGroupLabels[kGenderGroupNone]! : g;
}

/// مجموعة في القائمة: عنوانها الظاهر وأعضاؤها بترتيبهم الجاري.
class GenderGroup {
  const GenderGroup(this.label, this.members);
  final String label;
  final List<Map<String, dynamic>> members;
}

/// رؤوس المجموعات بالمعنى لا بالحروف: مجموعة لا أعضاء لها لا رأس لها، فالتصنيف
/// بلا أحدٍ لا يعني أن القسم «مقطوع» في منتصفه.
List<GenderGroup> genderGroupsOf(List<Map<String, dynamic>> users) {
  final groups = <GenderGroup>[];
  for (final group in kGenderGroupOrder) {
    final members = users.where((u) => genderGroupOf(u) == group).toList();
    if (members.isEmpty) continue;
    groups.add(GenderGroup(kGenderGroupLabels[group]!, members));
  }
  return groups;
}

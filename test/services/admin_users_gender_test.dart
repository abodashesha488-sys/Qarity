import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/user_gender_groups.dart';

Map<String, dynamic> _user({
  required String id,
  String role = 'user',
  String gender = '',
}) =>
    {
      'id': id,
      'name': id,
      'role': role,
      if (gender.isNotEmpty) 'gender': gender,
    };

void main() {
  group('تصنيف النوع في لوحة المستخدمين', () {
    test('ذكر/أنثى يُجمّعان، والفراغ والغياب والنص الغريب «بلا نوع»', () {
      expect(genderGroupOf(_user(id: 'a', gender: 'ذكر')), kGenderGroupMale);
      expect(genderGroupOf(_user(id: 'b', gender: 'أنثى')), kGenderGroupFemale);
      expect(genderGroupOf(_user(id: 'c')), kGenderGroupNone);
      expect(genderGroupOf(_user(id: 'd', gender: '   ')), kGenderGroupNone);
      expect(genderGroupOf(_user(id: 'e', gender: 'مذكر')), kGenderGroupNone);
      // الحقل نفسه مكتوب null (سجل بُني قبل الإجراء) لا يستثني المستند.
      expect(genderGroupOf({'id': 'f', 'gender': null}), kGenderGroupNone);
    });

    test('«الكل» بلا تضييق، وشرائط النوع تقطع ما لا يطابقها', () {
      final male = _user(id: 'm', gender: 'ذكر');
      final female = _user(id: 'w', gender: 'أنثى');
      final none = _user(id: 'n');
      expect(genderFilterMatches('all', male), isTrue);
      expect(genderFilterMatches('all', none), isTrue,
          reason: '«الكل» تعني بلا مرشّح، لا نوعًا رابعًا');
      expect(genderFilterMatches(kGenderGroupMale, male), isTrue);
      expect(genderFilterMatches(kGenderGroupMale, female), isFalse);
      expect(genderFilterMatches(kGenderGroupMale, none), isFalse,
          reason: 'بلا نوع ليس رجالًا — وإلا ظهر في قائمة الرجال خلسة');
      expect(genderFilterMatches(kGenderGroupFemale, none), isFalse);
    });

    test('تسمية مجموعة الأدوار «الكل» تتبع النوع المختار', () {
      expect(genderAwareAllLabel('all'), 'الكل');
      expect(genderAwareAllLabel(kGenderGroupMale), 'كل الرجال');
      expect(genderAwareAllLabel(kGenderGroupFemale), 'كل النساء');
    });
  });

  group('عدّادات مجمّعة ورؤوس الأقسام', () {
    final mixed = <Map<String, dynamic>>[
      _user(id: 'w1', gender: 'أنثى'),
      _user(id: 'm1', gender: 'ذكر'),
      _user(id: 'n1'),
      _user(id: 'w2', gender: 'أنثى'),
      _user(id: 'm2', gender: 'ذكر'),
    ];

    test('المجموعات الثلاث تُحصى وتجمعها يساوي القائمة كاملة', () {
      final groups = genderGroupsOf(mixed);
      expect(groups.map((g) => g.label).toList(), ['الرجال', 'النساء', 'بلا نوع']);
      expect(groups.map((g) => g.members.length).toList(), [2, 2, 1]);
      expect(groups.fold<int>(0, (s, g) => s + g.members.length), mixed.length,
          reason: 'لا مستند يضيع بين المجموعات ولا يُعدّ مرتين');
    });

    test('المجموعة الفارغة لا رأس لها', () {
      final onlyMen = [_user(id: 'm1', gender: 'ذكر')];
      expect(genderGroupsOf(onlyMen).map((g) => g.label).toList(), ['الرجال']);
      expect(genderGroupsOf([]), isEmpty);
    });

    test('ترتيب الرؤوس ثابت مهما كان ترتيب الدخول', () {
      final reversed = mixed.reversed.toList();
      expect(genderGroupsOf(reversed).map((g) => g.label).toList(),
          genderGroupsOf(mixed).map((g) => g.label).toList());
    });
  });

  group('ترتيب القائمة: النوع ثم رتبة الدور ثم المفتاح', () {
    int byName(Map<String, dynamic> a, Map<String, dynamic> b) =>
        (a['name'] as String).compareTo(b['name'] as String);

    test('النوع يحسم قبل الدور: مستخدم رجل قبل مديرة امرأة', () {
      final ordered = [
        _user(id: 'z', role: 'admin', gender: 'أنثى'),
        _user(id: 'a', gender: 'ذكر'),
      ]..sort((x, y) => compareUsersForList(x, y, byName));
      expect(ordered.map((u) => u['id']).toList(), ['a', 'z']);
    });

    test('بلا نوع آخر القائمة دائمًا', () {
      final ordered = [
        _user(id: 'n'),
        _user(id: 'w', gender: 'أنثى'),
        _user(id: 'm', gender: 'ذكر'),
      ]..sort((x, y) => compareUsersForList(x, y, byName));
      expect(ordered.map((u) => u['id']).toList(), ['m', 'w', 'n']);
    });

    test('داخل النوع: رتبة الدور أولًا ثم المفتاح المختار', () {
      final ordered = [
        _user(id: 'u2', gender: 'ذكر'),
        _user(id: 's1', role: 'seller', gender: 'ذكر'),
        _user(id: 'u1', gender: 'ذكر'),
        _user(id: 'ad', role: 'admin', gender: 'ذكر'),
      ]..sort((x, y) => compareUsersForList(x, y, byName));
      expect(ordered.map((u) => u['id']).toList(), ['ad', 's1', 'u1', 'u2']);
    });

    test('رتبة الأدوار معروفة: أدمن ⇒ مساعد ⇒ طبي ⇒ زراعي ⇒ مشرف ⇒ بائع، والمجهول آخرًا', () {
      const known = [
        'admin',
        'assistant_admin',
        'medical_admin',
        'agricultural_admin',
        'moderator',
        'seller',
      ];
      expect(known.map(userRoleRank).toList(), List<int>.generate(6, (i) => i));
      expect(userRoleRank('user'), 6);
      expect(userRoleRank('مجهول'), 6);
      expect(userRoleRank(''), 6,
          reason: 'أي دور جديد يواضع المستخدمين في الذيل ولا يتسلّل فوق الأدمن');
    });
  });

  group('عقد المصدر: لوحة المستخدمين', () {
    final src =
        File('lib/features/admin/admin_dashboard_users.dart').readAsStringSync();

    test('حالة النوع مستقلة عن قائمة الأدوار', () {
      expect(src, contains("String _genderFilter = 'all';"));
      expect(src, contains('if (!genderFilterMatches(_genderFilter, u))'),
          reason: 'المرشّحان يتراكبان بلا حالة مركّبة لكل تركيبة');
      expect(src, contains("key: const Key('gender-filter-row')"));
      expect(src, contains("Key('gender-filter-\${g.\$1}')"));
    });

    test('الترتيب يمرّ بالمقارنة المجمّعة لا برتبة الدور وحدها', () {
      expect(src, contains('compareUsersForList(a, b, _compareWithinRank)'));
      expect(src, isNot(contains('_rankOf')),
          reason: 'الرتبة الخاصة استُخرجت للمصدر المشترك فلا تتفارق اللوحة عنها');
    });

    test('القائمة تُبنى من صفوف فيها رؤوس، لا من المستخدمين مباشرة', () {
      expect(src, contains('final rows = _listRows(filtered);'));
      expect(src, contains('itemCount: rows.length'));
      expect(src, contains('if (row.isHeader)'));
      expect(src, contains("Key('gender-header-\$label')"));
      expect(src, isNot(contains('ListView.separated')),
          reason: 'الرؤوس تكسر افتراض «سطر = مستخدم» الذي يقوم عليه separated');
    });

    test('العدّادات مجمّعة على القائمة كاملة + رابعة للظاهر', () {
      expect(src, contains("key: const Key('gender-counters')"));
      expect(src, contains("theme, 'الرجال', '\$men'"));
      expect(src, contains("theme, 'النساء', '\$women'"));
      expect(src, contains("theme, 'بلا نوع', '\$noGender'"));
      expect(src, contains("theme, 'الظاهر', '\${filtered.length}'"),
          reason: 'صفرٌ تحت مرشّح لا يعني أن القرية بلا نساء');
      expect(src, contains('all.where((u) => genderGroupOf(u) == kGenderGroupMale)'),
          reason: 'عدّاد الرجال يقرأ القائمة كاملة لا المرشّحة');
      expect(
          src, contains('all.where((u) => genderGroupOf(u) == kGenderGroupFemale)'));
      expect(src, contains('final noGender = all.length - men - women;'),
          reason: '«بلا نوع» بالاطراح: لا مستند يفلت من العدّ');
    });

    test('مجموعة الأدوار تستعير التسمية الجنسية بدل أن تكررها', () {
      expect(src, contains('if (_filter == \'all\') '
          'return genderAwareAllLabel(_genderFilter);'));
    });

    test('المسار المشترك للنوع مستعمل ولا نصّ مكرّر في اللوحة', () {
      expect(src, contains('genderAwareAllLabel(_genderFilter)'));
      expect(src, contains('genderGroupsOf(sorted)'));
      expect(src, isNot(contains("== 'ذكر'")),
          reason: 'نص النوع مصدره kGenderMale وحده');
      expect(File('lib/core/utils/user_gender_groups.dart').readAsStringSync(),
          contains('if (g == kGenderMale) return kGenderGroupMale;'));
    });

    test('البحث سطرٌ كامل العرض وحده والرقائق في Wrap', () {
      final bar = src.substring(src.indexOf('// ── شريط الأدوات'),
          src.indexOf('// ── قائمة المستخدمين'));
      final head = bar.substring(bar.indexOf('child: Column('),
          bar.indexOf('Wrap('));
      // القياس الحيّ على 390dp: كان Expanded(TextField) يترك للبحث 38.20dp،
      // و8.62dp مع أطول تسمية دور «أدمن مساعد» + «RenderFlex overflowed by
      // 5.9 pixels» — أي دائرة عدسة بلا تلميح. الآن search=358.00 وoverflow=0.
      expect(head, contains("key: const Key('users-search-field')"));
      expect(head, isNot(contains('Expanded(')),
          reason: 'المرن في الصف كان هو من ينضغط حتى يختفي الحقل');
      expect(head, isNot(contains('Row(')),
          reason: 'البحث فوق الرقائق لا بجانبها');
      expect(bar, contains("key: const Key('users-tools-row')"));
      expect(bar.indexOf('Wrap('), lessThan(bar.indexOf('Tooltip(')),
          reason: 'الرقائق أبناء لـWrap فتلتفّ أسطرًا إن طالت التسميات');
      expect(bar, contains('spacing: 8,'));
      expect(bar, contains('runSpacing: 8,'));
      expect(bar, isNot(contains('Expanded(')),
          reason: 'لا شيء في الشريط كله يعود إلى التقلّص');
      // الحشو الرأسي يطابق ثيم الحقول (14) فلا يُبتر المظهر المعبّأ الموروث.
      expect(bar, contains('horizontal: 16, vertical: 14'),
          reason: 'الارتفاع المقيس 44.00dp بدل 40.00 المضغوط');
    });
  });

  group('البند ٥: وسم النوع الفردي', () {
    test('ذكر/أنثى كما في الملف، والفراغ والغياب والنص الغريب «بلا نوع»', () {
      expect(userGenderBadgeLabel(_user(id: 'm', gender: 'ذكر')), 'ذكر');
      expect(userGenderBadgeLabel(_user(id: 'w', gender: 'أنثى')), 'أنثى');
      expect(userGenderBadgeLabel(_user(id: 'n')), 'بلا نوع');
      expect(userGenderBadgeLabel(_user(id: 's', gender: '   ')), 'بلا نوع');
      expect(userGenderBadgeLabel({'id': 'x', 'gender': null}), 'بلا نوع',
          reason: 'الحقل مكتوب null صراحةً — لا يظهر وسمًا فارغًا');
      expect(userGenderBadgeLabel(_user(id: 'g', gender: 'مذكر')), 'مذكر',
          reason: 'قيمة غير معروفة تُعرض كما هي، فالمجموعة يحسمها genderGroupOf وحده');
    });
  });

  group('البند ٥: بطاقة المستخدم في سطر واحد مدمج', () {
    final usersSrc = File('lib/features/admin/admin_dashboard_users.dart')
        .readAsStringSync();

    // `slice` تُنادى أثناء جمع الاختبارات (داخل جسم `group`) فلا يجوز أن
    // تستعمل `expect` هناك — الاستثناء الصريح يقول أي وسم مفقود.
    String slice(String from, String to) {
      final a = usersSrc.indexOf(from);
      final b = usersSrc.indexOf(to);
      if (a < 0 || b <= a) {
        throw StateError('لم يُعثر على «$from» أو على نهايتها «$to»');
      }
      return usersSrc.substring(a, b);
    }

    final card =
        slice('Widget _userCard(ThemeData', 'Widget _badge(String text,');
    final badge =
        slice('Widget _badge(String text,', 'static String _typeLabel(');
    final detail =
        slice('void _showUserDetail(Map<String, dynamic> u)', 'Widget _buildDetailRow(');

    test('سطر واحد: `Row` واحد بلا عمود خارجي ولا التفاف', () {
      expect(card, contains('child: Row('));
      expect('Row('.allMatches(card).length, 1,
          reason: 'السطر الثاني وصفّ الأزرار الداخلي كانا Row إضافيين');
      expect(card, isNot(contains('Wrap(')),
          reason: 'الرقائق اللافّة كانت ترفع البطاقة سطرًا عند أي اسم طويل');
      expect(card.indexOf('child: Padding('), lessThan(card.indexOf('child: Row(')),
          reason: 'الحشو مباشرة داخل البطاقة، والـRow هو ولدها لا حفيدها');
    });

    test('السطر المدمج يُظهر الاسم والبريد والشارة', () {
      expect(card, contains("u['name']"), reason: 'الاسم');
      expect(card, contains("u['email']"), reason: 'البريد');
      expect(card, contains('userGenderBadgeLabel(u)'), reason: 'النوع');
      expect(card, contains(r'${opt.$1}'), reason: 'الرتبة في نفس الشارة');
      expect(card, contains('radius: 22'), reason: 'أفاتار ~44px');
      expect(card, contains('CircleAvatar('));
    });

    test('كل نصّ مقصوص بسطر واحد فلا شيء يفيض مخفيًا', () {
      expect('maxLines: 1'.allMatches(card).length, 2,
          reason: 'الاسم والبريد في السطر، والشارة مقصوصة في وسمها');
      expect('TextOverflow.ellipsis'.allMatches(card).length, 2);
      expect(badge, contains('maxLines: 1'));
      expect(badge, contains('TextOverflow.ellipsis'),
          reason: 'أطول تسمية دور فوقها تمرّ ellipsis لا فيضانًا');
      expect(card, contains('Flexible('),
          reason: 'الشارة داخل Flexible فتقبل الضيق بدل أن تفيض');
      expect(card, contains('Expanded('),
          reason: 'عمود الاسم والبريد هو المرن الوحيد في السطر');
      expect('mainAxisSize: MainAxisSize.min'.allMatches(card).length, 1,
          reason: 'Column الاسم/البريد لا يمتص ارتفاع البطاقة');
      expect('_badge('.allMatches(card).length, 2,
          reason: 'شارة واحدة للنوع والرتبة + «معطّل» عند التعطيل، لا لَفّة رقائق');
    });

    test('التاريخان حُذفا من البطاقة وبقيَا في نافذة الإدارة', () {
      expect(card, isNot(contains('_formatDay')),
          reason: 'سطر «تاريخ الإنشاء/آخر تسجيل دخول» المكرر حُذف');
      expect(card, isNot(contains('signupAt')));
      expect(card, isNot(contains('lastLogin')));
      expect(card, isNot(contains('_typeLabel')),
          reason: 'نوع البائع بيان إداري يقرؤه المراجع من النافذة');
      expect(usersSrc, isNot(contains('String _formatDay(')),
          reason: 'المُنسّق الذي لا مستعمل له يبقى تحذير analyze');
      expect(detail, contains("'تاريخ التسجيل'"));
      expect(detail, contains("'آخر تسجيل دخول'"));
      expect(detail, contains("'نوع البائع'"));
      expect(detail, contains('sellerType'));
      expect(card, contains('_showUserDetail(u)'),
          reason: 'النقر على البطاقة يفتح التفاصيل الكاملة');
    });

    test('زر إدارة واحد مضغوط، وحماية المدير العام قائمة', () {
      expect('IconButton('.allMatches(card).length, 1);
      expect(card, contains('visualDensity: VisualDensity.compact'));
      expect(card, contains('minimumSize: const Size(36, 36)'));
      expect(card, isNot(contains('chevron_left_rounded')),
          reason: 'السهم كان زرًا ثانيًا يوحي بإجراء مستقل');
      expect(card, contains('onPressed: protected ? null : () => _manage(context, u)'));
      expect(card, contains("'محمي — للمدير العام فقط'"));
      expect(card, contains('if (disabled) ...['),
          reason: 'الحساب المعطّل يفقد شارة «معطّل» فلا يُقرأ رفضه من إطار أحمر وحده');
    });
  });
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/utils/xlsx_export.dart';

/// ورقة واحدة بها `اسم` و`بريد` — نفس شكل صفوف المستخدمين المُصدَّرة.
List<Map<String, dynamic>> _rows({int count = 2}) => [
      for (int i = 0; i < count; i++)
        {
          'الرقم': i + 1,
          'الاسم': 'مستخدم $i',
          'البريد الإلكتروني': 'user$i@qarity.app',
        }
    ];

void main() {
  group('ملف Excel المفكَّك غير فارغ ويحمل البيانات', () {
    test('الورقة الوحيدة باسمها العربي وتحمل الاسم والبريد', () {
      final bytes = buildTableXlsx(sheetName: 'المستخدمون', rows: _rows());
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(0));

      final excel = Excel.decodeBytes(bytes);
      expect(excel.tables.keys.toList(), ['المستخدمون'],
          reason: 'لا Sheet1 الفارغة: الملف يفتح على البيانات لا على صفحة بيضاء');
      final sheet = excel['المستخدمون'];
      expect(sheet.maxRows, 3, reason: 'ترويسة + صفّان');
      expect(sheet.maxColumns, 3);

      String cell(int r, int c) => sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
          .value
          .toString();
      expect(cell(0, 1), 'الاسم');
      expect(cell(0, 2), 'البريد الإلكتروني');
      expect(cell(1, 1), 'مستخدم 0');
      expect(cell(1, 2), 'user0@qarity.app');
      expect(cell(2, 2), 'user1@qarity.app');
    });

    test('الترويسة تُلوَّن بـ ExcelColor لا بنص (سبب الانكسار السابق)', () {
      // الترويسة المسماة يجب أن تُقرأ من الملف نفسه؛ لون الخلية بعد فكّ الترميز
      // يعتمد على جدول الألوان فلا يُقارَن نصيًا.
      final sheet = Excel.decodeBytes(
              buildTableXlsx(sheetName: 'التقرير', rows: _rows(count: 1)))['التقرير'];
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value,
          isA<TextCellValue>());
      final util = File('lib/core/utils/xlsx_export.dart').readAsStringSync();
      expect(util, contains('backgroundColorHex: ExcelColor.fromInt(0xFF6F4E37)'));
      expect(util, contains('fontColorHex: ExcelColor.white'));
      expect(util, isNot(contains("'#6F4E37'")),
          reason: 'تمرير النص كان يرمي TypeError فيبتلعه catch ويقول «خطأ في التصدير»');
    });
  });

  group('الفراغ يُبلَّغ صراحةً', () {
    test('buildTableXlsx بلا صفوف ⇒ رسالة الفارغ لا ملف بحجم صفر', () {
      expect(() => buildTableXlsx(sheetName: 'المستخدمون', rows: []),
          throwsA(isA<ExportException>().having((e) => e.message, 'message',
              'لم يجد التصدير بيانات للتصدير')));
    });

    test('buildCsv بلا صفوف ⇒ نفس الرسالة', () {
      expect(() => buildCsv([]),
          throwsA(isA<ExportException>().having((e) => e.message, 'message',
              'لم يجد التصدير بيانات للتصدير')));
    });

    test('encodeWorkbook يحذف Sheet1 ويعطي بايتات غير فارغة لورقة واحدة', () {
      final excel = Excel.createExcel();
      final created = excel['فارغة'];
      expect(created.sheetName, 'فارغة');
      final bytes = encodeWorkbook(excel);
      expect(bytes.length, greaterThan(0));
      expect(Excel.decodeBytes(bytes).tables.keys.toList(), ['فارغة']);
    });

    test('الرسالة والمُلغاة ثابتان تُستعملان في اللوحة', () {
      expect(kExportEmptyMessageAr, 'لم يجد التصدير بيانات للتصدير');
      expect(kExportCancelledMessageAr, 'أُلغيت عملية حفظ الملف');
      final users = File('lib/features/admin/admin_dashboard_users.dart')
          .readAsStringSync();
      expect(users, contains('on ExportException catch (e) {'));
      expect(users, contains('_snack(e.message);'));
      expect(users, contains('kExportCancelledMessageAr'));
      final reports = File('lib/features/admin/admin_dashboard_reports.dart')
          .readAsStringSync();
      expect(reports, contains('_snack(kExportEmptyMessageAr)'));
      expect(reports, contains('on ExportException catch (e) {'));
      expect(reports, contains('kExportCancelledMessageAr'));
    });
  });

  group('CSV يبدأ بـ BOM', () {
    test('أول ثلاث بايتات هي EF BB BF', () {
      final bytes = utf8.encode(buildCsv(_rows(count: 1)));
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      expect(buildCsv(_rows(count: 1)), startsWith(kUtf8Bom));
      expect(kUtf8Bom, '\uFEFF');
    });

    test('الترويسة ثم صف لكل سجل، وكل خلية بين اقتباسين مع مضاعفة الداخلي',
        () {
      final csv = buildCsv([
        {
          'الاسم': 'قال: "مرحباً"',
          'ملاحظات': 'بلا',
        }
      ]);
      final lines = const LineSplitter().convert(csv);
      expect(lines.length, 2);
      // الـ BOM يبقى أول المحروف ولا يسقطه LineSplitter، فالترويسة تُقاس معه.
      expect(lines.first, '\uFEFF' 'الاسم,ملاحظات');
      expect(lines.last, '"قال: ""مرحباً""","بلا"');
    });
  });

  group('التصدير = القائمة الظاهرة فقط (لا إعادة تطبيق فلاتر)', () {
    test('المُصدِّر يرسم ما يُمرَّر إليه حرفيًا — أربع صفوف فأربعة أسطر', () {
      final csv = const LineSplitter().convert(buildCsv(_rows(count: 4)));
      expect(csv.length, 5);
      expect(csv.last, '"4","مستخدم 3","user3@qarity.app"');
      final sheet = Excel.decodeBytes(
          buildTableXlsx(sheetName: 'المستخدمون', rows: _rows(count: 4)))['المستخدمون'];
      expect(sheet.maxRows, 5);
    });

    test('عقد المصدر: الصفوف من _visible ولا فلترة داخل المُصدِّر', () {
      final users = File('lib/features/admin/admin_dashboard_users.dart')
          .readAsStringSync();
      expect(users, contains('for (final u in _visible)'));
      expect(users, contains('final rows = _exportRows();'));
      // المُصدِّر لا يلمس أي حالة مرشّح: لو طبّق البحث/الدور/النوع من جديد لأخرج
      // ملفًا لا يطابق ما تراه العين.
      final exportBody = users.substring(
          users.indexOf('List<Map<String, dynamic>> _exportRows()'),
          users.indexOf('String get _stamp'));
      expect(exportBody, isNot(contains('_search')));
      expect(exportBody, isNot(contains('_filter')));
      expect(exportBody, isNot(contains('_genderFilter')));
      expect(exportBody, isNot(contains('genderFilterMatches')));
      expect(exportBody, isNot(contains('where(')));
      final excelBody = users.substring(
          users.indexOf('Future<void> _handleExport(String type)'),
          users.indexOf('void _report('));
      expect(excelBody, contains('bytes: buildTableXlsx(sheetName: \'المستخدمون\', rows: rows)'));
      expect(excelBody, contains('bytes: utf8.encode(buildCsv(rows))'));
      expect(excelBody, isNot(contains('_genderFilter')));
      expect(excelBody, isNot(contains('where(')));
    });

    test('المُصدِّر القديم (بلا حذف Sheet1 وبلا فحص بايتات) مستأصل', () {
      final users = File('lib/features/admin/admin_dashboard_users.dart')
          .readAsStringSync();
      expect(users, isNot(contains('_buildUsersXlsx')));
      expect(users, isNot(contains('Excel.createExcel()')));
      expect(users, isNot(contains("StringBuffer('﻿')")),
          reason: 'BOM صار ثابتًا صريحًا kUtf8Bom لا حرفًا غير مرئي في النص');
      final reports = File('lib/features/admin/admin_dashboard_reports.dart')
          .readAsStringSync();
      expect(reports, contains('encodeWorkbook(excel)'));
      expect(reports, isNot(contains("excel.delete('Sheet1')")),
          reason: 'الحذف في encodeWorkbook فتنطبق الورقة الوحيدة على كل مُصدِّر');
      expect(reports, isNot(contains("throw Exception('فشل إنشاء ملف Excel')")));
    });
  });
}

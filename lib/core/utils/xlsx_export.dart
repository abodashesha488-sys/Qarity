import 'dart:typed_data';

import 'package:excel/excel.dart';
import '../../core/constants/app_colors.dart';

/// الورقة التي يولّدها `Excel.createExcel()` دائمًا. تبقى في المجلد فارغة إن لم
/// تُحذف قبل `encode()`، فيُفتح الملف على صفحة بيضاء بدل بيانات التقرير.
const String kExcelDefaultSheetName = 'Sheet1';

/// رسالة واحدة لكل حالات «لا شيء يُصدَّر»: لا رقم داخلي ولا «خطأ في التصدير».
const String kExportEmptyMessageAr = 'لم يجد التصدير بيانات للتصدير';

/// رسالة إلغاء المتصفح/نافذة المشاركة للحفظ — لا يجوز أن تُقرأ كنجاح.
const String kExportCancelledMessageAr = 'أُلغيت عملية حفظ الملف';

/// BOM في أول الملف حتى لا تفتح Excel العربية الحروف مكسورة. حرف غير مرئي في
/// النص، لذلك عُرّف صراحةً هنا وقِيست بايتاته في الاختبار لا شكله في المحرر.
const String kUtf8Bom = '\uFEFF';

/// فشل تصدير يُبلَّغ بصفحته: النص العربي جاهز للعرض كما هو.
class ExportException implements Exception {
  const ExportException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// ورقة واحدة: ترويسة من مفاتيح `rows` الأول منسّقة بالأبيض على البني، ثم
/// الصفوف، ثم عرض موحّد للأعمدة.
Uint8List buildTableXlsx({
  required String sheetName,
  required List<Map<String, dynamic>> rows,
  double columnWidth = 22.0,
}) {
  if (rows.isEmpty) throw const ExportException(kExportEmptyMessageAr);
  final excel = Excel.createExcel();
  final sheet = excel[sheetName];
  final headers = rows.first.keys.toList();

  for (int i = 0; i < headers.length; i++) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
      ..value = TextCellValue(headers[i])
      ..cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.fromInt(AppColors.primary.toARGB32()),
        horizontalAlign: HorizontalAlign.Center,
      );
  }
  for (int r = 0; r < rows.length; r++) {
    for (int c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
        ..value = TextCellValue(rows[r][headers[c]]?.toString() ?? '')
        ..cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);
    }
  }
  for (int i = 0; i < headers.length; i++) {
    sheet.setColumnWidth(i, columnWidth);
  }
  return encodeWorkbook(excel);
}

/// حذف `Sheet1` ثم الترميز مع فحص النتيجة: `encode()` قد ترجع `null` **أو قائمة
/// فارغة**، والقائمة الفارغة كانت تمرّ على أنها نجاح فتُحفظ ملف بحجم صفر.
Uint8List encodeWorkbook(Excel excel) {
  excel.delete(kExcelDefaultSheetName);
  final bytes = excel.encode();
  if (bytes == null || bytes.isEmpty) {
    throw const ExportException(kExportEmptyMessageAr);
  }
  return Uint8List.fromList(bytes);
}

/// CSV بصف واحد للترويسة ثم صف لكل سجل؛ كل خلية بين علامتَي اقتباس مع مضاعفة
/// الاقتباس الداخلي، والملف كله مسبق بـ BOM.
String buildCsv(List<Map<String, dynamic>> rows) {
  if (rows.isEmpty) throw const ExportException(kExportEmptyMessageAr);
  final headers = rows.first.keys.toList();
  final csv = StringBuffer(kUtf8Bom);
  csv.writeln(headers.join(','));
  for (final row in rows) {
    csv.writeln(headers.map((h) => _csvCell(row[h])).join(','));
  }
  return csv.toString();
}

String _csvCell(Object? value) =>
    '"${(value?.toString() ?? '').replaceAll('"', '""')}"';

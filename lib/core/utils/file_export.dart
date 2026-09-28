import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// تصدير ملف مُجهَّز (JSON/CSV/XLSX): على الويب تنزيل مباشر عبر المتصفح،
/// وعلى الأجهزة الأصلية كتابة في مجلد مؤقت ثم فتح نافذة المشاركة.
/// إعادة `false` تعني أن المستخدم ألغى العملية.
Future<bool> exportFile({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  if (kIsWeb) {
    return await FilePicker.saveFile(
          dialogTitle: 'حفظ $fileName',
          fileName: fileName,
          mimeType: mimeType,
          bytes: bytes,
        ) !=
        null;
  }
  final dir = await getTemporaryDirectory();
  final safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final file = File('${dir.path}/$safe');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(ShareParams(
    files: [XFile(file.path, mimeType: mimeType, name: fileName)],
    subject: fileName,
  ));
  return true;
}

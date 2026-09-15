import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// وثيقة الإصدار `app_version/current` — يديرها الأدمن من لوحة التحكم.
/// القراءة عامة (يحتاجها الفحص حتى قبل تسجيل الدخول)، والكتابة للأدمن.
class AppVersionInfo {
  const AppVersionInfo({
    required this.androidVersion,
    required this.androidBuild,
    required this.minBuild,
    required this.androidUrl,
    this.message = '',
    this.maintenance = false,
    this.maintenanceMessage = '',
    this.updatedAt,
  });

  final String androidVersion; // 1.0.2 — للعرض
  final int androidBuild; // versionCode — للمقارنة والتثبيت
  final int minBuild; // أقل build مقبول، دونه تحديث إلزامي
  final String androidUrl; // رابط APK على الاستضافة
  final String message; // ملاحظات الإصدار
  final bool maintenance;
  final String maintenanceMessage;
  final DateTime? updatedAt;

  factory AppVersionInfo.fromMap(Map<String, dynamic> m) => AppVersionInfo(
        androidVersion: m['androidVersion'] as String? ?? '',
        androidBuild: (m['androidBuild'] as num?)?.toInt() ?? 0,
        minBuild: (m['minBuild'] as num?)?.toInt() ?? 0,
        androidUrl: m['androidUrl'] as String? ?? '',
        message: m['message'] as String? ?? '',
        maintenance: m['maintenance'] as bool? ?? false,
        maintenanceMessage: m['maintenanceMessage'] as String? ?? '',
        updatedAt: m['updatedAt'] is Timestamp
            ? (m['updatedAt'] as Timestamp).toDate()
            : null,
      );

  Map<String, dynamic> toMap() => {
        'androidVersion': androidVersion,
        'androidBuild': androidBuild,
        'minBuild': minBuild,
        'androidUrl': androidUrl,
        'message': message,
        'maintenance': maintenance,
        'maintenanceMessage': maintenanceMessage,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

enum UpdateStatus { upToDate, available, forced, maintenance }

class AppUpdateService {
  final FirebaseFirestore _firestore;
  AppUpdateService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String docPath = 'app_version/current';

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.doc(docPath);

  Future<AppVersionInfo?> fetch() async {
    final snap = await _doc.get();
    return snap.exists ? AppVersionInfo.fromMap(snap.data()!) : null;
  }

  Future<void> save(AppVersionInfo info) => _doc.set(info.toMap());

  /// مقارنة نسخة عرض «x.y.z» عدديًا بالمقاطع (1.0.10 > 1.0.2).
  static int compareSemver(String a, String b) {
    List<int> parts(String s) => s
        .trim()
        .split('.')
        .map((p) => int.tryParse(RegExp(r'^\d+').stringMatch(p) ?? '') ?? 0)
        .toList();
    final pa = parts(a), pb = parts(b);
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < n; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  /// حساب الحالة من رقم البناء الحالي — دالة نقية قابلة للاختبار.
  static UpdateStatus computeStatus(
      {required int currentBuild, required AppVersionInfo v}) {
    if (v.maintenance) return UpdateStatus.maintenance;
    if (currentBuild <= 0 || currentBuild >= v.androidBuild) {
      return UpdateStatus.upToDate;
    }
    if (currentBuild < v.minBuild) return UpdateStatus.forced;
    return UpdateStatus.available;
  }

  /// الفحص الكامل — يعيد null على الويب/منصات لا تحتاج APK أو عند تعذر القراءة.
  Future<(AppVersionInfo, UpdateStatus)?> check() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      final pkg = await PackageInfo.fromPlatform();
      final build = int.tryParse(pkg.buildNumber) ?? 0;
      final v = await fetch();
      if (v == null || v.androidBuild <= 0) return null;
      return (v, computeStatus(currentBuild: build, v: v));
    } catch (_) {
      return null;
    }
  }
}

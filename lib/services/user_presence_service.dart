import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة رصد التواجد اللحظي للمستخدمين وإحصائيات المسجلين بالتطبيق
///
/// المهام:
/// 1) إدارة جلسة التواجد اللحظي (Presence): إرسال نبضة "متصل" عند فتح التطبيق،
///    وتحديثها دورياً، والتحويل إلى "غير متصل" عند إغلاق التطبيق أو تصغيره.
/// 2) توفير [onlineUsersStream]: دفق حيّ لحظي لعدد المستخدمين المتواجدين حالياً.
/// 3) توفير [totalUsersStream]: دفق حيّ لإجمالي عدد مستخدمي القرية المسجلين رسمياً.
/// 4) مزامنة العدادات عند تسجيل مستخدم جديد أو حذف حساب.
class UserPresenceService with WidgetsBindingObserver {
  UserPresenceService._({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
  })  : _firestoreInstance = firestore,
        _authInstance = auth;

  static UserPresenceService? _instance;
  static UserPresenceService get instance => _instance ??= UserPresenceService._();

  /// للاختبارات فقط: إمكانية تعيين كائن مخصص
  @visibleForTesting
  static void setMockInstance(UserPresenceService service) {
    _instance = service;
  }

  final FirebaseFirestore? _firestoreInstance;
  final firebase_auth.FirebaseAuth? _authInstance;

  FirebaseFirestore get _firestore =>
      _firestoreInstance ?? FirebaseFirestore.instance;

  firebase_auth.FirebaseAuth get _auth =>
      _authInstance ?? firebase_auth.FirebaseAuth.instance;

  static const String _prefGuestKey = 'app_guest_presence_id';
  static const String _statsDocId = 'users_stats';
  static const int _onlineTimeoutMinutes = 5;

  String? _sessionId;
  Timer? _heartbeatTimer;
  StreamSubscription<firebase_auth.User?>? _authSub;
  bool _initialized = false;
  bool _isOnline = false;

  String? _cachedUserName;
  String? _cachedUserPhoto;
  String? _cachedUserRole;

  String? get currentSessionId => _sessionId;
  bool get isOnline => _isOnline;

  /// تهيئة الخدمة وبدء رصد التواجد ودورات حياة التطبيق
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {
      // قد تفشل فقط في بيئات الاختبار غير المزودة بـ WidgetsBinding
    }

    await _resolveSessionId();

    // الاستماع لتغير حالة الدخول لتبديل المعرف إذا سجل المستخدم دخوله
    try {
      _authSub = _auth.authStateChanges().listen((user) async {
        _cachedUserName = null;
        _cachedUserPhoto = null;
        _cachedUserRole = null;
        if (user != null) {
          unawaited(_fetchAndCacheUserInfo(user.uid));
        }
        final newId = user?.uid ?? await _getGuestSessionId();
        if (_sessionId != newId) {
          if (_isOnline && _sessionId != null) {
            unawaited(_writePresence(isOnline: false));
          }
          _sessionId = newId;
          if (_isOnline) {
            unawaited(_writePresence(isOnline: true));
          }
        }
      });
    } catch (e) {
      debugPrint('UserPresenceService authStateChanges listener warning: $e');
    }

    await markOnline();
    _startHeartbeatTimer();
  }

  Future<void> _resolveSessionId() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid.isNotEmpty) {
        _sessionId = currentUser.uid;
        unawaited(_fetchAndCacheUserInfo(currentUser.uid));
        return;
      }
    } catch (_) {}
    _sessionId = await _getGuestSessionId();
  }

  Future<void> _fetchAndCacheUserInfo(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final d = doc.data();
        if (d != null) {
          _cachedUserName = (d['name'] as String?)?.trim();
          _cachedUserPhoto = (d['photoUrl'] as String?)?.trim();
          _cachedUserRole = (d['role'] as String?)?.trim();
        }
      }
    } catch (e) {
      debugPrint('UserPresenceService _fetchAndCacheUserInfo error: $e');
    }
    _cachedUserName ??= _auth.currentUser?.displayName?.trim();
    _cachedUserPhoto ??= _auth.currentUser?.photoURL?.trim();
  }

  /// إعادة تحميل بيانات المستخدم الحالي وتحديثها في وثيقة التواجد
  Future<void> refreshCurrentUserInfo() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      _cachedUserName = null;
      _cachedUserPhoto = null;
      _cachedUserRole = null;
      await _fetchAndCacheUserInfo(uid);
      if (_isOnline) {
        await _writePresence(isOnline: true);
      }
    }
  }

  Future<String> _getGuestSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(_prefGuestKey);
      if (id == null || id.isEmpty) {
        id = 'guest_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
        await prefs.setString(_prefGuestKey, id);
      }
      return id;
    } catch (_) {
      return 'guest_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    // إرسال نبضة خفيفة كل دقيقتين طالما التطبيق نشط
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_isOnline) {
        _writePresence(isOnline: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      markOnline();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      markOffline();
    }
  }

  /// تسجيل المستخدم كـ "متواجد حالياً"
  Future<void> markOnline() async {
    _isOnline = true;
    if (_sessionId == null) {
      await _resolveSessionId();
    }
    await _writePresence(isOnline: true);
  }

  /// تسجيل المستخدم كـ "غير متواجد"
  Future<void> markOffline() async {
    _isOnline = false;
    await _writePresence(isOnline: false);
  }

  Future<void> _writePresence({required bool isOnline}) async {
    final sid = _sessionId;
    if (sid == null || sid.isEmpty) return;

    try {
      final docRef = _firestore.collection('app_presence').doc(sid);
      if (isOnline) {
        final currentUser = _auth.currentUser;
        final isGuest = currentUser == null;
        if (!isGuest && _cachedUserName == null) {
          await _fetchAndCacheUserInfo(currentUser.uid);
        }

        final Map<String, dynamic> data = {
          'sessionId': sid,
          'isOnline': true,
          'isGuest': isGuest,
          'lastActive': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.name,
        };

        if (currentUser != null) {
          data['userId'] = currentUser.uid;
          final name = (_cachedUserName != null && _cachedUserName!.isNotEmpty)
              ? _cachedUserName
              : (currentUser.displayName?.trim().isNotEmpty == true
                  ? currentUser.displayName!.trim()
                  : 'عضو في التطبيق');
          data['userName'] = name;

          final photo =
              (_cachedUserPhoto != null && _cachedUserPhoto!.isNotEmpty)
                  ? _cachedUserPhoto
                  : currentUser.photoURL?.trim();
          if (photo != null && photo.isNotEmpty) {
            data['userPhoto'] = photo;
          }
          if (_cachedUserRole != null && _cachedUserRole!.isNotEmpty) {
            data['userRole'] = _cachedUserRole;
          }
        }

        await docRef.set(data, SetOptions(merge: true));
      } else {
        await docRef.set({
          'isOnline': false,
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // إخفاق صامت لحماية سلاسة الواجهة إن انقطع الاتصال
      debugPrint('UserPresenceService _writePresence error: $e');
    }
  }

  /// دفق لحظي لعدد المستخدمين المتواجدين حالياً (النقطة الخضراء)
  ///
  /// يقوم بفلترة الجلسات النشطة والتأكد من أنها متصلة وحدثت خلال الـ 5 دقائق الأخيرة.
  Stream<int> get onlineUsersStream {
    try {
      return _firestore
          .collection('app_presence')
          .where('isOnline', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        final now = DateTime.now();
        int activeCount = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data['isOnline'] != true) continue;

          final lastActiveTs = data['lastActive'] as Timestamp?;
          if (lastActiveTs == null) {
            // وثيقة جديدة أُنشئت للتو
            activeCount++;
            continue;
          }

          final diffMinutes = now.difference(lastActiveTs.toDate()).inMinutes;
          if (diffMinutes < _onlineTimeoutMinutes) {
            activeCount++;
          }
        }

        // بما أن المستخدم الحالي يرى الشاشة ونشط، فالعدد لا يقل عن 1
        return activeCount > 0 ? activeCount : 1;
      }).handleError((_) => 1);
    } catch (_) {
      return Stream.value(1);
    }
  }

  /// دفق تفصيلي لقائمة المستخدمين المتواجدين حالياً (مخصص للأدمن العام لعرض الأسماء والصور)
  Stream<List<OnlineUserInfo>> get onlineUsersListStream {
    try {
      return _firestore
          .collection('app_presence')
          .where('isOnline', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        final now = DateTime.now();
        final List<OnlineUserInfo> users = [];
        final Set<String> seenUserIds = {};

        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data['isOnline'] != true) continue;

          final lastActiveTs = data['lastActive'] as Timestamp?;
          if (lastActiveTs != null) {
            final diffMinutes = now.difference(lastActiveTs.toDate()).inMinutes;
            if (diffMinutes >= _onlineTimeoutMinutes) {
              continue;
            }
          }

          final info = OnlineUserInfo.fromMap(doc.id, data);
          // تجنب تكرار نفس المستخدم المسجل إذا كان لديه أكثر من جلسة نشطة
          if (!info.isGuest && info.userId != null) {
            if (seenUserIds.contains(info.userId)) continue;
            seenUserIds.add(info.userId!);
          }
          users.add(info);
        }

        // الترتيب:
        // 1. الأعضاء المسجلون أولاً، يليهم الزوار
        // 2. بين الأعضاء: المديرون أولاً، ثم الأحدث نشاطاً
        // 3. بين الزوار: الأحدث نشاطاً
        users.sort((a, b) {
          if (!a.isGuest && b.isGuest) return -1;
          if (a.isGuest && !b.isGuest) return 1;

          if (!a.isGuest && !b.isGuest) {
            final aIsAdmin = a.isAdmin;
            final bIsAdmin = b.isAdmin;
            if (aIsAdmin && !bIsAdmin) return -1;
            if (!aIsAdmin && bIsAdmin) return 1;
          }

          final aTime = a.lastActive ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.lastActive ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

        return users;
      }).handleError((e) {
        debugPrint('onlineUsersListStream handleError: $e');
        return <OnlineUserInfo>[];
      });
    } catch (e) {
      debugPrint('onlineUsersListStream catch: $e');
      return Stream.value(<OnlineUserInfo>[]);
    }
  }

  /// دفق حي لإجمالي المستخدمين المسجلين رسمياً في التطبيق (النقطة الحمراء)
  Stream<int> get totalUsersStream {
    try {
      return _firestore
          .collection('app_stats')
          .doc(_statsDocId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) return 19;
        final data = snapshot.data();
        final count = (data?['totalUsers'] as num?)?.toInt();
        return (count != null && count > 0) ? count : 19;
      }).handleError((_) => 19);
    } catch (_) {
      return Stream.value(19);
    }
  }

  /// زيادة إجمالي المستخدمين بمقدار 1 عند تسجيل مستخدم جديد
  Future<void> incrementTotalUsers() async {
    try {
      await _firestore.collection('app_stats').doc(_statsDocId).set({
        'totalUsers': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('incrementTotalUsers error: $e');
    }
  }

  /// إنقاص إجمالي المستخدمين بمقدار 1 عند حذف حساب مستخدم
  Future<void> decrementTotalUsers() async {
    try {
      await _firestore.collection('app_stats').doc(_statsDocId).set({
        'totalUsers': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('decrementTotalUsers error: $e');
    }
  }

  /// مزامنة دقيقة لإجمالي المسجلين من قبل الأدمن
  Future<void> syncTotalUsersFromAdmin() async {
    try {
      final snap = await _firestore.collection('users').count().get();
      final count = snap.count ?? 19;
      await _firestore.collection('app_stats').doc(_statsDocId).set({
        'totalUsers': count,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('syncTotalUsersFromAdmin error: $e');
    }
  }

  /// تنظيف الموارد عند الإغلاق
  void dispose() {
    _heartbeatTimer?.cancel();
    _authSub?.cancel();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _initialized = false;
  }
}

/// نموذج بيانات المستخدم المتواجد لحظياً بالتطبيق
class OnlineUserInfo {
  final String sessionId;
  final String? userId;
  final String name;
  final String? photoUrl;
  final String? role;
  final bool isGuest;
  final DateTime? lastActive;
  final String? platform;

  const OnlineUserInfo({
    required this.sessionId,
    this.userId,
    required this.name,
    this.photoUrl,
    this.role,
    this.isGuest = false,
    this.lastActive,
    this.platform,
  });

  factory OnlineUserInfo.fromMap(String id, Map<String, dynamic> data) {
    final lastActiveTs = data['lastActive'] as Timestamp?;
    final isGuest = data['isGuest'] == true;
    final rawName = (data['userName'] as String?)?.trim();
    final rawPhoto = (data['userPhoto'] as String?)?.trim();
    final rawRole = (data['userRole'] as String?)?.trim();

    return OnlineUserInfo(
      sessionId: id,
      userId: data['userId'] as String?,
      name: (rawName != null && rawName.isNotEmpty)
          ? rawName
          : (isGuest ? 'زائر للتطبيق' : 'عضو في التطبيق'),
      photoUrl: (rawPhoto != null && rawPhoto.isNotEmpty) ? rawPhoto : null,
      role: (rawRole != null && rawRole.isNotEmpty) ? rawRole : null,
      isGuest: isGuest,
      lastActive: lastActiveTs?.toDate(),
      platform: data['platform'] as String?,
    );
  }

  /// هل المستخدم صاحب صلاحية إدارية
  bool get isAdmin => role == 'admin' || role == 'assistant_admin';

  /// مسمى الدور العربي
  String get roleLabel {
    if (isGuest) return 'زائر';
    switch (role) {
      case 'admin':
        return 'مدير عام';
      case 'assistant_admin':
        return 'أدمن مساعد';
      case 'medical_admin':
        return 'مدير طبي';
      case 'agricultural_admin':
        return 'مشرف زراعي';
      case 'seller':
        return 'بائع معتمد';
      case 'moderator':
        return 'مشرف';
      default:
        return 'عضو مسجل';
    }
  }
}

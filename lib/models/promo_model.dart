import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseTs(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// إعلان دعائي منبثق يظهر فوق الشاشات (مجموعة promos).
/// linkType: none | app | url | whatsapp | facebook | instagram | youtube | telegram | tiktok
class Promo {
  const Promo({
    this.id = '',
    required this.title,
    required this.imageUrl,
    required this.placement,
    this.linkType = 'none',
    this.linkValue = '',
    this.showOnce = true,
    required this.startsAt,
    required this.endsAt,
    this.isActive = true,
    this.playSound = false,
    this.vibrate = false,
    this.version = 1,
    this.createdBy = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String imageUrl;

  /// مفتاح مكان الظهور من kPromoPlacements.
  final String placement;
  final String linkType;
  final String linkValue;

  /// true = مرة واحدة لكل مستخدم — false = كل زيارة خلال المدة.
  final bool showOnce;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;
  final bool playSound;
  final bool vibrate;

  /// يزداد مع كل تعديل جوهري — يعيد ظهور الإعلان «مرة واحدة» من جديد.
  final int version;
  final String createdBy;
  final DateTime? createdAt;

  bool isVisibleAt(DateTime now) =>
      isActive &&
      imageUrl.isNotEmpty &&
      !now.isBefore(startsAt) &&
      now.isBefore(endsAt);

  factory Promo.fromJson(Map<String, dynamic> json, String docId) {
    return Promo(
      id: docId,
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      placement: json['placement'] as String? ?? '',
      linkType: json['linkType'] as String? ?? 'none',
      linkValue: json['linkValue'] as String? ?? '',
      showOnce: json['showOnce'] as bool? ?? true,
      startsAt: _parseTs(json['startsAt']) ?? DateTime.now(),
      endsAt: _parseTs(json['endsAt']) ?? DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
      playSound: json['playSound'] as bool? ?? false,
      vibrate: json['vibrate'] as bool? ?? false,
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: _parseTs(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'imageUrl': imageUrl,
        'placement': placement,
        'linkType': linkType,
        'linkValue': linkValue,
        'showOnce': showOnce,
        'startsAt': Timestamp.fromDate(startsAt),
        'endsAt': Timestamp.fromDate(endsAt),
        'isActive': isActive,
        'playSound': playSound,
        'vibrate': vibrate,
        'version': version,
        'createdBy': createdBy,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  Promo copyWith({
    String? title,
    String? imageUrl,
    String? placement,
    String? linkType,
    String? linkValue,
    bool? showOnce,
    DateTime? startsAt,
    DateTime? endsAt,
    bool? isActive,
    bool? playSound,
    bool? vibrate,
    int? version,
  }) =>
      Promo(
        id: id,
        title: title ?? this.title,
        imageUrl: imageUrl ?? this.imageUrl,
        placement: placement ?? this.placement,
        linkType: linkType ?? this.linkType,
        linkValue: linkValue ?? this.linkValue,
        showOnce: showOnce ?? this.showOnce,
        startsAt: startsAt ?? this.startsAt,
        endsAt: endsAt ?? this.endsAt,
        isActive: isActive ?? this.isActive,
        playSound: playSound ?? this.playSound,
        vibrate: vibrate ?? this.vibrate,
        version: version ?? this.version,
        createdBy: createdBy,
        createdAt: createdAt,
      );

  /// مفتاح «شوهد» المحلي — يتغيّر تلقائيًا مع كل إصدار جديد من الإعلان.
  String get seenKey => 'promo_seen_${id}_v$version';
}

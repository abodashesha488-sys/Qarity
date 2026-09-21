import 'package:cloud_firestore/cloud_firestore.dart';

/// محتوى زراعي قابل للتحرير من الأدمن الزراعي، مع fallback للمحتوى المضمّن.
class AgricultureContent {
  const AgricultureContent({
    required this.id,
    required this.section,
    required this.title,
    this.subtitle = '',
    this.body = '',
    this.imageUrl,
    this.tags = const [],
    this.sortOrder = 0,
    this.isPublished = true,
  });

  final String id;
  final String section;
  final String title;
  final String subtitle;
  final String body;
  final String? imageUrl;
  final List<String> tags;
  final int sortOrder;
  final bool isPublished;

  factory AgricultureContent.fromJson(Map<String, dynamic> json, String docId) {
    return AgricultureContent(
      id: docId,
      section: json['section'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      body: json['body'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      tags: (json['tags'] as List?)?.whereType<String>().toList() ?? const [],
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isPublished: json['isPublished'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'section': section,
        'title': title,
        'subtitle': subtitle,
        'body': body,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
        'tags': tags,
        'sortOrder': sortOrder,
        'isPublished': isPublished,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

abstract final class AgricultureSections {
  static const advisor = 'advisor';
  static const crops = 'crops';
  static const fertilizers = 'fertilizers';
  static const pesticides = 'pesticides';
  static const weather = 'weather';
}

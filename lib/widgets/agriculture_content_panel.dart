import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/agriculture_content_model.dart';
import '../services/agriculture_content_service.dart';

/// جزء المحتوى القابل للتحرير في الشاشات الزراعية.
/// لا يظهر زر التحرير إلا للدور الزراعي أو المدير العام.
class AgricultureContentPanel extends StatefulWidget {
  const AgricultureContentPanel({
    super.key,
    required this.section,
    this.title = 'محتوى محدث من الإدارة',
  });

  final String section;
  final String title;

  @override
  State<AgricultureContentPanel> createState() =>
      _AgricultureContentPanelState();
}

class _AgricultureContentPanelState extends State<AgricultureContentPanel> {
  final _service = AgricultureContentService();
  late final Stream<List<AgricultureContent>> _stream =
      _service.watchSection(widget.section);
  bool _canEdit = false;

  @override
  void initState() {
    super.initState();
    _loadPermission();
  }

  Future<void> _loadPermission() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snapshot = await _service.userRole(uid);
      if (mounted) {
        setState(() =>
            _canEdit = snapshot == 'admin' || snapshot == 'agricultural_admin');
      }
    } catch (_) {}
  }

  Future<void> _editContent([AgricultureContent? content]) async {
    final title = TextEditingController(text: content?.title ?? '');
    final subtitle = TextEditingController(text: content?.subtitle ?? '');
    final body = TextEditingController(text: content?.body ?? '');
    final imageUrl = TextEditingController(text: content?.imageUrl ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(content == null ? 'إضافة محتوى' : 'تعديل المحتوى'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'العنوان')),
              TextField(
                  controller: subtitle,
                  decoration:
                      const InputDecoration(labelText: 'العنوان الفرعي')),
              TextField(
                  controller: body,
                  maxLines: 5,
                  decoration:
                      const InputDecoration(labelText: 'المقال / التفاصيل')),
              TextField(
                  controller: imageUrl,
                  decoration: const InputDecoration(
                      labelText: 'رابط الصورة (اختياري)')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              await _service.save(AgricultureContent(
                id: content?.id ?? '',
                section: widget.section,
                title: title.text.trim(),
                subtitle: subtitle.text.trim(),
                body: body.text.trim(),
                imageUrl:
                    imageUrl.text.trim().isEmpty ? null : imageUrl.text.trim(),
                sortOrder: content?.sortOrder ?? 0,
              ));
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    title.dispose();
    subtitle.dispose();
    body.dispose();
    imageUrl.dispose();
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AgricultureContent>>(
      stream: _stream,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AgricultureContent>[];
        if (items.isEmpty && !_canEdit) return const SizedBox.shrink();
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(widget.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900))),
                    if (_canEdit)
                      IconButton(
                        tooltip: 'إضافة محتوى',
                        onPressed: () => _editContent(),
                        icon: const Icon(Icons.edit_rounded),
                      ),
                  ],
                ),
                for (final item in items) ...[
                  if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (item.subtitle.isNotEmpty) Text(item.subtitle),
                  if (item.body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child:
                          Text(item.body, style: const TextStyle(height: 1.6)),
                    ),
                  if (_canEdit)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: () => _editContent(item),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('تعديل'),
                      ),
                    ),
                  const Divider(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

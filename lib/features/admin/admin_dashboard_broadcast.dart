part of 'admin_dashboard.dart';

class _BroadcastPage extends StatefulWidget {
  const _BroadcastPage({required this.currentUid});
  final String? currentUid;

  @override
  State<_BroadcastPage> createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<_BroadcastPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _routeController = TextEditingController();
  bool _isSending = false;
  bool _sendAlert = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final route = _routeController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('العنوان والنص مطلوبان'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await RemotePushService.broadcastToAllUsers(
        title: title,
        body: body,
        route: route.isEmpty ? null : route,
        alert: _sendAlert,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال الإشعار الإذاعي لجميع المستخدمين${_sendAlert ? ' (تنبيه عاجل)' : ''}'),
          backgroundColor: const Color(0xFF6F4E37),
        ),
      );
      _titleController.clear();
      _bodyController.clear();
      _routeController.clear();
      setState(() => _sendAlert = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إرسال إشعار إذاعي لجميع المستخدمين',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'سيصل هذا الإشعار لجميع مستخدمي التطبيق فوراً، حتى لو كان التطبيق مغلقاً. '
            'استخدمه للإعلانات المهمة والتنبيهات العاجلة.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تفاصيل الإشعار',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'العنوان *',
                      hintText: 'مثال: خبر عاجل، صيانة مجدولة، إعلان مهم...',
                      prefixIcon: Icon(Icons.title_rounded),
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bodyController,
                    decoration: const InputDecoration(
                      labelText: 'النص *',
                      hintText: 'اكتب نص الإشعار هنا...',
                      prefixIcon: Icon(Icons.message_rounded),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _routeController,
                    decoration: const InputDecoration(
                      labelText: 'مسار الفتح (اختياري)',
                      hintText: 'مثال: /news، /market، /obituaries، /forum...',
                      prefixIcon: Icon(Icons.open_in_new_rounded),
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('تنبيه عاجل (صوت + اهتزاز + أولوية قصوى)'),
                    subtitle: const Text('استخدم للحالات الطارئة فقط'),
                    value: _sendAlert,
                    onChanged: (v) => setState(() => _sendAlert = v),
                    activeThumbColor: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSending ? null : _sendBroadcast,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded),
                      label: Text(_isSending ? 'جاري الإرسال...' : 'إرسال للجميع الآن'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _sendAlert ? Colors.red : const Color(0xFF6F4E37),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _QuickTemplates(
            onSelectTemplate: (title, body, route, alert) {
              _titleController.text = title;
              _bodyController.text = body;
              _routeController.text = route;
              setState(() => _sendAlert = alert);
            },
          ),
        ],
      ),
    );
  }
}

class _QuickTemplates extends StatefulWidget {
  const _QuickTemplates({
    required this.onSelectTemplate,
  });

  final void Function(String title, String body, String route, bool alert) onSelectTemplate;

  @override
  State<_QuickTemplates> createState() => _QuickTemplatesState();
}

class _QuickTemplatesState extends State<_QuickTemplates> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = [
      {'title': '🛠️ صيانة مجدولة', 'body': 'سيتم إجراء صيانة للتطبيق يوم [التاريخ] من [الساعة] إلى [الساعة]. نعتذر عن أي إزعاج.', 'route': '/settings', 'alert': false},
      {'title': '📢 إعلان مهم', 'body': 'يرجى مراجعة قسم الأخبار للاطلاع على الإعلان الجديد الخاص بـ [الموضوع].', 'route': '/news', 'alert': false},
      {'title': '⚠️ تنبيه عاجل', 'body': 'تنبيه مهم لجميع الأهالي: [نص التنبيه]. يرجى اتخاذ الإجراءات اللازمة.', 'route': '/', 'alert': true},
      {'title': '🎉 مناسبة قادمة', 'body': 'تذكير: غداً مناسبة [اسم المناسبة] في القرية. نتمنى للجميع وقتاً سعيداً.', 'route': '/occasions', 'alert': false},
      {'title': '🩺 حملة طبية', 'body': 'تنطلق غداً حملة [نوع الحملة] في المركز الطبي الخيري. الحضور مجاني للجميع.', 'route': '/medical', 'alert': false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('قوالب سريعة',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: templates.map((t) {
            return ActionChip(
              avatar: Icon(t['alert'] as bool ? Icons.warning_amber_rounded : Icons.content_copy_rounded,
                  size: 16, color: (t['alert'] as bool) ? Colors.red : theme.colorScheme.primary),
              label: Text(t['title'] as String),
              onPressed: () {
                widget.onSelectTemplate(
                  t['title'] as String,
                  t['body'] as String,
                  t['route'] as String,
                  t['alert'] as bool,
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
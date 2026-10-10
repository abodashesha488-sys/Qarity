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

  /// سبب الفشل بعبارة عربية مستقلة لكل حالة — **بلا أرقام داخلية في الواجهة**
  /// (رمز الوضع وخيط العامل يبقى في `PushSendResult` لمن يحتاجه، لا في الشريط).
  String _broadcastFailureText(PushSendResult result) {
    const prefix = 'لم يُرسل الإشعار — ';
    final reason = switch (result.status) {
      PushSendStatus.sent => 'قُبل الطلب',
      PushSendStatus.noEndpoint =>
        'وجه خدمة الإشعارات غير مضبوط في هذا البناء.',
      PushSendStatus.noSession =>
        'لا جلسة تسجيل دخول محفوظة على هذا الجهاز، والإرسال الإذاعي يتطلب أدمنًا مسجّلًا.',
      PushSendStatus.timeout =>
        'انتهت مهلة الوصول إلى خدمة الإشعارات — أعد المحاولة بعد لحظات.',
      PushSendStatus.network =>
        'لا يمكن الوصول إلى خدمة الإشعارات — تحقّق من الاتصال ثم أعد المحاولة.',
      PushSendStatus.rejected =>
        'رفضت خدمة الإشعارات هذا الحساب — الإرسال الإذاعي للمدير العام أو المدير المساعد فقط.',
      PushSendStatus.badRequest =>
        'رفضت خدمة الإشعارات الطلب — تحقّق من العنوان والنص ثم أعد المحاولة.',
      PushSendStatus.serverFailed =>
        'فشل الإرسال داخل خدمة الإشعارات — أعد المحاولة بعد لحظات.',
      PushSendStatus.badResponse =>
        'جاء جواب غير مفهوم من خدمة الإشعارات فلم تُؤكَّد الوصول.',
    };
    return '$prefix$reason';
  }

  Future<void> _sendBroadcast() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final route = _routeController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        // أرضيات الشريط ألوان ثابتة في السمتين وحبره الافتراضي في الداكن داكن
        // ⇒ البياض يُثبَّت، والأحمر هو الهادئ لا `Colors.red` الساطع.
        const SnackBar(
            content: Text('العنوان والنص مطلوبان',
                style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSending = true);
    // `broadcastToAllUsers` **لا ترمي أبدًا**: الحالة تُقرأ من الناتج، فلا حاجة
    // إلى try/catch كان يصل إلى فرع «خطأ: $e» الميت بينما كل فشل صامت يُبلَّغ
    // كنجاح.
    final result = await RemotePushService.broadcastToAllUsers(
      title: title,
      body: body,
      route: route.isEmpty ? null : route,
      alert: _sendAlert,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    if (result.isSent) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'تم إرسال الإشعار الإذاعي لجميع المستخدمين${_sendAlert ? ' (تنبيه عاجل)' : ''}',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
        ),
      );
      _titleController.clear();
      _bodyController.clear();
      _routeController.clear();
      setState(() => _sendAlert = false);
    } else {
      messenger.showSnackBar(
        SnackBar(
            content: Text(_broadcastFailureText(result),
                style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.error),
      );
    }
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageHeader(
            icon: Icons.campaign_rounded,
            title: 'إرسال إشعار إذاعي لجميع المستخدمين',
            subtitle: 'سيصل هذا الإشعار لجميع مستخدمي التطبيق فوراً، حتى لو كان التطبيق مغلقاً. استخدمه للإعلانات المهمة والتنبيهات العاجلة.',
            color: Color(0xFF1565C0),
          ),
          const SizedBox(height: 20),
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
                    activeThumbColor:
                        AppColors.inkOn(AppColors.error, theme.brightness),
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
                        // الأرضية ثابتة في السمتين بينما `onPrimary` في الداكن
                        // داكن (1.4 فوق الزمردي) ⇒ البياض يُثبَّت، والتنبيه
                        // العاجل بأحمر الهادئ لا `Colors.red` الساطع.
                        backgroundColor:
                            _sendAlert ? AppColors.error : AppColors.primary,
                        foregroundColor: Colors.white,
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
                  size: 16, color: (t['alert'] as bool) ? AppColors.inkOn(AppColors.error, theme.brightness) : theme.colorScheme.primary),
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
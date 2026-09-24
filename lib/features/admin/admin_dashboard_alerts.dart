part of 'admin_dashboard.dart';

/// تبويب «التنبيهات العاجلة» — إدارة التنبيه الأحمر والخبر العاجل الأصفر:
/// نص + مستوى ظهور (عرض/إشعار/صوت) + مدة صلاحية + إعادة إرسال صريحة.
class _AlertsControlPage extends StatelessWidget {
  const _AlertsControlPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFC62828), size: 22),
            const SizedBox(width: 8),
            Text('إدارة التنبيهات العاجلة',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'التنبيه يظهر أعلى شاشة كل المستخدمين فورًا. «إعادة إرسال الإشعار» هي وحدها ما يوقظ هواتف الأهالي — التعديل العادي صامت.',
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.6),
        ),
        const SizedBox(height: 14),
        const _ManagedAlertCard(),
        const SizedBox(height: 14),
        const _ManagedAlertCard(breaking: true),
      ],
    );
  }
}

class _ManagedAlertCard extends StatefulWidget {
  const _ManagedAlertCard({this.breaking = false});
  final bool breaking;

  @override
  State<_ManagedAlertCard> createState() => _ManagedAlertCardState();
}

class _ManagedAlertCardState extends State<_ManagedAlertCard> {
  final AlertService _service = AlertService();
  final TextEditingController _controller = TextEditingController();
  VillageAlert _alert = const VillageAlert();
  String _mode = VillageAlertMode.push;
  int _validHours = 0; // 0 = بدون انتهاء
  bool _loading = true;
  bool _busy = false;

  bool get _breaking => widget.breaking;
  Color get _accent =>
      _breaking ? const Color(0xFFF9A825) : const Color(0xFFC62828);
  Color get _onActive => _breaking ? const Color(0xFF0D47A1) : Colors.white;

  static const List<(int, String)> _durations = [
    (0, 'بدون انتهاء'),
    (1, 'ساعة'),
    (3, '3 ساعات'),
    (6, '6 ساعات'),
    (12, '12 ساعة'),
    (24, 'يوم'),
    (72, '3 أيام'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final alert =
          _breaking ? await _service.getBreaking() : await _service.getAlert();
      if (!mounted) return;
      setState(() {
        _alert = alert;
        _controller.text = alert.message;
        _mode = alert.mode;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color ?? const Color(0xFF6F4E37)));
  }

  Future<void> _run(Future<void> Function() action, String okMsg) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _load();
      _snack(okMsg);
    } catch (e) {
      _snack('خطأ: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enable() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _snack('اكتب نص التنبيه أولاً', color: Colors.orange);
      return Future.value();
    }
    final expiresAt = _validHours == 0
        ? null
        : DateTime.now().add(Duration(hours: _validHours));
    return _run(
        () => _breaking
            ? _service.enableBreaking(text, mode: _mode, expiresAt: expiresAt)
            : _service.enableAlert(text, mode: _mode, expiresAt: expiresAt),
        _mode == VillageAlertMode.display
            ? '✅ مُفعَّل للعرض فقط — بلا إشعارات'
            : (_mode == VillageAlertMode.sound
                ? '✅ مُفعَّل + إشعار بصوت واهتزاز لجميع الأهالي'
                : '✅ مُفعَّل وأُرسل إشعار لجميع الأهالي'));
  }

  Future<void> _saveSilent() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _snack('اكتب النص أولاً', color: Colors.orange);
      return Future.value();
    }
    return _run(
        () => _breaking
            ? _service.updateBreakingText(text)
            : _service.updateAlertText(text),
        'تم تحديث النص بصمت (بلا إشعارات جديدة)');
  }

  Future<void> _renotify() => _run(
      () => _breaking
          ? _service.renotifyBreaking()
          : _service.renotifyAlert(),
      '📣 أعيد إرسال الإشعار لجميع الأهالي');

  Future<void> _disable() => _run(
      () => _breaking ? _service.disableBreaking() : _service.disableAlert(),
      'تم الإيقاف — عادت المساحة لما قبل التفعيل');

  String get _statusText {
    if (!_alert.isActive) return 'غير مُفعَّل';
    final exp = _alert.expiresAt;
    if (exp != null && !DateTime.now().isBefore(exp)) return 'انتهت صلاحيته';
    if (exp != null) {
      final mins = exp.difference(DateTime.now()).inMinutes;
      final h = mins ~/ 60;
      return h >= 1 ? 'مُفعَّل — متبقٍ $hس ${mins % 60}د' : 'مُفعَّل — متبقٍ $minsد';
    }
    return 'مُفعَّل الآن';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final red = _accent;
    if (_loading) {
      return const SizedBox(
          height: 90,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    final active = _alert.isActive;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            red.withValues(alpha: active ? 0.14 : 0.06),
            theme.colorScheme.surface,
          ],
        ),
        border: Border.all(
            color: red.withValues(alpha: active ? 0.5 : 0.25),
            width: active ? 1.4 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(
                    _breaking ? Icons.bolt_rounded : Icons.campaign_rounded,
                    color: red,
                    size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    _breaking ? 'الخبر العاجل للقرية' : 'تنبيه القرية العاجل',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: active ? red : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _statusText,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: active
                          ? _onActive
                          : theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            minLines: 2,
            maxLength: 240,
            enabled: !_busy,
            decoration: InputDecoration(
              hintText: _breaking
                  ? 'مثال: سوق الأحد مفتوح غدًا حتى المغرب — الدخول مجاني من الجهة البحرية'
                  : 'مثال: انقطاع المياه غدًا من 8 ص حتى 12 ظ — ادخروا حاجتكم',
              hintStyle:
                  theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              counterText: '',
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: red.withValues(alpha: 0.4))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: red.withValues(alpha: 0.4))),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),
          Text('مستوى الظهور',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _modeChip(VillageAlertMode.display, 'عرض فقط', Icons.visibility_rounded),
              _modeChip(VillageAlertMode.push, 'عرض + إشعار', Icons.notifications_rounded),
              _modeChip(VillageAlertMode.sound, 'عرض + إشعار + صوت واهتزاز',
                  Icons.volume_up_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Text('مدة الصلاحية (تنتهي تلقائيًا)',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (hours, label) in _durations)
                ChoiceChip(
                  label: Text(label,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800)),
                  selected: _validHours == hours,
                  selectedColor: red,
                  onSelected: (_) => setState(() => _validHours = hours),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (!active)
            _bigButton(
              icon: Icons.play_circle_fill_rounded,
              label: 'تفعيل الآن',
              bg: red,
              fg: _onActive,
              onTap: _enable,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _bigButton(
                        icon: Icons.save_rounded,
                        label: 'حفظ (صامت)',
                        bg: Colors.blueGrey,
                        fg: Colors.white,
                        onTap: _saveSilent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _bigButton(
                        icon: Icons.send_rounded,
                        label: 'إعادة إرسال الإشعار',
                        bg: red,
                        fg: _onActive,
                        onTap: _renotify,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _bigButton(
                        icon: Icons.refresh_rounded,
                        label: 'تفعيل جديد بالنمط/المدة',
                        bg: const Color(0xFF00897B),
                        fg: Colors.white,
                        onTap: _enable,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _bigButton(
                        icon: Icons.stop_circle_outlined,
                        label: 'إيقاف',
                        bg: Colors.transparent,
                        fg: Colors.blueGrey,
                        border: Colors.blueGrey,
                        onTap: _disable,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _modeChip(String value, String label, IconData icon) {
    final selected = _mode == value;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _mode = value),
      avatar: Icon(icon,
          size: 15, color: selected ? _onActive : _accent),
      label: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected ? _onActive : null)),
      selectedColor: _accent,
    );
  }

  Widget _bigButton({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    Color? border,
    required VoidCallback onTap,
  }) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        side: border == null ? null : BorderSide(color: border),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      ),
      onPressed: _busy ? null : onTap,
      icon: Icon(icon, size: 18),
      label: Flexible(
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      ),
    );
  }
}

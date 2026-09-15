part of 'admin_dashboard.dart';

/// بطاقة إدارة إصدار التطبيق — ينشر الأدمن رقم نسخة الأندرويد ورابط الـAPK
/// وشرط الإلزام ووضع الصيانة. الويب يتحديث تلقائيًا ولا يحتاج هنا شيئًا.
class _AppVersionAdminCard extends StatefulWidget {
  const _AppVersionAdminCard();

  @override
  State<_AppVersionAdminCard> createState() => _AppVersionAdminCardState();
}

class _AppVersionAdminCardState extends State<_AppVersionAdminCard> {
  final AppUpdateService _service = AppUpdateService();
  AppVersionInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final v = await _service.fetch();
      if (mounted) {
        setState(() {
          _info = v;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color get _accent => _info?.maintenance == true
      ? const Color(0xFFEF6C00)
      : const Color(0xFF1565C0);

  Future<void> _openForm() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (ctx, controller) => _AppVersionForm(
          current: _info,
          service: _service,
          controller: controller,
        ),
      ),
    );
    if (saved == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
            content: Text('تم نشر بيانات الإصدار'),
            backgroundColor: Color(0xFF6F4E37)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        border: Border.all(color: _accent.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.system_update_rounded,
                    color: _accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('إصدار التطبيق (أندرويد)',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
              if (_info != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                      _info!.maintenance
                          ? 'وضع الصيانة مُفعّل'
                          : 'v${_info!.androidVersion} (${_info!.androidBuild})',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Text('جارٍ التحميل…',
                style: TextStyle(fontSize: 12, color: Colors.black54))
          else if (_info == null)
            const Text(
                'لم يُنشر أي إصدار بعد — المستخدمون لن看到我 أي تنبيه تحديث. '
                'اضغط «نشر الإصدار» عند تجهيز APK جديد.',
                style: TextStyle(
                    fontSize: 12, height: 1.6, color: Colors.black54))
          else ...[
            Text(
                'الحد الأدنى للإلزام: build ${_info!.minBuild} — '
                '${_info!.androidUrl.isNotEmpty ? 'الرابط جاهز ✓' : 'لا رابط APK!'}',
                style: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700)),
            if (_info!.message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_info!.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openForm,
              style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: const Icon(Icons.edit_rounded, size: 17),
              label: Text(_info == null ? 'نشر الإصدار' : 'تعديل الإصدار المنشور',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppVersionForm extends StatefulWidget {
  const _AppVersionForm(
      {required this.current,
      required this.service,
      required this.controller});
  final AppVersionInfo? current;
  final AppUpdateService service;
  final ScrollController controller;

  @override
  State<_AppVersionForm> createState() => _AppVersionFormState();
}

class _AppVersionFormState extends State<_AppVersionForm> {
  late final _version =
      TextEditingController(text: widget.current?.androidVersion ?? '1.0.2');
  late final _build =
      TextEditingController(text: '${widget.current?.androidBuild ?? 2}');
  late final _min =
      TextEditingController(text: '${widget.current?.minBuild ?? 1}');
  late final _url = TextEditingController(
      text: widget.current?.androidUrl ??
          'https://abudshisha.web.app/download/qarity.apk');
  late final _message =
      TextEditingController(text: widget.current?.message ?? '');
  late final _maintMsg = TextEditingController(
      text: widget.current?.maintenanceMessage ?? '');
  late bool _maintenance = widget.current?.maintenance ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _version.dispose();
    _build.dispose();
    _min.dispose();
    _url.dispose();
    _message.dispose();
    _maintMsg.dispose();
    super.dispose();
  }

  String? _validateVersion(String? v) {
    if (v == null || !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(v.trim())) {
      return 'صيغة غير صحيحة — مثال: 1.0.2';
    }
    return null;
  }

  Future<void> _save() async {
    final buildN = int.tryParse(_build.text.trim()) ?? 0;
    final minN = int.tryParse(_min.text.trim()) ?? 0;
    final url = _url.text.trim();
    String? err;
    if (_validateVersion(_version.text) != null) {
      err = 'رقم الإصدار يجب أن يكون مثل 1.0.2';
    } else if (buildN <= 0) {
      err = 'رقم البناء (build) يجب أن يكون موجبًا';
    } else if (minN > buildN) {
      err = 'الحد الأدنى لا يجوز أن يتجاوز رقم البناء الحالي';
    } else if (!_maintenance &&
        url.isNotEmpty &&
        !url.startsWith('https://')) {
      err = 'رابط الـAPK يجب أن يبدأ بـ https://';
    }
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.save(AppVersionInfo(
        androidVersion: _version.text.trim(),
        androidBuild: buildN,
        minBuild: minN,
        androidUrl: url,
        message: _message.text.trim(),
        maintenance: _maintenance,
        maintenanceMessage: _maintMsg.text.trim(),
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  InputDecoration _dec(String hint, {String? label}) => InputDecoration(
        hintText: hint,
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: const Color(0x0A000000),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12)),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.all(16),
      children: [
        const Text('إصدار تطبيق أندرويد',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 4),
        const Text(
            'ينبّه المستخدمون عند فتح التطبيق. الويب لا يحتاج هذا — يتحديث وحده.',
            style: TextStyle(fontSize: 11.5, color: Colors.black54)),
        const SizedBox(height: 14),
        TextField(
            controller: _version,
            decoration: _dec('1.0.2', label: 'رقم الإصدار الظاهر *')),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                  controller: _build,
                  keyboardType: TextInputType.number,
                  decoration: _dec('2', label: 'رقم البناء build *')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                  controller: _min,
                  keyboardType: TextInputType.number,
                  decoration: _dec('1', label: 'الحد الأدنى للإلزام')),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
            'رقم البناء لا يتكرر أبدًا ولا يقل — وإلا رفض النظام التثبيت فوق الحالي.',
            style: TextStyle(fontSize: 10, color: Colors.black45)),
        const SizedBox(height: 10),
        TextField(
            controller: _url,
            decoration: _dec('https://…/qarity.apk',
                label: 'رابط تحميل الـAPK')),
        const SizedBox(height: 10),
        TextField(
            controller: _message,
            maxLines: 3,
            decoration: _dec('ما الجديد في هذا الإصدار؟ تظهر للمستخدم',
                label: 'رسالة التحديث')),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _maintenance,
          onChanged: (v) => setState(() => _maintenance = v),
          title: const Text('وضع الصيانة (قفل التطبيق للجميع)',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
        ),
        if (_maintenance) ...[
          const SizedBox(height: 6),
          TextField(
              controller: _maintMsg,
              maxLines: 2,
              decoration: _dec('سبب الصيانة ومتى نعود')),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13)),
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.campaign_rounded, size: 18),
            label: const Text('نشر بيانات الإصدار',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

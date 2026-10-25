part of 'admin_dashboard.dart';

/// مركز العمليات والأدوات الإدارية:
/// يجمع في واجهة موحدة كل الأدوات المستقلة (الإرسال الإذاعي، التنبيهات العاجلة،
/// الإعلانات الترويجية، والتقارير والإحصائيات) دون تشتيت الشريط العلوي الرئيسي.
class _OperationsHubPage extends StatefulWidget {
  const _OperationsHubPage({
    required this.currentUid,
    this.initialTool = 0,
    this.onToolChanged,
  });

  final String? currentUid;
  final int initialTool;
  final ValueChanged<int>? onToolChanged;

  @override
  State<_OperationsHubPage> createState() => _OperationsHubPageState();
}

class _OperationsHubPageState extends State<_OperationsHubPage> {
  late int _selectedTool;

  @override
  void initState() {
    super.initState();
    _selectedTool = widget.initialTool.clamp(0, 3);
  }

  @override
  void didUpdateWidget(covariant _OperationsHubPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTool != oldWidget.initialTool) {
      _selectedTool = widget.initialTool.clamp(0, 3);
    }
  }

  void _switchTool(int index) {
    if (_selectedTool == index) return;
    setState(() => _selectedTool = index);
    widget.onToolChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // شريط أدوات المركز
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildToolTab(
                  index: 0,
                  label: 'الإرسال',
                  icon: Icons.send_rounded,
                  color: Colors.blue,
                ),
                const SizedBox(width: 6),
                _buildToolTab(
                  index: 1,
                  label: 'التنبيهات',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 6),
                _buildToolTab(
                  index: 2,
                  label: 'الإعلانات',
                  icon: Icons.campaign_rounded,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 6),
                _buildToolTab(
                  index: 3,
                  label: 'التقارير',
                  icon: Icons.assessment_rounded,
                  color: Colors.teal,
                ),
              ],
            ),
          ),
          // محتوى الأداة المختارة مع الحفاظ على حالة النماذج والبيانات
          Expanded(
            child: IndexedStack(
              index: _selectedTool,
              children: [
                _BroadcastPage(currentUid: widget.currentUid),
                const _AlertsControlPage(),
                _PromosPage(currentUid: widget.currentUid),
                const _ReportsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolTab({
    required int index,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedTool == index;
    final theme = Theme.of(context);
    final ink = AppColors.readableInk(color, theme.brightness);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _switchTool(index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? ink : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? ink : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

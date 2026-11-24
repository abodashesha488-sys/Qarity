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
    _selectedTool = widget.initialTool.clamp(0, 4);
  }

  @override
  void didUpdateWidget(covariant _OperationsHubPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTool != oldWidget.initialTool) {
      _selectedTool = widget.initialTool.clamp(0, 4);
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
          // شريط أدوات المركز — كبسولات تمرير أفقي مريحة بلا تزاحم
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildToolTab(
                    index: 0,
                    label: 'الإرسال الإذاعي',
                    icon: Icons.send_rounded,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildToolTab(
                    index: 1,
                    label: 'التنبيهات العاجلة',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  _buildToolTab(
                    index: 2,
                    label: 'الإعلانات الترويجية',
                    icon: Icons.campaign_rounded,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 8),
                  _buildToolTab(
                    index: 3,
                    label: 'التقارير والإحصاءات',
                    icon: Icons.assessment_rounded,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 8),
                  _buildToolTab(
                    index: 4,
                    label: 'التجارة والصفقات',
                    icon: Icons.storefront_rounded,
                    color: const Color(0xFF16A34A),
                  ),
                ],
              ),
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
                const GroupDealsAdminScreen(isEmbedded: true),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _switchTool(index),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.16)
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.55)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? ink : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? ink : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

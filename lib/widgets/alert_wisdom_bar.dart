import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/wisdom_calendar.dart';
import '../../models/village_alert.dart';
import '../../services/alert_service.dart';
import '../../services/share_service.dart';

/// الشريط الثابت أسفل هيدر الرئيسية:
/// — تنبيه عاجل أحمر نابض عند تفعيله من لوحة الأدمن (يضغط لعرض النص كاملاً).
/// — «حكمة اليوم» من تقويم القرية اليومي (365 حكمة بالتاريخ)، والضغط يفتح
///   حوار اليوم مع شارات التصنيف/المناسبة وتصفّح أيام السنة ومشاركة.
class AlertWisdomBar extends StatefulWidget {
  const AlertWisdomBar({super.key});

  @override
  State<AlertWisdomBar> createState() => _AlertWisdomBarState();
}

class _AlertWisdomBarState extends State<AlertWisdomBar> {
  late final Stream<VillageAlert?> _stream = AlertService().watchLiveAlert();

  void _showAlertDialog(VillageAlert alert) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828)),
            SizedBox(width: 8),
            Text('تنبيه عاجل للقرية',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(alert.message,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, height: 1.6)),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً، فهمت'),
          ),
        ],
      ),
    );
  }

  void _openWisdomDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => const _WisdomDayDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VillageAlert?>(
      stream: _stream,
      builder: (context, snapshot) {
        final alert = snapshot.data;
        if (alert != null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showAlertDialog(alert),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [Color(0xFFB71C1C), Color(0xFFE53935)]),
                    boxShadow: [
                      BoxShadow(
                          color:
                              const Color(0xFFE53935).withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.campaign_rounded,
                            color: Colors.white, size: 18),
                      ).animate(onPlay: (c) => c.repeat()).scale(
                          duration: 600.ms,
                          curve: Curves.easeInOut,
                          begin: const Offset(0.82, 0.82),
                          end: const Offset(1.12, 1.12)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 1),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(6)),
                                  child: const Text('عاجل',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFB71C1C))),
                                ),
                                const SizedBox(width: 6),
                                Text('تنبيه القرية — اضغط لعرض التفاصيل',
                                    style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white
                                            .withValues(alpha: 0.85))),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(alert.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    height: 1.35)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_left_rounded,
                          color: Colors.white70, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 350.ms);
        }
        final wisdom = WisdomCalendar.of(DateTime.now());
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openWisdomDialog,
              child: Container(
                constraints: const BoxConstraints(minHeight: 58),
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  image: DecorationImage(
                    image: AssetImage('assets/images/hekma.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.format_quote_rounded,
                                size: 13,
                                color:
                                    Colors.white.withValues(alpha: 0.75)),
                            Text('حكمة اليوم',
                                style: TextStyle(
                                    color:
                                        Colors.white
                                            .withValues(alpha: 0.85),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(wisdom.text,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.45)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// حوار حكمة اليوم — نص كامل + شارات + تصفح أيام السنة + مشاركة.
class _WisdomDayDialog extends StatefulWidget {
  const _WisdomDayDialog();

  @override
  State<_WisdomDayDialog> createState() => _WisdomDayDialogState();
}

class _WisdomDayDialogState extends State<_WisdomDayDialog> {
  DateTime _date = DateTime.now();

  void _shift(int days) =>
      setState(() => _date = _date.add(Duration(days: days)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wisdom = WisdomCalendar.of(_date);
    final today = DateTime.now();
    final isToday = _date.year == today.year &&
        _date.month == today.month &&
        _date.day == today.day;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                    tooltip: 'اليوم السابق',
                    onPressed: () => _shift(-1),
                    icon: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16)),
                Expanded(
                  child: Column(
                    children: [
                      Text('حكمة اليوم',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary)),
                      Text(
                          '${WisdomCalendar.label(_date)}'
                          '${isToday ? '  •  اليوم' : ''}',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                    tooltip: 'اليوم التالي',
                    onPressed: () => _shift(1),
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 16)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('«${wisdom.text}»',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      height: 1.7)),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(theme, Icons.category_rounded, wisdom.category,
                    theme.colorScheme.primary),
                if (wisdom.isSpecial)
                  _chip(theme, Icons.emoji_events_rounded, wisdom.occasion,
                      const Color(0xFFB8860B)),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        IconButton(
          tooltip: 'مشاركة الحكمة',
          onPressed: () => ShareService.shareText(
              title: '💡 حكمة اليوم من قرية أبودشيشة',
              body: '«${wisdom.text}»\n${WisdomCalendar.label(_date)}'
                  '${wisdom.isSpecial ? ' — ${wisdom.occasion}' : ''}'),
          icon: Icon(Icons.share_rounded,
              color: theme.colorScheme.primary, size: 20),
        ),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق')),
      ],
    );
  }

  Widget _chip(ThemeData theme, IconData icon, String label, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      );
}

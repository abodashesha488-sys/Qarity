import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/wisdoms.dart';
import '../../models/village_alert.dart';
import '../../services/alert_service.dart';

/// الشريط الثابت أسفل هيدر الرئيسية:
/// — تنبيه عاجل أحمر نابض عند تفعيله من لوحة الأدمن (يضغط لعرض النص كاملاً).
/// — «حكمة اليوم» المتغيرة يومياً عندما لا يوجد تنبيه (تضغط لتنتقل لحكمة أخرى).
class AlertWisdomBar extends StatefulWidget {
  const AlertWisdomBar({super.key});

  @override
  State<AlertWisdomBar> createState() => _AlertWisdomBarState();
}

class _AlertWisdomBarState extends State<AlertWisdomBar> {
  int _wisdomOffset = 0;

  String get _wisdom {
    if (_wisdomOffset == 0) return TodayWisdom.pick();
    return TodayWisdom.pick(offset: _wisdomOffset);
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<VillageAlert?>(
      stream: AlertService().watchLiveAlert(),
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
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () =>
                  setState(() => _wisdomOffset = (_wisdomOffset + 1) % 7),
              child: Container(
                constraints: const BoxConstraints(minHeight: 58),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.55),
                        theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                      ]),
                  border: Border.all(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.format_quote_rounded,
                          size: 18, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Column(
                          key: ValueKey(_wisdom),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('حكمة اليوم • ${_todayLabel()}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(_wisdom,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.85))),
                          ],
                        ),
                      ),
                    ),
                    Icon(Icons.auto_awesome_rounded,
                        size: 16,
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.6)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const days = [
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ];
    return days[now.weekday % 7];
  }
}

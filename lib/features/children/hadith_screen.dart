import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/qurity_app_bar.dart';

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  static const _items = [
    _SubItem('الأمانة', Icons.handshake_rounded, Color(0xFF4CAF50), 'الصدق والأمانة'),
    _SubItem('الصبر', Icons.self_improvement_rounded, Color(0xFF2196F3), 'الصبر والتحمل'),
    _SubItem('البر والإحسان', Icons.favorite_rounded, Color(0xFFE53935), 'الإحسان للآخرين'),
    _SubItem('التواضع', Icons.person_rounded, Color(0xFF9C27B0), 'التواضع والخشية'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const QurityAppBar(title: 'أحاديث نبوية', color: AppColors.primary),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.85,
          children: [
            for (final item in _items)
              _SubTile(item: item),
          ],
        ),
      ),
    );
  }
}

class _SubItem {
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  const _SubItem(this.title, this.icon, this.color, this.description);
}

class _SubTile extends StatelessWidget {
  final _SubItem item;
  const _SubTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: item.color.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.color, size: 40),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: item.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/qurity_app_bar.dart';
import 'album_screen.dart';
import 'hadith_screen.dart';
import 'heritage_screen.dart';
import 'prayer_screen.dart';
import 'prophets_screen.dart';

const kChildrenColor = Color(0xFF66BB6A);
const kChildrenLight = Color(0xFFE8F5E9);

class ChildrenScreen extends StatelessWidget {
  const ChildrenScreen({super.key});

  static final _items = [
    const _ChildItem('تعليم الصلاة', Icons.workspace_premium_rounded, kChildrenColor, PrayerScreen()),
    const _ChildItem('أحاديث نبوية', Icons.book_rounded, Color(0xFF42A5F5), HadithScreen()),
    const _ChildItem('قصص الأنبياء', Icons.sports_soccer_rounded, Color(0xFFFF9800), ProphetsScreen()),
    const _ChildItem('حكاية مصورة', Icons.museum_rounded, Color(0xFFAB47BC), HeritageScreen()),
    const _ChildItem('ألبوم الأطفال', Icons.photo_album_rounded, Color(0xFFEC407A), AlbumScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const QurityAppBar(
        title: 'ركن الأطفال',
        color: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.85,
          children: [
            for (final item in _items)
              _ChildTile(item: item),
          ],
        ),
      ),
    );
  }
}

class _ChildItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;
  const _ChildItem(this.title, this.icon, this.color, this.page);
}

class _ChildTile extends StatelessWidget {
  final _ChildItem item;
  const _ChildTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: item.color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => item.page),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(item.icon, color: item.color, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: item.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'اضغط للدخول',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

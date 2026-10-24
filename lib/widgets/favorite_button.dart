import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../services/favorites_service.dart';

/// زر موحّد لإضافة / إزالة أي عنصر من المفضلة في كافة شاشات وقوائم التطبيق.
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.item,
    this.size = 22,
    this.activeColor = const Color(0xFFE53935),
    this.inactiveColor,
    this.showBadge = false,
    this.showSnackbar = true,
    this.tooltip,
  });

  final FavoriteItem item;
  final double size;
  final Color activeColor;
  final Color? inactiveColor;
  final bool showBadge;
  final bool showSnackbar;
  final String? tooltip;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    FavoritesService.instance.init();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    _animController.forward(from: 0.0);
    final isFav = await FavoritesService.instance.toggleFavorite(widget.item);
    if (!mounted) return;

    if (widget.showSnackbar) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: isFav ? AppColors.primary : const Color(0xFF323232),
          content: Row(
            children: [
              Icon(
                isFav ? Icons.bookmark_added_rounded : Icons.bookmark_remove_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isFav
                    ? 'تمت إضافة «${widget.item.title}» إلى المفضلة'
                    : 'تمت إزالة «${widget.item.title}» من المفضلة',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultInactive = widget.inactiveColor ?? theme.colorScheme.onSurfaceVariant;

    return ValueListenableBuilder<List<FavoriteItem>>(
      valueListenable: FavoritesService.instance.favoritesNotifier,
      builder: (context, _, __) {
        final isFav = FavoritesService.instance
            .isFavorite(widget.item.targetId, widget.item.collection);

        final icon = ScaleTransition(
          scale: _scaleAnimation,
          child: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: widget.size,
            color: isFav ? widget.activeColor : defaultInactive,
          ),
        );

        if (widget.showBadge) {
          return InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isFav
                    ? widget.activeColor.withValues(alpha: 0.12)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFav
                      ? widget.activeColor.withValues(alpha: 0.3)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 6),
                  Text(
                    isFav ? 'في المفضلة' : 'أضف للمفضلة',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isFav ? widget.activeColor : defaultInactive,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return IconButton(
          tooltip: widget.tooltip ?? (isFav ? 'إزالة من المفضلة' : 'إضافة للمفضلة'),
          icon: icon,
          onPressed: _handleTap,
        );
      },
    );
  }
}

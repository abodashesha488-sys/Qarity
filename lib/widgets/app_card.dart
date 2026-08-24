import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final bool bordered;
  final bool elevate;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.radius = 20,
    this.bordered = true,
    this.elevate = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    final card = Card(
      margin: margin,
      color: color ?? theme.cardColor,
      elevation: elevate ? 6 : 0,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: bordered
            ? BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35))
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

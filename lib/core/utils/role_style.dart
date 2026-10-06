import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/data_models.dart';

/// نظام موحّد لألوان وشارات الأدوار في كامل التطبيق.
///
/// القواعد:
///  • بائع ذهبي   → الاسم/الإطار ذهبي.
///  • بائع سوبر   → الاسم/الإطار فضي.
///  • بائع متميّز → الاسم/الإطار أحمر.
///  • بائع عادي   → لون النص العادي.
///  • مدير عام   → اسم ذهبي + أيقونة تاج 👑.
///  • مشرف/مدير طبي → اسم بلون الدور + أيقونة نجمة ⭐.
class RoleStyle {
  RoleStyle._();

  static const Color gold = Color(0xFFC9A227);
  static const Color silver = Color(0xFF8E9BA6);
  static const Color premiumRed = Color(0xFFD32F2F);
  static const Color adminGold = Color(0xFFB8860B);
  static const Color medicalTeal = Color(0xFF00897B);
  static const Color moderatorOrange = Color(0xFFEF6C00);

  static SellerType? parseSellerType(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final t in SellerType.values) {
      if (t.name == code) return t;
    }
    return null;
  }

  /// لون اسم البائع حسب نوعه (null = اللون الافتراضي للنص).
  static Color? sellerNameColor(SellerType? t) {
    switch (t) {
      case SellerType.goldSeller:
        return gold;
      case SellerType.superSeller:
        return silver;
      case SellerType.premiumSeller:
        return premiumRed;
      case SellerType.regular:
      case null:
        return null;
    }
  }

  /// لون اسم المسؤول حسب دوره (null = عادي).
  static Color? adminNameColor(String? role) {
    switch (role) {
      case 'admin':
      case 'assistant_admin':
        return adminGold;
      case 'medical_admin':
        return medicalTeal;
      case 'moderator':
        return moderatorOrange;
      default:
        return null;
    }
  }

  /// الشارة بجوار الاسم: تاج للمدير العام، نجمة لبقية المسؤولين.
  static IconData? badgeIcon(String? role) {
    switch (role) {
      case 'admin':
        return Icons.workspace_premium_rounded; // تاج ذهبي
      case 'assistant_admin':
        return Icons.shield_rounded; // درع ذهبي (أدمن مساعد)
      case 'medical_admin':
      case 'moderator':
        return Icons.star_rounded; // نجمة
      default:
        return null;
    }
  }

  static Color badgeColor(String? role) {
    switch (role) {
      case 'admin':
      case 'assistant_admin':
        return gold;
      case 'medical_admin':
        return medicalTeal;
      case 'moderator':
        return moderatorOrange;
      default:
        return Colors.grey;
    }
  }

  /// لون إطار بطاقة المنتج/المحل — مشتق من صاحب المحتوى.
  static Color? contentAccent(String? ownerRole, String? ownerSellerType) {
    final seller = sellerNameColor(parseSellerType(ownerSellerType));
    if (seller != null) return seller;
    return adminNameColor(ownerRole);
  }

  /// لون الدور **حبرًا** لا أرضيةً: في الفاتح كما هو تمامًا، وفي الداكن يُرفع
  /// سطوعه محافظًا على درجته. الاستثناء الذهبي مقصود ومقاس: `#B8860B` تقيس
  /// 5.15 على الأرضية الداكنة و`#C9A227` نحو 6.9 فتمرّان أصلًا، وتفتيحهما يحوّل
  /// تمييز «المدير العام» إلى أصفر باهت. ما يفشل ويُفتَّح: الأحمر `#D32F2F`
  /// (3.37) والتيل `#00897B` (3.84).
  static Color nameInk(Color ink, Brightness brightness) {
    if (brightness == Brightness.light) return ink;
    if (ink == gold || ink == adminGold) return ink;
    return AppColors.inkOn(ink, brightness);
  }
}

/// نص اسم مزيّن بلون الدور + شارة (تاج/نجمة) عند الحاجة.
class RoleNameText extends StatelessWidget {
  const RoleNameText({
    super.key,
    required this.name,
    this.role,
    this.sellerType,
    this.style,
    this.iconSize = 15,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
  });

  final String name;
  final String? role; // userRole/authorRole stored on the content
  final String? sellerType; // SellerType enum name if owner is a seller
  final TextStyle? style;
  final double iconSize;
  final int maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = style ??
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle();
    final accent = role == 'seller'
        ? RoleStyle.sellerNameColor(RoleStyle.parseSellerType(sellerType))
        : RoleStyle.adminNameColor(role);
    final badge = RoleStyle.badgeIcon(role);
    final brightness = Theme.of(context).brightness;
    final text = Text(
      name.isEmpty ? 'مستخدم' : name,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: base.copyWith(
        color: accent == null
            ? base.color
            : RoleStyle.nameInk(accent, brightness),
        fontWeight: accent != null ? FontWeight.w900 : base.fontWeight,
      ),
    );
    if (badge == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: text),
        SizedBox(width: iconSize > 16 ? 4 : 3),
        Icon(badge,
            size: iconSize,
            color: RoleStyle.nameInk(RoleStyle.badgeColor(role), brightness)),
      ],
    );
  }
}

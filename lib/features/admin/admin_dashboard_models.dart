part of 'admin_dashboard.dart';

/// مجموعة وهمية: قائمة موحّدة بكل العناصر المعلّقة عبر كل مجموعات المراجعة،
/// كل عنصر فيها يحمل `_collection` الأصلية ليُوجَّه الإجراء إليها.
const String kAllPending = 'pending_all';

/// مفتاح «بقية القيم» في عدّ التبويبات المصفّاة: السجلات التي لا تحمل حقل
/// التصنيف أو تحمل قيمة لا تعرفها اللوحة — يَرثها التبويب الافتراضي للمصدر
/// (`takesRest`) فلا يسقط سجل من المراجعة أبدًا.
const String _kRestGroup = '*';

/// فئة مراجعة في لوحة الأدمن — تمثل مجموعة Firestore قابلة للموافقة/الرفض.
/// معرّف خاص بمكتبة لوحة الأدمن عبر `part`.
/// فئة مراجعة — إما مجموعة Firestore حقيقية، أو **تبويب مُصفّى** من مجموعة
/// قائمة (`source` + `filterField`/`filterValues`). التبويب المصفّى لا يخترع
/// مجموعة ولا وثيقة ولا دورًا: يقرأ مستندات المصدر نفسه ويرفّصها، وكل قرار
/// فيه يُوجَّه إلى `realCollection` لأنها عنوان العنصر في Firestore فعلًا.
class _Cat {
  /// معرّف التبويب — فريد في القائمة، وقد يكون وهميًا (راجع `isVirtual`).
  final String collection;
  final String label;
  final IconData icon;
  final Color color;

  /// مجموعة Firestore الحقيقية عندما يكون التبويب عرضًا مُصفّى؛ `null` تعني
  /// أن `collection` هي المجموعة نفسها.
  final String? source;

  /// حقل الوثيقة الذي يُصنّف العنصر داخل التبويبات المصفّاة.
  final String? filterField;

  /// القيم التي يقبلها هذا التبويب حرفيًا.
  final Set<String>? filterValues;

  /// يَرِث هذا التبويب كل سجل لا تُطابق قيمته أيًا من قيم التبويبات الأخرى
  /// (بما فيها السجلات القديمة بلا الحقل) — فلا يسقط سجل من المراجعة أبدًا.
  final bool takesRest;

  const _Cat(this.collection, this.label, this.icon, this.color,
      {this.source,
      this.filterField,
      this.filterValues,
      this.takesRest = false});

  bool get isAllPending => collection == kAllPending;

  /// تبويب عرض مُصفّى داخل مجموعة قائمة، لا مجموعة مستقلة.
  bool get isVirtual => source != null;

  /// المجموعة التي تُقرأ منها الوثائق وتُوجَّه إليها القرارات.
  String get realCollection => source ?? collection;

  /// صدق العنصر على هذا التبويب. `restOwner` هو التبويب الوحيد الذي يرث
  /// القيم غير المعروفة في نفس المصدر.
  bool matches(Map<String, dynamic> item, {required Set<String> claimedElsewhere}) {
    final field = filterField;
    if (field == null) return true;
    final value = '${item[field]}';
    if (value.isEmpty) return takesRest;
    if (filterValues?.contains(value) == true) return true;
    return takesRest && !claimedElsewhere.contains(value);
  }
}

/// ترويسة موحّدة لكل تبويبات لوحة التحكم — أيقونة دائرية متدرّجة + عنوان
/// + سطر فرعي اختياري + شارة عدّاد اختيارية (المعلّقات وغيرها).
///
/// كانت كل تبويبة ترسم ترويستها الخاصة بتدرّجات وأحجام وهامش مختلفة، فتبدو
/// اللوحة كأنها سبعة تطبيقات منفصلة. هذا العنصر يفرض نفس الهندسة والقياسات
/// في كل مكان: نصف القطر 14، الحشو 12، الأيقونة 24، عنوان titleLarge w900
/// وسطر فرعي bodyMedium باهت.
class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.subtitle,
    this.count,
    this.countLabel,
  });

  final IconData icon;
  final String title;

  /// اللون الأساسية للترويسة (شارة الأيقونة + شارة العدّاد + لمسة الخلفية).
  final Color color;

  /// السطر الفرعي أسفل العنوان (عادة وصف قصير أو عدّ).
  final String? subtitle;

  /// عدّاد اختياري يظهر كشارة — مثلاً عدد العناصر المعلّقة.
  final int? count;

  /// نص بدائل للعدّاد عند عدم توفّر رقم (يظهر كلون ثابت بدل الرقم).
  final String? countLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCount = count != null || countLabel != null;
    final badge = hasCount
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(count != null
                    ? Icons.pending_actions_rounded
                    : Icons.check_circle_rounded,
                    size: 14,
                    color: color),
                const SizedBox(width: 5),
                Text(
                  count != null
                      ? '$count ${countLabel ?? 'عنصر'}'
                      : (countLabel ?? ''),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          )
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            color.withValues(alpha: 0.07),
            color.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, Color.alphaBlend(color.withValues(alpha: 0.25), Colors.black)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (badge != null) badge,
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';

/// قيم النوع المخزّنة في `users/{uid}.gender` (نفس صياغة نموذج متبرعي الدم).
const String kGenderMale = 'ذكر';
const String kGenderFemale = 'أنثى';

/// منتقي النوع (ذكر/أنثى) بأسلوب التطبيق — يُستخدم في «إكمال الملف الشخصي»
/// وفي نافذة تعديل البيانات، حتى تبقى القيمة واحدة في الموضعين.
class GenderSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const GenderSelector(
      {super.key, required this.value, required this.onChanged, this.errorText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('النوع *',
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GenderOption(
                label: kGenderMale,
                icon: Icons.male_rounded,
                selected: value == kGenderMale,
                onTap: () => onChanged(kGenderMale),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GenderOption(
                label: kGenderFemale,
                icon: Icons.female_rounded,
                selected: value == kGenderFemale,
                onTap: () => onChanged(kGenderFemale),
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(errorText!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error)),
        ],
      ],
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Material(
      color: selected
          ? color.withValues(alpha: 0.12)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : theme.colorScheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20, color: selected ? color : theme.iconTheme.color),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    color: selected ? color : theme.colorScheme.onSurface,
                  )),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle_rounded, size: 16, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

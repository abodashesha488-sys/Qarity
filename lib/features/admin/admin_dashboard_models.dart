part of 'admin_dashboard.dart';

/// فئة مراجعة في لوحة الأدمن — تمثل مجموعة Firestore قابلة للموافقة/الرفض.
/// معرّف خاص بمكتبة لوحة الأدمن عبر `part`.
class _Cat {
  final String collection;
  final String label;
  final IconData icon;
  final Color color;
  const _Cat(this.collection, this.label, this.icon, this.color);
}

import 'package:flutter/material.dart';

/// تصنيف منتجات المستلزمات الطبية — مصدر واحد يستعمله نموذج «إضافة منتج»
/// وقسم «المستلزمات الطبية» في بوابة الخدمات الطبية معًا، فلا يتفارق النص
/// بين الكاتب والقارئ (وهو شرط مطابقة الاستعلام الخادمي).
const String kMedicalSuppliesCategory = 'مستلزمات طبية';

/// فئات منتجات السوق — المصدر الوحيد المعتمد:
/// تُستخدم في تصفية تبويب «السوق» وفي نموذج «إضافة منتج» معاً.
const List<String> kProductCategories = [
  'مواد غذائية',
  'خضار وفواكه',
  'لحوم وطيور وأسماك',
  'ألبان وخير البلد',
  'حلويات ومخبوزات',
  'مشروبات ومقاهي',
  'أدوات منزلية ومنظفات',
  kMedicalSuppliesCategory,
  'إلكترونيات وهواتف',
  'أثاث ومفروشات',
  'ملابس وأحذية',
  'استعدادات افراح ومناسبات',
  'مستلزمات زراعة وأعلاف',
  'سوق المستعمل',
  'ورش وصيانة',
  'مخازن ومستودعات',
  'حرف يدوية',
  'خدمات أخرى',
  'عام',
];

/// الأيقونة التعبيرية لكل تصنيف لإضفاء مظهر بصري حديث يماثل التطبيقات العالمية
IconData getProductCategoryIcon(String category) {
  switch (category) {
    case 'الكل':
      return Icons.grid_view_rounded;
    case 'مواد غذائية':
      return Icons.shopping_basket_rounded;
    case 'خضار وفواكه':
      return Icons.eco_rounded;
    case 'لحوم وطيور وأسماك':
      return Icons.set_meal_rounded;
    case 'ألبان وخير البلد':
      return Icons.egg_alt_rounded;
    case 'حلويات ومخبوزات':
      return Icons.cake_rounded;
    case 'مشروبات ومقاهي':
      return Icons.local_cafe_rounded;
    case 'أدوات منزلية ومنظفات':
      return Icons.cleaning_services_rounded;
    case kMedicalSuppliesCategory:
      return Icons.medical_services_rounded;
    case 'إلكترونيات وهواتف':
      return Icons.phone_android_rounded;
    case 'أثاث ومفروشات':
      return Icons.chair_rounded;
    case 'ملابس وأحذية':
      return Icons.checkroom_rounded;
    case 'استعدادات افراح ومناسبات':
      return Icons.celebration_rounded;
    case 'مستلزمات زراعة وأعلاف':
      return Icons.agriculture_rounded;
    case 'سوق المستعمل':
      return Icons.recycling_rounded;
    case 'ورش وصيانة':
      return Icons.build_rounded;
    case 'مخازن ومستودعات':
      return Icons.warehouse_rounded;
    case 'حرف يدوية':
      return Icons.palette_rounded;
    case 'خدمات أخرى':
      return Icons.miscellaneous_services_rounded;
    case 'عام':
    default:
      return Icons.storefront_rounded;
  }
}

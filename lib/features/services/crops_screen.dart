import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/agriculture_content_model.dart';
import '../../widgets/agriculture_content_panel.dart';
import '../../widgets/qurity_app_bar.dart';

/// شاشة المحاصيل — شبكة من المحاصيل المصرية تفتح تفاصيل علمية
class CropsScreen extends StatelessWidget {
  const CropsScreen({super.key});

  static const List<CropRecord> _crops = [
    CropRecord(
      name: 'القمح',
      scientificName: 'Triticum aestivum',
      nameEn: 'Wheat',
      imageUrl:
          'https://images.unsplash.com/photo-1574323347407-f5e1ad6d066b?w=400',
      season: 'شتوي (نوفمبر - أبريل)',
      region: 'شمال ووسط الدلتا',
      description:
          'القمح هو المحصول الاستراتيجي الأول في مصر. يُزرع في الأراضي الطينية الثقيلة الجيدة الصرف. يحتاج لري منتظم وتسميد أزوتي على دفعات.',
      soilType: 'طينية ثقيلة - جيدة الصرف',
      irrigation: 'غمر: كل 10-15 يوم / حديث: كل 5-7 أيام',
      fertilization:
          'أزوت: 100-120 كجم/فدان (3 دفعات)\nفوسفات: 30-40 كجم P2O5/فدان\nبوتاس: 24 كجم K2O/فدان',
      pests: 'صدأ القمح، بقعة سيبتوريا، حشرة الحشد الخريفية',
      varieties: 'جميزة 11، سوهاج 3، مصر 1، سخا 94، مصر 2',
      yieldTarget: '18-22 أردب/فدان',
      plantingMethod: 'بذار مباشر على خطوط (15-20 سم بين السطور)',
      harvestMethod: 'حصاد آلي أو يدوي عند نضج الحبوب (رطوبة 12-14%)',
      economicImportance:
          'المحصول الاستراتيجي الأول — الاكتفاء الذاتي هدف قومي',
    ),
    CropRecord(
      name: 'الأرز',
      scientificName: 'Oryza sativa',
      nameEn: 'Rice',
      imageUrl:
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400',
      season: 'صيفي (مايو - أكتوبر)',
      region: 'شمال الدلتا (كفر الشيخ، البحيرة، الدقهلية)',
      description:
          'الأرز محصول صيفي رئيسي يُزرع في الأراضي الطينية الثقيلة التي تحتفظ بالماء. مصر من أكبر منتجي الأرز في أفريقيا.',
      soilType: 'طينية ثقيلة - تحتفظ بالماء',
      irrigation: 'غمر مستمر - مستوى ماء 5-10 سم طوال الموسم',
      fertilization:
          'أزوت: 80-100 كجم/فدان (دفعتين)\nفوسفات: 30 كجم P2O5/فدان\nزنك: 5 كجم/فدان (كبريتات الزنك)',
      pests:
          'دودة ورق الأرز، حفار الساق، ذبابة الساق، تبقع الأوراق، لفحة الساق',
      varieties: 'جيزة 177، جيزة 178، سخا 101، سخا 104، جيزة 179',
      yieldTarget: '3.5-4.5 طن/فدان',
      plantingMethod: 'شتل في مشاتل ثم نقل (25-30 يوم) / بذار مباشر',
      harvestMethod: 'حصاد آلي عند نضج الحبوب (رطوبة 20-22%)',
      economicImportance: 'ثاني محصول استراتيجي — تصدير وفائض للاستهلاك المحلي',
    ),
    CropRecord(
      name: 'الذرة الشامية',
      scientificName: 'Zea mays',
      nameEn: 'Maize/Corn',
      imageUrl:
          'https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=400',
      season: 'صيفي (أبريل - أغسطس) / نيلي (يوليو - نوفمبر)',
      region: 'شمال ووسط الدلتا',
      description:
          'الذرة الشامية محصول علف وحبوب استراتيجي. يُزرع علفاً أخضر وحبوباً. الهجن الحديثة تعطي إنتاجية عالية.',
      soilType: 'طينية صفراء - جيدة التهوية والصرف',
      irrigation: 'حديث: كل 3-5 أيام / غمر: كل 7-10 أيام',
      fertilization:
          'أزوت: 120-150 كجم/فدان (3 دفعات)\nفوسفات: 40-50 كجم P2O5/فدان\nبوتاس: 48 كجم K2O/فدان',
      pests:
          'حفار الساق، دودة الحشد الخريفية، ذبابة الساق، لفحة التبقع، ذبابة الورق',
      varieties: 'هجين 10، هجين 168، هجين 310، توبة 1، توبة 2',
      yieldTarget: '2.5-3.5 طن/فدان (حبوب) / 40-50 طن/فدان (علف أخضر)',
      plantingMethod:
          'بذار مباشر على خطوط (70-75 سم بين السطور، 25 سم بين الجور)',
      harvestMethod: 'حصاد آلي للحبوب / جزارة للعلف الأخضر',
      economicImportance: 'محصول علف استراتيجي — صناعة الزيوت والنشا',
    ),
    CropRecord(
      name: 'القطن',
      scientificName: 'Gossypium barbadense',
      nameEn: 'Cotton',
      imageUrl:
          'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=400',
      season: 'صيفي (مارس - أكتوبر)',
      region: 'وسط الدلتا (الغربية، المنوفية، القليوبية)',
      description:
          'القطن المصري طويل التيلة مشهور عالمياً بجودته العالية. يُزرع في الأراضي الطينية الصفراء العميقة.',
      soilType: 'طينية صفراء - عميقة - جيدة الصرف',
      irrigation: 'حديث: كل 5-7 أيام / مهم: عدم العطش في التزهير والعقد',
      fertilization:
          'أزوت: 60-80 كجم/فدان (دفعتين)\nفوسفات: 30 كجم P2O5/فدان\nبوتاس: 24 كجم K2O/فدان',
      pests:
          'دودة اللوز، دودة الورق، المن، ذبابة الورق، تبقع الأوراق، عفن الجذور',
      varieties: 'جيزة 94، جيزة 95، جيزة 96، جيزة 97، جيزة 98',
      yieldTarget: '10-12 قنطار/فدان',
      plantingMethod:
          'بذار مباشر على خطوط (60-70 سم بين السطور، 20-25 سم بين الجور)',
      harvestMethod: 'قطف يدوي أو آلي للتفاحات الناضجة (3-4 حشات)',
      economicImportance:
          'محصول تصديري عالي القيمة — قطن طويل التيلة شهرة عالمية',
    ),
    CropRecord(
      name: 'فول بلدي',
      scientificName: 'Vicia faba',
      nameEn: 'Fava Bean',
      imageUrl:
          'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400',
      season: 'شتوي (نوفمبر - أبريل)',
      region: 'شمال ووسط الدلتا',
      description:
          'الفول البلدي محصول بقولي شتوي مهم للبروتين النباتي. يثبت النيتروجين الجوي ويحسن خصوبة التربة.',
      soilType: 'طينية - جيدة الصرف',
      irrigation: 'غمر كل 15-20 يوم / حديث كل 7-10 أيام',
      fertilization:
          'أزوت: 15-20 كجم/فدان (بداية النمو فقط)\nفوسفات: 30-40 كجم P2O5/فدان\nبوتاس: 24 كجم K2O/فدان',
      pests: 'المن، دودة الأوراق، صدأ الفول، عفن الجذور، نيماتودا',
      varieties: 'جيزة 3، جيزة 40، جيزة 843، نوبارية 1، سخا 1',
      yieldTarget: '12-15 أردب/فدان',
      plantingMethod:
          'بذار مباشر على خطوط (50-60 سم بين السطور، 15-20 سم بين الجور)',
      harvestMethod: 'حصاد يدوي أو آلي عند جفاف القرون',
      economicImportance: 'مصدر بروتين نباتي رخيص — تحسين تربة (ثابت نيتروجين)',
    ),
    CropRecord(
      name: 'بنجر السكر',
      scientificName: 'Beta vulgaris',
      nameEn: 'Sugar Beet',
      imageUrl:
          'https://images.unsplash.com/photo-1598554747436-c9293d6a588f?w=400',
      season: 'شتوي (أكتوبر - مايو)',
      region: 'شمال ووسط الدلتا',
      description:
          'بنجر السكر محصول سكري شتوي بديل لقصب السكر. يُزرع في الأراضي الطينية العميقة الخالية من الحجارة.',
      soilType: 'طينية عميقة - جيدة الصرف - خالية من الحجارة',
      irrigation: 'حديث: كل 5-7 أيام / انتظام الري حاسم لنسبة السكر',
      fertilization:
          'أزوت: 80-100 كجم/فدان (دفعتين)\nفوسفات: 40 كجم P2O5/فدان\nبوتاس: 60 كجم K2O/فدان (مهم جداً للسكر)',
      pests: 'دودة الحشد، المن، عفن الجذور، تبقع الأوراق، نيماتودا',
      varieties: 'جلوريا، مونوفورت، كاسندرا، فيلينا، باسكال',
      yieldTarget: '25-30 طن/فدان (نسبة سكر 18-20%)',
      plantingMethod:
          'بذار مباشر (حبوب مغلفة) على خطوط (50 سم بين السطور، 20 سم بين الجور)',
      harvestMethod: 'قلع آلي للجذور + قطع الورق + نقل للمصنع',
      economicImportance: 'مصدر سكر محلي — بديل استيرادي — مخلفات علفية قيّمة',
    ),
    CropRecord(
      name: 'عباد الشمس',
      scientificName: 'Helianthus annuus',
      nameEn: 'Sunflower',
      imageUrl:
          'https://images.unsplash.com/photo-1597848212624-3a1e3a2f8c4e?w=400',
      season: 'صيفي (مارس - يوليو) / نيلي (أغسطس - ديسمبر)',
      region: 'شمال ووسط الدلتا والأراضي الجديدة',
      description:
          'عباد الشمس محصول زيتي صيفي/نيلي. يتحمل الملوحة والجفاف نسبياً. دورة قصيرة (100-110 يوم).',
      soilType: 'طينية صفراء - رملية طينية - جيدة الصرف',
      irrigation: 'حديث: كل 5-7 أيام / يتحمل جفاف نسبي',
      fertilization:
          'أزوت: 60-80 كجم/فدان (دفعتين)\nفوسفات: 30 كجم P2O5/فدان\nبوتاس: 36 كجم K2O/فدان',
      pests: 'دودة رأس الزهرة، المن، عفن الساق، تبقع الأوراق',
      varieties:
          'جيزة 1، جيزة 2، هجين 100، هجين 200، بذور مستوردة (سيرينا، إل كي)',
      yieldTarget: '1.5-2 طن/فدان (بذور) / زيت 40-45%',
      plantingMethod:
          'بذار مباشر على خطوط (70 سم بين السطور، 25-30 سم بين الجور)',
      harvestMethod: 'حصاد آلي عند جفاف الرؤوس (رطوبة بذور 9-10%)',
      economicImportance: 'مصدر زيت نباتي — كسب علف عالي البروتين (40-44%)',
    ),
    CropRecord(
      name: 'فول الصويا',
      scientificName: 'Glycine max',
      nameEn: 'Soybean',
      imageUrl:
          'https://images.unsplash.com/photo-1510681459799-fa215a24f3a7?w=400',
      season: 'صيفي (مايو - سبتمبر) / نيلي (يوليو - نوفمبر)',
      region: 'شمال ووسط الدلتا والأراضي الجديدة',
      description:
          'فول الصويا محصول بقولي زيتي بروتيني عالمي الأهمية. يثبت النيتروجين ويستخدم في صناعة الزيوت والأعلاف.',
      soilType: 'طينية صفراء - رملية طينية - جيدة الصرف - PH 6-6.8',
      irrigation: 'حديث: كل 5-7 أيام / حساس للعطش في التزهير والعقد',
      fertilization:
          'أزوت: 15-20 كجم/فدان (بداية نمو)\nفوسفات: 40 كجم P2O5/فدان\nبوتاس: 36 كجم K2O/فدان',
      pests: 'دودة القرون، المن، صدأ الصويا، عفن البذور، نيماتودا',
      varieties: 'جيزة 22، جيزة 35، جيزة 111، كروفر، مستوردة (أسجرو، بيل)',
      yieldTarget: '1.5-2.5 طن/فدان (بذور) / زيت 18-20% / بروتين 38-40%',
      plantingMethod:
          'بذار مباشر على خطوط (50-60 سم بين السطور، 5-10 سم بين الجور)',
      harvestMethod: 'حصاد آلي عند جفاف القرون (رطوبة بذور 13%)',
      economicImportance:
          'بروتين نباتي عالي الجودة — زيت — كسب علف — تثبيت نيتروجين',
    ),
    CropRecord(
      name: 'السمسم',
      scientificName: 'Sesamum indicum',
      nameEn: 'Sesame',
      imageUrl:
          'https://images.unsplash.com/photo-1508739773434-1b8e9b1b8b1e?w=400',
      season: 'صيفي (أبريل - أغسطس) / نيلي (يوليو - أكتوبر)',
      region: 'شمال ووسط الدلتا والأراضي الجديدة',
      description:
          'السمسم محصول زيتي صيفي/نيلي يتحمل الجفاف والملوحة. دورة قصيرة (90-110 يوم). بذوره غنية بالزيت (50-55%).',
      soilType: 'رملية طينية - طينية خفيفة - جيدة الصرف',
      irrigation: 'حديث: كل 7-10 أيام / يتحمل جفاف عالي',
      fertilization:
          'أزوت: 40-50 كجم/فدان (دفعتين)\nفوسفات: 25 كجم P2O5/فدان\nبوتاس: 24 كجم K2O/فدان',
      pests: 'دودة الكبسولة، المن، تبقع الأوراق، عفن الجذور',
      varieties: 'جيزة 32، سيناء 1، توشكي 1، جيزة 12',
      yieldTarget: '0.8-1.2 طن/فدان (بذور) / زيت 50-55%',
      plantingMethod:
          'بذار مباشر (بذر ناعم) على خطوط (60 سم بين السطور، 10-15 سم بين الجور)',
      harvestMethod: 'قطع يدوي/آلي عند جفاف الكبسولات (قبل تفتحها)',
      economicImportance: 'زيت سمسم فاخر — طحينة — حلويات — تصدير عالي القيمة',
    ),
    CropRecord(
      name: 'البرسيم الحجازي',
      scientificName: 'Medicago sativa',
      nameEn: 'Alfalfa',
      imageUrl:
          'https://images.unsplash.com/photo-1505008088507-214a5a6d55f5?w=400',
      season: 'حولية (زراعة أكتوبر - حصاد متعدد سنوات)',
      region: 'جميع أنحاء الدلتا والأراضي الجديدة',
      description:
          'البرسيم الحجازي ملك الأعلاف الخضراء. محصول بقولي حولي يثبت النيتروجين. يعطي 8-10 حشات/سنة. عمر الإنتاجية 3-5 سنوات.',
      soilType: 'طينية عميقة - جيدة الصرف - PH 6.5-7.5',
      irrigation: 'غمر: كل 10-15 يوم / حديث: كل 5-7 أيام',
      fertilization:
          'فوسفات: 40 كجم P2O5/فدان (سنوياً)\nبوتاس: 48 كجم K2O/فدان (سنوياً)\nلا يحتاج أزوت (ثابت نيتروجين)',
      pests: 'دودة ورق البرسيم، المن، نيماتودا، عفن الجذور',
      varieties: 'جيزة 1، جيزة 2، نوبارية 1، كوفي، أمريكا (مستوردة)',
      yieldTarget: '80-120 طن/فدان/سنة (علف أخضر) / 20-30 طن/فدان (قش)',
      plantingMethod: 'بذار ناعم نثر أو خطوط (20 سم) — معدل 15-20 كجم/فدان',
      harvestMethod: 'حش آلي/يدوي كل 25-35 يوم (8-10 حشات/سنة)',
      economicImportance:
          'ملك الأعلاف — بروتين عالي (20-25%) — يحسن التربة — تدوير محاصيل مثالي',
    ),
    CropRecord(
      name: 'الطماطم',
      scientificName: 'Solanum lycopersicum',
      nameEn: 'Tomato',
      imageUrl:
          'https://images.unsplash.com/photo-1546470427-e26264be0b0d?w=700',
      season: 'صيفي ونيلي حسب المنطقة',
      region: 'الدلتا والأراضي الجديدة',
      description:
          'محصول خضري مهم في الدلتا، يحتاج صرفًا جيدًا وانتظامًا في الري ومراقبة مبكرة للذبابة البيضاء واللفحة.',
      soilType: 'طينية صفراء أو رملية طينية جيدة الصرف',
      irrigation: 'تنقيط كل 1-3 أيام حسب الحرارة ومرحلة النمو',
      fertilization:
          'تحليل التربة أولًا، ثم برنامج متوازن NPK مع كالسيوم وبورون أثناء التزهير والعقد',
      pests: 'الذبابة البيضاء، دودة الثمار، الندوة المبكرة والمتأخرة',
      varieties: 'هجن مناسبة للزراعة المكشوفة والصوب حسب المنطقة',
      yieldTarget: '20-40 طن/فدان حسب الصنف والخدمة',
      plantingMethod: 'شتلات سليمة مع تعقيم الأدوات ومراعاة دورة المحصول',
      harvestMethod: 'جمع الثمار عند اكتمال اللون والحجم على دفعات',
      economicImportance: 'غذاء أساسي وصناعة صلصة وتجفيف وتصنيع غذائي',
    ),
    CropRecord(
      name: 'البطاطس',
      scientificName: 'Solanum tuberosum',
      nameEn: 'Potato',
      imageUrl:
          'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=700',
      season: 'عروة صيفية وشتوية ونيلية',
      region: 'البحيرة والدقهلية والغربية والنوبارية',
      description:
          'محصول درني واسع الانتشار في مصر، حساس للصرف والملوحة ودرجات الحرارة المرتفعة أثناء تكوين الدرنات.',
      soilType: 'رملية طينية خفيفة جيدة التهوية والصرف',
      irrigation: 'تنقيط منتظم مع تجنب التعطيش ثم الري الغزير المفاجئ',
      fertilization:
          'فوسفور وبوتاسيوم مناسب للتدرن مع تقسيم الأزوت وعدم الإفراط فيه',
      pests: 'الندوة المتأخرة، فراشة درنات البطاطس، المن، الحفار',
      varieties: 'أصناف محلية ومعتمدة حسب الغرض التصنيعي أو التصديري',
      yieldTarget: '10-18 طن/فدان حسب العروة والخدمة',
      plantingMethod: 'تقاوي معتمدة مقسمة أو كاملة في خطوط جيدة التجهيز',
      harvestMethod: 'إيقاف الري قبل التقليع وتجفيف الدرنات في الظل',
      economicImportance: 'غذاء وتصنيع وتصدير ومصدر دخل رئيسي للمزارع',
    ),
    CropRecord(
      name: 'البرتقال',
      scientificName: 'Citrus sinensis',
      nameEn: 'Orange',
      imageUrl:
          'https://images.unsplash.com/photo-1547514701-42782101795e?w=700',
      season: 'شجرة دائمة الخضرة، إثمار شتوي',
      region: 'البحيرة والنوبارية والإسماعيلية ومناطق الدلتا',
      description:
          'من أهم أشجار الفاكهة المصرية، يحتاج شمسًا جيدة وصرفًا ممتازًا وبرنامج ري وتسميد ثابتًا.',
      soilType: 'رملية طينية جيدة الصرف وغير مرتفعة الملوحة',
      irrigation: 'تنقيط حسب عمر الشجرة والحرارة مع تقليل الري وقت البرودة',
      fertilization:
          'عضوي متحلل مع NPK وعناصر صغرى، ويحدد البرنامج بتحليل التربة والأوراق',
      pests: 'الحشرات القشرية، صانعة الأنفاق، ذبابة الفاكهة، أعفان الجذور',
      varieties: 'فالنسيا، أبو صرة، البلدي وأصناف تجارية معتمدة',
      yieldTarget: 'يختلف حسب عمر الشجرة والصنف والكثافة',
      plantingMethod: 'شتلات مطعومة سليمة على أصول مناسبة للمنطقة',
      harvestMethod: 'جمع الثمار مكتملة الحجم واللون مع تجنب الجروح',
      economicImportance: 'استهلاك محلي وعصائر وتصدير ومصدر دخل طويل الأجل',
    ),
    CropRecord(
      name: 'العنب',
      scientificName: 'Vitis vinifera',
      nameEn: 'Grape',
      imageUrl:
          'https://images.unsplash.com/photo-1537640538966-79f369143f8f?w=700',
      season: 'إثمار صيفي',
      region: 'الدلتا والأراضي الجديدة والمناطق الدافئة',
      description:
          'شجرة/كرمة فاكهة اقتصادية تحتاج تقليمًا وتربية دقيقة وتهوية جيدة لتقليل الأمراض الفطرية.',
      soilType: 'رملية طينية جيدة الصرف قليلة الملوحة',
      irrigation: 'تنقيط منتظم مع ضبط الري أثناء التزهير ونضج الثمار',
      fertilization:
          'تحليل تربة وأوراق مع تركيز البوتاسيوم والعناصر الصغرى في مراحل الجودة',
      pests: 'البياض الدقيقي والزغبي، دودة الثمار، الحشرات القشرية',
      varieties: 'بناتي، فليم، رومي أحمر وأصناف تصديرية حسب المنطقة',
      yieldTarget: 'يختلف حسب التربية والكثافة والصنف',
      plantingMethod: 'شتلات أو عقل معتمدة على تعريشة جيدة التهوية',
      harvestMethod: 'جمع العناقيد جافة وفي الصباح مع تداول لطيف',
      economicImportance: 'فاكهة طازجة وتصنيع وتصدير عالي القيمة',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF6A1B9A); // بنفسجي

    return Scaffold(
      appBar: const QurityAppBar(
        title: 'محاصيل مصر',
        color: color,
      ),
      body: Column(
        children: [
          const AgricultureContentPanel(section: AgricultureSections.crops),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _crops.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.68,
              ),
              itemBuilder: (context, index) => _CropCard(
                crop: _crops[index],
                color: color,
                index: index,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CropCard extends StatelessWidget {
  final CropRecord crop;
  final Color color;
  final int index;

  const _CropCard(
      {required this.crop, required this.color, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CropDetailScreen(crop: crop)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: CachedNetworkImage(
                imageUrl: crop.imageUrl,
                fit: BoxFit.contain,
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.12),
                colorBlendMode: BlendMode.dstOver,
                placeholder: (c, u) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (c, u, e) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  child: Image.asset(
                    'assets/images/plant.jpg',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(crop.icon,
                        size: 48, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          crop.season,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: color),
                        ),
                      ),
                      const Spacer(),
                      if (crop.yieldTarget.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.trending_up_rounded,
                                  size: 10, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                crop.yieldTarget.split(' ').first,
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.amber),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    crop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    crop.nameEn,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 11, color: color),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          crop.region,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 9,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (index * 50).ms)
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.92, 0.92));
  }
}

class CropDetailScreen extends StatelessWidget {
  final CropRecord crop;

  const CropDetailScreen({super.key, required this.crop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFF6A1B9A);

    return Scaffold(
      appBar: QurityAppBar(
        title: crop.name,
        color: color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المحصول
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(
                  imageUrl: crop.imageUrl,
                  fit: BoxFit.contain,
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.12),
                  colorBlendMode: BlendMode.dstOver,
                  placeholder: (c, u) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (c, u, e) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    child: Image.asset(
                      'assets/images/plant.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(crop.icon,
                          size: 64, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // الاسم والعلم
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: Icon(crop.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(crop.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900, color: color)),
                      const SizedBox(height: 4),
                      Text(crop.scientificName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text(crop.nameEn,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // شريط المواصفات السريعة
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: crop.season,
                    color: color),
                _InfoChip(
                    icon: Icons.location_on_rounded,
                    label: crop.region,
                    color: color),
                _InfoChip(
                    icon: Icons.terrain_rounded,
                    label: crop.soilType,
                    color: color),
                _InfoChip(
                    icon: Icons.trending_up_rounded,
                    label: crop.yieldTarget.split(' ').first,
                    color: Colors.amber),
              ],
            ),

            const SizedBox(height: 24),

            // الوصف
            _DetailSection(
              title: 'وصف المحصول',
              icon: Icons.description_rounded,
              color: color,
              child: Text(crop.description,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
            ),

            const SizedBox(height: 16),

            // طريقة الزراعة
            _DetailSection(
              title: 'طريقة الزراعة',
              icon: Icons.agriculture_rounded,
              color: color,
              child: Text(crop.plantingMethod,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
            ),

            const SizedBox(height: 16),

            // الري
            _DetailSection(
              title: 'نظام الري',
              icon: Icons.water_drop_rounded,
              color: color,
              child: Text(crop.irrigation,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
            ),

            const SizedBox(height: 16),

            // التسميد
            _DetailSection(
              title: 'برنامج التسميد',
              icon: Icons.science_rounded,
              color: color,
              child: SelectableText(crop.fertilization,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.7)),
            ),

            const SizedBox(height: 16),

            // الآفات
            _DetailSection(
              title: 'أهم الآفات والأمراض',
              icon: Icons.bug_report_rounded,
              color: color,
              child: Text(crop.pests,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
            ),

            const SizedBox(height: 16),

            // الأصناف
            _DetailSection(
              title: 'الأصناف الموصى بها (مركز البحوث الزراعية)',
              icon: Icons.eco_rounded,
              color: color,
              child: Text(crop.varieties,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
            ),

            const SizedBox(height: 16),

            // الحصاد
            _DetailSection(
              title: 'طريقة الحصاد',
              icon: Icons.agriculture_rounded,
              color: color,
              child: Text(crop.harvestMethod,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
            ),

            const SizedBox(height: 16),

            // الأهمية الاقتصادية
            _DetailSection(
              title: 'الأهمية الاقتصادية',
              icon: Icons.trending_up_rounded,
              color: color,
              child: Text(crop.economicImportance,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
            ),

            const SizedBox(height: 24),

            // مراجع علمية
            const _DetailSection(
              title: 'مراجع علمية مصرية موثقة',
              icon: Icons.menu_book_rounded,
              color: Color(0xFF6A1B9A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RefItem(
                      'دليل الممارسات الزراعية الجيدة - مركز البحوث الزراعية - معهد بحوث المحاصيل الحقلية'),
                  _RefItem(
                      'التوصيات الفنية للمحاصيل الحقلية - وزارة الزراعة واستصلاح الأراضي'),
                  _RefItem(
                      'أطلس المحاصيل المصرية - معهد بحوث المحاصيل - قسم بحوث القمح/الأرز/الذرة/القطن/البقوليات'),
                  _RefItem(
                      'برنامج التسميد المتوازن - معهد بحوث الأراضي والمياه والبيئة'),
                  _RefItem(
                      'دليل المكافحة المتكاملة للآفات - معهد بحوث وقاية النباتات'),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900, color: color)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _RefItem extends StatelessWidget {
  final String text;
  const _RefItem(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle_rounded, size: 8, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
        ],
      ),
    );
  }
}

class CropRecord {
  final String name;
  final String scientificName;
  final String nameEn;
  final String imageUrl;
  final String season;
  final String region;
  final String description;
  final String soilType;
  final String irrigation;
  final String fertilization;
  final String pests;
  final String varieties;
  final String yieldTarget;
  final String plantingMethod;
  final String harvestMethod;
  final String economicImportance;
  final IconData icon;

  const CropRecord({
    required this.name,
    required this.scientificName,
    required this.nameEn,
    required this.imageUrl,
    required this.season,
    required this.region,
    required this.description,
    required this.soilType,
    required this.irrigation,
    required this.fertilization,
    required this.pests,
    required this.varieties,
    required this.yieldTarget,
    required this.plantingMethod,
    required this.harvestMethod,
    required this.economicImportance,
  }) : icon = Icons.grass_rounded;
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurity/core/theme/app_theme.dart';
import 'package:qurity/features/home/about_app.dart';
import 'package:qurity/models/service_provider_model.dart';
import 'package:qurity/routes/app_routes.dart';
import 'package:qurity/widgets/whatsapp_mark.dart';

/// اختبارات الجزء المعدّل فقط: صفحة «عن التطبيق» — بطاقة بيانات المطور
/// واتصالاتها الثلاث وحالات فشلها، وشبكة الأقسام، وتجديد المحتوى.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pageFile = 'lib/features/home/about_app.dart';
  const phone = AboutScreen.developerPhone; // 01032231330
  const waUrl = 'https://wa.me/201032231330';

  final calls = <_LaunchCall>[];

  /// url_launcher على هذا المضيف لا يمرّ بالقناة القديمة وحدها: التنفيذ
  /// الفعلي تنفيذ سطح المكتب (`..._linux`) بأسماء طرق وردود مختلفة
  /// (`CanLaunch` ببولين، و`LaunchWithParams` بخريطة `{'value': …}`).
  /// المنفذ يردّ على الاثنين بالشكل الصحيح، ويسجّل كل نداء ب URL المقصود.
  void stubLauncher({bool launchable = true, bool throwFromChannel = false}) {
    calls.clear();
    void mock(MethodChannel channel, {required bool desktop}) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        final args = call.arguments;
        calls.add(_LaunchCall(
          call.method,
          args is Map ? args['url'] as String? : null,
        ));
        if (throwFromChannel) throw PlatformException(code: 'no-handler');
        if (desktop && call.method == 'LaunchWithParams') {
          return <String, Object?>{'value': launchable};
        }
        return launchable;
      });
    }

    mock(const MethodChannel('plugins.flutter.io/url_launcher'), desktop: false);
    mock(const MethodChannel('plugins.flutter.io/url_launcher_linux'), desktop: true);
  }

  /// عناوين الرابط التي فُتحت فعلًا (لا مجرد الفحص عن availability).
  List<String?> launchedUrls() => calls
      .where((c) => c.method == 'LaunchWithParams' || c.method == 'launch')
      .map((c) => c.url)
      .toList();

  /// نفس إعداد `main.dart`: عربية مصرية بمندوبيها، فالصفحة تُختبر في الاتجاه
  /// الذي تُبنى فيه فعلًا (بلا المندوبين يبقى LTR وتصبح «RTL» بلا معنى).
  Future<void> pumpPage(WidgetTester tester,
      {List<String>? pushed, double logicalHeight = 844}) async {
    tester.view.physicalSize = Size(1170, logicalHeight * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.aboutApp,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.aboutApp) {
          return MaterialPageRoute<AboutScreen>(
            builder: (_) => const AboutScreen(),
            settings: settings,
          );
        }
        pushed?.add(settings.name ?? '');
        return MaterialPageRoute<void>(
          builder: (_) => const SizedBox(key: Key('pushed-route')),
          settings: settings,
        );
      },
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Color? backgroundOf(WidgetTester tester, String key) {
    final button = tester.widget<FilledButton>(find.byKey(Key(key)));
    return button.style?.backgroundColor?.resolve(const <WidgetState>{});
  }

  /// اسم الأصل المعروض فعلًا: `cacheWidth` يلفّ المزوّد داخل `ResizeImage`،
  /// و`AssetImage.assetName` عامّ — فالمطابقة بالاسم لا بنصّ `toString()`.
  bool Function(Widget) imageWithAsset(String asset) => (w) {
        if (w is! Image) return false;
        final provider = w.image is ResizeImage ? (w.image as ResizeImage).imageProvider : w.image;
        return provider is AssetImage && provider.assetName == asset;
      };

  /// البطاقة داخل `ListView` كسول والطول زاد (صورة 68 + نبذة ثلاثة أسطر)،
  /// فأسفلها يقع تحت طيّ النافذة: `tap` بلا تمرير يشتقّ نقطة خارج شجرة الرسم.
  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  group('بطاقة بيانات المطور', () {
    testWidgets('الاسم والتسمية والنبذة ظاهرة، والأرقام لم تُكتب نصًا', (tester) async {
      stubLauncher();
      await pumpPage(tester);
      expect(find.text('م محمد العراقي'), findsWidgets);
      expect(find.text(AboutScreen.developerRole), findsWidgets);
      expect(find.text(AboutScreen.developerBio), findsOneWidget);
      // الرموز على الأزرار هي الدليل، فلا أسطر «رقم هاتف : 0103…» تُكرر الرقم
      expect(find.text(phone), findsNothing);
      expect(find.text('eleraki2010'), findsNothing);
      expect(find.text('رقم هاتف :'), findsNothing);
      expect(find.text('واتساب :'), findsNothing);
      expect(find.text('فيس بوك :'), findsNothing);
      expect(find.byKey(const Key('dev-call')), findsOneWidget);
      expect(find.byKey(const Key('dev-whatsapp')), findsOneWidget);
      expect(find.byKey(const Key('dev-facebook')), findsOneWidget);
    });

    testWidgets('صورة المطور من أصل leader، والضغط يفتحها بالحجم الكامل', (tester) async {
      stubLauncher();
      await pumpPage(tester);
      expect(find.byWidgetPredicate(imageWithAsset(AboutScreen.developerPhotoAsset)),
          findsOneWidget,
          reason: 'البطاقة لا تعرض صورة المطور');
      expect(find.byIcon(Icons.person_rounded), findsNothing);

      expect(find.byKey(const Key('dev-photo-viewer')), findsNothing);
      await tapKey(tester, 'dev-photo');
      await tester.pump(const Duration(milliseconds: 350));
      final viewer = find.byKey(const Key('dev-photo-viewer'));
      expect(viewer, findsOneWidget);
      // التكبير بالسحب وقرصتي الإبهام، لا بقراءة مقاس ثابت
      expect(tester.widget<InteractiveViewer>(viewer).maxScale, greaterThan(1));
      expect(find.byWidgetPredicate(imageWithAsset(AboutScreen.developerPhotoAsset)),
          findsNWidgets(2)); // البطاقة + العارض

      await tester.tap(find.text('إغلاق'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('dev-photo-viewer')), findsNothing);
    });

    testWidgets('الكارت العلوي يحمل شعار القرية لا أيقونة رمزية', (tester) async {
      stubLauncher();
      await pumpPage(tester);
      expect(find.byWidgetPredicate(imageWithAsset('assets/images/Qurity.png')),
          findsOneWidget);
      // أيقونة «تعرف على القرية» في سطر الروابط تبقى: المطلوب غياب الأيقونة
      // الرمزية من الكارت العلوي وحده، وقد ثبُت أن الشعار واحد في الصفحة.
    });

    test('الأصلان موجودان فعلًا في الحزمة (لا مسار ميت)', () async {
      for (final asset in [
        AboutScreen.developerPhotoAsset,
        'assets/images/Qurity.png',
      ]) {
        final data = await rootBundle.load(asset);
        expect(data.lengthInBytes, greaterThan(1000), reason: '$asset فارغ');
      }
    });

    testWidgets('الصفحة تُبنى وتُقرأ من اليمين كما بقية التطبيق', (tester) async {
      stubLauncher();
      await pumpPage(tester);
      expect(
        Directionality.of(tester.element(find.byKey(const Key('dev-photo')))),
        TextDirection.rtl,
      );
      // في RTL الطفل الأول هو الأيمن: صورة المطور يمين اسمه
      final photo = tester.getCenter(find.byKey(const Key('dev-photo')));
      final name = tester.getCenter(find.text('م محمد العراقي').first);
      expect(photo.dx, greaterThan(name.dx));
    });

    testWidgets('زر واتساب يحمل رمز واتساب المرسوم لا أيقونة نظام', (tester) async {
      stubLauncher();
      await pumpPage(tester);
      expect(
        find.descendant(
            of: find.byKey(const Key('dev-whatsapp')), matching: find.byType(WhatsAppMark)),
        findsOneWidget,
      );
      // الرمز في الزر وحده بعد أن حُذف سطر البيان
      expect(find.byType(WhatsAppMark), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsNothing);
    });

    testWidgets('الأزرار الثلاثة بألوانها المعروفة من مصادرها الواحدة', (tester) async {
      stubLauncher();
      await pumpPage(tester);
      expect(backgroundOf(tester, 'dev-call'), kCallButtonColor);
      expect(backgroundOf(tester, 'dev-whatsapp'), kWhatsAppGreen);
      expect(backgroundOf(tester, 'dev-facebook'), kFacebookBlue);
      expect(kCallButtonColor, const Color(0xFF2E7D32));
    });

    testWidgets('الاتصال يطلب رقم المطور بصيغة tel ولا رسالة فشل', (tester) async {
      stubLauncher();
      await pumpPage(tester);
      await tapKey(tester, 'dev-call');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(calls.map((c) => c.url), containsAllInOrder(['tel:$phone', 'tel:$phone']));
      expect(find.byKey(const Key('dev-contact-error')), findsNothing);
    });

    testWidgets('واتساب يفتح عنوان مصر الموحّد من مصريًا خارج المتصفح', (tester) async {
      stubLauncher();
      await pumpPage(tester);
      await tapKey(tester, 'dev-whatsapp');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(launchedUrls(), [waUrl]);
      expect(find.byKey(const Key('dev-contact-error')), findsNothing);
    });

    testWidgets('فيسبوك يفتح الرابط المعطى حرفيًا', (tester) async {
      stubLauncher();
      await pumpPage(tester);
      await tapKey(tester, 'dev-facebook');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(launchedUrls(), [AboutScreen.developerFacebookUrl]);
    });

    testWidgets('كل حالة فشل لها كلمتها الخاصة داخل البطاقة', (tester) async {
      stubLauncher(launchable: false);
      await pumpPage(tester);

      await tapKey(tester, 'dev-whatsapp');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      var error = tester.widget<Text>(find.byKey(const Key('dev-contact-error')));
      expect(error.data, 'واتساب غير متاح على هذا الجهاز.');
      expect(error.style!.color, kContactFailureRed);

      await tapKey(tester, 'dev-call');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      error = tester.widget<Text>(find.byKey(const Key('dev-contact-error')));
      expect(error.data, 'لا يمكن الاتصال على هذا الجهاز.');
      expect(error.data, isNot('واتساب غير متاح على هذا الجهاز.'));
    });

    testWidgets('استثناء المشغّل يُبلَّغ ولا يصمت', (tester) async {
      stubLauncher(throwFromChannel: true);
      await pumpPage(tester);
      await tapKey(tester, 'dev-facebook');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.widget<Text>(find.byKey(const Key('dev-contact-error'))).data,
        'تعذّر فتح صفحة فيسبوك — تحقّق من الاتصال ثم أعد المحاولة.',
      );
    });

    testWidgets('النجاح يُسقط رسالة الفشل السابقة', (tester) async {
      stubLauncher(launchable: false);
      await pumpPage(tester);
      await tapKey(tester, 'dev-call');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('dev-contact-error')), findsOneWidget);

      stubLauncher(); // إعادة التركيب هذه المرة بالردّ الناجح
      await tapKey(tester, 'dev-call');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('dev-contact-error')), findsNothing);
    });
  });

  group('المحتوى المحدّث وشبكة الأقسام', () {
    // الشبكة داخل ListView كسول: بلا نافذة طويلة لا تُبنى البلاطات الستّ
    // عشرة كلها، فيبدو الفحص كأنه «صفر بلاطات» لا «بلاطة ميتة».
    testWidgets('لا بلاطة ميتة: كل مسار في الشبكة مسجّل فعلًا', (tester) async {
      stubLauncher();
      await pumpPage(tester, logicalHeight: 2600);
      final keys = tester
          .widgetList<InkWell>(find.byWidgetPredicate((w) =>
              w is InkWell && (w.key as ValueKey<String>?)?.value.startsWith('about-section-') == true))
          .map((w) => (w.key as ValueKey<String>).value.substring('about-section-'.length))
          .toList();
      expect(keys.length, greaterThanOrEqualTo(15));
      for (final route in keys) {
        expect(AppRoutes.routes.keys, contains(route), reason: 'بلاطة «$route» تدفع مسارًا غير مسجّل');
      }
      expect(keys, contains(AppRoutes.medical));
      expect(keys, contains(AppRoutes.legalAdvisor));
      expect(keys, contains(AppRoutes.villageAds));
    });

    testWidgets('النقر على بلاطة قسم يدفع مسارها', (tester) async {
      stubLauncher();
      final pushed = <String>[];
      await pumpPage(tester, pushed: pushed, logicalHeight: 2600);
      await tester.tap(find.byKey(const Key('about-section-${AppRoutes.children}')));
      await tester.pumpAndSettle();
      // أول نداء هو المسار الابتدائي الذي تطلبه MaterialApp نفسها، فالمهم
      // ما دُفع بعد النقر.
      expect(pushed.last, AppRoutes.children);
      expect(find.byKey(const Key('pushed-route')), findsOneWidget);
    });

    test('صفحة «عن التطبيق» تذكر الأقسام الحقيقية لا القديمة', () {
      final source = File(pageFile).readAsStringSync();
      for (final label in [
        'إعلانات القرية',
        'مستشار القرية',
        'المستلزمات الطبية',
        'سجل العزاء',
        'ركن الأطفال',
        'دليل الهاتف',
        'أحدث ما أُضيف إلى التطبيق',
      ]) {
        expect(source, contains(label), reason: 'المحتوى لم يُحدَّث ليشمل «$label»');
      }
      // القائمة القديمة التي حذفتها إعادة التصميم لا تعود
      expect(source, isNot(contains('طلب الخدمات العامة')));
      expect(source, isNot(contains("'الرئيسية وخدمات القرية'")));
    });

    test('عقد المصدر: لا تبني عنوان واتساب ولا تكتب الرقم في زر الاتصال', () {
      final source = File(pageFile).readAsStringSync();
      expect(source, contains('egyptianWhatsAppUrl('));
      expect(source, isNot(contains('wa.me')));
      expect(source, contains('scheme: \'tel\''));
      expect(source, contains('LaunchMode.externalApplication'));
      expect(source, contains('kCallButtonColor'));
      expect(source, contains('kWhatsAppGreen'));
      expect(source, contains('WhatsAppMark('));
      // الصورة تكبر: عارض تفاعلي لا معاينة ثابتة المقاس
      expect(source, contains('InteractiveViewer('));
      expect(source, contains('assets/images/leader.jpg'));
      expect(source, contains('assets/images/Qurity.png'));
    });

    test('النبذة تُقرأ كما أعطاها صاحبها، والاسم يظهر مرة واحدة', () {
      // النص تجميده هنا مقصود: هو حرفية ما أعطاه صاحبها، وأي تحريف لاحق
      // (وليس تحريرًا مقصودًا منه) يُسقط هذا الاختبار.
      expect(AboutScreen.developerBio,
          'مطور ومصمم تطبيقات ، مهتم بتحويل الأفكار الإبداعية إلى تطبيقات '
          'رقمية عملية وجميلة. أسعى دائماً لتقديم تجربة مستخدم سلسة وعالية '
          'الجودة في كل مشروع أقدمه.');
      expect(AboutScreen.developerBio, contains('مطور ومصمم'));
      expect(AboutScreen.developerBio, contains('تجربة مستخدم'));
      final source = File(pageFile).readAsStringSync();
      // معالج «فيس بوك» لم يعد سطر بيان، فالمعرّف يبقى في الرابط وحده
      expect(RegExp('eleraki2010').allMatches(source).length, 1);
      expect(source, isNot(contains("'فيس بوك'")));
      expect(source, isNot(contains("'رقم هاتف'")));
    });

    test('بيانات المطور ثوابت واحدة المصدر تُستعمل في كل المواضع', () {
      expect(AboutScreen.developerName, 'م محمد العراقي');
      expect(AboutScreen.developerRole.trim(), 'مهندس برمجيات');
      expect(AboutScreen.developerPhone, '01032231330');
      expect(AboutScreen.developerFacebookUrl,
          'https://www.facebook.com/eleraki2010?locale=ar_AR');
      final source = File(pageFile).readAsStringSync();
      expect(RegExp('AboutScreen\\.developer').allMatches(source).length, greaterThanOrEqualTo(7));
      // الرقم لا يُكتب نصًا في الشيفرة خارج الثابت
      expect(RegExp('01032231330').allMatches(source).length, 1);
    });

    testWidgets('لا فيضان على مقاس الهاتف أثناء مشي الصفحة كاملًا', (tester) async {
      stubLauncher();
      await pumpPage(tester);
      final list = find.byType(Scrollable).first;
      for (var step = 0; step < 8; step++) {
        await tester.drag(list, const Offset(0, -500));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(tester.takeException(), isNull, reason: 'خطوة $step أفاضت العرض');
      }
      expect(find.text('العمل بلا اتصال: المحتوى محفوظ محليًا ويظهر فور عودة الشبكة.'), findsOneWidget);
    });
  });
}

class _LaunchCall {
  _LaunchCall(this.method, this.url);
  final String method;
  final String? url;
}

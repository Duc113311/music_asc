import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:muvik/presentation/screen_dashboard/dashboard_tab.dart';
import 'package:muvik/services/storage/pref_store.dart';
import 'package:muvik/utils/app_localize.dart';
import 'package:muvik/values/app_colors.dart';
import 'package:muvik/values/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'language': 'vi_VN'});
    await PrefStore.init();
    await AppLocalize.ensureConfigured();
    await AppLocalize.loadTranslations();
  });

  Future<void> pumpSlides(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark(AccentColor.lavender),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(body: Center(child: homeBannersForTest())),
      ),
    );
    await tester.pump();
  }

  testWidgets('three slides, one at a time, with their own copy and button', (
    tester,
  ) async {
    await pumpSlides(tester, const Size(390, 844));
    expect(find.text('DÀNH RIÊNG CHO BẠN'), findsOneWidget);
    expect(find.text('Phát ngẫu nhiên'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('TÌM LẠI CẢM XÚC'), findsOneWidget);
    expect(find.text('Khám phá lại'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('BẬT CHẾ ĐỘ HỨNG KHỞI'), findsOneWidget);
    expect(find.text('Nghe ngay'), findsOneWidget);
    // No fourth slide.
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('BẬT CHẾ ĐỘ HỨNG KHỞI'), findsOneWidget);
  });

  for (final c in const [
    (Size(390, 844), 1.0),
    (Size(320, 568), 1.0),
    (Size(412, 915), 1.3),
    (Size(360, 640), 1.5),
  ]) {
    testWidgets('no overflow on ${c.$1.width.toInt()}x${c.$1.height.toInt()} '
        'at text scale ${c.$2}', (tester) async {
      await pumpSlides(tester, c.$1, textScale: c.$2);
      for (var i = 0; i < 3; i++) {
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'slide ${i + 1}');
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
      }
    });
  }
}

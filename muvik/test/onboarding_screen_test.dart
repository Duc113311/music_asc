import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:muvik/controller/onboarding_controller.dart';
import 'package:muvik/presentation/screens_onboarding/onboarding_screen.dart';

void main() {
  Future<void> pumpOnboarding(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.put(OnboardingController());
    await tester.pumpWidget(const GetMaterialApp(home: OnboardingScreen()));
  }

  setUp(Get.reset);
  tearDown(Get.reset);

  // Without translations loaded `.tr` returns the key, which is what the
  // finders below use.
  testWidgets('elements appear one after another, then stay', (tester) async {
    await pumpOnboarding(tester, const Size(390, 844));

    double opacityOf(String key) {
      final o = tester.widget<Opacity>(
        find.ancestor(of: find.text(key), matching: find.byType(Opacity)).first,
      );
      return o.opacity;
    }

    // Just built: nothing visible yet.
    expect(opacityOf('onb1_title'), 0);
    expect(opacityOf('action_continue'), 0);

    // Title is up before the button; the button is up before the end.
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacityOf('onb1_title'), greaterThan(0.9));
    expect(opacityOf('onb1_desc'), lessThan(opacityOf('onb1_title')));
    expect(opacityOf('action_continue'), lessThan(0.9));

    await tester.pump(const Duration(milliseconds: 1500));
    for (final key in [
      'onb1_title',
      'onb1_highlight',
      'onb1_desc',
      'action_continue',
      'action_skip',
    ]) {
      expect(opacityOf(key), 1, reason: key);
    }
  });

  testWidgets('page 1 has Skip and no back arrow; next shows back + CTA', (
    tester,
  ) async {
    await pumpOnboarding(tester, const Size(390, 844));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('action_skip'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);

    await tester.tap(find.text('action_continue'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('onb2_title'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

    await tester.tap(find.text('action_continue'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('onb3_title'), findsOneWidget);
    expect(find.text('action_get_started'), findsOneWidget);
  });

  for (final size in const [
    Size(390, 844),
    Size(360, 640),
    Size(412, 915),
    Size(320, 568),
  ]) {
    testWidgets('no overflow on ${size.width.toInt()}x${size.height.toInt()}', (
      tester,
    ) async {
      await pumpOnboarding(tester, size);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  }
}

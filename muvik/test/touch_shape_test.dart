import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:muvik/controller/onboarding_controller.dart';
import 'package:muvik/presentation/common_components/app_touchable.dart';
import 'package:muvik/presentation/screens_onboarding/onboarding_screen.dart';
import 'package:muvik/values/app_colors.dart';
import 'package:muvik/values/app_theme.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  testWidgets('onboarding CTA spans the full width, whatever the label', (
    tester,
  ) async {
    // 600 wide: the label ("action_continue" in tests) is far shorter than
    // 600 - 2*24, so a shrink-wrapped button would be much narrower.
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.put(OnboardingController());
    await tester.pumpWidget(const GetMaterialApp(home: OnboardingScreen()));
    await tester.pump(const Duration(seconds: 2));

    final button = find
        .ancestor(
          of: find.text('action_continue'),
          matching: find.byType(DecoratedBox),
        )
        .last;
    expect(tester.getSize(button).width, 600 - 48);
  });

  testWidgets('icon buttons use a round, contained ripple (no square corners)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(AccentColor.lavender),
        home: Scaffold(
          body: Row(
            children: [
              AppIconButton(icon: Icons.favorite_rounded, tooltip: 'a', onPressed: () {}),
              AppIconButton(
                icon: Icons.calendar_month_rounded,
                tooltip: 'b',
                filled: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    final inks = tester.widgetList<InkResponse>(
      find.descendant(
        of: find.byType(AppIconButton),
        matching: find.byType(InkResponse),
      ),
    );
    expect(inks, hasLength(2));
    for (final ink in inks) {
      expect(ink.customBorder, isA<CircleBorder>());
      expect(ink.containedInkWell, isTrue);
      expect(ink.highlightShape, BoxShape.circle);
    }
    // The 48x48 touch target is kept for both variants.
    for (final b in tester.widgetList<AppIconButton>(find.byType(AppIconButton))) {
      expect(tester.getSize(find.byWidget(b)), const Size(48, 48));
    }
  });
}

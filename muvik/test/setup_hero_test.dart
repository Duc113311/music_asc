import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/presentation/screens_setup/setup_screen.dart';
import 'package:muvik/values/app_assets.dart';

void main() {
  testWidgets('setup illustration is as wide as the screen, not the padded list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            // The same 20 px side padding the setup steps use.
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              for (final a in [AppAssets.step1, AppAssets.step2, AppAssets.step3])
                SetupHero(asset: a, aspect: 600 / 900),
            ],
          ),
        ),
      ),
    );
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, hasLength(3));
    for (final i in images) {
      expect(i.width, 390);
    }
    // Rendered width: the full 390, wider than the 350 px content area.
    expect(tester.getSize(find.byType(Image).first).width, 390);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the illustration height is capped on short screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [SetupHero(asset: AppAssets.step1, aspect: 600 / 900)],
          ),
        ),
      ),
    );
    // 34% of 560 = 190, below the 240 an uncapped 360-wide image would take.
    expect(tester.getSize(find.byType(SetupHero)).height, lessThanOrEqualTo(560 * 0.34 + 0.01));
  });
}

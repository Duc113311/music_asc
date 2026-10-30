import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:muvik/configs/pref_const.dart';
import 'package:muvik/services/storage/pref_store.dart';
import 'package:muvik/tour/tour_anchor.dart';
import 'package:muvik/tour/tour_controller.dart';
import 'package:muvik/tour/tour_overlay.dart';
import 'package:muvik/tour/tour_steps.dart';
import 'package:muvik/values/app_colors.dart';
import 'package:muvik/values/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app() => GetMaterialApp(
      theme: AppTheme.dark(AccentColor.lavender),
      builder: (context, child) => TourOverlay(child: child!),
      home: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final id in [
                TourAnchors.homeShuffle,
                TourAnchors.librarySong,
                TourAnchors.statsPeriod,
              ])
                Expanded(
                    child: TourAnchor(id: id, child: const SizedBox.expand())),
            ],
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    await PrefStore.init();
    Get.put(TourController(), permanent: true);
  });

  testWidgets('runs through the three spotlights once, then never again',
      (tester) async {
    await tester.pumpWidget(_app());
    final tour = TourController.to;
    expect(tour.shouldStart, isTrue);

    final started = tester.runAsync(() => tour.start());
    await tester.pump(const Duration(milliseconds: 300));
    expect(await started, isTrue);
    await tester.pump();
    expect(tour.active.value, isTrue);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('tour_home'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);

    await tester.runAsync(() => tour.next());
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('tour_library'), findsOneWidget);
    await tester.runAsync(() => tour.previous());
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('tour_home'), findsOneWidget);

    await tester.runAsync(() => tour.next());
    await tester.runAsync(() => tour.next());
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('3/3'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(find.text('tour_done'), findsOneWidget);
    expect(find.text('tour_skip'), findsNothing); // nothing left to skip

    await tester.runAsync(() => tour.next());
    await tester.pump();
    expect(tour.active.value, isFalse);
    expect(PrefStore.getBool(PrefConst.tourSeen, false), isTrue);
    expect(tour.shouldStart, isFalse);
    expect(await tester.runAsync(() => tour.start()), isFalse);
  });

  testWidgets('opens the step tab and skips steps with no anchor',
      (tester) async {
    await tester.pumpWidget(_app());
    final tour = TourController.to;
    final tabs = <int>[];
    tour.selectTab = tabs.add;
    await tester.runAsync(() => tour.start());
    // Drop the library step's anchor: next() must jump straight to stats.
    tour.anchors.remove(TourAnchors.librarySong);
    await tester.runAsync(() => tour.next());
    expect(tour.index.value, 2);
    expect(tabs, [0, 1, 2]);
    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('skip ends the tour and it is not shown again', (tester) async {
    await tester.pumpWidget(_app());
    final tour = TourController.to;
    final started = tester.runAsync(() => tour.start());
    await tester.pump(const Duration(milliseconds: 300));
    await started;
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.text('tour_skip'));
    await tester.pump();
    expect(tour.active.value, isFalse);
    expect(tour.shouldStart, isFalse);
  });

  testWidgets('an install that has seen the tour does not start it',
      (tester) async {
    SharedPreferences.setMockInitialValues({PrefConst.tourSeen: true});
    await PrefStore.init();
    await tester.pumpWidget(_app());
    expect(await tester.runAsync(() => TourController.to.start()), isFalse);
    expect(TourController.to.active.value, isFalse);
  });
}

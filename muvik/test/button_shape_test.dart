import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:muvik/presentation/common_components/primary_button.dart';
import 'package:muvik/presentation/dialogs/rate_app_dialog.dart';
import 'package:muvik/services/storage/pref_store.dart';
import 'package:muvik/values/app_colors.dart';
import 'package:muvik/values/app_dimensions.dart';
import 'package:muvik/values/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(Widget home) => GetMaterialApp(
    theme: AppTheme.dark(AccentColor.lavender),
    home: home,
  );

  testWidgets('every button variant is a full pill (fill and ripple)', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Column(
            children: [
              for (final v in ButtonVariant.values)
                PrimaryButton(label: v.name, variant: v, onPressed: () async {}),
            ],
          ),
        ),
      ),
    );
    final pill = BorderRadius.circular(AppRadius.full);
    for (final box in tester.widgetList<AnimatedContainer>(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(AnimatedContainer),
      ),
    )) {
      expect((box.decoration! as BoxDecoration).borderRadius, pill);
    }
    final inks = tester.widgetList<InkWell>(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(InkWell),
      ),
    );
    expect(inks, hasLength(ButtonVariant.values.length));
    for (final ink in inks) {
      expect(ink.borderRadius, pill);
    }
  });

  testWidgets('rate dialog: 8 px between "Đánh giá" and "Để sau"', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await PrefStore.init();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const Scaffold(body: SizedBox())));
    showRateAppDialog();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final buttons = find.byType(PrimaryButton);
    expect(buttons, findsNWidgets(2));
    final rate = tester.getRect(buttons.at(0));
    final later = tester.getRect(buttons.at(1));
    expect(later.top - rate.bottom, 8);
    expect(rate.height, later.height);
    expect(rate.width, later.width);
    // Let the opening animation finish so no timer is left pending.
    await tester.pump(const Duration(seconds: 3));
  });
}

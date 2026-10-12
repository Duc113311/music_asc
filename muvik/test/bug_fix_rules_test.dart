import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/main.dart';
import 'package:muvik/models/ui_models/repeat_mode.dart';
import 'package:muvik/presentation/common_components/cards.dart';
import 'package:muvik/services/application/equalizer_service.dart';
import 'package:muvik/services/storage/pref_store.dart';
import 'package:muvik/configs/pref_const.dart';
import 'package:muvik/values/app_colors.dart';
import 'package:muvik/values/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rules added by Muvik_Bug_Fix_Notes.md (font −2px, repeat button,
/// loudness boost, 8 accents, smaller "Playlist dành cho bạn" cards).
void main() {
  group('repeat button', () {
    test('cycles Off → All → One → Off', () {
      expect(RepeatMode.off.next, RepeatMode.all);
      expect(RepeatMode.all.next, RepeatMode.one);
      expect(RepeatMode.one.next, RepeatMode.off);
    });
  });

  group('SmallerTextScaler', () {
    test('every font is 2px smaller, never below 8px', () {
      const s = SmallerTextScaler(TextScaler.noScaling);
      expect(s.scale(16), 14);
      expect(s.scale(12), 10);
      expect(s.scale(9), 8);
      expect(s.scale(7.5), 7.5);
    });

    test('keeps the system text scale on top', () {
      final s = SmallerTextScaler(TextScaler.linear(1.3));
      expect(s.scale(16), closeTo(14 * 1.3, 1e-9));
    });

    test('equality follows the base scaler', () {
      expect(
        const SmallerTextScaler(TextScaler.noScaling),
        const SmallerTextScaler(TextScaler.noScaling),
      );
      expect(
        SmallerTextScaler(TextScaler.linear(1.3)) ==
            const SmallerTextScaler(TextScaler.noScaling),
        isFalse,
      );
    });
  });

  group('loudness boost', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PrefStore.init();
    });

    test('clamps to 0..+10 dB and is saved', () async {
      final eq = EqualizerService();
      await eq.setLoudnessGain(25);
      expect(eq.state.value.loudnessGainDb, EqualizerState.maxLoudnessDb);
      expect(PrefStore.getDouble(PrefConst.eqLoudnessGainDb, -1), 10);
      await eq.setLoudnessGain(-3);
      expect(eq.state.value.loudnessGainDb, 0);
    });

    test('is restored from prefs and cleared by reset', () async {
      await PrefStore.setDouble(PrefConst.eqLoudnessGainDb, 4.5);
      final eq = EqualizerService()..loadPrefs();
      expect(eq.state.value.loudnessGainDb, 4.5);
      await eq.reset();
      expect(eq.state.value.loudnessGainDb, 0);
      expect(PrefStore.getDouble(PrefConst.eqLoudnessGainDb, -1), 0);
    });
  });

  test('12 accent colors with unique keys', () {
    expect(AccentColor.values.length, 12);
    expect(AccentColor.values.map((a) => a.key).toSet().length, 12);
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('compact "for you" card fits 124×196 (x$scale)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(AccentColor.values.first),
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 640),
              textScaler: SmallerTextScaler(TextScaler.linear(scale)),
            ),
            child: Scaffold(
              body: SizedBox(
                height: 196,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    CoverCard(
                      width: 124,
                      title: 'Một tên playlist rất dài để xuống hai dòng',
                      subtitle: '12 bài hát',
                      onPlay: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}

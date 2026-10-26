import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:muvik/controller/ringtone_editor_controller.dart';
import 'package:muvik/models/data_models/song.dart';
import 'package:muvik/models/ui_models/ringtone_range.dart';
import 'package:muvik/presentation/screens_settings/waveform_selector.dart';
import 'package:muvik/services/native/ringtone_channel.dart';
import 'package:muvik/services/storage/pref_store.dart';
import 'package:muvik/values/app_colors.dart';
import 'package:muvik/values/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Song _song({int durationMs = 200000}) => Song(
  sourceId: 1,
  identity: 'x',
  uri: 'content://media/x',
  title: 'Demo song',
  artist: 'Demo',
  durationMs: durationMs,
  folderPath: 'Music',
  fileName: 'x.mp3',
  firstSeenAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RingtoneRange', () {
    test('starts 15 s in, 30 s long, inside a long song', () {
      final r = RingtoneRange.initial(200000);
      expect(r.startMs, 15000);
      expect(r.endMs, 45000);
      expect(r.lengthMs, 30000);
    });

    test('a short song is taken whole', () {
      final r = RingtoneRange.initial(20000);
      expect((r.startMs, r.endMs), (0, 20000));
      final tiny = RingtoneRange.initial(2000);
      expect((tiny.startMs, tiny.endMs), (0, 2000));
      // It cannot be shrunk below the song itself.
      expect(tiny.withEnd(500).endMs, 2000);
    });

    test('length stays between 3 s and 40 s', () {
      var r = RingtoneRange.initial(200000); // 15..45 s
      r = r.withStart(0); // would be 45 s: the start is held at end - 40 s
      expect(r.lengthMs, RingtoneRange.maxMs);
      expect(r.startMs, 5000);
      r = r.withStart(44000); // would be 1 s: held at end - 3 s
      expect(r.lengthMs, RingtoneRange.minMs);
      r = r.withEnd(500000); // past the song and past 40 s
      expect(r.endMs <= 200000, isTrue);
      expect(r.lengthMs, lessThanOrEqualTo(RingtoneRange.maxMs));
      r = r.withEnd(0);
      expect(r.lengthMs, RingtoneRange.minMs);
    });

    test('the end never goes past the song', () {
      final r = RingtoneRange.initial(60000).withEnd(999999);
      expect(r.endMs, 55000); // start 15 s + 40 s max
      final late = r.shifted(999999);
      expect(late.endMs, 60000);
      expect(late.lengthMs, r.lengthMs);
      expect(late.shifted(-999999).startMs, 0);
    });

    test('time format', () {
      expect(RingtoneRange.format(0), '0:00.0');
      expect(RingtoneRange.format(7540), '0:07.5');
      expect(RingtoneRange.format(125900), '2:05.9');
    });
  });

  group('WaveformSelector', () {
    Future<List<RingtoneRange>> pump(
      WidgetTester tester,
      RingtoneRange start,
    ) async {
      final changes = <RingtoneRange>[];
      var current = start;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(AccentColor.lavender),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SizedBox(
                width: 400,
                child: WaveformSelector(
                  peaks: List.generate(100, (i) => (i % 10) / 10),
                  range: current,
                  onChanged: (r) {
                    changes.add(r);
                    setState(() => current = r);
                  },
                ),
              ),
            ),
          ),
        ),
      );
      return changes;
    }

    testWidgets('dragging the left handle moves the start only', (tester) async {
      // 200 s over 400 px = 2 px per second: the clip 40 s..80 s is x 80..160.
      final start = RingtoneRange.initial(200000).shifted(25000).withEnd(80000);
      final changes = await pump(tester, start);
      final box = tester.getTopLeft(find.byType(WaveformSelector));
      final g = await tester.startGesture(box + const Offset(80, 60));
      await g.moveBy(const Offset(20, 0)); // 10 s later
      await g.up();
      expect(changes, isNotEmpty);
      expect(changes.last.endMs, 80000);
      expect(changes.last.startMs, greaterThan(40000));
      // Going earlier would make the clip longer than 40 s: it is held there.
      final g2 = await tester.startGesture(box + Offset(changes.last.startMs / 1000 * 2, 60));
      await g2.moveBy(const Offset(-80, 0));
      await g2.up();
      expect(changes.last.lengthMs, lessThanOrEqualTo(RingtoneRange.maxMs));
    });

    testWidgets('dragging inside slides the whole clip', (tester) async {
      final start = RingtoneRange.initial(200000).shifted(25000).withEnd(80000);
      final changes = await pump(tester, start);
      final box = tester.getTopLeft(find.byType(WaveformSelector));
      final g = await tester.startGesture(box + const Offset(120, 60));
      await g.moveBy(const Offset(40, 0)); // +20 s
      await g.up();
      expect(changes.last.lengthMs, 40000);
      expect(changes.last.startMs, greaterThan(40000));
    });

    testWidgets('dragging outside the clip changes nothing', (tester) async {
      final start = RingtoneRange.initial(200000).shifted(25000).withEnd(80000);
      final changes = await pump(tester, start);
      final box = tester.getTopLeft(find.byType(WaveformSelector));
      final g = await tester.startGesture(box + const Offset(300, 60));
      await g.moveBy(const Offset(30, 0));
      await g.up();
      expect(changes, isEmpty);
    });
  });

  group('RingtoneChannel and the editor', () {
    const ch = MethodChannel('com.asctechsoft.muvik/ringtone');
    const lib = MethodChannel('com.asctechsoft.muvik/media_library');
    final calls = <MethodCall>[];
    var canWrite = true;
    Object? failWith;

    setUp(() async {
      Get.reset();
      calls.clear();
      canWrite = true;
      failWith = null;
      SharedPreferences.setMockInitialValues({});
      await PrefStore.init();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockMethodCallHandler(lib, (c) async => c.method == 'sdkInt' ? 34 : null)
        ..setMockMethodCallHandler(ch, (c) async {
          calls.add(c);
          switch (c.method) {
            case 'canWriteSettings':
              return canWrite;
            case 'waveform':
              return {'durationMs': 180000, 'peaks': [0.2, 1.0, 0.5]};
            case 'cut':
              if (failWith != null) {
                throw PlatformException(code: failWith! as String, message: 'x');
              }
              return {'uri': 'content://media/new', 'name': 'Demo song (Muvik)'};
            case 'setDefault':
              return true;
          }
          return null;
        });
    });

    tearDown(() {
      Get.reset();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockMethodCallHandler(ch, null)
        ..setMockMethodCallHandler(lib, null);
    });

    test('waveform is parsed and the real duration replaces the library one', () async {
      final c = Get.put(RingtoneEditorController(_song(durationMs: 100000)));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(c.peaks.toList(), [0.2, 1.0, 0.5]);
      expect(c.range.value.durationMs, 180000);
      expect(c.loadingWave.value, isFalse);
    });

    test('save only: cuts the chosen range and does not touch the system', () async {
      final c = Get.put(RingtoneEditorController(_song()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      c.setType(RingtoneType.notification);
      await c.save(makeDefault: false);
      final cut = calls.singleWhere((m) => m.method == 'cut');
      expect(cut.arguments['startMs'], c.range.value.startMs);
      expect(cut.arguments['endMs'], c.range.value.endMs);
      expect(cut.arguments['type'], 'notification');
      expect(calls.any((m) => m.method == 'setDefault'), isFalse);
      expect(c.busy.value, isFalse);
    });

    test('set as ringtone: cuts, then makes it the default', () async {
      final c = Get.put(RingtoneEditorController(_song()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await c.save(makeDefault: true);
      final names = calls.map((m) => m.method).toList();
      expect(names.indexOf('cut'), lessThan(names.indexOf('setDefault')));
      final set = calls.singleWhere((m) => m.method == 'setDefault');
      expect(set.arguments['uri'], 'content://media/new');
      expect(set.arguments['type'], 'ringtone');
    });

    test('without "Modify system settings" nothing is cut for a default sound', () async {
      canWrite = false;
      final c = Get.put(RingtoneEditorController(_song()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // The explanation dialog needs a Navigator; with none it is skipped and
      // the save is simply not done.
      try {
        await c.save(makeDefault: true);
      } catch (_) {}
      expect(calls.any((m) => m.method == 'cut'), isFalse);
      expect(calls.any((m) => m.method == 'setDefault'), isFalse);
    });

    test('a failing cut leaves the editor usable', () async {
      failWith = 'ringtone_failed';
      final c = Get.put(RingtoneEditorController(_song()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await c.save(makeDefault: true);
      expect(c.busy.value, isFalse);
      expect(calls.any((m) => m.method == 'setDefault'), isFalse);
    });
  });
}

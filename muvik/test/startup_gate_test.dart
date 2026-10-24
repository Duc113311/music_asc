import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/presentation/screen_splash/startup_gate.dart';

void main() {
  const appKey = Key('app');
  Widget gate(List<StartupStep> steps) => StartupGate(
    steps: steps,
    builder: (_) => const SizedBox(key: appKey),
  );

  testWidgets('runs the steps in order, then shows the app', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(
      gate([
        StartupStep('a', () => log.add('a')),
        StartupStep('b', () async => log.add('b')),
      ]),
    );
    await tester.pump();
    expect(log, ['a', 'b']);
    expect(find.byKey(appKey), findsOneWidget);
  });

  testWidgets('a step that never answers is skipped after its timeout', (
    tester,
  ) async {
    final never = Completer<void>();
    var after = false;
    await tester.pumpWidget(
      gate([
        StartupStep(
          'hangs',
          () => never.future,
          timeout: const Duration(seconds: 2),
        ),
        StartupStep('next', () => after = true),
      ]),
    );
    // Still on the boot screen: the app has not started and nothing crashed.
    expect(find.byKey(appKey), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(after, isTrue);
    expect(find.byKey(appKey), findsOneWidget);
  });

  testWidgets('a non-critical failure is skipped', (tester) async {
    await tester.pumpWidget(
      gate([
        StartupStep('boom', () => throw StateError('x')),
        StartupStep('ok', () {}),
      ]),
    );
    await tester.pump();
    expect(find.byKey(appKey), findsOneWidget);
  });

  testWidgets('a critical failure shows Retry and a retry can succeed', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      gate([
        StartupStep('prefs', () {
          attempts++;
          if (attempts == 1) throw StateError('first launch');
        }, critical: true),
        StartupStep('later', () {}),
      ]),
    );
    await tester.pump();
    expect(find.byKey(appKey), findsNothing);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(attempts, 2);
    expect(find.byKey(appKey), findsOneWidget);
  });

  testWidgets('a completed step is not run again on retry', (tester) async {
    var first = 0;
    var second = 0;
    await tester.pumpWidget(
      gate([
        StartupStep('first', () => first++),
        StartupStep('second', () {
          second++;
          if (second == 1) throw StateError('fail once');
        }, critical: true),
      ]),
    );
    await tester.pump();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(first, 1);
    expect(second, 2);
    expect(find.byKey(appKey), findsOneWidget);
  });
}

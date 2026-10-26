import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:muvik/controller/onboarding_controller.dart';
import 'package:muvik/presentation/screens_onboarding/onboarding_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Pretends to be the native player: reports a 1080x1920 clip and records what
/// the app asked it to do.
class _FakePlayer extends VideoPlayerPlatform {
  final List<String> calls = [];
  final List<String> sources = [];
  double volume = -1;
  bool looping = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async => calls.add('dispose');

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    sources.add(options.dataSource.asset ?? '');
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 4),
      size: const Size(1080, 1920),
    ),
  );

  @override
  Future<void> setLooping(int playerId, bool looping) async =>
      this.looping = looping;

  @override
  Future<void> setVolume(int playerId, double volume) async =>
      this.volume = volume;

  @override
  Future<void> play(int playerId) async => calls.add('play');

  @override
  Future<void> pause(int playerId) async => calls.add('pause');

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox(key: Key('fake-video-surface'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = VideoPlayerPlatform.instance;

  setUp(Get.reset);
  tearDown(() {
    Get.reset();
    VideoPlayerPlatform.instance = original;
  });

  Future<void> pumpOnboarding(
    WidgetTester tester, {
    bool disableAnimations = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.put(OnboardingController());
    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: const OnboardingScreen(),
      ),
    );
    // Let the player initialize and the fade-in finish.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('page 1 plays its video: muted, looping, no still image', (
    tester,
  ) async {
    final fake = _FakePlayer();
    VideoPlayerPlatform.instance = fake;
    await pumpOnboarding(tester);

    expect(fake.sources, ['assets/images/mp4/mp4_slide_1.mp4']);
    expect(fake.volume, 0);
    expect(fake.looping, isTrue);
    expect(fake.calls, contains('play'));
    expect(find.byType(VideoPlayer), findsOneWidget);
    expect(find.byKey(const Key('fake-video-surface')), findsOneWidget);
    // The still image is only the fallback.
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('next page uses its own video', (tester) async {
    final fake = _FakePlayer();
    VideoPlayerPlatform.instance = fake;
    await pumpOnboarding(tester);

    await tester.tap(find.text('action_continue'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(fake.sources, contains('assets/images/mp4/mp4_slide_2.mp4'));
    // The page that left the screen released its player.
    expect(fake.calls, contains('dispose'));
  });

  testWidgets('if the video cannot be loaded the still image is shown', (
    tester,
  ) async {
    // No fake: the real plugin has no native side in a unit test, so loading
    // fails like an unsupported codec would.
    await pumpOnboarding(tester);
    expect(find.byType(VideoPlayer), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with animations off the video is not even started', (
    tester,
  ) async {
    final fake = _FakePlayer();
    VideoPlayerPlatform.instance = fake;
    await pumpOnboarding(tester, disableAnimations: true);
    expect(fake.sources, isEmpty);
    expect(find.byType(Image), findsOneWidget);
  });
}

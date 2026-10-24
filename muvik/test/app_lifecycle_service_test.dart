import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:muvik/services/application/app_lifecycle_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late AppLifecycleService service;

  setUp(() {
    Get.reset();
    service = Get.put(AppLifecycleService(), permanent: true);
  });

  tearDown(Get.reset);

  void moveTo(AppLifecycleState state) =>
      binding.handleAppLifecycleStateChanged(state);

  test('resumed listeners run on resume, background listeners on pause', () {
    var resumed = 0;
    var background = 0;
    service
      ..addResumedListener(() => resumed++)
      ..addBackgroundListener(() => background++);

    moveTo(AppLifecycleState.inactive);
    moveTo(AppLifecycleState.hidden);
    moveTo(AppLifecycleState.paused);
    expect(background, 1);
    expect(resumed, 0);
    expect(service.current.value, AppLifecycleState.paused);

    moveTo(AppLifecycleState.hidden);
    moveTo(AppLifecycleState.inactive);
    moveTo(AppLifecycleState.resumed);
    expect(resumed, 1);
    expect(background, 1);
  });

  test('a removed listener is no longer called', () {
    var calls = 0;
    void listener() => calls++;
    service.addResumedListener(listener);
    moveTo(AppLifecycleState.inactive);
    moveTo(AppLifecycleState.resumed);
    expect(calls, 1);

    service.removeResumedListener(listener);
    moveTo(AppLifecycleState.inactive);
    moveTo(AppLifecycleState.resumed);
    expect(calls, 1);
  });

  test('a listener may unsubscribe itself while being notified', () {
    var calls = 0;
    late final VoidCallback once;
    once = () {
      calls++;
      service.removeResumedListener(once);
    };
    var other = 0;
    service
      ..addResumedListener(once)
      ..addResumedListener(() => other++);

    moveTo(AppLifecycleState.inactive);
    moveTo(AppLifecycleState.resumed);
    moveTo(AppLifecycleState.inactive);
    moveTo(AppLifecycleState.resumed);
    expect(calls, 1);
    expect(other, 2);
  });
}

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/app_figs.dart';
import '../../utils/app_log.dart';
import '../../values/app_assets.dart';

/// One step of the start-up sequence run by [StartupGate].
class StartupStep {
  const StartupStep(
    this.name,
    this.run, {
    this.timeout = const Duration(seconds: 5),
    this.critical = false,
  });

  /// Shown on the boot screen of alpha/dev builds and written to the log.
  final String name;
  final FutureOr<void> Function() run;

  /// A step that has not finished after this long is abandoned.
  final Duration timeout;

  /// A critical step that fails or times out stops the start-up and shows the
  /// retry button; any other step is logged and skipped.
  final bool critical;
}

/// First widget of the app: it is on screen right after the engine starts and
/// runs the start-up [steps] one by one, each bounded by its own timeout, then
/// swaps itself for [builder] (the real app).
///
/// Why it exists: the steps used to run BEFORE `runApp`, so one plugin call that
/// never answered (system UI, prefs, Firebase...) left the user on a blank white
/// window forever on the first launch, until the app was swiped away. Now the
/// worst case is a visible boot screen that names the stuck step, and a step
/// that hangs is skipped (or, when critical, offers "Try again").
class StartupGate extends StatefulWidget {
  const StartupGate({super.key, required this.steps, required this.builder});

  final List<StartupStep> steps;
  final WidgetBuilder builder;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  final ValueNotifier<String> _label = ValueNotifier('');
  final Set<String> _done = {};
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _failed = false);
    final total = Stopwatch()..start();
    for (final step in widget.steps) {
      if (_done.contains(step.name)) continue;
      _label.value = step.name;
      final sw = Stopwatch()..start();
      try {
        await Future<void>.sync(step.run).timeout(step.timeout);
        _done.add(step.name);
        AppLog.info('startup: ${step.name} ${sw.elapsedMilliseconds} ms');
      } on TimeoutException {
        AppLog.info('startup: ${step.name} TIMED OUT after ${step.timeout}');
        if (step.critical) return _fail();
      } catch (e, st) {
        AppLog.error('startup: ${step.name} failed', e, st);
        if (step.critical) return _fail();
      }
    }
    AppLog.info('startup: done in ${total.elapsedMilliseconds} ms');
    if (mounted) setState(() => _ready = true);
  }

  void _fail() {
    if (mounted) setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.builder(context);
    return _BootScreen(
      label: _label,
      failed: _failed,
      onRetry: _run,
    );
  }
}

/// Plain boot screen with no MaterialApp, theme or translations (none of them
/// exists yet): dark background like the native launch window, logo, dots.
class _BootScreen extends StatefulWidget {
  const _BootScreen({
    required this.label,
    required this.failed,
    required this.onRetry,
  });

  final ValueListenable<String> label;
  final bool failed;
  final VoidCallback onRetry;

  @override
  State<_BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<_BootScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF090F20);
  static const _accent = Color(0xFF985AFD);

  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  String _retryText() {
    final t = 'splash_init_failed'.tr;
    return t == 'splash_init_failed' ? "Couldn't start Muvik." : t;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: _bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(AppAssets.logo, width: 104, height: 104),
              ),
              const SizedBox(height: 28),
              if (widget.failed) ...[
                Text(
                  _retryText(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: widget.onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ] else
                AnimatedBuilder(
                  animation: _a,
                  builder: (context, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final active = (_a.value * 3).floor() == i;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? _accent
                              : _accent.withValues(alpha: 0.35),
                        ),
                      );
                    }),
                  ),
                ),
              if (AppFigs.isShowTestOption)
                ValueListenableBuilder<String>(
                  valueListenable: widget.label,
                  builder: (context, step, _) => Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      step,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

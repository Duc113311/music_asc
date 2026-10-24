import 'dart:async';

import 'package:dsp_base/dsp_base.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:get/get.dart';

typedef AnalyticsEventSink =
    void Function(String name, Map<String, Object>? parameters);
typedef AnalyticsPropSink = void Function(String name, String value);

/// Central analytics gateway for Muvik, same design as smart_drink: every event
/// funnels through here, screens and controllers never touch Firebase directly.
///
/// * **Name validation.** Firebase silently drops a malformed name; this asserts
///   loudly in dev and drops it in release instead of crashing a user.
/// * **String-only parameters.** GA4 custom dimensions only capture text; a
///   numeric parameter reports `(not set)` and breaks every breakdown built on
///   it, so numbers are bucketed into low-cardinality strings first.
/// * **A swappable sink**, so host tests assert on event names without a
///   platform channel.
/// * **Safe without Firebase.** Muvik plays music offline: when Firebase did not
///   come up (offline first launch, missing config) events are dropped silently.
///
/// The event list lives in `docs/analytics_spec.md`. GA4 has no rename: changing
/// a name starts a new series, so settle names against that doc before shipping.
class Analytics {
  Analytics._();

  /// Firebase accepts 1-40 characters: a letter, then letters/digits/underscore.
  static final RegExp _validEventName = RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,39}$');
  static const List<String> _reservedEventPrefixes = [
    'firebase_',
    'google_',
    'ga_',
  ];

  static AnalyticsEventSink _eventSink = _sendToFirebase;
  static AnalyticsPropSink _propSink = _sendPropToFirebase;

  static bool get _ready =>
      DspFirebaseService.isCoreReady && Get.isRegistered<DspAnalytics>();

  static void _log(String name, [Map<String, Object>? params]) {
    assert(
      isValidEventName(name),
      'Invalid Firebase Analytics event name: $name',
    );
    assert(
      _hasOnlyStringParams(params),
      'Analytics event $name has a non-String parameter; bucket it first',
    );
    if (!isValidEventName(name) || !_hasOnlyStringParams(params)) return;
    _eventSink(name, params);
  }

  static void _sendToFirebase(String name, Map<String, Object>? params) {
    if (!_ready) return;
    unawaited(
      DspAnalytics.to.log(DspAnalyticsEvent(name, params)).catchError((e) {
        debugPrint('Analytics.log($name) failed: $e');
      }),
    );
  }

  static void _sendPropToFirebase(String name, String value) {
    if (!_ready) return;
    unawaited(
      DspAnalytics.to.setUserProperty(name, value).catchError((e) {
        debugPrint('Analytics.setUserProperty($name) failed: $e');
      }),
    );
  }

  /// Sends an event from the spec when no typed helper is warranted. Prefer a
  /// named helper below so the event list stays greppable.
  static void track(String name, [Map<String, Object>? parameters]) =>
      _log(name, parameters);

  /// Sets a user property from the spec.
  static void setProperty(String name, String value) => _propSink(name, value);

  @visibleForTesting
  static bool isValidEventName(String name) =>
      _validEventName.hasMatch(name) &&
      !_reservedEventPrefixes.any(name.startsWith);

  static bool _hasOnlyStringParams(Map<String, Object>? params) =>
      params == null || params.values.every((value) => value is String);

  /// Swaps both sinks so host tests never reach the Firebase platform channel.
  @visibleForTesting
  static void setEventSinkForTest(
    AnalyticsEventSink eventSink, {
    AnalyticsPropSink? propSink,
  }) {
    _eventSink = eventSink;
    _propSink = propSink ?? (_, _) {};
  }

  @visibleForTesting
  static void resetEventSinkForTest() {
    _eventSink = _sendToFirebase;
    _propSink = _sendPropToFirebase;
  }

  // ============================== Events ==============================

  /// One `screen_view` per named route (see `RouteAnalytics`).
  static void screenView(String route) =>
      _log('screen_view', {'screen_name': route});
}

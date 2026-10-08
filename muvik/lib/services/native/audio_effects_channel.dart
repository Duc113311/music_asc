import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../utils/app_log.dart';

/// What the device's audio effect engine supports for the current session.
class AudioEffectsCapabilities {
  const AudioEffectsCapabilities({
    this.eqSupported = false,
    this.bandCentersHz = const [],
    this.minLevelDb = -12,
    this.maxLevelDb = 12,
    this.bassSupported = false,
    this.virtualizerSupported = false,
  });

  final bool eqSupported;
  final List<double> bandCentersHz;
  final double minLevelDb;
  final double maxLevelDb;
  final bool bassSupported;
  final bool virtualizerSupported;

  static const none = AudioEffectsCapabilities();

  factory AudioEffectsCapabilities.fromMap(Map m) => AudioEffectsCapabilities(
    eqSupported: (m['eqSupported'] as bool?) ?? false,
    bandCentersHz: ((m['bandCentersHz'] as List?) ?? const [])
        .map((e) => (e as num).toDouble())
        .toList(),
    minLevelDb: ((m['minLevelMb'] as num?) ?? -1200) / 100,
    maxLevelDb: ((m['maxLevelMb'] as num?) ?? 1200) / 100,
    bassSupported: (m['bassSupported'] as bool?) ?? false,
    virtualizerSupported: (m['virtualizerSupported'] as bool?) ?? false,
  );
}

/// Android audiofx (Equalizer, BassBoost, Virtualizer) bound to the player's
/// audio session id, so UI changes affect real output (P14-06).
class AudioEffectsChannel {
  AudioEffectsChannel._();
  static const MethodChannel _ch = MethodChannel(
    'com.asctechsoft.muvik/audio_effects',
  );

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<AudioEffectsCapabilities> attach(int sessionId) async {
    if (!isSupported) return AudioEffectsCapabilities.none;
    try {
      final r = await _ch.invokeMapMethod<String, dynamic>('attach', {
        'sessionId': sessionId,
      });
      return r == null
          ? AudioEffectsCapabilities.none
          : AudioEffectsCapabilities.fromMap(r);
    } on PlatformException catch (e) {
      AppLog.info('AudioEffectsChannel.attach: $e');
      return AudioEffectsCapabilities.none;
    }
  }

  static Future<void> apply({
    required bool enabled,
    required List<double> bandGainsDb,
    required int bassStrength,
    required int virtualizerStrength,
  }) async {
    if (!isSupported) return;
    try {
      await _ch.invokeMethod('apply', {
        'enabled': enabled,
        'bandLevelsMb': bandGainsDb.map((g) => (g * 100).round()).toList(),
        'bassStrength': bassStrength,
        'virtualizerStrength': virtualizerStrength,
      });
    } on PlatformException catch (e) {
      AppLog.info('AudioEffectsChannel.apply: $e');
    }
  }

  static Future<void> release() async {
    if (!isSupported) return;
    try {
      await _ch.invokeMethod('release');
    } on PlatformException catch (_) {}
  }
}

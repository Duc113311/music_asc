import 'package:flutter/services.dart';

/// What the clip is for; also the folder it is saved in.
enum RingtoneType {
  ringtone('ringtone'),
  notification('notification'),
  alarm('alarm');

  const RingtoneType(this.key);
  final String key;
}

/// Waveform of a whole song: [peaks] are 0..1 values, one per bar.
class RingtoneWaveform {
  const RingtoneWaveform({required this.durationMs, required this.peaks});
  final int durationMs;
  final List<double> peaks;
}

/// A clip saved on the device.
class RingtoneClip {
  const RingtoneClip({required this.uri, required this.name});
  final String uri;
  final String name;
}

/// Why a native call failed; [needsWriteSettings] means the user has not
/// allowed "Modify system settings" yet.
class RingtoneException implements Exception {
  const RingtoneException(this.code, [this.message]);
  final String code;
  final String? message;

  bool get needsWriteSettings => code == 'permission_denied';

  @override
  String toString() => 'RingtoneException($code, $message)';
}

/// Dart side of the Kotlin `RingtoneHandler`: waveform, cutting, saving and
/// making a clip the default sound. Everything stays on the device.
class RingtoneChannel {
  RingtoneChannel._();

  static const MethodChannel _ch = MethodChannel(
    'com.asctechsoft.muvik/ringtone',
  );

  static Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _ch.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw RingtoneException(e.code, e.message);
    } on MissingPluginException {
      throw const RingtoneException('unsupported');
    }
  }

  /// Whether the user allowed Muvik to "Modify system settings".
  static Future<bool> canWriteSettings() async {
    try {
      return await _call<bool>('canWriteSettings') ?? false;
    } on RingtoneException {
      return false;
    }
  }

  /// Opens the system page where the user allows it for Muvik.
  static Future<void> openWriteSettings() => _call<void>('openWriteSettings');

  static Future<RingtoneWaveform> waveform(
    String uri, {
    int buckets = 160,
  }) async {
    final map = await _call<Map<Object?, Object?>>('waveform', {
      'uri': uri,
      'buckets': buckets,
    });
    final peaks = (map?['peaks'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        const <double>[];
    return RingtoneWaveform(
      durationMs: (map?['durationMs'] as num?)?.toInt() ?? 0,
      peaks: peaks,
    );
  }

  /// Cuts [startMs]..[endMs] of [uri] and saves it for [type].
  static Future<RingtoneClip> cut({
    required String uri,
    required int startMs,
    required int endMs,
    required String name,
    required RingtoneType type,
  }) async {
    final map = await _call<Map<Object?, Object?>>('cut', {
      'uri': uri,
      'startMs': startMs,
      'endMs': endMs,
      'name': name,
      'type': type.key,
    });
    return RingtoneClip(
      uri: map?['uri'] as String? ?? '',
      name: map?['name'] as String? ?? name,
    );
  }

  /// Makes the saved clip the default sound of [type].
  static Future<void> setDefault(String uri, RingtoneType type) =>
      _call<void>('setDefault', {'uri': uri, 'type': type.key});
}

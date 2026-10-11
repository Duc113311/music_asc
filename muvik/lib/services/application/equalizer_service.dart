import 'package:flutter/foundation.dart';

import '../../configs/pref_const.dart';
import '../../configs/pref_defaults.dart';
import '../../models/ui_models/audio_preset.dart';
import '../native/audio_effects_channel.dart';
import '../storage/pref_store.dart';

@immutable
class EqualizerState {
  const EqualizerState({
    this.enabled = false,
    this.preset = AudioPreset.normal,
    this.bandGainsDb = const [],
    this.bassStrength = 0,
    this.virtualizerStrength = 0,
    this.loudnessGainDb = 0,
    this.capabilities = AudioEffectsCapabilities.none,
  });

  final bool enabled;
  final AudioPreset preset;

  /// One gain per device band (length == capabilities.bandCentersHz.length).
  final List<double> bandGainsDb;

  /// 0..1000 as in Android audiofx.
  final int bassStrength;
  final int virtualizerStrength;

  /// Loudness boost 0..[maxLoudnessDb]; independent of [enabled].
  final double loudnessGainDb;
  final AudioEffectsCapabilities capabilities;

  static const double maxLoudnessDb = 10;

  /// Above this the UI warns about distortion and hearing damage.
  static const double loudnessWarnDb = 6;

  bool get supported =>
      capabilities.eqSupported ||
      capabilities.bassSupported ||
      capabilities.virtualizerSupported ||
      capabilities.loudnessSupported;

  EqualizerState copyWith({
    bool? enabled,
    AudioPreset? preset,
    List<double>? bandGainsDb,
    int? bassStrength,
    int? virtualizerStrength,
    double? loudnessGainDb,
    AudioEffectsCapabilities? capabilities,
  }) => EqualizerState(
    enabled: enabled ?? this.enabled,
    preset: preset ?? this.preset,
    bandGainsDb: bandGainsDb ?? this.bandGainsDb,
    bassStrength: bassStrength ?? this.bassStrength,
    virtualizerStrength: virtualizerStrength ?? this.virtualizerStrength,
    loudnessGainDb: loudnessGainDb ?? this.loudnessGainDb,
    capabilities: capabilities ?? this.capabilities,
  );
}

/// Single source of EQ truth shared by the player sheet and the full screen.
/// Re-applies to every new audio session (P14-07).
class EqualizerService {
  final ValueNotifier<EqualizerState> state = ValueNotifier(
    const EqualizerState(),
  );

  List<double> _customGains = const [];

  void loadPrefs() {
    final preset = AudioPreset.fromKey(
      PrefStore.getString(PrefConst.eqPreset, PrefDefaults.eqPreset),
    );
    final csv = PrefStore.getString(
      PrefConst.eqCustomGains,
      PrefDefaults.eqCustomGains,
    );
    _customGains = csv.isEmpty
        ? const []
        : csv.split(',').map((e) => double.tryParse(e) ?? 0).toList();
    state.value = state.value.copyWith(
      enabled: PrefStore.getBool(PrefConst.eqEnabled, PrefDefaults.eqEnabled),
      preset: preset,
      bassStrength: PrefStore.getInt(
        PrefConst.eqBassStrength,
        PrefDefaults.eqBassStrength,
      ),
      virtualizerStrength: PrefStore.getInt(
        PrefConst.eqVirtualizerStrength,
        PrefDefaults.eqVirtualizerStrength,
      ),
      loudnessGainDb: PrefStore.getDouble(
        PrefConst.eqLoudnessGainDb,
        PrefDefaults.eqLoudnessGainDb,
      ).clamp(0, EqualizerState.maxLoudnessDb).toDouble(),
    );
  }

  /// Binds to the player's audio session and applies saved settings.
  Future<void> attach(int? sessionId) async {
    if (sessionId == null || sessionId == 0) return;
    final caps = await AudioEffectsChannel.attach(sessionId);
    final s = state.value;
    final gains =
        s.preset == AudioPreset.custom &&
            _customGains.length == caps.bandCentersHz.length
        ? _customGains
        : _gainsFor(s.preset, caps);
    state.value = s.copyWith(capabilities: caps, bandGainsDb: gains);
    await _apply();
  }

  List<double> _gainsFor(AudioPreset p, AudioEffectsCapabilities caps) => [
    for (final hz in caps.bandCentersHz)
      p.gainAt(hz).clamp(caps.minLevelDb, caps.maxLevelDb).toDouble(),
  ];

  Future<void> setEnabled(bool enabled) async {
    state.value = state.value.copyWith(enabled: enabled);
    await PrefStore.setBool(PrefConst.eqEnabled, enabled);
    await _apply();
  }

  Future<void> selectPreset(AudioPreset preset) async {
    final s = state.value;
    final gains =
        preset == AudioPreset.custom &&
            _customGains.length == s.capabilities.bandCentersHz.length
        ? _customGains
        : _gainsFor(preset, s.capabilities);
    state.value = s.copyWith(preset: preset, bandGainsDb: gains);
    await PrefStore.setString(PrefConst.eqPreset, preset.key);
    await _apply();
  }

  /// Manual band change switches to the Custom preset (spec §8.3).
  Future<void> setBandGain(int band, double db) async {
    final s = state.value;
    if (band < 0 || band >= s.bandGainsDb.length) return;
    final gains = [...s.bandGainsDb]..[band] = db;
    _customGains = gains;
    state.value = s.copyWith(preset: AudioPreset.custom, bandGainsDb: gains);
    await PrefStore.setString(PrefConst.eqPreset, AudioPreset.custom.key);
    await PrefStore.setString(
      PrefConst.eqCustomGains,
      gains.map((g) => g.toStringAsFixed(1)).join(','),
    );
    await _apply();
  }

  Future<void> setBassStrength(int v) async {
    state.value = state.value.copyWith(bassStrength: v.clamp(0, 1000));
    await PrefStore.setInt(PrefConst.eqBassStrength, state.value.bassStrength);
    await _apply();
  }

  Future<void> setVirtualizerStrength(int v) async {
    state.value = state.value.copyWith(virtualizerStrength: v.clamp(0, 1000));
    await PrefStore.setInt(
      PrefConst.eqVirtualizerStrength,
      state.value.virtualizerStrength,
    );
    await _apply();
  }

  /// Loudness boost (sc_bo_chinh_am), saved and re-applied per session.
  Future<void> setLoudnessGain(double db) async {
    final v = db.clamp(0, EqualizerState.maxLoudnessDb).toDouble();
    state.value = state.value.copyWith(loudnessGainDb: v);
    await PrefStore.setDouble(PrefConst.eqLoudnessGainDb, v);
    await _apply();
  }

  /// "Đặt lại": defaults defined in PrefDefaults, applied for real (P14-09).
  Future<void> reset() async {
    _customGains = const [];
    await PrefStore.setBool(PrefConst.eqEnabled, PrefDefaults.eqEnabled);
    await PrefStore.setString(PrefConst.eqPreset, PrefDefaults.eqPreset);
    await PrefStore.setString(
      PrefConst.eqCustomGains,
      PrefDefaults.eqCustomGains,
    );
    await PrefStore.setInt(
      PrefConst.eqBassStrength,
      PrefDefaults.eqBassStrength,
    );
    await PrefStore.setInt(
      PrefConst.eqVirtualizerStrength,
      PrefDefaults.eqVirtualizerStrength,
    );
    await PrefStore.setDouble(
      PrefConst.eqLoudnessGainDb,
      PrefDefaults.eqLoudnessGainDb,
    );
    final caps = state.value.capabilities;
    final preset = AudioPreset.fromKey(PrefDefaults.eqPreset);
    state.value = EqualizerState(
      enabled: PrefDefaults.eqEnabled,
      preset: preset,
      bandGainsDb: _gainsFor(preset, caps),
      bassStrength: PrefDefaults.eqBassStrength,
      virtualizerStrength: PrefDefaults.eqVirtualizerStrength,
      loudnessGainDb: PrefDefaults.eqLoudnessGainDb,
      capabilities: caps,
    );
    await _apply();
  }

  Future<void> _apply() async {
    final s = state.value;
    if (!s.supported) return;
    await AudioEffectsChannel.apply(
      enabled: s.enabled,
      bandGainsDb: s.bandGainsDb,
      bassStrength: s.bassStrength,
      virtualizerStrength: s.virtualizerStrength,
      loudnessGainDb: s.loudnessGainDb,
    );
  }
}

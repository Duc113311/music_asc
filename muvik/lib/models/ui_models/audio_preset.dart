import 'dart:math' as math;

/// EQ presets defined as a gain curve (dB) over reference frequencies. The
/// curve is interpolated onto whatever bands the device equalizer exposes, so
/// the UI never pretends to have a fixed band count (P14-05, P14-08).
enum AudioPreset {
  normal('normal', 'eq_preset_normal', [0, 0, 0, 0, 0, 0, 0]),
  bass('bass', 'eq_preset_bass', [8, 6, 3, 0, -1, -1, 0]),
  pop('pop', 'eq_preset_pop', [-1, 2, 4, 4, 2, 0, -1]),
  rock('rock', 'eq_preset_rock', [5, 3, -1, -2, 1, 3, 5]),
  vocal('vocal', 'eq_preset_vocal', [-2, -1, 1, 4, 4, 2, 0]),
  custom('custom', 'eq_preset_custom', [0, 0, 0, 0, 0, 0, 0]);

  const AudioPreset(this.key, this.labelKey, this.curveDb);

  final String key;
  final String labelKey;
  final List<double> curveDb;

  /// Reference frequencies (Hz) for [curveDb].
  static const List<double> curveFreqsHz = [
    60,
    170,
    310,
    600,
    1000,
    3000,
    6000,
  ];

  static List<AudioPreset> get selectable =>
      AudioPreset.values.where((p) => p != AudioPreset.custom).toList();

  static AudioPreset fromKey(String? key) => AudioPreset.values.firstWhere(
    (p) => p.key == key,
    orElse: () => AudioPreset.normal,
  );

  /// Gain (dB) for a band centred at [hz], log-interpolated along the curve.
  double gainAt(double hz) {
    const f = curveFreqsHz;
    if (hz <= f.first) return curveDb.first;
    if (hz >= f.last) return curveDb.last;
    for (var i = 0; i < f.length - 1; i++) {
      if (hz >= f[i] && hz <= f[i + 1]) {
        final t =
            (math.log(hz) - math.log(f[i])) /
            (math.log(f[i + 1]) - math.log(f[i]));
        return curveDb[i] + (curveDb[i + 1] - curveDb[i]) * t;
      }
    }
    return 0;
  }
}

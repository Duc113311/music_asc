enum RepeatMode {
  off('off'),
  all('all'),
  one('one');

  const RepeatMode(this.key);
  final String key;

  /// Player button order: Off → All → One → Off.
  RepeatMode get next => switch (this) {
    RepeatMode.off => RepeatMode.all,
    RepeatMode.all => RepeatMode.one,
    RepeatMode.one => RepeatMode.off,
  };

  static RepeatMode fromKey(String? key) => RepeatMode.values.firstWhere(
    (m) => m.key == key,
    orElse: () => RepeatMode.off,
  );
}

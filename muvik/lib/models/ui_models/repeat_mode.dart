enum RepeatMode {
  off('off'),
  all('all'),
  one('one');

  const RepeatMode(this.key);
  final String key;

  static RepeatMode fromKey(String? key) => RepeatMode.values.firstWhere(
    (m) => m.key == key,
    orElse: () => RepeatMode.off,
  );
}

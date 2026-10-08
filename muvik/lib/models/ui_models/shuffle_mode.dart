enum ShuffleMode {
  off('off'),
  on('on');

  const ShuffleMode(this.key);
  final String key;

  bool get enabled => this == ShuffleMode.on;

  static ShuffleMode fromKey(String? key) => ShuffleMode.values.firstWhere(
    (m) => m.key == key,
    orElse: () => ShuffleMode.off,
  );
}

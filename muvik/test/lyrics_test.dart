import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/models/data_models/lyrics.dart';

void main() {
  test('parses LRC with stamps, multi-stamp lines and meta tags', () {
    final l = Lyrics.parse(
      '[ti:Song]\n[00:12.50]Hello\n[00:05.00][00:30.5]Chorus\n[01:02]End',
    )!;
    expect(l.synced, isTrue);
    expect(l.lines.map((e) => e.text), ['Chorus', 'Hello', 'Chorus', 'End']);
    expect(l.lines.first.time, const Duration(seconds: 5));
    expect(l.lines[2].time, const Duration(seconds: 30, milliseconds: 500));
    expect(l.indexAt(const Duration(seconds: 4)), -1);
    expect(l.indexAt(const Duration(seconds: 13)), 1);
    expect(l.indexAt(const Duration(minutes: 5)), 3);
  });

  test('plain lyrics keep their lines and are not synced', () {
    final l = Lyrics.parse('one\n\ntwo\r\nthree')!;
    expect(l.synced, isFalse);
    expect(l.lines.map((e) => e.text), ['one', 'two', 'three']);
    expect(Lyrics.parse('   '), isNull);
    expect(Lyrics.parse(null), isNull);
  });
}

import 'dart:ui';

import 'package:dsp_base/convenience_imports.dart' show PrefAssist;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:muvik/models/data_models/song.dart';
import 'package:muvik/models/ui_models/audio_preset.dart';
import 'package:muvik/models/ui_models/library_groups.dart';
import 'package:muvik/presentation/screen_dashboard/dashboard_tab.dart';
import 'package:muvik/repository/listening_repository.dart';
import 'package:muvik/services/application/statistics_service.dart';
import 'package:muvik/utils/app_localize.dart';
import 'package:muvik/utils/date_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

Song song(
  int id,
  String title, {
  String? artist,
  String? album,
  int ms = 1000,
  String folder = 'Music',
}) {
  final t = DateTime(2026, 1, id);
  return Song(
    id: id,
    sourceId: 1,
    identity: 'v/$folder/$title.mp3',
    uri: 'u$id',
    title: title,
    artist: artist,
    album: album,
    durationMs: ms,
    folderPath: folder,
    fileName: '$title.mp3',
    firstSeenAt: t,
    updatedAt: t,
  );
}

void main() {
  test('greeting follows the hour ranges of spec §4.2', () {
    expect(greetingKey(5), 'greeting_morning');
    expect(greetingKey(10), 'greeting_morning');
    expect(greetingKey(11), 'greeting_noon');
    expect(greetingKey(13), 'greeting_noon');
    expect(greetingKey(14), 'greeting_afternoon');
    expect(greetingKey(17), 'greeting_afternoon');
    expect(greetingKey(18), 'greeting_evening');
    expect(greetingKey(4), 'greeting_evening');
  });

  test('XML strings load through dsp_base CommLocalize', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await PrefAssist.init();
    final locale = await AppLocalize.ensureConfigured();
    expect(AppLocalize.translatedLocales, contains(locale));
    await AppLocalize.loadTranslations();
    final en = Get.translations['en_US'];
    if (en != null) {
      expect(en['count_songs_n'], '@args1 songs');
      expect(en['dlg_delete_playlist_msg'], startsWith('Playlist "@args1"'));
    }
    final current = Get.translations[locale.toString()]!;
    expect(current['count_songs_n'], contains('@args1'));
  });

  test('locale resolution falls back to English', () {
    expect(AppLocalize.resolve(const Locale('vi')).languageCode, 'vi');
    expect(AppLocalize.resolve(const Locale('ja')).languageCode, 'en');
    expect(AppLocalize.resolve(null), AppLocalize.fallbackLocale);
  });

  test('EQ preset curve interpolates onto device bands', () {
    expect(AudioPreset.bass.gainAt(60), 8);
    expect(AudioPreset.bass.gainAt(30), 8);
    final mid = AudioPreset.bass.gainAt(100);
    expect(mid, inInclusiveRange(6, 8));
    expect(AudioPreset.normal.gainAt(14000), 0);
  });

  test('sorting is stable with title/id tie-breaks', () {
    final list = [song(2, 'b'), song(1, 'B'), song(3, 'a')]
      ..sort(SongSort.titleAsc.compare);
    expect(list.map((s) => s.id), [3, 1, 2]);
    final byDur = [song(1, 'x', ms: 5), song(2, 'y', ms: 1)]
      ..sort(SongSort.duration.compare);
    expect(byDur.first.id, 2);
  });

  test('unknown artists are grouped once, never as a fake artist', () {
    final groups = LibraryGrouping.artists([
      song(1, 'a'),
      song(2, 'b', artist: '<unknown>'),
      song(3, 'c', artist: 'Sơn Tùng'),
      song(4, 'd', artist: 'son tung'),
    ]);
    expect(groups.length, 2);
    expect(groups.last.isUnknown, isTrue);
    expect(groups.last.songs.length, 2);
    expect(groups.first.songs.length, 2);
  });

  test('top songs tie-break: plays, then listened time, then title', () {
    final songs = {1: song(1, 'Zeta'), 2: song(2, 'Alpha'), 3: song(3, 'Beta')};
    final ranked = StatisticsService.rankSongs(const [
      SongPlayStat(1, 3, 100),
      SongPlayStat(2, 3, 100),
      SongPlayStat(3, 3, 500),
    ], songs);
    expect(ranked.map((r) => r.song.id), [3, 2, 1]);
  });

  test('artists: unknown tags merge into one group', () {
    final r = StatisticsService.mergeArtists(const [
      ArtistStat(null, 1000, 1),
      ArtistStat('<unknown>', 2000, 1),
      ArtistStat('A', 500, 1),
    ]);
    expect(r.first.artist, isNull);
    expect(r.first.listenedMs, 3000);
  });

  test('date keys and leap years', () {
    expect(AppDateUtils.formatDateKey(DateTime(2026, 3, 4)), '2026-03-04');
    expect(AppDateUtils.isLeapYear(2028), isTrue);
    expect(AppDateUtils.isLeapYear(2100), isFalse);
    expect(AppDateUtils.daysInMonth(2028, 2), 29);
  });
}

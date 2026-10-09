import 'dart:math';

import 'package:get/get.dart';

import '../configs/pref_const.dart';
import '../configs/pref_defaults.dart';
import '../models/data_models/music_source.dart';
import '../models/data_models/playlist.dart';
import '../models/data_models/song.dart';
import '../models/ui_models/library_groups.dart';
import '../models/ui_models/scan_state.dart';
import '../repository/listening_repository.dart';
import '../services/application/audio_handler.dart';
import '../services/application/library_data_service.dart';
import '../services/application/library_scan_service.dart';
import '../services/application/listening_stats_service.dart';
import '../services/application/playlist_service.dart';
import '../services/application/song_identity.dart';
import '../services/storage/pref_store.dart';
import '../utils/mood_rules.dart';
import '../utils/toast_utils.dart';

/// Library-wide state for every screen: songs, groups, playlists, history,
/// scan/permission. Re-derives when the underlying services change, so
/// favorites/exclusions/playlist edits show up everywhere at once.
class LibraryController extends GetxController {
  static LibraryController get to => Get.find();

  final LibraryDataService _library = Get.find();
  final LibraryScanService scanService = Get.find();
  final PlaylistService _playlists = Get.find();
  final ListeningStatsService _stats = Get.find();
  final MuvikAudioHandler _handler = Get.find();
  final ListeningRepository _history = ListeningRepository();

  final RxList<Song> songs = <Song>[].obs;
  final Rx<SongSort> sort = SongSort.titleAsc.obs;
  final RxList<SongGroup> albums = <SongGroup>[].obs;
  final RxList<SongGroup> artists = <SongGroup>[].obs;
  final RxList<SongGroup> folders = <SongGroup>[].obs;
  final RxList<Song> favorites = <Song>[].obs;
  final RxList<Playlist> playlists = <Playlist>[].obs;
  final RxList<Song> recent = <Song>[].obs;
  final RxMap<int, int> playCounts = <int, int>{}.obs;
  final RxBool hasHistory = false.obs;
  final RxBool loading = true.obs;

  final Rx<ScanState> scan = const ScanState().obs;
  final Rx<AudioPermissionStatus> permission = AudioPermissionStatus.denied.obs;
  final RxList<MusicSource> sources = <MusicSource>[].obs;

  /// Random seed for "Phát ngẫu nhiên" so the card is stable until refresh.
  int shuffleSeed = Random().nextInt(1 << 30);

  @override
  void onInit() {
    super.onInit();
    sort.value = SongSort.fromKey(
      PrefStore.getString(PrefConst.songSort, PrefDefaults.songSort),
    );
    _library.revision.addListener(_onLibraryChanged);
    _playlists.revision.addListener(loadPlaylists);
    _stats.revision.addListener(loadHistory);
    scanService.state.addListener(_onScan);
    scanService.permission.addListener(_onPermission);
    scanService.sources.addListener(_onSources);
    _onScan();
    _onPermission();
    _onSources();
    _rebuild();
    loadPlaylists();
    loadHistory();
  }

  @override
  void onClose() {
    _library.revision.removeListener(_onLibraryChanged);
    _playlists.revision.removeListener(loadPlaylists);
    _stats.revision.removeListener(loadHistory);
    scanService.state.removeListener(_onScan);
    scanService.permission.removeListener(_onPermission);
    scanService.sources.removeListener(_onSources);
    super.onClose();
  }

  void _onScan() => scan.value = scanService.state.value;
  void _onPermission() => permission.value = scanService.permission.value;
  void _onSources() => sources.assignAll(scanService.sources.value);

  void _onLibraryChanged() {
    _rebuild();
    loadPlaylists();
    loadHistory();
    _handler.refreshCurrentSong();
  }

  void _rebuild() {
    final all = _library.visibleSongs..sort(sort.value.compare);
    songs.assignAll(all);
    albums.assignAll(LibraryGrouping.albums(all));
    artists.assignAll(LibraryGrouping.artists(all));
    folders.assignAll(LibraryGrouping.folders(all));
    favorites.assignAll(
      all.where((s) => s.favorite).toList()..sort(
        (a, b) => (b.favoriteAt ?? DateTime(0)).compareTo(
          a.favoriteAt ?? DateTime(0),
        ),
      ),
    );
    loading.value = false;
  }

  Future<void> loadPlaylists() async {
    playlists.assignAll(await _playlists.getAll());
  }

  /// Ordered songs of a playlist; id -1 is the system Favorites list.
  Future<List<Song>> playlistSongs(int playlistId) async =>
      playlistId < 0 ? favorites.toList() : _playlists.getSongs(playlistId);

  Future<void> loadHistory() async {
    final ids = await _history.recentSongIds(limit: 50);
    final map = await _library.resolve(ids);
    recent.assignAll([
      for (final id in ids)
        if (map[id] != null && !map[id]!.hidden) map[id]!,
    ]);
    playCounts.assignAll(await _history.allTimePlayCounts());
    hasHistory.value = ids.isNotEmpty;
  }

  bool get isEmpty => songs.isEmpty;
  bool get hasPermission => permission.value == AudioPermissionStatus.granted;
  int get availableCount => songs.where((s) => s.available).length;

  Future<void> setSort(SongSort s) async {
    sort.value = s;
    await PrefStore.setString(PrefConst.songSort, s.key);
    _rebuild();
  }

  Song? songById(int id) => _library.cached(id);

  SongGroup? group(GroupKind kind, String key) {
    final list = switch (kind) {
      GroupKind.album => albums,
      GroupKind.artist => artists,
      GroupKind.folder => folders,
    };
    return list.firstWhereOrNull((g) => g.key == key);
  }

  /// Songs listened most (all time), for "Nghe lại".
  List<Song> mostPlayed({int limit = 50}) {
    final list = songs.where((s) => (playCounts[s.id] ?? 0) > 0).toList()
      ..sort(
        (a, b) => (playCounts[b.id] ?? 0).compareTo(playCounts[a.id] ?? 0),
      );
    return list.take(limit).toList();
  }

  /// Available songs with the fewest plays, for "Bài hát ít nghe".
  List<Song> leastPlayed({int limit = 50}) {
    final list = songs.where((s) => s.available).toList()
      ..sort((a, b) {
        final c = (playCounts[a.id] ?? 0).compareTo(playCounts[b.id] ?? 0);
        return c != 0 ? c : SongSort.titleAsc.compare(a, b);
      });
    return list.take(limit).toList();
  }

  List<Song> randomMix({int limit = 50}) {
    final list = songs.where((s) => s.available).toList()
      ..shuffle(Random(shuffleSeed));
    return list.take(limit).toList();
  }

  /// Ordered by first discovery, so rescans don't make everything "new"
  /// (P11-05).
  /// Songs whose genre tag matches [mood] (rules in mood_rules.dart).
  List<Song> songsByMood(Mood mood) =>
      songs.where((s) => s.available && mood.matches(s)).toList()
        ..sort(SongSort.titleAsc.compare);

  List<Song> recentlyAdded({int limit = 50}) {
    final list = [...songs]..sort(SongSort.recentlyAdded.compare);
    return list.take(limit).toList();
  }

  // ---------------- actions ----------------

  Future<void> toggleFavorite(Song song) async {
    final updated = await _library.setFavorite(song.id!, !song.favorite);
    if (updated == null) return;
    ToastUtils.success(
      updated.favorite
          ? 'toast_favorite_added'.tr
          : 'toast_favorite_removed'.tr,
    );
  }

  Future<void> excludeSong(Song song) async {
    await _library.excludeSong(song);
    await _handler.onSongRemoved(song.id!);
    ToastUtils.success('toast_removed_from_library'.tr);
  }

  Future<void> excludeFolder(SongGroup folder) async {
    final ids = folder.songs.map((s) => s.id!).toList();
    final prefix = SongIdentity.folderOf(folder.songs.first.identity);
    await _library.excludeFolder(prefix);
    for (final id in ids) {
      await _handler.onSongRemoved(id);
    }
    ToastUtils.success('toast_removed_from_library'.tr);
  }

  Future<ScanState> startScan({Set<int>? onlySourceIds}) =>
      scanService.scan(onlySourceIds: onlySourceIds);
}

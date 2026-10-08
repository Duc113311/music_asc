import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../configs/app_config.dart';
import '../configs/pref_const.dart';
import '../configs/pref_defaults.dart';
import '../models/data_models/playlist.dart';
import '../models/data_models/song.dart';
import '../models/ui_models/library_groups.dart';
import '../services/storage/pref_store.dart';
import '../utils/metadata_fallback.dart';
import 'library_controller.dart';

class SearchResults {
  const SearchResults({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.folders = const [],
    this.playlists = const [],
  });

  final List<Song> songs;
  final List<SongGroup> albums;
  final List<SongGroup> artists;
  final List<SongGroup> folders;
  final List<Playlist> playlists;

  bool get isEmpty =>
      songs.isEmpty &&
      albums.isEmpty &&
      artists.isEmpty &&
      folders.isEmpty &&
      playlists.isEmpty;
}

/// Route-scoped local search (P09-07..P09-09): debounced, case- and
/// Vietnamese-diacritic-insensitive; a newer query always wins.
class MusicSearchController extends GetxController {
  final TextEditingController text = TextEditingController();
  final FocusNode focus = FocusNode();
  final RxString query = ''.obs;
  final RxBool searching = false.obs;
  final Rx<SearchResults> results = const SearchResults().obs;
  final RxList<String> history = <String>[].obs;

  Timer? _debounce;
  int _token = 0;

  @override
  void onInit() {
    super.onInit();
    history.assignAll(
      PrefStore.getStringList(
        PrefConst.searchHistory,
        PrefDefaults.searchHistory,
      ),
    );
  }

  @override
  void onClose() {
    _debounce?.cancel();
    text.dispose();
    focus.dispose();
    super.onClose();
  }

  void onChanged(String v) {
    query.value = v;
    _debounce?.cancel();
    if (v.trim().isEmpty) {
      _token++;
      searching.value = false;
      results.value = const SearchResults();
      return;
    }
    searching.value = true;
    _debounce = Timer(AppConfig.searchDebounce, () => _run(v));
  }

  void useHistory(String q) {
    text.text = q;
    text.selection = TextSelection.collapsed(offset: q.length);
    onChanged(q);
  }

  Future<void> _run(String raw) async {
    final token = ++_token;
    final q = MetadataFallback.normalize(raw);
    final r = await Future(() => search(q, LibraryController.to));
    if (token != _token) return; // stale result
    results.value = r;
    searching.value = false;
  }

  /// Pure search over the in-memory library.
  static SearchResults search(String q, LibraryController lib) {
    bool hit(String? v) =>
        v != null && MetadataFallback.normalize(v).contains(q);
    final songs = lib.songs
        .where(
          (s) =>
              hit(s.displayTitle) ||
              hit(s.artist) ||
              hit(s.album) ||
              hit(s.fileName) ||
              hit(s.folderName),
        )
        .take(100)
        .toList();
    return SearchResults(
      songs: songs,
      albums: lib.albums.where((g) => hit(g.title)).take(20).toList(),
      artists: lib.artists.where((g) => hit(g.title)).take(20).toList(),
      folders: lib.folders
          .where((g) => hit(g.title) || hit(g.subtitle))
          .take(20)
          .toList(),
      playlists: lib.playlists.where((p) => hit(p.name)).take(20).toList(),
    );
  }

  Future<void> remember() async {
    final q = query.value.trim();
    if (q.isEmpty) return;
    history
      ..remove(q)
      ..insert(0, q);
    if (history.length > AppConfig.searchHistoryMax) history.removeLast();
    await PrefStore.setStringList(PrefConst.searchHistory, history.toList());
  }

  /// Clears search history only — never music (spec §4.5).
  Future<void> clearHistory() async {
    history.clear();
    await PrefStore.setStringList(PrefConst.searchHistory, const []);
  }

  void clear() {
    text.clear();
    onChanged('');
    focus.requestFocus();
  }
}

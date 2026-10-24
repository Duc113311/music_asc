import 'package:get/get.dart';

import '../models/data_models/playlist.dart';
import '../models/data_models/song.dart';
import '../services/application/library_data_service.dart';
import '../services/application/playlist_service.dart';
import '../utils/toast_utils.dart';
import 'library_controller.dart';

/// Playlist detail + in-place edit (reorder/remove) with an explicit save;
/// leaving with unsaved edits asks to discard (P10-04, P10-05).
/// Id -1 is the system Favorites list (no rename/delete).
class PlaylistDetailController extends GetxController {
  final PlaylistService _service = Get.find();
  final LibraryDataService _library = Get.find();

  late final int playlistId;
  final Rxn<Playlist> playlist = Rxn<Playlist>();
  final RxList<Song> songs = <Song>[].obs;
  final RxBool loading = true.obs;
  final RxBool missing = false.obs;

  final RxBool editing = false.obs;
  final RxList<Song> draft = <Song>[].obs;

  bool get isFavorites => playlistId < 0;
  bool get dirty =>
      editing.value &&
      (draft.length != songs.length ||
          [
            for (var i = 0; i < draft.length; i++) draft[i].id != songs[i].id,
          ].any((d) => d));

  @override
  void onInit() {
    super.onInit();
    playlistId = (Get.arguments as int?) ?? -1;
    _service.revision.addListener(load);
    _library.revision.addListener(load);
    load();
  }

  @override
  void onClose() {
    _service.revision.removeListener(load);
    _library.revision.removeListener(load);
    super.onClose();
  }

  Future<void> load() async {
    if (editing.value) return;
    if (isFavorites) {
      final fav = LibraryController.to.favorites.toList();
      songs.assignAll(fav);
      loading.value = false;
      return;
    }
    final p = await _service.getById(playlistId);
    if (p == null) {
      missing.value = true;
      loading.value = false;
      return;
    }
    playlist.value = p;
    songs.assignAll(await _service.getSongs(playlistId));
    loading.value = false;
  }

  int get totalMs => songs.fold(0, (a, s) => a + s.durationMs);

  void startEdit() {
    draft.assignAll(songs);
    editing.value = true;
  }

  void cancelEdit() {
    editing.value = false;
    draft.clear();
    load();
  }

  /// [to] is already the final index (ReorderableListView.onReorderItem).
  void reorder(int from, int to) {
    final s = draft.removeAt(from);
    draft.insert(to, s);
  }

  void removeFromDraft(Song s) => draft.remove(s);

  Future<void> saveEdit() async {
    if (isFavorites) {
      // Favorites order is by time favorited; removal = unfavorite.
      final keep = draft.map((s) => s.id).toSet();
      for (final s in songs.where((s) => !keep.contains(s.id))) {
        await _library.setFavorite(s.id!, false);
      }
    } else {
      await _service.saveEdits(
        playlist.value!,
        orderedSongIds: draft.map((s) => s.id!).toList(),
      );
    }
    editing.value = false;
    draft.clear();
    await load();
    ToastUtils.success('toast_saved'.tr);
  }

  Future<void> addSongs(List<int> ids) async {
    if (isFavorites) {
      for (final id in ids) {
        await _library.setFavorite(id, true);
      }
      return;
    }
    final r = await _service.addSongs(playlistId, ids);
    if (r.added > 0) {
      ToastUtils.success('toast_added_playlist'.tr);
    } else if (r.duplicates > 0) {
      ToastUtils.show('toast_no_new_songs'.tr, type: ToastType.warning);
    }
  }
}

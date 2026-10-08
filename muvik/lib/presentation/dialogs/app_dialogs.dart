import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../controller/playback_controller.dart';
import '../../models/data_models/playlist.dart';
import '../../models/data_models/song.dart';
import '../../models/ui_models/library_groups.dart';
import '../../services/application/equalizer_service.dart';
import '../../services/application/playlist_service.dart';
import '../../utils/toast_utils.dart';
import '../common_components/primary_dialog.dart';

/// Named confirmation dialogs from spec §9.1 (Figma keys in comments).

/// Sc_delete_danh_sach_cho — clears upcoming entries, keeps the current song.
Future<void> confirmClearQueue() async {
  await showConfirmDialog(
    icon: Icons.delete_sweep_rounded,
    title: 'dlg_clear_queue_title'.tr,
    message: 'dlg_clear_queue_msg'.tr,
    confirmLabel: 'dlg_clear_queue_confirm'.tr,
    onConfirm: () async {
      final n = await PlaybackController.to.handler.clearUpcoming();
      if (n > 0) ToastUtils.success('toast_queue_cleared'.tr);
    },
  );
}

/// Sc_dung_phat_nhac — only from the explicit "Dừng phát" menu item.
Future<void> confirmStopPlayback() async {
  await showConfirmDialog(
    icon: Icons.stop_circle_rounded,
    title: 'dlg_stop_title'.tr,
    message: 'dlg_stop_msg'.tr,
    confirmLabel: 'dlg_stop_confirm'.tr,
    destructive: true,
    onConfirm: PlaybackController.to.stop,
  );
}

/// Sc_bo_khoi_thu_vien — hides the song in Muvik, the file stays.
Future<void> confirmRemoveFromLibrary(Song song) async {
  await showConfirmDialog(
    icon: Icons.visibility_off_rounded,
    title: 'dlg_remove_library_title'.tr,
    message: 'dlg_remove_library_msg'.trParams({'args1': song.displayTitle}),
    confirmLabel: 'dlg_remove_library_confirm'.tr,
    destructive: true,
    onConfirm: () => LibraryController.to.excludeSong(song),
  );
}

Future<void> confirmRemoveFolderFromLibrary(SongGroup folder) async {
  await showConfirmDialog(
    icon: Icons.folder_off_rounded,
    title: 'dlg_remove_folder_title'.tr,
    message: 'dlg_remove_folder_msg'.trParams({'args1': folder.title ?? ''}),
    confirmLabel: 'dlg_remove_library_confirm'.tr,
    destructive: true,
    onConfirm: () => LibraryController.to.excludeFolder(folder),
  );
}

/// Sc_dat_lai_bo_chinh_am.
Future<void> confirmResetEqualizer() async {
  await showConfirmDialog(
    icon: Icons.restart_alt_rounded,
    title: 'dlg_reset_eq_title'.tr,
    message: 'dlg_reset_eq_msg'.tr,
    confirmLabel: 'dlg_reset_eq_confirm'.tr,
    onConfirm: Get.find<EqualizerService>().reset,
  );
}

/// Delete a user playlist; files and the current queue are untouched.
Future<bool> confirmDeletePlaylist(Playlist p) => showConfirmDialog(
  icon: Icons.delete_rounded,
  title: 'dlg_delete_playlist_title'.tr,
  message: 'dlg_delete_playlist_msg'.trParams({'args1': p.name}),
  confirmLabel: 'dlg_delete_playlist_confirm'.tr,
  destructive: true,
  onConfirm: () async {
    await Get.find<PlaylistService>().delete(p.id!);
    ToastUtils.success('toast_playlist_deleted'.tr);
  },
);

/// "Bỏ thay đổi / Tiếp tục sửa" — true means discard.
Future<bool> confirmDiscardChanges() => showConfirmDialog(
  icon: Icons.edit_off_rounded,
  title: 'dlg_discard_title'.tr,
  message: 'dlg_discard_msg'.tr,
  confirmLabel: 'dlg_discard_confirm'.tr,
  cancelLabel: 'dlg_keep_editing'.tr,
  destructive: true,
);

/// Sign out keeps all local data.
Future<bool> confirmLogout(Future<void> Function() signOut) =>
    showConfirmDialog(
      icon: Icons.logout_rounded,
      title: 'dlg_logout_title'.tr,
      message: 'dlg_logout_msg'.tr,
      confirmLabel: 'dlg_logout_confirm'.tr,
      onConfirm: signOut,
    );

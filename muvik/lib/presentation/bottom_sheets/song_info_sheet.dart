import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/data_models/song.dart';
import '../../services/native/media_library_channel.dart';
import '../../utils/duration_formatter.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/primary_bottom_sheet.dart';

/// "Thông tin file": read-only metadata and format of the local file.
Future<void> showSongInfo(Song song) {
  return showAppSheet<void>(
    builder: (context) {
      return SheetScaffold(
        title: 'action_file_info'.tr,
        child: FutureBuilder<AudioFormatInfo?>(
          future: song.available
              ? MediaLibraryChannel.getAudioFormat(song.uri)
              : null,
          builder: (context, snap) {
            final f = snap.data;
            final unknown = 'unknown_value'.tr;
            final rows = <(String, String)>[
              ('info_title'.tr, song.displayTitle),
              ('info_artist'.tr, song.artistOrNull ?? 'unknown_artist'.tr),
              ('info_album'.tr, song.albumOrNull ?? 'unknown_album'.tr),
              (
                'info_duration'.tr,
                song.durationMs > 0
                    ? DurationFormatter.clockMs(song.durationMs)
                    : unknown,
              ),
              (
                'info_size'.tr,
                song.sizeBytes > 0
                    ? DurationFormatter.fileSize(song.sizeBytes)
                    : unknown,
              ),
              ('info_format'.tr, f?.mimeType ?? song.mimeType ?? unknown),
              (
                'info_bitrate'.tr,
                f?.bitrate != null
                    ? '${(f!.bitrate! / 1000).round()} kbps'
                    : unknown,
              ),
              (
                'info_sample_rate'.tr,
                f?.sampleRate != null ? '${f!.sampleRate} Hz' : unknown,
              ),
              ('info_folder'.tr, song.folderPath),
              ('info_file'.tr, song.fileName),
              (
                'info_status'.tr,
                song.available ? 'status_available'.tr : 'song_unavailable'.tr,
              ),
            ];
            return InfoTable(rows: rows);
          },
        ),
      );
    },
  );
}

class InfoTable extends StatelessWidget {
  const InfoTable({super.key, required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    r.$1,
                    style: AppTypography.bodyM.copyWith(color: c.textMuted),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    r.$2,
                    style: AppTypography.bodyM.copyWith(color: c.textPrimary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

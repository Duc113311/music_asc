import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/playback_controller.dart';
import '../../models/data_models/song.dart';
import '../../services/native/media_library_channel.dart';
import '../../utils/duration_formatter.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../bottom_sheets/song_info_sheet.dart';
import '../common_components/cards.dart';
import '../common_components/song_artwork.dart';
import '../common_components/state_views.dart';

/// sc_chat_luong_phat: read-only properties of the current file. "Gốc" means
/// the file is played as-is; no fake 128/320 kbps options (P14-10).
class PlaybackQualityScreen extends StatelessWidget {
  const PlaybackQualityScreen({super.key});

  String _format(String? mime, String fileName) {
    final ext =
        fileName.contains('.') ? fileName.split('.').last.toUpperCase() : null;
    if (mime == null) return ext ?? 'unknown_value'.tr;
    final sub = mime.split('/').last.toUpperCase().replaceAll('MPEG', 'MP3');
    return ext != null && ext != sub ? '$sub ($ext)' : sub;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pc = PlaybackController.to;
    return Scaffold(
      appBar: DetailAppBar(title: 'settings_quality'.tr),
      body: SafeArea(
        child: Obx(() {
          final Song? song = pc.currentSong;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            children: [
              AppCard(
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded, color: c.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'quality_original'.tr,
                            style: AppTypography.headingS.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            'quality_original_desc'.tr,
                            style: AppTypography.bodyM.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (song == null)
                EmptyState(
                  icon: Icons.music_note_rounded,
                  title: 'quality_no_song'.tr,
                  message: 'quality_no_song_desc'.tr,
                )
              else
                AppCard(
                  child: FutureBuilder<AudioFormatInfo?>(
                    future: song.available
                        ? MediaLibraryChannel.getAudioFormat(song.uri)
                        : null,
                    builder: (context, snap) {
                      final f = snap.data;
                      final unknown = 'unknown_value'.tr;
                      // Average bitrate from size/duration when the codec doesn't report it.
                      final bitrate = f?.bitrate ??
                          (song.sizeBytes > 0 && song.durationMs > 0
                              ? (song.sizeBytes * 8 * 1000 / song.durationMs)
                                  .round()
                              : null);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SongArtwork(song: song, size: 56),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  song.displayTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.songTitle.copyWith(
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (snap.connectionState == ConnectionState.waiting)
                            const LinearProgressIndicator()
                          else
                            InfoTable(
                              rows: [
                                (
                                  'info_format'.tr,
                                  _format(
                                    f?.mimeType ?? song.mimeType,
                                    song.fileName,
                                  ),
                                ),
                                (
                                  'info_bitrate'.tr,
                                  bitrate == null
                                      ? unknown
                                      : '${(bitrate / 1000).round()} kbps',
                                ),
                                (
                                  'info_sample_rate'.tr,
                                  f?.sampleRate == null
                                      ? unknown
                                      : '${(f!.sampleRate! / 1000).toStringAsFixed(1)} kHz',
                                ),
                                (
                                  'info_channels'.tr,
                                  f?.channels == null
                                      ? unknown
                                      : (f!.channels == 1
                                          ? 'channels_mono'.tr
                                          : (f.channels == 2
                                              ? 'channels_stereo'.tr
                                              : '${f.channels}')),
                                ),
                                (
                                  'info_size'.tr,
                                  song.sizeBytes > 0
                                      ? DurationFormatter.fileSize(
                                          song.sizeBytes,
                                        )
                                      : unknown,
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

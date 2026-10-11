import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/app_config.dart';
import '../../controller/library_controller.dart';
import '../../models/data_models/playlist.dart';
import '../../models/data_models/song.dart';
import '../../models/ui_models/app_error.dart';
import '../../services/application/playlist_service.dart';
import '../../utils/toast_utils.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../../values/route_name.dart';
import '../common_components/app_inputs.dart';
import '../common_components/cards.dart';
import '../common_components/primary_bottom_sheet.dart';
import '../common_components/primary_button.dart';
import '../common_components/song_artwork.dart';
import '../dialogs/app_dialogs.dart';

class PlaylistFormArgs {
  const PlaylistFormArgs({this.editing, this.addSongIds = const []});

  /// Null → create.
  final Playlist? editing;

  /// Songs added to the new playlist right after creation.
  final List<int> addSongIds;
}

/// Create / edit playlist (P10-01, P10-02, P10-05). Name is trimmed,
/// required and limited to 80 chars; cover is a song artwork or the fallback.
class PlaylistFormScreen extends StatefulWidget {
  const PlaylistFormScreen({super.key});

  @override
  State<PlaylistFormScreen> createState() => _PlaylistFormScreenState();
}

class _PlaylistFormScreenState extends State<PlaylistFormScreen> {
  late final PlaylistFormArgs args =
      (Get.arguments as PlaylistFormArgs?) ?? const PlaylistFormArgs();
  late final _name = TextEditingController(text: args.editing?.name ?? '');
  late final _desc = TextEditingController(
    text: args.editing?.description ?? '',
  );
  late String? _coverUri = args.editing?.coverUri;
  String? _error;
  List<Song> _songs = const [];

  bool get _isEdit => args.editing != null;

  bool get _dirty =>
      _name.text.trim() != (args.editing?.name ?? '') ||
      _desc.text.trim() != (args.editing?.description ?? '') ||
      _coverUri != args.editing?.coverUri;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final lib = LibraryController.to;
    final list = _isEdit
        ? await lib.playlistSongs(args.editing!.id!)
        : [for (final id in args.addSongIds) ?lib.songById(id)];
    if (mounted) setState(() => _songs = list);
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final service = Get.find<PlaylistService>();
    try {
      PlaylistService.validateName(_name.text);
    } on AppError catch (e) {
      setState(() => _error = (e.detail ?? 'error_validation').tr);
      return;
    }
    if (_isEdit) {
      await service.saveEdits(
        args.editing!.copyWith(
          name: _name.text,
          description: _desc.text.trim(),
          coverUri: _coverUri,
          clearCover: _coverUri == null,
        ),
      );
      Get.back<void>();
      ToastUtils.success('toast_saved'.tr);
      return;
    }
    final id = await service.create(
      name: _name.text,
      description: _desc.text,
      coverUri: _coverUri,
      songIds: args.addSongIds,
    );
    if (args.addSongIds.isNotEmpty) {
      Get.back<void>();
      ToastUtils.success('toast_added_playlist'.tr);
    } else {
      Get.offNamed(RouteName.playlistDetail, arguments: id);
      ToastUtils.success('toast_playlist_created'.tr);
    }
  }

  Future<void> _back() async {
    if (_dirty && !(await confirmDiscardChanges())) return;
    Get.back<void>();
  }

  Future<void> _pickCover() async {
    if (_songs.isEmpty) return;
    final uri = await showAppSheet<String>(
      builder: (context) {
        final c = context.colors;
        return SheetScaffold(
          title: 'playlist_cover'.tr,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              Semantics(
                button: true,
                selected: _coverUri == null,
                label: 'playlist_cover_default'.tr,
                child: InkWell(
                  onTap: () => Get.back(result: ''),
                  child: const ArtworkPlaceholder(
                    size: 88,
                    icon: Icons.queue_music_rounded,
                  ),
                ),
              ),
              for (final s in _songs.take(30))
                Semantics(
                  button: true,
                  selected: s.uri == _coverUri,
                  label: s.displayTitle,
                  child: InkWell(
                    onTap: () => Get.back(result: s.uri),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: s.uri == _coverUri
                              ? c.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SongArtwork(song: s, size: 84),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
    if (uri != null) setState(() => _coverUri = uri.isEmpty ? null : uri);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cover = _coverUri == null
        ? null
        : _songs.firstWhereOrNull((s) => s.uri == _coverUri);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: DetailAppBar(
          title: _isEdit ? 'playlist_edit'.tr : 'playlist_create'.tr,
          onBack: _back,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            children: [
              Center(
                child: Semantics(
                  button: true,
                  label: 'playlist_cover'.tr,
                  child: InkWell(
                    onTap: _songs.isEmpty ? null : _pickCover,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    child: Stack(
                      children: [
                        cover == null
                            ? const ArtworkPlaceholder(
                                size: 120,
                                icon: Icons.queue_music_rounded,
                              )
                            : SongArtwork(
                                song: cover,
                                size: 120,
                                radius: AppRadius.input,
                              ),
                        if (_songs.isNotEmpty)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: c.surfaceElevated,
                              child: Icon(
                                Icons.edit_rounded,
                                size: 18,
                                color: c.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_songs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'playlist_cover_hint'.tr,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(color: c.textMuted),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: _name,
                label: 'playlist_name'.tr,
                hint: 'playlist_name_hint'.tr,
                maxLength: AppConfig.playlistNameMaxLength,
                error: _error,
                autofocus: !_isEdit,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextArea(
                controller: _desc,
                label: 'playlist_description'.tr,
                hint: 'playlist_description_hint'.tr,
                maxLength: AppConfig.playlistDescriptionMaxLength,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.phone_android_rounded,
                    size: 18,
                    color: c.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'playlist_local_note'.tr,
                      style: AppTypography.caption.copyWith(color: c.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'action_cancel'.tr,
                      variant: ButtonVariant.secondary,
                      onPressed: _back,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: _isEdit
                          ? 'action_save'.tr
                          : 'playlist_create_cta'.tr,
                      height: AppSizes.buttonSecondary,
                      onPressed: _name.text.trim().isEmpty ? null : _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

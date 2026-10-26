import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../configs/app_config.dart';
import '../../models/data_models/song.dart';
import '../../services/native/media_library_channel.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';

/// Bounded LRU of decoded-size artwork bytes; requests are de-duplicated so a
/// fast scroll does not decode the same cover many times (P05-09, P09-10).
class ArtworkCache {
  ArtworkCache._();

  static final LinkedHashMap<String, Uint8List?> _cache = LinkedHashMap();
  static final Map<String, Future<Uint8List?>> _pending = {};

  static Future<Uint8List?> load(String uri) {
    if (_cache.containsKey(uri)) {
      final v = _cache.remove(uri);
      _cache[uri] = v;
      return Future.value(v);
    }
    return _pending[uri] ??=
        MediaLibraryChannel.getArtwork(uri, size: AppConfig.artworkSizePx)
            .then((bytes) {
              _cache[uri] = bytes;
              while (_cache.length > AppConfig.artworkCacheEntries) {
                _cache.remove(_cache.keys.first);
              }
              return bytes;
            })
            .whenComplete(() => _pending.remove(uri));
  }

  static Uint8List? peek(String uri) => _cache[uri];
}

/// Cover art with a branded fallback; errors never break the screen.
class SongArtwork extends StatefulWidget {
  const SongArtwork({
    super.key,
    required this.song,
    this.size = 56,
    this.radius = 8,
    this.iconSize,
  });

  final Song? song;
  final double size;
  final double radius;
  final double? iconSize;

  @override
  State<SongArtwork> createState() => _SongArtworkState();
}

class _SongArtworkState extends State<SongArtwork> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(SongArtwork old) {
    super.didUpdateWidget(old);
    if (old.song?.uri != widget.song?.uri) _resolve();
  }

  void _resolve() {
    final uri = widget.song?.uri;
    _future = uri == null ? null : ArtworkCache.load(uri);
  }

  @override
  Widget build(BuildContext context) {
    final cacheW = (widget.size * MediaQuery.devicePixelRatioOf(context))
        .round();
    final peek = widget.song == null
        ? null
        : ArtworkCache.peek(widget.song!.uri);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox.square(
        dimension: widget.size,
        child: peek != null
            ? _image(peek, cacheW)
            : FutureBuilder<Uint8List?>(
                future: _future,
                builder: (context, snap) {
                  final bytes = snap.data;
                  if (bytes == null) {
                    return ArtworkPlaceholder(
                      size: widget.size,
                      iconSize: widget.iconSize,
                    );
                  }
                  return _image(bytes, cacheW);
                },
              ),
      ),
    );
  }

  Widget _image(Uint8List bytes, int cacheW) => Image.memory(
    bytes,
    fit: BoxFit.cover,
    gaplessPlayback: true,
    cacheWidth: cacheW,
    errorBuilder: (_, _, _) =>
        ArtworkPlaceholder(size: widget.size, iconSize: widget.iconSize),
  );
}

class ArtworkPlaceholder extends StatelessWidget {
  const ArtworkPlaceholder({
    super.key,
    required this.size,
    this.iconSize,
    this.icon,
  });
  final double size;
  final double? iconSize;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surfaceSelected, c.primary.withValues(alpha: 0.35)],
        ),
      ),
      // A song without artwork shows the brand music note; a playlist or
      // favorites placeholder passes its own [icon].
      child: icon != null
          ? Icon(icon, color: c.primary, size: iconSize ?? size * 0.42)
          : Center(
              child: Image.asset(
                AppAssets.noteIcon,
                width: iconSize ?? size * 0.54,
                height: iconSize ?? size * 0.54,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
              ),
            ),
    );
  }
}

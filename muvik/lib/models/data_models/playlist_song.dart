/// Membership of a song in a playlist. Unique (playlist_id, song_id).
class PlaylistSong {
  const PlaylistSong({
    this.id,
    required this.playlistId,
    required this.songId,
    required this.position,
    required this.addedAt,
  });

  final int? id;
  final int playlistId;
  final int songId;
  final int position;
  final DateTime addedAt;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'playlist_id': playlistId,
    'song_id': songId,
    'position': position,
    'added_at': addedAt.toUtc().toIso8601String(),
  };

  factory PlaylistSong.fromMap(Map<String, Object?> m) => PlaylistSong(
    id: m['id'] as int?,
    playlistId: m['playlist_id'] as int,
    songId: m['song_id'] as int,
    position: m['position'] as int,
    addedAt: DateTime.parse(m['added_at'] as String).toLocal(),
  );
}

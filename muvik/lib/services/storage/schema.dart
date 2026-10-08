/// All DDL for muvik.db. Migrations are additive only — never DROP/reset a
/// released schema (P04-14).
class DbSchema {
  DbSchema._();

  static const String dbName = 'muvik.db';
  static const int dbVersion = 1;

  static const String tableSongs = 'songs';
  static const String tableSources = 'music_sources';
  static const String tablePlaylists = 'playlists';
  static const String tablePlaylistSongs = 'playlist_songs';
  static const String tableExcluded = 'excluded_items';
  static const String tableSnapshot = 'playback_snapshot';
  static const String tableQueue = 'queue_entries';
  static const String tableSessions = 'playback_sessions';
  static const String tableSegments = 'listening_segments';
  static const String tableDailySummary = 'daily_summary';

  static const List<String> createV1 = [
    '''
    CREATE TABLE $tableSources (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      type             TEXT    NOT NULL,
      uri              TEXT    NOT NULL UNIQUE,
      display_name     TEXT    NOT NULL DEFAULT '',
      removable        INTEGER NOT NULL DEFAULT 0,
      enabled          INTEGER NOT NULL DEFAULT 1,
      accessible       INTEGER NOT NULL DEFAULT 1,
      last_scan_at     TEXT,
      last_scan_status TEXT,
      song_count       INTEGER NOT NULL DEFAULT 0
    )''',
    '''
    CREATE TABLE $tableSongs (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      source_id     INTEGER NOT NULL,
      identity      TEXT    NOT NULL UNIQUE,
      uri           TEXT    NOT NULL,
      media_id      INTEGER,
      title         TEXT    NOT NULL DEFAULT '',
      artist        TEXT,
      album         TEXT,
      album_id      INTEGER,
      duration_ms   INTEGER NOT NULL DEFAULT 0,
      size_bytes    INTEGER NOT NULL DEFAULT 0,
      mime_type     TEXT,
      folder_path   TEXT    NOT NULL DEFAULT '',
      file_name     TEXT    NOT NULL DEFAULT '',
      date_added_ms INTEGER NOT NULL DEFAULT 0,
      first_seen_at TEXT    NOT NULL,
      updated_at    TEXT    NOT NULL,
      available     INTEGER NOT NULL DEFAULT 1,
      hidden        INTEGER NOT NULL DEFAULT 0,
      favorite      INTEGER NOT NULL DEFAULT 0,
      favorite_at   TEXT,
      search_key    TEXT    NOT NULL DEFAULT ''
    )''',
    'CREATE INDEX idx_songs_source ON $tableSongs (source_id)',
    'CREATE INDEX idx_songs_visible ON $tableSongs (hidden, available)',
    'CREATE INDEX idx_songs_favorite ON $tableSongs (favorite)',
    '''
    CREATE TABLE $tablePlaylists (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL,
      description TEXT    NOT NULL DEFAULT '',
      cover_uri   TEXT,
      created_at  TEXT    NOT NULL,
      updated_at  TEXT    NOT NULL
    )''',
    '''
    CREATE TABLE $tablePlaylistSongs (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      playlist_id INTEGER NOT NULL REFERENCES $tablePlaylists(id) ON DELETE CASCADE,
      song_id     INTEGER NOT NULL REFERENCES $tableSongs(id),
      position    INTEGER NOT NULL,
      added_at    TEXT    NOT NULL,
      UNIQUE (playlist_id, song_id)
    )''',
    'CREATE INDEX idx_playlist_songs_order ON $tablePlaylistSongs (playlist_id, position)',
    '''
    CREATE TABLE $tableExcluded (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      type       TEXT NOT NULL,
      identity   TEXT NOT NULL,
      created_at TEXT NOT NULL,
      UNIQUE (type, identity)
    )''',
    '''
    CREATE TABLE $tableSnapshot (
      id               INTEGER PRIMARY KEY CHECK (id = 1),
      current_entry_id TEXT,
      position_ms      INTEGER NOT NULL DEFAULT 0,
      repeat_mode      TEXT    NOT NULL DEFAULT 'off',
      shuffle_mode     TEXT    NOT NULL DEFAULT 'off',
      updated_at       TEXT    NOT NULL
    )''',
    '''
    CREATE TABLE $tableQueue (
      entry_id        TEXT    PRIMARY KEY,
      song_id         INTEGER NOT NULL,
      order_index     INTEGER NOT NULL,
      canonical_index INTEGER NOT NULL
    )''',
    '''
    CREATE TABLE $tableSessions (
      id                 INTEGER PRIMARY KEY AUTOINCREMENT,
      song_id            INTEGER NOT NULL,
      started_at         TEXT    NOT NULL,
      ended_at           TEXT,
      listened_ms        INTEGER NOT NULL DEFAULT 0,
      qualified          INTEGER NOT NULL DEFAULT 0,
      qualified_date_key TEXT,
      end_reason         TEXT
    )''',
    'CREATE INDEX idx_sessions_qualified ON $tableSessions (qualified_date_key)',
    'CREATE INDEX idx_sessions_song ON $tableSessions (song_id)',
    '''
    CREATE TABLE $tableSegments (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id    INTEGER NOT NULL REFERENCES $tableSessions(id) ON DELETE CASCADE,
      song_id       INTEGER NOT NULL,
      date_key      TEXT    NOT NULL,
      listened_ms   INTEGER NOT NULL DEFAULT 0,
      tz_offset_min INTEGER NOT NULL DEFAULT 0,
      updated_at    TEXT    NOT NULL,
      UNIQUE (session_id, date_key)
    )''',
    'CREATE INDEX idx_segments_date ON $tableSegments (date_key)',
    '''
    CREATE TABLE $tableDailySummary (
      date_key    TEXT    PRIMARY KEY,
      listened_ms INTEGER NOT NULL DEFAULT 0,
      play_count  INTEGER NOT NULL DEFAULT 0,
      updated_at  TEXT    NOT NULL
    )''',
  ];

  /// Ordered migration steps keyed by the version they upgrade *to*.
  /// Example for a future release:
  ///   2: ['ALTER TABLE songs ADD COLUMN bitrate INTEGER'],
  static const Map<int, List<String>> migrations = {};
}

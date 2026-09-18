import 'package:sound_foundry/data/local/database/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Initial schema setup: version 1.
/// Defines normalized tables for tracks, playlists, playlist_items,
/// playback_history, and key_value_store, plus initial seed data.
class V1InitialSchema implements Migration {
  @override
  int get version => 1;

  @override
  Future<void> up(Database db) async {
    // Tracks table
    await db.execute('''
      CREATE TABLE tracks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT,
        duration_ms INTEGER NOT NULL,
        media_uri TEXT NOT NULL UNIQUE,
        source_type INTEGER NOT NULL DEFAULT 0,
        artwork_uri TEXT,
        track_number INTEGER,
        disc_number INTEGER,
        year INTEGER,
        genre TEXT,
        bit_rate INTEGER,
        sample_rate INTEGER,
        file_size INTEGER NOT NULL DEFAULT 0,
        date_added INTEGER NOT NULL,
        date_modified INTEGER,
        is_favorite INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // Index for fast search and sorting
    await db.execute('CREATE INDEX idx_tracks_title ON tracks(title COLLATE NOCASE);');
    await db.execute('CREATE INDEX idx_tracks_artist ON tracks(artist COLLATE NOCASE);');
    await db.execute('CREATE INDEX idx_tracks_album ON tracks(album COLLATE NOCASE);');
    await db.execute('CREATE INDEX idx_tracks_is_favorite ON tracks(is_favorite);');
    await db.execute('CREATE INDEX idx_tracks_date_added ON tracks(date_added DESC);');

    // Playlists table
    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        artwork_uri TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_smart INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('CREATE INDEX idx_playlists_name ON playlists(name COLLATE NOCASE);');

    // Playlist Items (Join table)
    await db.execute('''
      CREATE TABLE playlist_items (
        playlist_id TEXT NOT NULL,
        track_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        added_at INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, track_id),
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
        FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('CREATE INDEX idx_playlist_items_order ON playlist_items(playlist_id, position ASC);');

    // Playback History table
    await db.execute('''
      CREATE TABLE playback_history (
        id TEXT PRIMARY KEY,
        track_id TEXT NOT NULL,
        played_at INTEGER NOT NULL,
        played_duration_ms INTEGER NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('CREATE INDEX idx_history_played_at ON playback_history(played_at DESC);');
    await db.execute('CREATE INDEX idx_history_track_id ON playback_history(track_id);');

    // Key-Value settings store table
    await db.execute('''
      CREATE TABLE key_value_store (
        key TEXT PRIMARY KEY,
        value_text TEXT,
        value_int INTEGER,
        value_real REAL,
        value_type TEXT NOT NULL
      );
    ''');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS key_value_store;');
    await db.execute('DROP TABLE IF EXISTS playback_history;');
    await db.execute('DROP TABLE IF EXISTS playlist_items;');
    await db.execute('DROP TABLE IF EXISTS playlists;');
    await db.execute('DROP TABLE IF EXISTS tracks;');
  }
}

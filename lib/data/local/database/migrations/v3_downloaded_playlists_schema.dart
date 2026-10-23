import 'package:sound_foundry/data/local/database/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Schema migration: version 3.
/// Adds support for:
/// - downloaded_playlists: persistent download collections (e.g. 1990s Hindi Hits, English Classics)
/// - downloaded_playlist_items: joins downloaded collections with member tracks and tracks track-level status
/// - offline_audio_blobs: persistent binary storage of audio payloads for 100% offline playback on Web / Edge
class V3DownloadedPlaylistsSchema implements Migration {
  @override
  int get version => 3;

  @override
  Future<void> up(Database db) async {
    // 1. Downloaded Playlists collection table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS downloaded_playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        artwork_uri TEXT,
        source_type TEXT NOT NULL DEFAULT 'curated',
        remote_id TEXT,
        total_tracks INTEGER NOT NULL DEFAULT 0,
        downloaded_tracks INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'downloaded',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_dl_playlists_created ON downloaded_playlists(created_at DESC);');

    // 2. Downloaded Playlist Items table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS downloaded_playlist_items (
        playlist_id TEXT NOT NULL,
        track_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        download_status TEXT NOT NULL DEFAULT 'completed',
        PRIMARY KEY (playlist_id, track_id),
        FOREIGN KEY (playlist_id) REFERENCES downloaded_playlists(id) ON DELETE CASCADE,
        FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_dl_items_order ON downloaded_playlist_items(playlist_id, position ASC);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_dl_items_track ON downloaded_playlist_items(track_id);');

    // 3. Offline Audio Blobs table (Web / Edge persistent IndexedDB audio store)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_audio_blobs (
        track_id TEXT PRIMARY KEY,
        audio_data BLOB NOT NULL,
        mime_type TEXT NOT NULL DEFAULT 'audio/mp4',
        file_size INTEGER NOT NULL,
        saved_at INTEGER NOT NULL
      );
    ''');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS offline_audio_blobs;');
    await db.execute('DROP TABLE IF EXISTS downloaded_playlist_items;');
    await db.execute('DROP TABLE IF EXISTS downloaded_playlists;');
  }
}

import 'package:sound_foundry/domain/entities/track.dart';

/// Lightweight provider contract for remote online music services (JioSaavn, Gaana).
/// Enables search and stream resolution on normalized [Track] entities.
abstract class RemoteMusicProvider {
  /// Unique provider identifier (e.g. 'jiosaavn', 'gaana').
  String get id;

  /// Human-readable provider name.
  String get displayName;

  /// Searches the provider catalog for tracks matching the query.
  Future<List<Track>> search(String query);

  /// Resolves the playable remote stream URL for a given track.
  /// Accepts [track] or track identifier/title query.
  Future<String> resolveStreamUri({Track? track, String? trackIdOrQuery});
}

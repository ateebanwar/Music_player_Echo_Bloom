import 'package:sound_foundry/data/remote/clients/gaana_client.dart';
import 'package:sound_foundry/data/remote/providers/remote_music_provider.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Fallback remote music provider powered by Gaana.
class GaanaProvider implements RemoteMusicProvider {
  final GaanaClient _client;

  GaanaProvider({GaanaClient? client})
      : _client = client ?? GaanaClient();

  @override
  String get id => 'gaana';

  @override
  String get displayName => 'Gaana';

  @override
  Future<List<Track>> search(String query) async {
    return await _client.search(query);
  }

  @override
  Future<String> resolveStreamUri({Track? track, String? trackIdOrQuery}) async {
    final query = trackIdOrQuery ?? track?.id ?? track?.title ?? '';

    // If we have a direct seokey or gaana stream URI
    if (query.startsWith('gaana://') || query.startsWith('gaana_')) {
      final seokey = query.replaceFirst('gaana://stream?seokey=', '').replaceFirst('gaana_', '');
      final resolved = await _client.resolveStreamUri(seokey);
      if (resolved.isNotEmpty) return resolved;
    }

    // Fallback: search Gaana by song title and artist to match track
    final searchTitle = track?.title ?? query.replaceFirst('jiosaavn_', '').trim();
    if (searchTitle.isNotEmpty) {
      final searchResults = await _client.search(searchTitle);
      for (final result in searchResults) {
        final stream = await _client.resolveStreamUri(result.id);
        if (stream.isNotEmpty) return stream;
      }
    }

    return '';
  }
}

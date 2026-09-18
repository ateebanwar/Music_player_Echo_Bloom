import 'package:sound_foundry/data/remote/clients/jiosaavn_client.dart';
import 'package:sound_foundry/data/remote/providers/remote_music_provider.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Primary remote music provider powered by JioSaavn.
class JioSaavnProvider implements RemoteMusicProvider {
  final JioSaavnClient _client;

  JioSaavnProvider({JioSaavnClient? client})
      : _client = client ?? JioSaavnClient();

  @override
  String get id => 'jiosaavn';

  @override
  String get displayName => 'JioSaavn';

  @override
  Future<List<Track>> search(String query) async {
    return await _client.search(query);
  }

  @override
  Future<String> resolveStreamUri({Track? track, String? trackIdOrQuery}) async {
    final query = trackIdOrQuery ?? track?.id ?? track?.title ?? '';
    final permaUrl = track?.remotePermaUrl;
    final title = track?.title;
    final artist = track?.artist;

    return await _client.resolveStreamUri(
      query,
      permaUrl: permaUrl,
      title: title,
      artist: artist,
    );
  }
}

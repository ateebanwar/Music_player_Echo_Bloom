import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/data/remote/clients/gaana_client.dart';
import 'package:sound_foundry/domain/entities/track.dart';

void main() {
  group('GaanaClient Tests', () {
    late GaanaClient client;

    setUp(() {
      client = GaanaClient();
    });

    test('parseTracks correctly parses sample Gaana search response into Track entities', () {
      final sampleJson = <String, dynamic>{
        'tracks': <dynamic>[
          <String, dynamic>{
            'seokey': 'kesariya-audio',
            'track_title': 'Kesariya (From &quot;Brahmastra&quot;)',
            'artist_name': 'Arijit Singh, Pritam',
            'album_title': 'Brahmastra',
            'duration': '268',
            'artwork': 'https://img.gaana.com/sample_art.jpg',
          },
          <String, dynamic>{
            'seokey': 'tum-hi-ho',
            'track_title': 'Tum Hi Ho',
            'artist_name': 'Arijit Singh',
            'album_title': 'Aashiqui 2',
            'duration': '262',
            'artwork_large': 'https://img.gaana.com/tum_hi_ho.jpg',
          }
        ]
      };

      final tracks = client.parseTracks(sampleJson);
      expect(tracks.length, 2);

      final track1 = tracks[0];
      expect(track1.id, 'gaana_kesariya-audio');
      expect(track1.title, 'Kesariya (From "Brahmastra")');
      expect(track1.artist, 'Arijit Singh, Pritam');
      expect(track1.album, 'Brahmastra');
      expect(track1.duration, const Duration(seconds: 268));
      expect(track1.sourceType, TrackSourceType.remoteStream);
      expect(track1.mediaUri, 'gaana://stream?seokey=kesariya-audio');
      expect(track1.artworkUri, 'https://img.gaana.com/sample_art.jpg');

      final track2 = tracks[1];
      expect(track2.id, 'gaana_tum-hi-ho');
      expect(track2.title, 'Tum Hi Ho');
      expect(track2.artworkUri, 'https://img.gaana.com/tum_hi_ho.jpg');
    });

    test('parseTracks handles direct List input as well', () {
      final sampleJson = <dynamic>[
        <String, dynamic>{
          'seokey': 'song-one',
          'track_title': 'Song One',
          'artist_name': 'Artist',
          'duration': '180',
        }
      ];

      final tracks = client.parseTracks(sampleJson);
      expect(tracks.length, 1);
      expect(tracks[0].id, 'gaana_song-one');
      expect(tracks[0].title, 'Song One');
    });

    test('parseTracks gracefully returns empty list on HTML or disabled deployment payload', () {
      expect(client.parseTracks(<dynamic>[]), isEmpty);
      expect(client.parseTracks(null), isEmpty);
      expect(client.parseTracks('Payment required DEPLOYMENT_DISABLED'), isEmpty);
      expect(client.parseTracks(<String, dynamic>{'error': 'server_error'}), isEmpty);
    });
  });
}

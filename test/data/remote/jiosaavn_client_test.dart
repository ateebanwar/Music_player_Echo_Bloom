import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/data/remote/clients/jiosaavn_client.dart';
import 'package:sound_foundry/domain/entities/track.dart';

void main() {
  group('JioSaavnClient Tests', () {
    late JioSaavnClient client;

    setUp(() {
      client = JioSaavnClient();
    });

    test('unescapeHtml unescapes common HTML entities correctly', () {
      expect(JioSaavnClient.unescapeHtml('Kesariya (From &quot;Brahmastra&quot;)'),
          'Kesariya (From "Brahmastra")');
      expect(JioSaavnClient.unescapeHtml('Rock&#039;n&#039;Roll &amp; Jazz'),
          'Rock\'n\'Roll & Jazz');
      expect(JioSaavnClient.unescapeHtml('&lt;Hello&gt; &amp; &quot;World&quot;'),
          '<Hello> & "World"');
    });

    test('parseTracks correctly parses sample JioSaavn JSON response into Track entities', () {
      final sampleJson = <dynamic>[
        <String, dynamic>{
          'id': 'lDbCuERl',
          'song': "Jai Jai Ram (From 'Ramayana')",
          'primary_artists': 'A.R. Rahman, Shreya Ghoshal, Arijit Singh',
          'singers': 'Arijit Singh',
          'album': 'Jai Jai Ram',
          'duration': '320',
          'year': '2026',
          'language': 'hindi',
          'image': 'https://c.saavncdn.com/816/Jai-Jai-Ram-500x500.jpg',
          'media_url': 'https://aac.saavncdn.com/816/sample_320.mp4',
          'media_preview_url': 'https://preview.saavncdn.com/816/sample_96_p.mp4',
        },
        <String, dynamic>{
          'id': 'fY2ah9K7',
          'song': 'Chahun Main Ya Naa',
          'primary_artists': 'Arijit Singh, Palak Muchhal',
          'album': 'Aashiqui 2',
          'duration': '304',
          'year': '2013',
          'language': 'hindi',
          'image': 'https://c.saavncdn.com/430/Aashiqui-2-500x500.jpg',
          'media_url': 'https://aac.saavncdn.com/430/sample2_320.mp4',
        }
      ];

      final tracks = client.parseTracks(sampleJson);

      expect(tracks.length, 2);

      final track1 = tracks[0];
      expect(track1.id, 'jiosaavn_lDbCuERl');
      expect(track1.title, "Jai Jai Ram (From 'Ramayana')");
      expect(track1.artist, 'A.R. Rahman, Shreya Ghoshal, Arijit Singh');
      expect(track1.album, 'Jai Jai Ram');
      expect(track1.duration, const Duration(seconds: 320));
      expect(track1.year, 2026);
      expect(track1.genre, 'hindi');
      expect(track1.sourceType, TrackSourceType.remoteStream);
      expect(track1.mediaUri, 'https://aac.saavncdn.com/816/sample_320.mp4');
      expect(track1.artworkUri, 'https://c.saavncdn.com/816/Jai-Jai-Ram-500x500.jpg');

      final track2 = tracks[1];
      expect(track2.id, 'jiosaavn_fY2ah9K7');
      expect(track2.title, 'Chahun Main Ya Naa');
      expect(track2.mediaUri, 'https://aac.saavncdn.com/430/sample2_320.mp4');
    });

    test('parseTracks handles media_preview_url fallback when media_url is absent', () {
      final sampleJson = <dynamic>[
        <String, dynamic>{
          'id': 'previewOnly',
          'song': 'Preview Song',
          'primary_artists': 'Artist One',
          'duration': '120',
          'media_preview_url': 'https://preview.saavncdn.com/sample_preview.mp4',
        }
      ];

      final tracks = client.parseTracks(sampleJson);
      expect(tracks.length, 1);
      expect(tracks[0].mediaUri, 'https://preview.saavncdn.com/sample_preview.mp4');
    });

    test('parseTracks safely handles empty, null, or malformed inputs without throwing', () {
      expect(client.parseTracks(<dynamic>[]), isEmpty);
      expect(client.parseTracks(null), isEmpty);
      expect(client.parseTracks('malformed string'), isEmpty);
      expect(client.parseTracks(<String, dynamic>{'invalid': 123}), isEmpty);
      expect(client.parseTracks(<dynamic>[<String, dynamic>{'id': '', 'song': ''}]), isEmpty);
    });
  });
}

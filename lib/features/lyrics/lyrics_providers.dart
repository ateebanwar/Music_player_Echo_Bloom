import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/features/lyrics/lyrics_contract.dart';

/// Provider for lazy lyrics resolution service.
final lyricsServiceProvider = Provider<LyricsService>((ref) {
  return DefaultLyricsService();
});

/// Family provider to lazily fetch lyrics on demand when the user opens the lyrics view.
final trackLyricsFamilyProvider =
    FutureProvider.family<Lyrics, String>((ref, trackId) async {
  final service = ref.watch(lyricsServiceProvider);
  final result = await service.getLyricsForTrack(trackId);
  return result.when(
    ok: (lyrics) => lyrics,
    err: (failure) => Lyrics(trackId: trackId),
  );
});

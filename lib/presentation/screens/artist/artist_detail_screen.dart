import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/domain/entities/artist.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/features/favorites/favorites_controller.dart';
import 'package:sound_foundry/features/playback/playback_providers.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/screens/playlists/playlist_detail_screen.dart';
import 'package:sound_foundry/presentation/widgets/song_context_menu.dart';
import 'package:sound_foundry/presentation/widgets/track_artwork_widget.dart';

final artistTracksProvider =
    FutureProvider.family<List<Track>, String>((ref, artistName) async {
  final trackRepo = ref.watch(trackRepositoryProvider);
  final res = await trackRepo.getTracksByArtist(artistName);
  return res.valueOrNull ?? [];
});

/// Dedicated Artist Detail Screen providing Spotify/JioSaavn-inspired discovery,
/// popular tracks, Play/Shuffle, and discography albums.
class ArtistDetailScreen extends ConsumerWidget {
  final Artist artist;

  const ArtistDetailScreen({
    super.key,
    required this.artist,
  });

  static void show(BuildContext context, {required Artist artist}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArtistDetailScreen(artist: artist),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final currentTrack = ref.watch(currentTrackProvider);
    final playbackRepo = ref.watch(playbackRepositoryProvider);
    final favoritesState = ref.watch(favoritesControllerProvider);
    final favoritesController = ref.read(favoritesControllerProvider.notifier);

    final tracksAsync = ref.watch(artistTracksProvider(artist.name));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBackgroundGradient : AppColors.backgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? AppColors.darkText : AppColors.iconNavy,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        artist.name,
                        style: AppTypography.trackTitle.copyWith(
                          fontSize: 18.0,
                          color: isDark ? AppColors.darkText : AppColors.textNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: tracksAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryPurple),
                  ),
                  error: (err, _) => Center(
                    child: Text(
                      'Failed to load artist tracks: $err',
                      style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                    ),
                  ),
                  data: (tracks) {
                    final albums = <String, Track>{};
                    for (final t in tracks) {
                      if (t.album != null && t.album!.isNotEmpty) {
                        albums.putIfAbsent(t.album!, () => t);
                      }
                    }

                    return CustomScrollView(
                      slivers: [
                        // Artist Profile Header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 20.0),
                            child: Column(
                              children: [
                                // Circular Avatar
                                Container(
                                  width: 130.0,
                                  height: 130.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryPurple.withValues(alpha: 0.25),
                                        blurRadius: 24.0,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: artist.artworkUri != null && artist.artworkUri!.isNotEmpty
                                        ? Image.network(
                                            artist.artworkUri!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _fallbackAvatar(),
                                          )
                                        : _fallbackAvatar(),
                                  ),
                                ),
                                const SizedBox(height: 16.0),

                                // Artist Name
                                Text(
                                  artist.name,
                                  style: AppTypography.trackTitle.copyWith(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkText : AppColors.textNavy,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4.0),

                                // Artist Meta
                                Text(
                                  'Artist • ${tracks.length} Songs${albums.isNotEmpty ? ' • ${albums.length} Albums' : ''}',
                                  style: AppTypography.artistName.copyWith(
                                    fontSize: 13.5,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 20.0),

                                // Action Buttons (Play All & Shuffle)
                                if (tracks.isNotEmpty)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryPurple,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                                          elevation: 4.0,
                                        ),
                                        icon: const Icon(Icons.play_arrow_rounded, size: 22.0),
                                        label: const Text(
                                          'Play All',
                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                        ),
                                        onPressed: () {
                                          playbackRepo.setQueue(tracks, initialIndex: 0);
                                        },
                                      ),
                                      const SizedBox(width: 14.0),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: isDark ? AppColors.darkText : AppColors.textNavy,
                                          side: BorderSide(
                                            color: isDark ? Colors.white24 : Colors.black12,
                                            width: 1.5,
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                                        ),
                                        icon: const Icon(Icons.shuffle_rounded, size: 20.0),
                                        label: const Text(
                                          'Shuffle',
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.0),
                                        ),
                                        onPressed: () {
                                          final shuffled = List<Track>.from(tracks)..shuffle();
                                          playbackRepo.setQueue(shuffled, initialIndex: 0);
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Section Title: Popular Songs
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 8.0),
                            child: Text(
                              'Popular Songs',
                              style: AppTypography.headerTitle.copyWith(
                                fontSize: 17.0,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkText : AppColors.textNavy,
                              ),
                            ),
                          ),
                        ),

                        // Popular Songs List
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final track = tracks[index];
                              final isCurrent = currentTrack?.id == track.id;
                              final isFavorite = favoritesState.favorites.any((f) => f.id == track.id);

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 3.0),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? (isDark
                                          ? AppColors.primaryPurple.withValues(alpha: 0.18)
                                          : AppColors.primaryPurple.withValues(alpha: 0.08))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 24.0,
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontSize: 13.0,
                                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                              color: isCurrent
                                                  ? AppColors.primaryPurple
                                                  : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        TrackArtworkWidget(
                                          artworkUri: track.artworkUri,
                                          size: 44.0,
                                          borderRadius: 8.0,
                                          isDark: isDark,
                                        ),
                                      ],
                                    ),
                                    title: Text(
                                      track.title,
                                      style: AppTypography.trackTitle.copyWith(
                                        fontSize: 14.5,
                                        color: isCurrent
                                            ? AppColors.primaryPurple
                                            : (isDark ? AppColors.darkText : AppColors.textNavy),
                                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      track.album ?? track.artist,
                                      style: AppTypography.artistName.copyWith(
                                        fontSize: 12.0,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatDuration(track.duration),
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                            size: 19.0,
                                            color: isFavorite ? AppColors.accentRed : (isDark ? AppColors.darkIcon : AppColors.iconMuted),
                                          ),
                                          onPressed: () => favoritesController.toggleFavorite(track),
                                        ),
                                        SongContextMenu(track: track),
                                      ],
                                    ),
                                    onTap: () {
                                      playbackRepo.setQueue(tracks, initialIndex: index);
                                    },
                                  ),
                                ),
                              );
                            },
                            childCount: tracks.length,
                          ),
                        ),

                        // Section Title: Albums & Discography
                        if (albums.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 10.0),
                              child: Text(
                                'Albums & Discography',
                                style: AppTypography.headerTitle.copyWith(
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkText : AppColors.textNavy,
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 175.0,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                itemCount: albums.length,
                                itemBuilder: (context, idx) {
                                  final albumName = albums.keys.elementAt(idx);
                                  final sampleTrack = albums[albumName]!;

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(14.0),
                                    onTap: () {
                                      PlaylistDetailScreen.show(
                                        context,
                                        playlistId: 'album_${albumName.hashCode}',
                                        initialPlaylist: Playlist(
                                          id: 'album_${albumName.hashCode}',
                                          name: albumName,
                                          description: 'Album by ${artist.name}',
                                          artworkUri: sampleTrack.artworkUri,
                                          createdAt: DateTime.now(),
                                          updatedAt: DateTime.now(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 125.0,
                                      margin: const EdgeInsets.symmetric(horizontal: 6.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          TrackArtworkWidget(
                                            artworkUri: sampleTrack.artworkUri,
                                            size: 125.0,
                                            borderRadius: 12.0,
                                            isDark: isDark,
                                          ),
                                          const SizedBox(height: 6.0),
                                          Text(
                                            albumName,
                                            style: TextStyle(
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppColors.darkText : AppColors.textNavy,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            sampleTrack.year != null ? '${sampleTrack.year}' : 'Album',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],

                        const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: AppColors.primaryPurple.withValues(alpha: 0.15),
      child: const Center(
        child: Icon(Icons.person_rounded, size: 64.0, color: AppColors.primaryPurple),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_spacing.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/core/theme/neumorphic_decorations.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/features/download/download_controller.dart';
import 'package:sound_foundry/features/playback/playback_providers.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/screens/playlists/playlist_detail_screen.dart';
import 'package:sound_foundry/presentation/widgets/song_context_menu.dart';
import 'package:sound_foundry/presentation/widgets/track_artwork_widget.dart';

/// Dedicated screen for user's offline library displaying differentiated sections for
/// Downloaded Playlists (collections with progress tracking) and Downloaded Songs.
class DownloadedScreen extends ConsumerWidget {
  const DownloadedScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DownloadedScreen(),
      ),
    );
  }

  String _formatTrackDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final downloadState = ref.watch(downloadControllerProvider);
    final downloadNotifier = ref.read(downloadControllerProvider.notifier);
    final playbackRepo = ref.watch(playbackRepositoryProvider);
    final currentTrack = ref.watch(currentTrackProvider);

    final tracks = downloadState.downloadedTracks;
    final playlists = downloadState.downloadedPlaylists;

    final isEmpty = tracks.isEmpty && playlists.isEmpty;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBackgroundGradient : AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 20.0, 8.0),
                child: Row(
                  children: [
                    Semantics(
                      label: 'Back',
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.0),
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20.0,
                            color: isDark ? AppColors.darkText : AppColors.iconNavy,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Downloaded',
                            style: AppTypography.headerTitle.copyWith(
                              fontSize: 20.0,
                              color: isDark ? AppColors.darkText : AppColors.textNavy,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            isEmpty
                                ? 'No offline downloads'
                                : '${playlists.length} playlists • ${tracks.length} songs offline',
                            style: AppTypography.artistName.copyWith(
                              fontSize: 12.0,
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tracks.isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(Icons.shuffle_rounded, color: AppColors.primaryPurple, size: 22.0),
                        tooltip: 'Shuffle All Offline',
                        onPressed: () {
                          final shuffled = List<Track>.from(tracks)..shuffle();
                          playbackRepo.setQueue(shuffled, initialIndex: 0);
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.play_circle_filled_rounded,
                          size: 32.0,
                          color: AppColors.primaryPurple,
                        ),
                        tooltip: 'Play All Offline',
                        onPressed: () => playbackRepo.setQueue(tracks, initialIndex: 0),
                      ),
                    ],
                  ],
                ),
              ),

              // Content
              Expanded(
                child: isEmpty
                    ? _buildEmptyState(isDark)
                    : CustomScrollView(
                        slivers: [
                          // Section: Downloaded Playlists
                          if (playlists.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
                                child: Text(
                                  'Downloaded Playlists',
                                  style: AppTypography.headerTitle.copyWith(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkText : AppColors.textNavy,
                                  ),
                                ),
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, idx) {
                                  final pl = playlists[idx];
                                  final progressText = downloadState.playlistProgress[pl.id] ??
                                      '${pl.downloadedTracks}/${pl.totalTracks} downloaded';

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                                    decoration: NeumorphicDecorations.elevatedCard(
                                      borderRadius: AppSpacing.roundedArtwork,
                                      isDark: isDark,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                                        leading: TrackArtworkWidget(
                                          artworkUri: pl.artworkUri,
                                          size: 50.0,
                                          borderRadius: 12.0,
                                          isDark: isDark,
                                        ),
                                        title: Text(
                                          pl.name,
                                          style: AppTypography.headerTitle.copyWith(
                                            fontSize: 15.0,
                                            color: isDark ? AppColors.darkText : AppColors.textNavy,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          progressText,
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            color: pl.isFullyDownloaded
                                                ? AppColors.accentGreen
                                                : AppColors.primaryPurple,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert_rounded,
                                            size: 20.0,
                                            color: isDark ? AppColors.darkTextMuted : AppColors.iconMuted,
                                          ),
                                          onSelected: (val) {
                                            if (val == 'delete') {
                                              downloadNotifier.deleteDownloadedPlaylist(pl.id);
                                            } else if (val == 'retry') {
                                              downloadNotifier.retryPlaylistDownload(pl.id);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            if (!pl.isFullyDownloaded)
                                              const PopupMenuItem(
                                                value: 'retry',
                                                child: Text('Retry Incomplete Tracks'),
                                              ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete from Downloads', style: TextStyle(color: AppColors.errorRed)),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          PlaylistDetailScreen.show(
                                            context,
                                            playlistId: pl.id,
                                            initialPlaylist: pl.toPlaylist(),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                                childCount: playlists.length,
                              ),
                            ),
                          ],

                          // Section: Downloaded Songs
                          if (tracks.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 8.0),
                                child: Text(
                                  'Downloaded Songs',
                                  style: AppTypography.headerTitle.copyWith(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkText : AppColors.textNavy,
                                  ),
                                ),
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, idx) {
                                  final track = tracks[idx];
                                  final isCurrent = currentTrack?.id == track.id;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                                    decoration: NeumorphicDecorations.elevatedCard(
                                      borderRadius: AppSpacing.roundedArtwork,
                                      isDark: isDark,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                                        leading: TrackArtworkWidget(
                                          artworkUri: track.artworkUri,
                                          size: 46.0,
                                          borderRadius: 12.0,
                                        ),
                                        title: Text(
                                          track.title,
                                          style: AppTypography.headerTitle.copyWith(
                                            fontSize: 14.5,
                                            color: isCurrent
                                                ? AppColors.primaryPurple
                                                : (isDark ? AppColors.darkText : AppColors.iconNavy),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          track.artist,
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
                                              _formatTrackDuration(track.duration),
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                              ),
                                            ),
                                            const SizedBox(width: 4.0),
                                            SongContextMenu(track: track),
                                          ],
                                        ),
                                        onTap: () => playbackRepo.setQueue(tracks, initialIndex: idx),
                                      ),
                                    ),
                                  );
                                },
                                childCount: tracks.length,
                              ),
                            ),
                          ],

                          const SliverToBoxAdapter(child: SizedBox(height: 80.0)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.0,
              height: 72.0,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.download_done_rounded,
                  size: 36.0,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'No Downloaded Music',
              style: AppTypography.trackTitle.copyWith(
                fontSize: 18.0,
                color: isDark ? AppColors.darkText : AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Download songs or entire playlists while in Online mode to listen to your music offline without internet.',
              textAlign: TextAlign.center,
              style: AppTypography.artistName.copyWith(
                fontSize: 13.0,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/features/download/download_controller.dart';
import 'package:sound_foundry/features/playback/playback_providers.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/widgets/song_context_menu.dart';
import 'package:sound_foundry/presentation/widgets/track_artwork_widget.dart';

/// Dedicated screen for user's offline downloaded online tracks.
class DownloadedScreen extends ConsumerWidget {
  const DownloadedScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DownloadedScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final downloadState = ref.watch(downloadControllerProvider);
    final playbackRepo = ref.watch(playbackRepositoryProvider);
    final currentTrack = ref.watch(currentTrackProvider);
    final tracks = downloadState.downloadedTracks;

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
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 20.0, 12.0),
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
                            tracks.isEmpty
                                ? 'No offline downloads'
                                : '${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'} available offline',
                            style: AppTypography.artistName.copyWith(
                              fontSize: 12.0,
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tracks.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.play_circle_filled_rounded,
                          size: 32.0,
                          color: AppColors.primaryPurple,
                        ),
                        tooltip: 'Play All',
                        onPressed: () => playbackRepo.setQueue(tracks, initialIndex: 0),
                      ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: tracks.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 32.0),
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          final isPlayingThis = currentTrack?.id == track.id;

                          return _buildTrackTile(
                            context: context,
                            ref: ref,
                            track: track,
                            index: index,
                            tracks: tracks,
                            isDark: isDark,
                            isPlayingThis: isPlayingThis,
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download_done_rounded,
                size: 48.0,
                color: isDark ? AppColors.darkTextMuted : AppColors.iconMuted,
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'No Downloaded Songs',
              style: AppTypography.headerTitle.copyWith(
                fontSize: 18.0,
                color: isDark ? AppColors.darkText : AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Save online songs to your device for 100% offline playback without internet.',
              textAlign: TextAlign.center,
              style: TextStyle(
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

  Widget _buildTrackTile({
    required BuildContext context,
    required WidgetRef ref,
    required Track track,
    required int index,
    required List<Track> tracks,
    required bool isDark,
    required bool isPlayingThis,
  }) {
    final sizeFormatted = track.fileSize > 0
        ? '${(track.fileSize / (1024 * 1024)).toStringAsFixed(1)} MB'
        : 'Offline';

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isPlayingThis
            ? (isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
        leading: SizedBox(
          width: 44.0,
          height: 44.0,
          child: TrackArtworkWidget(
            artworkUri: track.artworkUri,
            size: 44.0,
            borderRadius: 8.0,
          ),
        ),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.headerTitle.copyWith(
            fontSize: 14.0,
            color: isPlayingThis
                ? AppColors.primaryPurple
                : (isDark ? AppColors.darkText : AppColors.textNavy),
          ),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.0,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 6.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                sizeFormatted,
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.more_vert_rounded,
            size: 20.0,
            color: isDark ? AppColors.darkTextMuted : AppColors.iconMuted,
          ),
          onPressed: () {
            SongContextMenu.show(
              context: context,
              ref: ref,
              track: track,
              isNowPlayingContext: false,
              isFavorite: track.isFavorite,
            );
          },
        ),
        onTap: () {
          ref.read(playbackRepositoryProvider).setQueue(tracks, initialIndex: index);
        },
      ),
    );
  }
}

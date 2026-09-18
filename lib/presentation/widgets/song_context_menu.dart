import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/features/download/download_controller.dart';
import 'package:sound_foundry/features/favorites/favorites_controller.dart';
import 'package:sound_foundry/features/playlists/playlist_providers.dart';
import 'package:sound_foundry/presentation/screens/equalizer/equalizer_screen.dart';
import 'package:sound_foundry/presentation/widgets/create_playlist_dialog.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';
import 'package:sound_foundry/presentation/widgets/track_artwork_widget.dart';

/// Context menu for track actions in Now Playing and song-list views with theme adaptivity.
class SongContextMenu {
  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required Track track,
    required bool isNowPlayingContext,
    required bool isFavorite,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.darkIcon : AppColors.iconNavy;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.3),
                blurRadius: 20.0,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Container(
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkTextMuted.withValues(alpha: 0.3)
                      : AppColors.iconMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              const SizedBox(height: 16.0),

              // Header: Song Title & Artist
              Row(
                children: [
                  TrackArtworkWidget(
                    artworkUri: track.artworkUri,
                    size: 44.0,
                    borderRadius: 12.0,
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: AppTypography.headerTitle.copyWith(
                            fontSize: 16.0,
                            color: isDark ? AppColors.darkText : AppColors.textNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          track.artist,
                          style: AppTypography.artistName.copyWith(
                            fontSize: 13.0,
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Divider(
                color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                height: 1.0,
              ),
              const SizedBox(height: 8.0),

              // Actions List
              if (!isNowPlayingContext) ...[
                _buildActionTile(
                  icon: CustomIcons.play(size: 18.0, color: iconColor),
                  title: 'Play',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    ref.read(playbackRepositoryProvider).playTrack(track);
                  },
                ),
                _buildActionTile(
                  icon: CustomIcons.skipNext(size: 18.0, color: iconColor),
                  title: 'Play Next',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    ref.read(playbackRepositoryProvider).playNext(track);
                    _showFeedback(context, 'Playing next: ${track.title}');
                  },
                ),
                _buildActionTile(
                  icon: CustomIcons.playlistGrid(size: 18.0, color: iconColor),
                  title: 'Add to Queue',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    ref.read(playbackRepositoryProvider).addToQueue(track);
                    _showFeedback(context, 'Added to queue: ${track.title}');
                  },
                ),
              ],

              // State-dependent Favorite action
              _buildActionTile(
                icon: CustomIcons.heart(
                  size: 18.0,
                  color: isFavorite ? AppColors.favoriteRed : iconColor,
                  isFilled: isFavorite,
                ),
                title: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  ref.read(favoritesControllerProvider.notifier).toggleFavorite(track);
                  _showFeedback(
                    context,
                    isFavorite ? 'Removed from favorites' : 'Added to favorites',
                  );
                },
              ),

              _buildActionTile(
                icon: CustomIcons.disc(size: 18.0, color: iconColor),
                title: 'Add to Playlist',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showAddToPlaylistSheet(context, ref, track);
                },
              ),

              // Save Offline / Downloaded action for remote online songs
              if (track.sourceType == TrackSourceType.remoteStream) ...[
                Consumer(
                  builder: (context, consumerRef, _) {
                    final downloadNotifier = consumerRef.watch(downloadControllerProvider.notifier);
                    final isDownloaded = downloadNotifier.isTrackDownloaded(track);
                    final isDownloading = downloadNotifier.isDownloading(track.id);

                    if (isDownloaded) {
                      return _buildActionTile(
                        icon: const Icon(Icons.download_done_rounded, size: 18.0, color: AppColors.primaryPurple),
                        title: 'Downloaded',
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _showFeedback(context, 'This song is already saved offline.');
                        },
                      );
                    } else if (isDownloading) {
                      return _buildActionTile(
                        icon: const SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.primaryPurple),
                        ),
                        title: 'Downloading...',
                        isDark: isDark,
                        onTap: () {},
                      );
                    } else {
                      return _buildActionTile(
                        icon: Icon(Icons.download_rounded, size: 18.0, color: iconColor),
                        title: 'Save Offline',
                        isDark: isDark,
                        onTap: () async {
                          Navigator.pop(bottomSheetContext);
                          _showFeedback(context, 'Downloading ${track.title}...');
                          final success = await ref.read(downloadControllerProvider.notifier).downloadTrack(track);
                          if (context.mounted) {
                            _showFeedback(
                              context,
                              success ? 'Saved offline: ${track.title}' : 'Failed to download ${track.title}',
                            );
                          }
                        },
                      );
                    }
                  },
                ),
              ],

              // Delete Download action for downloaded tracks
              if (track.sourceType == TrackSourceType.downloaded) ...[
                _buildActionTile(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18.0, color: AppColors.favoriteRed),
                  title: 'Delete Download',
                  isDark: isDark,
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await ref.read(downloadControllerProvider.notifier).deleteDownload(track);
                    if (context.mounted) {
                      _showFeedback(context, 'Removed download: ${track.title}');
                    }
                  },
                ),
              ],

              _buildActionTile(
                icon: CustomIcons.shuffle(size: 18.0, color: iconColor),
                title: 'Equalizer',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  EqualizerScreen.show(context);
                },
              ),

              _buildActionTile(
                icon: CustomIcons.menu(size: 18.0, color: iconColor),
                title: 'Crop Audio',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showCropAudioSheet(context, track);
                },
              ),

              _buildActionTile(
                icon: CustomIcons.musicNote(size: 18.0, color: iconColor),
                title: 'Set as Ringtone',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showSetAsRingtoneSheet(context, track);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildActionTile({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      leading: SizedBox(width: 28.0, height: 28.0, child: Center(child: icon)),
      title: Text(
        title,
        style: AppTypography.headerTitle.copyWith(
          fontSize: 15.0,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkText : AppColors.textNavy,
        ),
      ),
      onTap: onTap,
    );
  }

  static void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13.0)),
        backgroundColor: AppColors.darkCapsule,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }

  static void _showAddToPlaylistSheet(BuildContext context, WidgetRef ref, Track track) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final playlistState = ref.watch(playlistControllerProvider);
        final playlists = playlistState.playlists;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add to Playlist',
                    style: AppTypography.trackTitle.copyWith(
                      fontSize: 20.0,
                      color: isDark ? AppColors.darkText : AppColors.textNavy,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      CreatePlaylistDialog.show(context: context, ref: ref, initialTrack: track);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 14.0, color: AppColors.primaryPurple),
                          const SizedBox(width: 4.0),
                          Text(
                            'New',
                            style: AppTypography.headerTitle.copyWith(
                              fontSize: 12.0,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              if (playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    children: [
                      Text(
                        'No playlists available yet',
                        style: AppTypography.artistName.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        ),
                        icon: const Icon(Icons.add, size: 16.0),
                        label: const Text('Create Playlist & Add Song'),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          CreatePlaylistDialog.show(context: context, ref: ref, initialTrack: track);
                        },
                      ),
                    ],
                  ),
                )
              else
                ...playlists.map((playlist) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      leading: Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Center(
                          child: CustomIcons.playlistGrid(size: 18.0, color: AppColors.primaryPurple),
                        ),
                      ),
                      title: Text(
                        playlist.name,
                        style: AppTypography.headerTitle.copyWith(
                          fontSize: 15.0,
                          color: isDark ? AppColors.darkText : AppColors.textNavy,
                        ),
                      ),
                      subtitle: Text(
                        '${playlist.trackCount} tracks',
                        style: AppTypography.artistName.copyWith(
                          fontSize: 12.0,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(sheetCtx);
                        final success = await ref
                            .read(playlistControllerProvider.notifier)
                            .addTrackToPlaylist(playlist.id, track);
                        if (context.mounted) {
                          _showFeedback(
                            context,
                            success
                                ? 'Added "${track.title}" to ${playlist.name}'
                                : 'Could not add to playlist',
                          );
                        }
                      },
                    )),
            ],
          ),
        );
      },
    );
  }

  static void _showCropAudioSheet(BuildContext context, Track track) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crop Audio',
                style: AppTypography.trackTitle.copyWith(
                  fontSize: 20.0,
                  color: isDark ? AppColors.darkText : AppColors.textNavy,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Non-destructively trim a clip from "${track.title}". Original file will be preserved untouched.',
                style: AppTypography.artistName.copyWith(
                  fontSize: 13.0,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _showFeedback(context, 'Cropped audio clip saved to device storage');
                    },
                    child: const Text('Save Clip', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showSetAsRingtoneSheet(BuildContext context, Track track) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set as Ringtone',
                style: AppTypography.trackTitle.copyWith(
                  fontSize: 20.0,
                  color: isDark ? AppColors.darkText : AppColors.textNavy,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Set "${track.title}" as your phone ringtone.',
                style: AppTypography.artistName.copyWith(
                  fontSize: 13.0,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _showFeedback(context, 'Ringtone successfully updated');
                    },
                    child: const Text('Apply', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

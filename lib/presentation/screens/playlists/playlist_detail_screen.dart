import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_spacing.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/core/theme/neumorphic_decorations.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/features/favorites/favorites_controller.dart';
import 'package:sound_foundry/features/playback/playback_providers.dart';
import 'package:sound_foundry/features/playlists/playlist_providers.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';
import 'package:sound_foundry/presentation/widgets/song_context_menu.dart';
import 'package:sound_foundry/presentation/widgets/track_artwork_widget.dart';

/// Screen displaying the contents of a specific playlist, accurate song count,
/// individual song playback, and safe playlist deletion with confirmation.
class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;
  final Playlist? initialPlaylist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.initialPlaylist,
  });

  /// Static helper to navigate to [PlaylistDetailScreen].
  static void show(BuildContext context, {required String playlistId, Playlist? initialPlaylist}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaylistDetailScreen(
          playlistId: playlistId,
          initialPlaylist: initialPlaylist,
        ),
      ),
    );
  }

  String _formatSongCount(int count) {
    if (count == 1) return '1 Song';
    return '$count Songs';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Text(
            'Delete Playlist?',
            style: AppTypography.headerTitle.copyWith(
              fontSize: 18.0,
              color: isDark ? AppColors.darkText : AppColors.textNavy,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${playlist.name}"?\nSongs will remain in your library.',
            style: AppTypography.artistName.copyWith(
              fontSize: 14.0,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await ref.read(playlistControllerProvider.notifier).deletePlaylist(playlist.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Playlist "${playlist.name}" deleted',
              style: const TextStyle(color: Colors.white, fontSize: 13.0),
            ),
            backgroundColor: AppColors.darkCapsule,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final playlistState = ref.watch(playlistControllerProvider);
    final playbackRepo = ref.watch(playbackRepositoryProvider);
    final currentTrack = ref.watch(currentTrackProvider);
    final favoritesState = ref.watch(favoritesControllerProvider);
    final favoritesController = ref.read(favoritesControllerProvider.notifier);

    // Resolve playlist entity from state or fallback
    final playlist = playlistState.playlists
        .cast<Playlist?>()
        .firstWhere((p) => p?.id == playlistId, orElse: () => initialPlaylist);

    final isProtected = playlist?.isSmartPlaylist == true ||
        (playlist?.name.trim().toLowerCase() == 'start playlist');

    final tracksAsync = ref.watch(playlistTracksProvider(playlistId));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBackgroundGradient : AppColors.backgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header with Back Button, Playlist Title, and Delete action
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? AppColors.darkText : AppColors.iconNavy,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        playlist?.name ?? 'Playlist',
                        style: AppTypography.trackTitle.copyWith(
                          fontSize: 20.0,
                          color: isDark ? AppColors.darkText : AppColors.textNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isProtected && playlist != null)
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: isDark ? AppColors.darkTextMuted : AppColors.iconNavy,
                          size: 22.0,
                        ),
                        tooltip: 'Delete Playlist',
                        onPressed: () => _confirmDelete(context, ref, playlist),
                      ),
                  ],
                ),
              ),

              // Playlist Info Banner
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 4.0, 24.0, 16.0),
                child: Row(
                  children: [
                    Container(
                      width: 56.0,
                      height: 56.0,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Center(
                        child: CustomIcons.playlistGrid(
                          size: 26.0,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist?.name ?? 'Playlist',
                            style: AppTypography.headerTitle.copyWith(
                              fontSize: 18.0,
                              color: isDark ? AppColors.darkText : AppColors.textNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),
                          tracksAsync.when(
                            data: (tracks) => Text(
                              _formatSongCount(tracks.length),
                              style: AppTypography.artistName.copyWith(
                                fontSize: 14.0,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                            ),
                            loading: () => Text(
                              _formatSongCount(playlist?.trackCount ?? 0),
                              style: AppTypography.artistName.copyWith(
                                fontSize: 14.0,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                            ),
                            error: (_, __) => Text(
                              _formatSongCount(playlist?.trackCount ?? 0),
                              style: AppTypography.artistName.copyWith(
                                fontSize: 14.0,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tracks List / Empty State / Loading State / Error State
              Expanded(
                child: tracksAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryPurple,
                      strokeWidth: 3.0,
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Unable to load playlist songs',
                          style: AppTypography.headerTitle.copyWith(
                            fontSize: 16.0,
                            color: isDark ? AppColors.darkText : AppColors.textNavy,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          ),
                          onPressed: () => ref.refresh(playlistTracksProvider(playlistId)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (tracks) {
                    if (tracks.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64.0,
                                height: 64.0,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: CustomIcons.musicNote(
                                    size: 28.0,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Text(
                                'No songs in this playlist yet',
                                style: AppTypography.headerTitle.copyWith(
                                  fontSize: 17.0,
                                  color: isDark ? AppColors.darkText : AppColors.textNavy,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                'Add songs from your library to get started',
                                textAlign: TextAlign.center,
                                style: AppTypography.artistName.copyWith(
                                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24.0, 4.0, 24.0, 24.0),
                      itemCount: tracks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final isCurrent = currentTrack?.id == track.id;
                        final isFavorite = favoritesState.favorites.any((f) => f.id == track.id);

                        return Container(
                          decoration: NeumorphicDecorations.elevatedCard(
                            borderRadius: AppSpacing.roundedArtwork,
                            isDark: isDark,
                          ),
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
                                fontSize: 15.0,
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
                                fontSize: 13.0,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Favorite Heart Button
                                GestureDetector(
                                  onTap: () => favoritesController.toggleFavorite(track),
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: CustomIcons.heart(
                                      size: 20.0,
                                      color: isFavorite
                                          ? AppColors.favoriteRed
                                          : (isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.iconNavy.withValues(alpha: 0.4)),
                                      isFilled: isFavorite,
                                    ),
                                  ),
                                ),

                                // 3-dots Context Menu Button
                                GestureDetector(
                                  onTap: () {
                                    SongContextMenu.show(
                                      context: context,
                                      ref: ref,
                                      track: track,
                                      isNowPlayingContext: false,
                                      isFavorite: isFavorite,
                                    );
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: CustomIcons.moreVertical(
                                      size: 18.0,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.iconNavy.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => playbackRepo.setQueue(tracks, initialIndex: index),
                          ),
                        );
                      },
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
}

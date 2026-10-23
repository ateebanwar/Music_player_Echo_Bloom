import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/domain/entities/downloaded_playlist.dart';
import 'package:sound_foundry/domain/entities/playlist.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/features/download/download_controller.dart';
import 'package:sound_foundry/features/favorites/favorites_controller.dart';
import 'package:sound_foundry/features/playback/playback_providers.dart';
import 'package:sound_foundry/features/playlists/playlist_providers.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';
import 'package:sound_foundry/presentation/widgets/song_context_menu.dart';
import 'package:sound_foundry/presentation/widgets/track_artwork_widget.dart';

/// Screen displaying the contents of a playlist (user, discovery, album, or downloaded),
/// accurate song count, total calculated duration, individual track playback, and full playlist downloading.
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

  String _formatTotalDuration(List<Track> tracks) {
    int totalSec = 0;
    for (final t in tracks) {
      totalSec += t.duration.inSeconds;
    }
    if (totalSec <= 0) return '';
    final minutes = totalSec ~/ 60;
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    return '${hours}h ${remainingMins}m';
  }

  String _formatTrackDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
    final downloadState = ref.watch(downloadControllerProvider);
    final downloadNotifier = ref.read(downloadControllerProvider.notifier);
    final playbackRepo = ref.watch(playbackRepositoryProvider);
    final currentTrack = ref.watch(currentTrackProvider);
    final favoritesState = ref.watch(favoritesControllerProvider);
    final favoritesController = ref.read(favoritesControllerProvider.notifier);

    // Resolve playlist entity from state or fallback
    final playlist = playlistState.playlists
        .cast<Playlist?>()
        .firstWhere((p) => p?.id == playlistId, orElse: () => initialPlaylist);

    final isProtected = playlist?.isSmartPlaylist == true ||
        (playlist?.name.trim().toLowerCase() == 'start playlist') ||
        playlistId.startsWith('discovery_') ||
        playlistId.startsWith('album_');

    final tracksAsync = ref.watch(playlistTracksProvider(playlistId));

    final isDownloadingPlaylist = downloadState.downloadingPlaylistIds.contains(playlistId);
    final isDownloadedPlaylist = downloadState.downloadedPlaylists.any(
      (p) => p.id == playlistId && p.status == DownloadPlaylistStatus.downloaded,
    );
    final progressStr = downloadState.playlistProgress[playlistId];

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
              // Screen Header with Back Button, Title, and Actions
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

              // Playlist Banner & Metadata Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 6.0, 24.0, 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Artwork / Cover
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Container(
                        width: 72.0,
                        height: 72.0,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                        ),
                        child: playlist?.artworkUri != null && playlist!.artworkUri!.isNotEmpty
                            ? Image.network(
                                playlist.artworkUri!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _fallbackCover(isDark),
                              )
                            : _fallbackCover(isDark),
                      ),
                    ),
                    const SizedBox(width: 16.0),

                    // Title & Metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist?.name ?? 'Playlist',
                            style: AppTypography.headerTitle.copyWith(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.textNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (playlist?.description != null && playlist!.description!.isNotEmpty) ...[
                            const SizedBox(height: 3.0),
                            Text(
                              playlist.description!,
                              style: TextStyle(
                                fontSize: 12.0,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 4.0),
                          tracksAsync.when(
                            data: (tracks) {
                              final dur = _formatTotalDuration(tracks);
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatSongCount(tracks.length),
                                    style: AppTypography.artistName.copyWith(
                                      fontSize: 13.0,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                    ),
                                  ),
                                  if (dur.isNotEmpty) ...[
                                    Text(
                                      ' • $dur',
                                      style: AppTypography.artistName.copyWith(
                                        fontSize: 13.0,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                            loading: () => Text(
                              _formatSongCount(playlist?.trackCount ?? 0),
                              style: AppTypography.artistName.copyWith(
                                fontSize: 13.0,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                            ),
                            error: (_, __) => Text(
                              _formatSongCount(playlist?.trackCount ?? 0),
                              style: AppTypography.artistName.copyWith(
                                fontSize: 13.0,
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

              // Playlist Play, Shuffle & Download Actions
              tracksAsync.maybeWhen(
                data: (tracks) => tracks.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 12.0),
                        child: Row(
                          children: [
                            // Play All Button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 20.0),
                              label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                              onPressed: () => playbackRepo.setQueue(tracks, initialIndex: 0),
                            ),
                            const SizedBox(width: 10.0),

                            // Shuffle Button
                            IconButton(
                              icon: Icon(
                                Icons.shuffle_rounded,
                                color: isDark ? AppColors.darkText : AppColors.iconNavy,
                                size: 20.0,
                              ),
                              tooltip: 'Shuffle',
                              onPressed: () {
                                final shuffled = List<Track>.from(tracks)..shuffle();
                                playbackRepo.setQueue(shuffled, initialIndex: 0);
                              },
                            ),

                            const Spacer(),

                            // Download Playlist Button
                            if (isDownloadingPlaylist)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 14.0,
                                      height: 14.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        color: AppColors.primaryPurple,
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      progressStr ?? 'Downloading...',
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isDownloadedPlaylist)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.download_done_rounded, color: AppColors.successGreen, size: 18.0),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    'Downloaded',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkText : AppColors.textNavy,
                                    ),
                                  ),
                                ],
                              )
                            else
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primaryPurple,
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                ),
                                icon: const Icon(Icons.download_rounded, size: 18.0),
                                label: const Text('Download', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.0)),
                                onPressed: () async {
                                  final effectivePlaylist = playlist ??
                                      Playlist(
                                        id: playlistId,
                                        name: 'Playlist',
                                        createdAt: DateTime.now(),
                                        updatedAt: DateTime.now(),
                                      );
                                  await downloadNotifier.downloadPlaylist(effectivePlaylist, tracks);
                                },
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
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
                      padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 24.0),
                      itemCount: tracks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6.0),
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final isCurrent = currentTrack?.id == track.id;
                        final isFavorite = favoritesState.favorites.any((f) => f.id == track.id);
                        final isDownloaded = downloadNotifier.isTrackDownloaded(track);

                        return Container(
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 22.0,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12.5,
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
                                    borderRadius: 10.0,
                                  ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      track.title,
                                      style: AppTypography.headerTitle.copyWith(
                                        fontSize: 14.5,
                                        color: isCurrent
                                            ? AppColors.primaryPurple
                                            : (isDark ? AppColors.darkText : AppColors.iconNavy),
                                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isDownloaded)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4.0),
                                      child: Icon(
                                        Icons.download_done_rounded,
                                        size: 14.0,
                                        color: AppColors.successGreen,
                                      ),
                                    ),
                                ],
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
                                  IconButton(
                                    icon: Icon(
                                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      size: 18.0,
                                      color: isFavorite ? AppColors.favoriteRed : (isDark ? AppColors.darkIcon : AppColors.iconMuted),
                                    ),
                                    onPressed: () => favoritesController.toggleFavorite(track),
                                  ),
                                  SongContextMenu(track: track),
                                ],
                              ),

                              onTap: () => playbackRepo.setQueue(tracks, initialIndex: index),
                            ),
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

  Widget _fallbackCover(bool isDark) {
    return Center(
      child: CustomIcons.playlistGrid(
        size: 32.0,
        color: AppColors.primaryPurple,
      ),
    );
  }
}

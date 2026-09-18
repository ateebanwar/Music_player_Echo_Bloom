import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/core/theme/neumorphic_decorations.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/features/favorites/favorites_controller.dart';
import 'package:sound_foundry/features/playback/playback_providers.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/screens/main_navigation_shell.dart';
import 'package:sound_foundry/presentation/screens/now_playing/widgets/album_artwork_view.dart';
import 'package:sound_foundry/presentation/screens/now_playing/widgets/now_playing_header.dart';
import 'package:sound_foundry/presentation/screens/now_playing/widgets/playback_control_panel.dart';
import 'package:sound_foundry/presentation/screens/now_playing/widgets/track_info_section.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';
import 'package:sound_foundry/presentation/widgets/song_context_menu.dart';

/// The reference "Now Playing" screen dynamically bound to the real playback state and device library.
class NowPlayingScreen extends ConsumerWidget {
  final VoidCallback? onMenuTap;

  const NowPlayingScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(currentPlaybackStateProvider);
    final playbackRepo = ref.watch(playbackRepositoryProvider);
    final favoritesState = ref.watch(favoritesControllerProvider);
    final favoritesController = ref.read(favoritesControllerProvider.notifier);

    final currentTrack = playbackState.currentTrack;

    final isFavorite = currentTrack != null &&
        favoritesState.favorites.any((t) => t.id == currentTrack.id);
    final isDark = ref.watch(isDarkModeProvider);

    if (currentTrack == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBackgroundGradient : AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              NowPlayingHeader(
                isDark: isDark,
                onMenuTap: onMenuTap ?? () => Scaffold.maybeOf(context)?.openDrawer(),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80.0,
                          height: 80.0,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: CustomIcons.musicNote(
                              size: 36.0,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Text(
                          'No Track Playing',
                          style: AppTypography.trackTitle.copyWith(
                            fontSize: 20.0,
                            color: isDark ? AppColors.darkText : AppColors.textNavy,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Select a song from All Songs to start playing your offline music.',
                          textAlign: TextAlign.center,
                          style: AppTypography.artistName.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        GestureDetector(
                          onTap: () {
                            ref.read(mainNavIndexProvider.notifier).state = 1;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                            decoration: NeumorphicDecorations.elevatedCard(
                              borderRadius: BorderRadius.circular(24.0),
                              isDark: isDark,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIcons.disc(size: 20.0, color: AppColors.primaryPurple),
                                const SizedBox(width: 8.0),
                                Text(
                                  'Go to All Songs',
                                  style: AppTypography.headerTitle.copyWith(
                                    color: AppColors.primaryPurple,
                                    fontSize: 14.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkBackgroundGradient : AppColors.backgroundGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final isTallScreen = availableHeight >= 700;
            final calculatedArtSize = (availableHeight * 0.38).clamp(180.0, 312.0);
            final maxArtSize = math.min(constraints.maxWidth - 48.0, calculatedArtSize);

            Widget content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4.0),

                // 1. Top Header
                NowPlayingHeader(
                  isDark: isDark,
                  onMenuTap: onMenuTap ?? () => Scaffold.maybeOf(context)?.openDrawer(),
                  onOptionsTap: () {
                    SongContextMenu.show(
                      context: context,
                      ref: ref,
                      track: currentTrack,
                      isNowPlayingContext: true,
                      isFavorite: isFavorite,
                    );
                  },
                ),

                if (isTallScreen) const Spacer(flex: 1) else const SizedBox(height: 14.0),

                // 2. Album Artwork View
                AlbumArtworkView(
                  artworkUri: currentTrack.artworkUri,
                  size: maxArtSize,
                  isDark: isDark,
                ),

                if (isTallScreen) const Spacer(flex: 2) else const SizedBox(height: 20.0),

                // 3. Track Info Section & Favorite Toggle
                TrackInfoSection(
                  track: currentTrack,
                  position: playbackState.position,
                  duration: playbackState.duration > Duration.zero
                      ? playbackState.duration
                      : (currentTrack.duration > Duration.zero
                          ? currentTrack.duration
                          : Duration.zero),
                  isFavorite: isFavorite,
                  isDark: isDark,
                  onFavoriteToggle: () => favoritesController.toggleFavorite(currentTrack),
                ),

                if (isTallScreen) const Spacer(flex: 2) else const SizedBox(height: 20.0),

                // 4. Playback Control Panel
                Consumer(
                  builder: (context, ref, _) {
                    final posAsync = ref.watch(playbackPositionStreamProvider);
                    final livePosition = posAsync.valueOrNull ?? playbackState.position;

                    return PlaybackControlPanel(
                      isDark: isDark,
                      playbackState: playbackState.copyWith(
                        duration: playbackState.duration > Duration.zero
                            ? playbackState.duration
                            : (currentTrack.duration > Duration.zero
                                ? currentTrack.duration
                                : Duration.zero),
                      ),
                      currentPosition: livePosition,
                      onPlayPauseTap: () => playbackRepo.togglePlayPause(),
                      onPreviousTap: () => playbackRepo.skipToPrevious(),
                      onNextTap: () => playbackRepo.skipToNext(),
                      onShuffleTap: () => playbackRepo.toggleShuffle(),
                      onRepeatTap: () {
                        final nextMode = switch (playbackState.repeatMode) {
                          RepeatMode.off => RepeatMode.all,
                          RepeatMode.all => RepeatMode.one,
                          RepeatMode.one => RepeatMode.off,
                        };
                        playbackRepo.setRepeatMode(nextMode);
                      },
                      onSeek: (newPos) => playbackRepo.seek(newPos),
                    );
                  },
                ),

                const SizedBox(height: 94.0),
              ],
            );

            if (!isTallScreen) {
              content = SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: content,
              );
            }

            return content;
          },
        ),
      ),
    );
  }
}

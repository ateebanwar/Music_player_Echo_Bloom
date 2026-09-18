import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_spacing.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/core/theme/neumorphic_decorations.dart';
import 'package:sound_foundry/features/favorites/favorites_controller.dart';
import 'package:sound_foundry/features/playback/playback_providers.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';
import 'package:sound_foundry/presentation/widgets/song_context_menu.dart';
import 'package:sound_foundry/presentation/widgets/track_artwork_widget.dart';

/// Favorites screen styled with neumorphic cards and connected to favorites controller.
class FavoritesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onMenuTap;

  const FavoritesScreen({super.key, this.onMenuTap});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(favoritesControllerProvider.notifier).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(favoritesControllerProvider);
    final playbackRepo = ref.watch(playbackRepositoryProvider);
    final favoritesController = ref.read(favoritesControllerProvider.notifier);
    final isDark = ref.watch(isDarkModeProvider);

    final currentTrack = ref.watch(currentTrackProvider);
    final favorites = favoritesState.favorites;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkBackgroundGradient : AppColors.backgroundGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header with Universal Hamburger Menu
            Padding(
              padding: const EdgeInsets.fromLTRB(18.0, 10.0, 20.0, 12.0),
              child: Row(
                children: [
                  Semantics(
                    label: 'Menu',
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: widget.onMenuTap ?? () => Scaffold.maybeOf(context)?.openDrawer(),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: CustomIcons.menu(
                          size: 22.0,
                          color: isDark ? AppColors.darkIcon : AppColors.iconNavy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Favorites',
                      style: AppTypography.trackTitle.copyWith(
                        fontSize: 22.0,
                        color: isDark ? AppColors.darkText : AppColors.textNavy,
                      ),
                    ),
                  ),
                  Text(
                    '${favorites.length} Favorite${favorites.length == 1 ? '' : 's'}',
                    style: AppTypography.artistName.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      fontSize: 13.0,
                    ),
                  ),
                ],
              ),
            ),

            // Favorites List
            Expanded(
              child: favorites.isEmpty && !favoritesState.isLoading
                  ? Center(
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
                              child: CustomIcons.heart(
                                size: 28.0,
                                color: AppColors.primaryPurple,
                                isFilled: false,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'No Favorites Yet',
                            style: AppTypography.headerTitle.copyWith(
                              fontSize: 17.0,
                              color: isDark ? AppColors.darkText : AppColors.textNavy,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            'Tap the heart on any song to add it here',
                            style: AppTypography.artistName.copyWith(
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
                      itemCount: favorites.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                      itemBuilder: (context, index) {
                        final track = favorites[index];
                        final isCurrent = currentTrack?.id == track.id;

                        return Container(
                          decoration: NeumorphicDecorations.elevatedCard(
                            borderRadius: AppSpacing.roundedArtwork,
                            isDark: isDark,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
                                // Independent Heart Button
                                GestureDetector(
                                  onTap: () => favoritesController.toggleFavorite(track),
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: CustomIcons.heart(
                                      size: 20.0,
                                      color: AppColors.favoriteRed,
                                      isFilled: true,
                                    ),
                                  ),
                                ),

                                // Independent 3-dots Menu Button
                                GestureDetector(
                                  onTap: () {
                                    SongContextMenu.show(
                                      context: context,
                                      ref: ref,
                                      track: track,
                                      isNowPlayingContext: false,
                                      isFavorite: true,
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
                            onTap: () => playbackRepo.setQueue(favorites, initialIndex: index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

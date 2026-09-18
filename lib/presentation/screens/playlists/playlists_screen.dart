import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_spacing.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/core/theme/neumorphic_decorations.dart';
import 'package:sound_foundry/features/playlists/playlist_providers.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/screens/playlists/playlist_detail_screen.dart';
import 'package:sound_foundry/presentation/widgets/create_playlist_dialog.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';

/// Playlists view styled consistently with the neumorphic design system and theme adaptivity.
class PlaylistsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onMenuTap;

  const PlaylistsScreen({super.key, this.onMenuTap});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(playlistControllerProvider.notifier).loadPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playlistState = ref.watch(playlistControllerProvider);
    final isDark = ref.watch(isDarkModeProvider);

    final playlists = playlistState.playlists;

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
                      'Playlists',
                      style: AppTypography.trackTitle.copyWith(
                        fontSize: 22.0,
                        color: isDark ? AppColors.darkText : AppColors.textNavy,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Create Playlist Action Button
                      GestureDetector(
                        onTap: () => CreatePlaylistDialog.show(context: context, ref: ref),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 16.0, color: AppColors.primaryPurple),
                              const SizedBox(width: 4.0),
                              Text(
                                'New',
                                style: AppTypography.headerTitle.copyWith(
                                  fontSize: 13.0,
                                  color: AppColors.primaryPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        '${playlists.length} Playlist${playlists.length == 1 ? '' : 's'}',
                        style: AppTypography.artistName.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Playlist Grid
            Expanded(
              child: playlists.isEmpty && !playlistState.isLoading
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
                              child: CustomIcons.playlistGrid(
                                size: 28.0,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'No Playlists Yet',
                            style: AppTypography.headerTitle.copyWith(
                              fontSize: 18.0,
                              color: isDark ? AppColors.darkText : AppColors.textNavy,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            'Create your first playlist to organize your music',
                            style: AppTypography.artistName.copyWith(
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            ),
                            icon: const Icon(Icons.add, size: 18.0),
                            label: const Text('Create Playlist', style: TextStyle(fontWeight: FontWeight.w600)),
                            onPressed: () => CreatePlaylistDialog.show(context: context, ref: ref),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return GestureDetector(
                          onTap: () {
                            PlaylistDetailScreen.show(
                              context,
                              playlistId: playlist.id,
                              initialPlaylist: playlist,
                            );
                          },
                          child: Container(
                            decoration: NeumorphicDecorations.elevatedCard(
                              borderRadius: AppSpacing.roundedArtwork,
                              isDark: isDark,
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 48.0,
                                  height: 48.0,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                                    borderRadius: BorderRadius.circular(14.0),
                                  ),
                                  child: Center(
                                    child: CustomIcons.playlistGrid(
                                      size: 22.0,
                                      color: AppColors.primaryPurple,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      playlist.name,
                                      style: AppTypography.headerTitle.copyWith(
                                        fontSize: 16.0,
                                        color: isDark ? AppColors.darkText : AppColors.textNavy,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      '${playlist.trackCount} ${playlist.trackCount == 1 ? 'Track' : 'Tracks'}',
                                      style: AppTypography.artistName.copyWith(
                                        fontSize: 13.0,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_spacing.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/core/theme/neumorphic_decorations.dart';
import 'package:sound_foundry/domain/entities/app_mode.dart';
import 'package:sound_foundry/features/playlists/playlist_providers.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/screens/playlists/playlist_detail_screen.dart';
import 'package:sound_foundry/presentation/widgets/create_playlist_dialog.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';
import 'package:sound_foundry/presentation/widgets/track_artwork_widget.dart';

/// Playlists view displaying clearly differentiated sections for User-Created Playlists
/// and Online Discovery Collections (1990s Hindi Hits, Romantic, Pop, etc.).
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
    final settings = ref.watch(settingsControllerProvider);
    final isOnline = settings.appMode == AppMode.online;
    final isDark = ref.watch(isDarkModeProvider);

    final userPlaylists = playlistState.playlists;
    final discoveryAsync = ref.watch(discoveryPlaylistsProvider);

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
              padding: const EdgeInsets.fromLTRB(18.0, 10.0, 20.0, 10.0),
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
                        '${userPlaylists.length} Local',
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

            // Scrollable Content
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Section: Online Discovery Collections
                  if (isOnline) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 8.0),
                        child: Row(
                          children: [
                            Text(
                              'Discovery Collections',
                              style: AppTypography.headerTitle.copyWith(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkText : AppColors.textNavy,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: const Text(
                                'JioSaavn',
                                style: TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: discoveryAsync.when(
                        loading: () => const SizedBox(
                          height: 140.0,
                          child: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (discovery) => SizedBox(
                          height: 165.0,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            itemCount: discovery.length,
                            itemBuilder: (context, idx) {
                              final pl = discovery[idx];
                              return InkWell(
                                borderRadius: BorderRadius.circular(14.0),
                                onTap: () => PlaylistDetailScreen.show(context, playlistId: pl.id, initialPlaylist: pl),
                                child: Container(
                                  width: 125.0,
                                  margin: const EdgeInsets.symmetric(horizontal: 6.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TrackArtworkWidget(
                                        artworkUri: pl.artworkUri,
                                        size: 115.0,
                                        borderRadius: 14.0,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: 6.0),
                                      Text(
                                        pl.name,
                                        style: TextStyle(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkText : AppColors.textNavy,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${pl.trackCount} Songs',
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
                    ),
                  ],

                  // Section: Your Local Playlists
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 18.0, 24.0, 8.0),
                      child: Text(
                        'Your Playlists',
                        style: AppTypography.headerTitle.copyWith(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.textNavy,
                        ),
                      ),
                    ),
                  ),

                  if (userPlaylists.isEmpty && !playlistState.isLoading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 56.0,
                                height: 56.0,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.playlist_add_rounded, size: 28.0, color: AppColors.primaryPurple),
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                'No Local Playlists',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkText : AppColors.textNavy,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                'Tap "+ New" above to create a personal playlist.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 100.0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14.0,
                          mainAxisSpacing: 14.0,
                          childAspectRatio: 1.05,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final playlist = userPlaylists[index];
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
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 44.0,
                                      height: 44.0,
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      child: Center(
                                        child: CustomIcons.playlistGrid(
                                          size: 20.0,
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
                                            fontSize: 15.0,
                                            color: isDark ? AppColors.darkText : AppColors.textNavy,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3.0),
                                        Text(
                                          '${playlist.trackCount} ${playlist.trackCount == 1 ? 'Track' : 'Tracks'}',
                                          style: AppTypography.artistName.copyWith(
                                            fontSize: 12.0,
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
                          childCount: userPlaylists.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

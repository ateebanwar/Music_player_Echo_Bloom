import 'package:flutter/material.dart';
import 'package:sound_foundry/core/extensions/duration_extensions.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';
import 'package:sound_foundry/presentation/widgets/neumorphic_container.dart';

/// Renders song title, artist, progress timestamp, and elevated favorite button with theme adaptability.
class TrackInfoSection extends StatelessWidget {
  final Track track;
  final Duration position;
  final Duration duration;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final bool? isDark;

  const TrackInfoSection({
    super.key,
    required this.track,
    required this.position,
    required this.duration,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Song metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Track Title
                Text(
                  track.title,
                  style: AppTypography.trackTitle.copyWith(
                    color: effectiveIsDark ? AppColors.darkText : AppColors.textNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3.0),

                // Artist Name
                Text(
                  track.artist,
                  style: AppTypography.artistName.copyWith(
                    color: effectiveIsDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6.0),

                // Time progress "1:32 / 3:46"
                Text(
                  '${position.toFormattedTimeString()} / ${duration.toFormattedTimeString()}',
                  style: AppTypography.timeProgress.copyWith(
                    color: effectiveIsDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16.0),

          // Right: Raised Neumorphic Favorite Heart Button
          NeumorphicContainer(
            width: 44.0,
            height: 44.0,
            shape: BoxShape.circle,
            isDark: effectiveIsDark,
            onTap: onFavoriteToggle,
            child: Center(
              child: CustomIcons.heart(
                size: 22.0,
                color: isFavorite
                    ? AppColors.favoriteRed
                    : (effectiveIsDark ? AppColors.darkTextMuted : AppColors.iconNavy.withValues(alpha: 0.6)),
                isFilled: isFavorite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

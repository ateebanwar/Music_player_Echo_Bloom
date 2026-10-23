import 'package:flutter/material.dart' hide RepeatMode;
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_spacing.dart';
import 'package:sound_foundry/core/theme/neumorphic_decorations.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/presentation/widgets/circular_seeker.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';
import 'package:sound_foundry/presentation/widgets/neumorphic_container.dart';

/// Renders the bottom elevated playback card containing Shuffle, Previous,
/// Circular Seeker with Center Play/Pause, Next, and Repeat controls.
class PlaybackControlPanel extends StatelessWidget {
  final PlaybackState playbackState;
  final Duration? currentPosition;
  final VoidCallback? onPlayPauseTap;
  final VoidCallback? onPreviousTap;
  final VoidCallback? onNextTap;
  final VoidCallback? onShuffleTap;
  final VoidCallback? onRepeatTap;
  final ValueChanged<Duration>? onSeek;
  final bool? isDark;

  const PlaybackControlPanel({
    super.key,
    required this.playbackState,
    this.currentPosition,
    this.onPlayPauseTap,
    this.onPreviousTap,
    this.onNextTap,
    this.onShuffleTap,
    this.onRepeatTap,
    this.onSeek,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final isPlaying = playbackState.isPlaying;
    final isShuffled = playbackState.isShuffleEnabled;
    final isRepeatActive = playbackState.repeatMode != RepeatMode.off;
    final effectivePosition = currentPosition ?? playbackState.position;

    final baseIconColor = effectiveIsDark ? AppColors.darkIcon : AppColors.iconNavy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        height: 142.0,
        decoration: NeumorphicDecorations.elevatedCard(
          borderRadius: AppSpacing.roundedControlPanel,
          isDark: effectiveIsDark,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Shuffle Button
            NeumorphicContainer(
              width: 44.0,
              height: 44.0,
              shape: BoxShape.circle,
              isDark: effectiveIsDark,
              onTap: onShuffleTap,
              child: Center(
                child: CustomIcons.shuffle(
                  size: 18.0,
                  color: isShuffled ? AppColors.primaryPurple : (effectiveIsDark ? AppColors.darkTextMuted : AppColors.iconNavy),
                ),
              ),
            ),

            // 2. Previous Button
            Semantics(
              label: 'Previous track',
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onPreviousTap,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: CustomIcons.skipPrevious(size: 20.0, color: baseIconColor),
                ),
              ),
            ),

            // 3. Center Circular Seeker with Inner Play/Pause Button
            CircularSeeker(
              position: effectivePosition,
              duration: playbackState.duration,
              size: 108.44,
              strokeWidth: 15.5,
              onSeek: onSeek,
              onPlayPauseTap: onPlayPauseTap,
              centerChild: NeumorphicContainer(
                shape: BoxShape.circle,
                elevation: 1.1,
                isDark: effectiveIsDark,
                child: Center(
                  child: isPlaying
                      ? CustomIcons.pause(width: 15.0, height: 18.0, color: baseIconColor)
                      : CustomIcons.play(size: 20.0, color: baseIconColor),
                ),
              ),
            ),

            // 4. Next Button
            Semantics(
              label: 'Next track',
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onNextTap,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: CustomIcons.skipNext(size: 20.0, color: baseIconColor),
                ),
              ),
            ),

            // 5. Repeat / Loop Button
            NeumorphicContainer(
              width: 44.0,
              height: 44.0,
              shape: BoxShape.circle,
              isDark: effectiveIsDark,
              onTap: onRepeatTap,
              child: Center(
                child: CustomIcons.repeat(
                  size: 19.0,
                  color: isRepeatActive ? AppColors.primaryPurple : (effectiveIsDark ? AppColors.darkTextMuted : AppColors.iconNavy),
                  isRepeatOne: playbackState.repeatMode == RepeatMode.one,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sound_foundry/core/theme/neumorphic_decorations.dart';
import 'package:sound_foundry/presentation/widgets/track_artwork_widget.dart';

/// Renders the large square album artwork with soft neumorphic depth matching active theme.
class AlbumArtworkView extends StatelessWidget {
  final String? artworkUri;
  final double size;
  final bool? isDark;

  const AlbumArtworkView({
    super.key,
    this.artworkUri,
    this.size = 312.0,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: NeumorphicDecorations.artworkContainer(isDark: effectiveIsDark),
        child: TrackArtworkWidget(
          artworkUri: artworkUri,
          size: size,
          borderRadius: 28.0,
          iconSize: 64.0,
        ),
      ),
    );
  }
}

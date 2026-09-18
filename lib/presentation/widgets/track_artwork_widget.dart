import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';

/// Renders extracted local file artwork, bundled asset artwork, or smooth neumorphic fallback.
class TrackArtworkWidget extends StatelessWidget {
  final String? artworkUri;
  final double size;
  final double borderRadius;
  final IconData? fallbackIcon;
  final double iconSize;

  const TrackArtworkWidget({
    super.key,
    required this.artworkUri,
    this.size = 46.0,
    this.borderRadius = 12.0,
    this.fallbackIcon,
    this.iconSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildImage(context),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final uri = artworkUri;
    if (uri == null || uri.isEmpty) {
      return _buildFallback();
    }

    final isNetworkOrContentUri = uri.startsWith('http://') ||
        uri.startsWith('https://') ||
        uri.startsWith('content://');
    if (isNetworkOrContentUri) {
      return Image.network(
        uri,
        fit: BoxFit.cover,
        cacheWidth: (size * 2).toInt().clamp(64, 1024),
        cacheHeight: (size * 2).toInt().clamp(64, 1024),
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    final isFilePath = uri.startsWith('/') || uri.startsWith('file://') || uri.contains(r':\');
    if (isFilePath) {
      if (!kIsWeb) {
        final cleanPath = uri.replaceFirst('file://', '');
        final file = File(cleanPath);
        return Image.file(
          file,
          fit: BoxFit.cover,
          cacheWidth: (size * 2).toInt().clamp(64, 1024),
          cacheHeight: (size * 2).toInt().clamp(64, 1024),
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      }
      return _buildFallback();
    }

    return Image.asset(
      uri,
      fit: BoxFit.cover,
      cacheWidth: (size * 2).toInt().clamp(64, 1024),
      cacheHeight: (size * 2).toInt().clamp(64, 1024),
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF176B5A), // Deep botanical teal
            Color(0xFF65B995), // Primary Echo Green
            Color(0xFF75C9A3), // Primary accent mint
          ],
        ),
      ),
      child: Center(
        child: CustomIcons.musicNote(
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}

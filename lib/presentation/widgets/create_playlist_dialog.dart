import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/features/playlists/playlist_providers.dart';

/// Modal dialog for creating a new playlist, with optional initial track association and theme adaptivity.
class CreatePlaylistDialog extends StatefulWidget {
  final WidgetRef ref;
  final Track? initialTrack;

  const CreatePlaylistDialog({
    super.key,
    required this.ref,
    this.initialTrack,
  });

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    Track? initialTrack,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CreatePlaylistDialog(
        ref: ref,
        initialTrack: initialTrack,
      ),
    );
  }

  @override
  State<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<CreatePlaylistDialog> {
  late final TextEditingController _textController;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_isSubmitting) return;

    final name = _textController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a playlist name';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final created = await widget.ref
        .read(playlistControllerProvider.notifier)
        .createPlaylist(name, initialTrack: widget.initialTrack);

    if (!mounted) return;

    if (created != null) {
      Navigator.of(context).pop();
      final feedback = widget.initialTrack != null
          ? 'Added "${widget.initialTrack!.title}" to $name'
          : 'Playlist "$name" created';

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedback, style: const TextStyle(color: Colors.white, fontSize: 13.0)),
          backgroundColor: AppColors.darkCapsule,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      );
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Could not create playlist. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 20.0),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.35),
              blurRadius: 24.0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Playlist',
              style: AppTypography.trackTitle.copyWith(
                fontSize: 20.0,
                color: isDark ? AppColors.darkText : AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              widget.initialTrack != null
                  ? 'Create a playlist and add "${widget.initialTrack!.title}"'
                  : 'Enter a name for your new playlist',
              style: AppTypography.artistName.copyWith(
                fontSize: 13.0,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 18.0),

            // Input field
            TextField(
              controller: _textController,
              autofocus: true,
              style: AppTypography.headerTitle.copyWith(
                fontSize: 15.0,
                color: isDark ? AppColors.darkText : AppColors.textNavy,
              ),
              decoration: InputDecoration(
                hintText: 'Playlist name',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  fontSize: 14.0,
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                errorText: _errorMessage,
                errorStyle: const TextStyle(fontSize: 12.0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _handleCreate(),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
            const SizedBox(height: 22.0),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      fontSize: 14.0,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  onPressed: _isSubmitting ? null : _handleCreate,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                        )
                      : const Text('Create', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.0)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

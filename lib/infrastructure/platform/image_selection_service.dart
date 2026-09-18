import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Lightweight, local-only image selection and optimization service.
abstract final class ImageSelectionService {
  static final ImagePicker _picker = ImagePicker();

  /// Prompts user to pick a photo from local device storage, compresses it, and saves locally.
  static Future<String?> pickAndSaveProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      if (kIsWeb) {
        return pickedFile.path;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory(p.join(appDir.path, 'profile_images'));
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File(p.join(profileDir.path, fileName));
      await File(pickedFile.path).copy(savedFile.path);

      return savedFile.path;
    } catch (_) {
      return null;
    }
  }
}

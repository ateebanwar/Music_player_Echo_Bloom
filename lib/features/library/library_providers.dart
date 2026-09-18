import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/features/library/library_controller.dart';
import 'package:sound_foundry/features/library/library_state.dart';

/// Provider for the [LibraryController] and [LibraryState].
final libraryControllerProvider =
    StateNotifierProvider<LibraryController, LibraryState>((ref) {
  final trackRepository = ref.watch(trackRepositoryProvider);
  final mediaScanner = ref.watch(mediaScannerProvider);
  return LibraryController(trackRepository, mediaScanner: mediaScanner);
});

/// Stream provider for tracking library size changes.
final libraryTrackCountStreamProvider = StreamProvider<int>((ref) {
  final trackRepository = ref.watch(trackRepositoryProvider);
  return trackRepository.watchTrackCount();
});

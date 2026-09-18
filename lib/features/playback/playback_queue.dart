import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Immutable queue model managing original and shuffled track order.
class PlaybackQueue extends Equatable {
  final List<Track> originalList;
  final List<Track> currentList;
  final int currentIndex;
  final RepeatMode repeatMode;
  final bool isShuffled;

  const PlaybackQueue({
    this.originalList = const [],
    this.currentList = const [],
    this.currentIndex = -1,
    this.repeatMode = RepeatMode.off,
    this.isShuffled = false,
  });

  Track? get currentTrack =>
      (currentIndex >= 0 && currentIndex < currentList.length) ? currentList[currentIndex] : null;

  bool get isEmpty => currentList.isEmpty;
  bool get hasNext => currentIndex < currentList.length - 1 || repeatMode != RepeatMode.off;
  bool get hasPrevious => currentIndex > 0 || repeatMode != RepeatMode.off;

  PlaybackQueue setTracks(List<Track> tracks, {int initialIndex = 0}) {
    final safeIndex = tracks.isEmpty ? -1 : initialIndex.clamp(0, tracks.length - 1);
    return PlaybackQueue(
      originalList: List.unmodifiable(tracks),
      currentList: List.unmodifiable(tracks),
      currentIndex: safeIndex,
      repeatMode: repeatMode,
      isShuffled: false,
    );
  }

  PlaybackQueue addTrack(Track track) {
    if (isEmpty) {
      return setTracks([track], initialIndex: 0);
    }
    final newOriginal = [...originalList, track];
    final newCurrent = [...currentList, track];
    return copyWith(
      originalList: List.unmodifiable(newOriginal),
      currentList: List.unmodifiable(newCurrent),
    );
  }

  PlaybackQueue insertNext(Track track) {
    if (isEmpty) {
      return setTracks([track], initialIndex: 0);
    }
    final insertIdx = (currentIndex + 1).clamp(0, currentList.length);
    final newCurrent = List<Track>.from(currentList)..insert(insertIdx, track);
    final newOriginal = List<Track>.from(originalList)..insert(insertIdx, track);
    return copyWith(
      originalList: List.unmodifiable(newOriginal),
      currentList: List.unmodifiable(newCurrent),
    );
  }

  PlaybackQueue next() {
    if (isEmpty) return this;

    if (currentIndex < currentList.length - 1) {
      return copyWith(currentIndex: currentIndex + 1);
    } else if (repeatMode != RepeatMode.off) {
      return copyWith(currentIndex: 0);
    }

    return this;
  }

  PlaybackQueue previous() {
    if (isEmpty) return this;

    if (currentIndex > 0) {
      return copyWith(currentIndex: currentIndex - 1);
    } else if (repeatMode != RepeatMode.off) {
      return copyWith(currentIndex: currentList.length - 1);
    }

    return this;
  }

  PlaybackQueue toggleShuffle([Random? random]) {
    if (isEmpty) return this;

    if (isShuffled) {
      // Restore original order
      final currentItem = currentTrack;
      final restoredIndex = currentItem != null ? originalList.indexOf(currentItem) : 0;
      return PlaybackQueue(
        originalList: originalList,
        currentList: originalList,
        currentIndex: restoredIndex >= 0 ? restoredIndex : 0,
        repeatMode: repeatMode,
        isShuffled: false,
      );
    } else {
      // Shuffle, keeping current track at current index or front
      final currentItem = currentTrack;
      final shuffled = List<Track>.from(originalList)..shuffle(random);
      if (currentItem != null) {
        shuffled.remove(currentItem);
        shuffled.insert(0, currentItem);
      }
      return PlaybackQueue(
        originalList: originalList,
        currentList: List.unmodifiable(shuffled),
        currentIndex: 0,
        repeatMode: repeatMode,
        isShuffled: true,
      );
    }
  }

  PlaybackQueue setRepeatMode(RepeatMode mode) {
    return copyWith(repeatMode: mode);
  }

  PlaybackQueue copyWith({
    List<Track>? originalList,
    List<Track>? currentList,
    int? currentIndex,
    RepeatMode? repeatMode,
    bool? isShuffled,
  }) {
    return PlaybackQueue(
      originalList: originalList ?? this.originalList,
      currentList: currentList ?? this.currentList,
      currentIndex: currentIndex ?? this.currentIndex,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffled: isShuffled ?? this.isShuffled,
    );
  }

  @override
  List<Object?> get props => [originalList, currentList, currentIndex, repeatMode, isShuffled];
}

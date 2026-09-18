/// Utility extensions for [Duration].
extension DurationFormatting on Duration {
  /// Formats duration as mm:ss or hh:mm:ss.
  String toFormattedTimeString() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutesStr:$secondsStr';
    }
    return '$minutesStr:$secondsStr';
  }
}

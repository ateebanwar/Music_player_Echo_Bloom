/// Audio focus interaction modes.
enum AudioFocusState {
  focused,
  ducked,
  lost,
}

/// Abstract contract for handling platform audio focus (incoming calls,
/// other media apps, navigation announcements).
abstract class AudioFocusManager {
  Stream<AudioFocusState> get focusStream;
  Future<bool> requestFocus();
  Future<void> abandonFocus();
}

/// Headless/Default implementation of [AudioFocusManager].
class DefaultAudioFocusManager implements AudioFocusManager {
  @override
  Stream<AudioFocusState> get focusStream => const Stream.empty();

  @override
  Future<bool> requestFocus() async => true;

  @override
  Future<void> abandonFocus() async {}
}

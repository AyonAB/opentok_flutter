import 'package:opentok_flutter/opentok.dart';

/// This class takes the OpenTok config and connects with platform side.
///
/// This class also handles platform callbacks.
class OpenTokFlutter implements OpenTokPlatformApi {
  final OpenTokConfig _config;
  final OpenTokHostApi _openTokHostApi = OpenTokHostApi();

  /// A callback to notify client about new connection state.
  /// returns [ConnectionState] enum & an optional error description.
  final void Function(ConnectionStateCallback)? onUpdate;

  /// Create [OpenTokFlutter] class with necessary config values and register a callback for connection status update.
  /// [OpenTokConfig] contains API key, Session Id & Token.
  OpenTokFlutter(OpenTokConfig config, {this.onUpdate}) : _config = config {
    OpenTokPlatformApi.setup(this);
  }

  /// Returns new state from platform side.
  @override
  void onStateUpdate(ConnectionStateCallback connectionState) => onUpdate?.call(connectionState);

  /// Initiates a opentok session with the given [OpenTokConfig] value.
  Future<void> initSession() async {
    try {
      return await _openTokHostApi.initSession(_config);
    } catch (e) {
      rethrow;
    }
  }

  /// Ends the connected opentok session.
  Future<void> endSession() async {
    try {
      return await _openTokHostApi.endSession();
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle/Swap between front & back camera.
  Future<void> toggleCamera() async {
    try {
      return await _openTokHostApi.toggleCamera();
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle microphone on/off.
  Future<void> toggleAudio(bool enabled) async {
    try {
      return await _openTokHostApi.toggleAudio(enabled);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggles video on/off.
  Future<void> toggleVideo(bool enabled) async {
    try {
      return await _openTokHostApi.toggleVideo(enabled);
    } catch (e) {
      rethrow;
    }
  }

  /// Pauses the session including camera & audio.
  ///
  /// Invoke this method whenever your app goes to background if there is an active session.
  Future<void> onPause() async {
    try {
      return await _openTokHostApi.onPause();
    } catch (e) {
      rethrow;
    }
  }

  /// Resumes the session.
  ///
  /// Invoke this method whenever your app comes back to foreground if there is an active session.
  Future<void> onResume() async {
    try {
      return await _openTokHostApi.onResume();
    } catch (e) {
      rethrow;
    }
  }

  /// Forcefully releases hardware resources (e.g. camera, microphone etc.) from using.
  /// 
  /// Use it after the session is over if needed.
  Future<void> onStop() async {
    try {
      return await _openTokHostApi.onStop();
    } catch (e) {
      rethrow;
    }
  }
}

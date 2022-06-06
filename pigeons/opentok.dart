import 'package:pigeon/pigeon.dart';

enum ConnectionState { loggedOut, loggedIn, wait, onCall, error }

class ConnectionStateCallback {
  final ConnectionState state;

  const ConnectionStateCallback(this.state);
}

class OpenTokConfig {
  final String apiKey;
  final String sessionId;
  final String token;

  const OpenTokConfig({
    required this.apiKey,
    required this.sessionId,
    required this.token,
  });
}

@HostApi()
abstract class OpenTokHostApi {
  void initSession(OpenTokConfig config);

  void endSession();

  void toggleCamera();

  void toggleAudio(bool enabled);

  void toggleVideo(bool enabled);
}

@FlutterApi()
abstract class OpenTokPlatformApi {
  void onStateUpdate(ConnectionStateCallback connectionState);
}

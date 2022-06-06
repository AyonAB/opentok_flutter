import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:opentok_flutter/opentok.dart' as open_tok;
import 'package:opentok_flutter/opentok_flutter.dart';

/// The connection state, audio enabled & video enabled settings of a [OpenTokController]
@immutable
class OpenTokValue {
  /// Current connection state of the session.
  /// Default to [open_tok.ConnectionState.loggedOut].
  final open_tok.ConnectionState state;

  /// Whether publisher audio (microphone) is enabled or not.
  final bool audioEnabled;

  /// Whether publisher video is enabled or not.
  final bool videoEnabled;

  /// Constructs a [OpenTokValue] with the given values.
  ///
  /// [open_tok.ConnectionState] is [open_tok.ConnectionState.loggedOut] by default.
  /// [audioEnabled] & [videoEnabled] are default to true.
  const OpenTokValue({
    this.state = open_tok.ConnectionState.loggedOut,
    this.audioEnabled = true,
    this.videoEnabled = true,
  });

  /// Returns a new instance that has the same values as this current instance,
  /// except for any overrides passed in as arguments to [copyWith].
  OpenTokValue copyWith({open_tok.ConnectionState? state, bool? audioEnabled, bool? videoEnabled}) {
    return OpenTokValue(
      state: state ?? this.state,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      videoEnabled: videoEnabled ?? this.videoEnabled,
    );
  }
}

/// Controls OpenTok video platform and provides updates when the state is changing.
///
/// The publisher/subscriber video is displayed in a Flutter app by creating a [OpenTokView] widget.
class OpenTokController extends ValueNotifier<OpenTokValue> {
  OpenTokFlutter? _openTokFlutter;

  /// Constructs a [OpenTokController].
  OpenTokController() : super(const OpenTokValue());

  /// This method gets called whenever the OpenTok session state changes.
  ///
  /// The new state value is also passed as a parameter.
  void onStateUpdate(open_tok.ConnectionState state) async {
    value = value.copyWith(state: state);
  }

  /// Initiates a OpenTok session with the given [open_tok.OpenTokConfig] values.
  void initSession(open_tok.OpenTokConfig config) async {
    _openTokFlutter = OpenTokFlutter(config, onUpdate: onStateUpdate);
    await _openTokFlutter?.initSession();
  }

  /// Ends the OpenTok session.
  void endSession() async {
    await _openTokFlutter?.endSession();
  }

  /// Toggle/Switch between front/back camera if available.
  void toggleCamera() async {
    await _openTokFlutter?.toggleCamera();
  }

  /// Enable/Disable audio (Microphone) for current OpenTok session.
  void toggleAudio(bool enabled) async {
    value = value.copyWith(audioEnabled: enabled);
    await _openTokFlutter?.toggleAudio(enabled);
  }

  /// Enable/Disable video for current OpenTok session.
  void toggleVideo(bool enabled) async {
    value = value.copyWith(videoEnabled: enabled);
    await _openTokFlutter?.toggleVideo(enabled);
  }
}

/// Widget that displays the OpenTok video controlled by [controller].
class OpenTokView extends StatefulWidget {
  /// Constructs an instance of [OpenTokView] with the given [controller].
  const OpenTokView({Key? key, required this.controller}) : super(key: key);

  /// The [OpenTokController] responsible for the OpenTok video being rendered in this widget.
  final OpenTokController controller;

  @override
  State<OpenTokView> createState() => _OpenTokViewState();
}

class _OpenTokViewState extends State<OpenTokView> {
  /// This is used in the platform side to register the view.
  static const String viewType = 'opentok-video-container';

  @override
  void initState() {
    widget.controller.addListener(_listener);
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    print("Connection State: ${widget.controller.value.state.name}");
    print("Audio Enabled: ${widget.controller.value.audioEnabled.toString()}");
    print("Video Enabled: ${widget.controller.value.videoEnabled.toString()}");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (defaultTargetPlatform == TargetPlatform.android)
          const AndroidOpenTokVideoView(viewType: viewType)
        else if (defaultTargetPlatform == TargetPlatform.iOS)
          const IOSOpenTokVideoView(viewType: viewType)
        else
          throw UnsupportedError('Unsupported platform view'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: widget.controller.endSession,
              icon: const Icon(Icons.call_end),
              color: Colors.red,
            ),
            IconButton(
              onPressed: widget.controller.toggleCamera,
              icon: const Icon(Icons.cameraswitch),
            ),
            IconButton(
              onPressed: () => widget.controller.toggleAudio(!widget.controller.value.audioEnabled),
              icon: widget.controller.value.audioEnabled
                  ? const Icon(Icons.mic)
                  : const Icon(Icons.mic_off),
            ),
            IconButton(
              onPressed: () => widget.controller.toggleVideo(!widget.controller.value.videoEnabled),
              icon: widget.controller.value.videoEnabled
                  ? const Icon(Icons.videocam)
                  : const Icon(Icons.videocam_off),
            ),
          ],
        ),
      ],
    );
  }
}

/// A widget to host native android view for OpenTok.
class AndroidOpenTokVideoView extends StatelessWidget {
  /// This is used in the platform side to register the view.
  final String viewType;

  /// Constructs an [AndroidOpenTokVideoView] instance with the given [viewType].
  const AndroidOpenTokVideoView({Key? key, required this.viewType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: PlatformViewLink(
        viewType: viewType,
        surfaceFactory: (BuildContext context, PlatformViewController controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: {},
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () => params.onFocusChanged(true),
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      ),
    );
  }
}

/// A widget to host native iOS view for OpenTok.
class IOSOpenTokVideoView extends StatelessWidget {
  /// This is used in the platform side to register the view.
  final String viewType;

  /// Constructs an [IOSOpenTokVideoView] instance with the given [viewType].
  const IOSOpenTokVideoView({Key? key, required this.viewType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: const {},
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:opentok_flutter/opentok.dart';
import 'package:opentok_flutter/opentok_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late OpenTokConfig _config;
  late OpenTokController _controller;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    _config = OpenTokConfig(
      apiKey: "",
      sessionId: "",
      token: "",
    );

    _controller = OpenTokController();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.initSession(_config);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: OpenTokView(
          controller: _controller,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _controller.endSession,
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<CircleBorder>(const CircleBorder()),
                    padding:
                        MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(8.0)),
                    elevation: MaterialStateProperty.all<double>(8.0),
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                  ),
                  child: const Icon(Icons.call_end),
                ),
                ElevatedButton(
                  onPressed: _controller.toggleCamera,
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<CircleBorder>(const CircleBorder()),
                    padding:
                        MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(8.0)),
                    elevation: MaterialStateProperty.all<double>(8.0),
                  ),
                  child: const Icon(Icons.cameraswitch),
                ),
                ElevatedButton(
                  onPressed: () => _controller.toggleAudio(_controller.value.audioEnabled),
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<CircleBorder>(const CircleBorder()),
                    padding:
                        MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(8.0)),
                    elevation: MaterialStateProperty.all<double>(8.0),
                  ),
                  child: _controller.value.audioEnabled
                      ? const Icon(Icons.mic)
                      : const Icon(Icons.mic_off),
                ),
                ElevatedButton(
                  onPressed: () => _controller.toggleVideo(!_controller.value.videoEnabled),
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<CircleBorder>(const CircleBorder()),
                    padding:
                        MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(8.0)),
                    elevation: MaterialStateProperty.all<double>(8.0),
                  ),
                  child: _controller.value.videoEnabled
                      ? const Icon(Icons.videocam)
                      : const Icon(Icons.videocam_off),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

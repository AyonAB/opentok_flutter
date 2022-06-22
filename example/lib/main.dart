import 'package:flutter/material.dart';
import 'dart:async';

import 'package:opentok_flutter/opentok.dart';
import 'package:opentok_flutter/opentok_view.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
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
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();
      final isGranted = statuses[Permission.camera] == PermissionStatus.granted &&
          statuses[Permission.microphone] == PermissionStatus.granted;
      if (isGranted) {
        _controller.initSession(_config);
      } else {
        debugPrint("Camera or Microphone permission or both denied by the user!");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
        actions: [
          IconButton(
            onPressed: () => _controller.initSession(_config),
            icon: const Icon(Icons.video_call_rounded),
          )
        ],
      ),
      body: SizedBox(
        //height: MediaQuery.of(context).size.height * 0.8,
        child: OpenTokView(
          controller: _controller,
          onEndButtonTap: () => _controller.endSession(),
          onCameraButtonTap: () => _controller.toggleCamera(),
          onMicButtonTap: (isEnabled) => _controller.toggleAudio(!isEnabled),
          onVideoButtonTap: (isEnabled) => _controller.toggleVideo(!isEnabled),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:opentok_flutter/opentok.dart';
import 'package:opentok_flutter/opentok_view.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.initSession(_config);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: SizedBox(
        //height: MediaQuery.of(context).size.height,
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

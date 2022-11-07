#import "OpentokFlutterPlugin.h"
#import <OpenTok/OpenTok.h>
#import "OpenTok.h"
#import "Video.h"

@interface OpentokFlutterPlugin () <FLTOpenTokHostApi>
@property FLTOpenTokPlatformApi *opentokFlutterApi;
@end

@interface OpentokFlutterPlugin () <OTSessionDelegate, OTSubscriberDelegate, OTPublisherDelegate>
@property (nonatomic) OTSession *session;
@property (nonatomic) OTPublisher *publisher;
@property (nonatomic) OTSubscriber *subscriber;
@end

@implementation OpentokFlutterPlugin
OpentokVideoFactory *factory;

// MARK: Plugin initialization
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  OpentokFlutterPlugin *instance = [[OpentokFlutterPlugin alloc] init];
  FLTOpenTokHostApiSetup(registrar.messenger, instance);
  instance.opentokFlutterApi = [[FLTOpenTokPlatformApi alloc] initWithBinaryMessenger:registrar.messenger];

  factory = [[OpentokVideoFactory alloc] initWithBinaryMessenger:registrar.messenger];
  [registrar registerViewFactory:factory withId:@"opentok-video-container"];
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FLTOpenTokHostApiSetup(registrar.messenger, nil);
  _opentokFlutterApi = nil;
}


// MARK: OpenTok flutter API methods
- (void)initSessionConfig:(nonnull FLTOpenTokConfig *)config error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  OTError *otError = nil;
  [self notifyStateChange:FLTConnectionStateWait errorDescription:nil];

  _session = [[OTSession alloc] initWithApiKey:config.apiKey sessionId:config.sessionId delegate:self];
  [_session connectWithToken:config.token error:&otError];

  if (otError) {
    [self notifyStateChange:FLTConnectionStateError errorDescription:otError.localizedDescription];
  }
}

- (void)endSessionWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  OTError *otError = nil;
  [_session disconnect:&otError];

  if (otError) {
    [self notifyStateChange:FLTConnectionStateError errorDescription:otError.localizedDescription];
  }
}

- (void)toggleCameraWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  if ([_publisher cameraPosition] == AVCaptureDevicePositionFront) {
    [_publisher setCameraPosition:AVCaptureDevicePositionBack];
  } else {
    [_publisher setCameraPosition:AVCaptureDevicePositionFront];
  }
}

- (void)toggleAudioEnabled:(nonnull NSNumber *)enabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  [_publisher setPublishAudio:enabled.boolValue];
}

- (void)toggleVideoEnabled:(nonnull NSNumber *)enabled error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  [_publisher setPublishVideo:enabled.boolValue];
}

- (void)onPauseWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  return;
}

- (void)onResumeWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  return;
}

- (void)onStopWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  return;
}


// MARK: OpenTok session callbacks
- (void)session:(nonnull OTSession *)session didFailWithError:(nonnull OTError *)error {
  [self notifyStateChange:FLTConnectionStateError errorDescription:error.localizedDescription];
}

- (void)session:(nonnull OTSession *)session streamCreated:(nonnull OTStream *)stream {
  if (_subscriber != nil) return;
  // If the incoming stream is the same as publisher then ignore.
  if (stream.streamId == _publisher.stream.streamId) return;

  OTError *otError = nil;
  _subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
  [session subscribe:_subscriber error:&otError];

  if (otError) {
    [self notifyStateChange:FLTConnectionStateError errorDescription:otError.localizedDescription];
  }
}

- (void)session:(nonnull OTSession *)session streamDestroyed:(nonnull OTStream *)stream {
  [self notifyStateChange:FLTConnectionStateLoggedOut errorDescription:nil];

  if ([_subscriber.stream.streamId isEqualToString:stream.streamId]) {
      [self cleanupSubscriber];
  }
}

- (void)session:(OTSession *)session connectionDestroyed:(OTConnection *)connection {
  if ([_subscriber.stream.connection.connectionId isEqualToString:connection.connectionId]) {
    [self cleanupSubscriber];
  }
}

- (void)sessionDidConnect:(nonnull OTSession *)session {
  OTError *otError = nil;
  [self notifyStateChange:FLTConnectionStateLoggedIn errorDescription:nil];

  OTPublisherSettings *settings = [[OTPublisherSettings alloc] init];
  settings.name = [UIDevice currentDevice].name;
  _publisher = [[OTPublisher alloc] initWithDelegate:self settings:settings];

  [_session publish:_publisher error:&otError];

  if (otError) {
    [self notifyStateChange:FLTConnectionStateError errorDescription:otError.localizedDescription];
  }

  if ([_publisher view] == nil) {
    return;
  }

  if ([factory view] == nil) {
    [factory setPublisherView:[_publisher view]];
  } else {
    [[factory view] addPublisherView:[_publisher view]];
  }
}

- (void)sessionDidDisconnect:(nonnull OTSession *)session {
  [self notifyStateChange:FLTConnectionStateLoggedOut errorDescription:nil];
}


// MARK: OpenTok subscriber callbacks
- (void)subscriber:(nonnull OTSubscriberKit *)subscriber didFailWithError:(nonnull OTError *)error {
  [self notifyStateChange:FLTConnectionStateError errorDescription:error.localizedDescription];
}

- (void)subscriberDidConnectToStream:(nonnull OTSubscriberKit *)subscriber {
  if ([_subscriber view] == nil) {
    return;
  }

  [_subscriber setViewScaleBehavior:OTVideoViewScaleBehaviorFit];

  if ([factory view] == nil) {
    [factory setSubscriberView:[_subscriber view]];
  } else {
    [[factory view] addSubscriberView:[_subscriber view]];
  }
}


// MARK: OpenTok publisher callbacks
- (void)publisher:(nonnull OTPublisherKit *)publisher didFailWithError:(nonnull OTError *)error {
  [self notifyStateChange:FLTConnectionStateError errorDescription:error.localizedDescription];
  [self cleanupPublisher];
}

- (void)publisher:(OTPublisherKit *)publisher streamDestroyed:(OTStream *)stream {
  if ([_subscriber.stream.streamId isEqualToString:stream.streamId]) {
    [self cleanupSubscriber];
  }

  [self cleanupPublisher];
}


// MARK: Private methods
- (void)notifyStateChange:(FLTConnectionState)state errorDescription:(nullable NSString *)errorDescription {
  FLTConnectionStateCallback *connectionStateCallback = [FLTConnectionStateCallback makeWithState:state errorDescription:errorDescription];
  [_opentokFlutterApi onStateUpdateConnectionState:connectionStateCallback completion:^(NSError *error) {}];
}

- (void)cleanupPublisher {
  [_publisher.view removeFromSuperview];
  [_session unpublish:_publisher error:nil];
  _publisher = nil;
}

- (void)cleanupSubscriber {
  [_subscriber.view removeFromSuperview];
  [_session unsubscribe:_subscriber error:nil];
  _subscriber = nil;
}

@end

import Flutter
import UIKit
import OpenTok

public class SwiftOpentokFlutterPlugin: NSObject, FlutterPlugin, FLTOpenTokHostApi {

  private static var openTokApi : FLTOpenTokPlatformApi?

  private var session : OTSession?
  var subscriber: OTSubscriber?
  var otError: OTError?
  lazy var publisher: OTPublisher? = {
      let settings = OTPublisherSettings()
      settings.name = UIDevice.current.name
      return OTPublisher(delegate: self, settings: settings)
  }()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger : FlutterBinaryMessenger = registrar.messenger()
    let instance : FLTOpenTokHostApi & NSObjectProtocol = SwiftOpentokFlutterPlugin.init()
    FLTOpenTokHostApiSetup(messenger, instance)
    openTokApi = FLTOpenTokPlatformApi.init(binaryMessenger: messenger)

    let factory = OpentokVideoFactory(messenger: messenger)
    registrar.register(factory, withId: "opentok-video-container")
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    FLTOpenTokHostApiSetup(registrar.messenger(), nil)
    SwiftOpentokFlutterPlugin.openTokApi = nil
  }

  public func initSessionConfig(_ config: FLTOpenTokConfig, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
    notifyStateChange(state: FLTConnectionState.wait)

    session = OTSession(apiKey: config.apiKey, sessionId: config.sessionId, delegate: self)
    session?.connect(withToken: config.token, error: &otError)

    if let error = otError {
      print(error.localizedDescription)
      notifyStateChange(state: FLTConnectionState.error)
    }
  }

  public func endSessionWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
    session?.disconnect(&otError)

    if let error = otError {
      print(error.localizedDescription)
      notifyStateChange(state: FLTConnectionState.error)
    }
  }

  public func toggleCameraWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
    if publisher?.cameraPosition == .front {
        publisher?.cameraPosition = .back
    } else {
        publisher?.cameraPosition = .front
    }
  }

  public func toggleAudioEnabled(_ enabled: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
    publisher?.publishAudio = enabled.boolValue
  }

  public func toggleVideoEnabled(_ enabled: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
    publisher?.publishVideo = enabled.boolValue
  }

  private func notifyStateChange(state : FLTConnectionState) {
    let connectionStateCallback = FLTConnectionStateCallback.make(with: state)
    SwiftOpentokFlutterPlugin.openTokApi?.onStateUpdateConnectionState(connectionStateCallback, completion: { error in })
  }
}

extension SwiftOpentokFlutterPlugin: OTSessionDelegate {
  public func sessionDidConnect(_ session: OTSession) {
    notifyStateChange(state: FLTConnectionState.loggedIn)

    guard let publisher = self.publisher else {
      return
    }

    self.session?.publish(publisher, error: &otError)

    guard let pubView = publisher.view else {
      return
    }

    pubView.frame = CGRect(x: 0, y: 0, width: 200, height: 300)

    if OpentokVideoFactory.view == nil {
        OpentokVideoFactory.viewToAddPub = pubView
    } else {
        OpentokVideoFactory.view?.addPublisherView(pubView)
    }
  }

  public func sessionDidDisconnect(_ session: OTSession) {
    notifyStateChange(state: FLTConnectionState.loggedOut)
  }

  public func session(_ session: OTSession, didFailWithError error: OTError) {
    print(error.localizedDescription)
    notifyStateChange(state: FLTConnectionState.error)
  }

  public func session(_ session: OTSession, streamCreated stream: OTStream) {
    subscriber = OTSubscriber(stream: stream, delegate: self)

    if let subscriber = self.subscriber {
      session.subscribe(subscriber, error: &otError)
    }
  }

  public func session(_ session: OTSession, streamDestroyed stream: OTStream) {
    notifyStateChange(state: FLTConnectionState.loggedOut)
  }
}

extension SwiftOpentokFlutterPlugin: OTSubscriberDelegate {
  public func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
    guard let subView = self.subscriber?.view else {
      return
    }

    subView.frame = CGRect(x: 0, y: 0, width: 200, height: 300)

    if OpentokVideoFactory.view == nil {
        OpentokVideoFactory.viewToAddSub = subView
    } else {
        OpentokVideoFactory.view?.addSubscriberView(subView)
    }
  }

  public func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
    print(error.localizedDescription)
    notifyStateChange(state: FLTConnectionState.error)
  }
}

extension SwiftOpentokFlutterPlugin: OTPublisherDelegate {
  public func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
    print(error.localizedDescription)
    notifyStateChange(state: FLTConnectionState.error)
  }

  public func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {}

  public func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {}
}

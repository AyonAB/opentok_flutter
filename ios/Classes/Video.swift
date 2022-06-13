//
//  Video.swift
//  opentok_flutter
//
//  Created by Ayon Das on 13/06/22.
//

import Foundation

class OpentokVideoFactory: NSObject, FlutterPlatformViewFactory {
    static var view: OpentokVideoPlatformView?

    static var viewToAddSub: UIView?
    static var viewToAddPub: UIView?

    static func getViewInstance(
        frame: CGRect,
        viewId: Int64,
        args: Any?,
        messenger: FlutterBinaryMessenger?
    ) -> OpentokVideoPlatformView{
        if(view == nil) {
            view = OpentokVideoPlatformView()
            if viewToAddSub != nil {
                view?.addSubscriberView(viewToAddSub!)
            }
            if viewToAddPub != nil {
                view?.addPublisherView(viewToAddPub!)
            }
        }

        return view!
    }

    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return OpentokVideoFactory.getViewInstance(
            frame: frame,
            viewId: viewId,
            args: args,
            messenger: messenger)
    }
}

class OpentokVideoPlatformView: NSObject, FlutterPlatformView {
    private let videoContainer: OpenTokVideoContainer

    override init() {
        videoContainer = OpenTokVideoContainer()
        super.init()
    }

    public func addSubscriberView(_ view: UIView) {
        videoContainer.addSubscriberView(view)
    }

    public func addPublisherView(_ view: UIView) {
        videoContainer.addPublisherView(view)
    }

    func view() -> UIView {
        return videoContainer
    }
}

final class OpenTokVideoContainer: UIView {
    private let subscriberContainer = UIView()
    private let publisherContainer = UIView()

    init() {
        super.init(frame: .zero)
        addSubview(subscriberContainer)
        addSubview(publisherContainer)
    }


    public func addSubscriberView(_ view: UIView) {
        subscriberContainer.addSubview(view)
    }

    public func addPublisherView(_ view: UIView) {
        publisherContainer.addSubview(view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = frame.width
        let height = frame.height

        let videoWidth = width / 2
        subscriberContainer.frame = CGRect(x: 0, y: 0, width: videoWidth, height: height)
        publisherContainer.frame = CGRect(x: videoWidth, y: 0, width: videoWidth, height: height)
    }
}

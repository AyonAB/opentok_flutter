package com.natureglobal.opentok_flutter

import android.content.Context
import android.opengl.GLSurfaceView
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.ViewGroup
import androidx.annotation.NonNull
import com.opentok.android.*

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** OpentokFlutterPlugin */
class OpentokFlutterPlugin : FlutterPlugin, OpenTok.OpenTokHostApi {
    private lateinit var openTokPlatform: OpenTok.OpenTokPlatformApi

    private var context: Context? = null

    private var session: Session? = null
    private var publisher: Publisher? = null
    private var subscriber: Subscriber? = null

    private lateinit var opentokVideoPlatformView: OpentokVideoPlatformView

    // region Lifecycle methods
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        OpenTok.OpenTokHostApi.setup(flutterPluginBinding.binaryMessenger, this)
        openTokPlatform = OpenTok.OpenTokPlatformApi(flutterPluginBinding.binaryMessenger)

        context = flutterPluginBinding.applicationContext
        opentokVideoPlatformView = OpentokVideoFactory.getViewInstance(context)

        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "opentok-video-container",
            OpentokVideoFactory()
        )
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        OpenTok.OpenTokHostApi.setup(binding.binaryMessenger, null)
        context = null
    }
    // endregion

    // region Opentok flutter plugin methods
    override fun initSession(config: OpenTok.OpenTokConfig) {
        notifyFlutter(OpenTok.ConnectionState.WAIT)

        session = Session.Builder(context, config.apiKey, config.sessionId).build()
        session?.setSessionListener(sessionListener)
        session?.connect(config.token)
    }

    override fun endSession() {
        session?.disconnect()
    }

    override fun toggleCamera() {
        publisher?.cycleCamera()
    }

    override fun toggleAudio(enabled: Boolean) {
        publisher?.publishAudio = enabled
    }

    override fun toggleVideo(enabled: Boolean) {
        publisher?.publishVideo = enabled
    }
    // endregion

    // region Opentok callbacks
    private val sessionListener: Session.SessionListener = object : Session.SessionListener {
        override fun onConnected(session: Session) {
            publisher = Publisher.Builder(context).build().apply {
                setPublisherListener(publisherListener)

                renderer?.setStyle(
                    BaseVideoRenderer.STYLE_VIDEO_SCALE,
                    BaseVideoRenderer.STYLE_VIDEO_FILL
                )

                view.layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                opentokVideoPlatformView.publisherContainer.addView(view)

                if (view is GLSurfaceView) {
                    (view as GLSurfaceView).setZOrderOnTop(true)
                }
            }

            notifyFlutter(OpenTok.ConnectionState.LOGGED_IN)

            session.publish(publisher)
        }

        override fun onDisconnected(session: Session) {
            notifyFlutter(OpenTok.ConnectionState.LOGGED_OUT)
        }

        override fun onStreamReceived(session: Session, stream: Stream) {
            if (subscriber != null) return

            subscriber = Subscriber.Builder(context, stream).build().apply {
                renderer?.setStyle(
                    BaseVideoRenderer.STYLE_VIDEO_SCALE,
                    BaseVideoRenderer.STYLE_VIDEO_FIT
                )
                setSubscriberListener(subscriberListener)
                session.subscribe(this)

                opentokVideoPlatformView.subscriberContainer.addView(view)
            }
        }

        override fun onStreamDropped(session: Session, stream: Stream) {
            if (subscriber != null) {
                cleanUpSubscriber()
            }
        }

        override fun onError(session: Session, opentokError: OpentokError) {
            notifyFlutter(OpenTok.ConnectionState.ERROR, opentokError.message)
        }
    }

    private val publisherListener: PublisherKit.PublisherListener =
        object : PublisherKit.PublisherListener {
            override fun onStreamCreated(publisherKit: PublisherKit, stream: Stream) {}

            override fun onStreamDestroyed(publisherKit: PublisherKit, stream: Stream) {
                cleanUpSubscriber()
                cleanUpPublisher()
            }

            override fun onError(publisherKit: PublisherKit, opentokError: OpentokError) {
                notifyFlutter(OpenTok.ConnectionState.ERROR, opentokError.message)
                cleanUpPublisher()
            }
        }

    private val subscriberListener: SubscriberKit.SubscriberListener =
        object : SubscriberKit.SubscriberListener {
            override fun onConnected(subscriberKit: SubscriberKit) {}

            override fun onDisconnected(subscriberKit: SubscriberKit) {
                notifyFlutter(OpenTok.ConnectionState.LOGGED_OUT)
            }

            override fun onError(subscriberKit: SubscriberKit, opentokError: OpentokError) {
                notifyFlutter(OpenTok.ConnectionState.ERROR, opentokError.message)
            }
        }
    // endregion

    // region Private methods
    private fun notifyFlutter(
        @NonNull state: OpenTok.ConnectionState,
        errorDescription: String? = null
    ) {
        val connectionStateCallback: OpenTok.ConnectionStateCallback =
            OpenTok.ConnectionStateCallback.Builder().setState(state)
                .setErrorDescription(errorDescription)
                .build()
        Handler(Looper.getMainLooper()).post {
            openTokPlatform.onStateUpdate(connectionStateCallback) {}
        }
    }

    private fun cleanUpPublisher() {
        opentokVideoPlatformView.publisherContainer.removeAllViews()
        publisher = null
    }

    private fun cleanUpSubscriber() {
        opentokVideoPlatformView.subscriberContainer.removeAllViews()
        subscriber = null
    }
    // endregion
}

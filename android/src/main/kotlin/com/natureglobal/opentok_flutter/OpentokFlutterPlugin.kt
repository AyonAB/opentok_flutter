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

    override fun initSession(config: OpenTok.OpenTokConfig) {
        val connectionStateCallback: OpenTok.ConnectionStateCallback =
            OpenTok.ConnectionStateCallback.Builder().setState(OpenTok.ConnectionState.wait)
                .build()
        Handler(Looper.getMainLooper()).post {
            openTokPlatform.onStateUpdate(connectionStateCallback) {}
        }

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

    private val sessionListener: Session.SessionListener = object : Session.SessionListener {
        override fun onConnected(session: Session) {
            // Connected to session
            Log.d("OpenTok Flutter", "Connected to session ${session.sessionId}")

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

            val connectionStateCallback: OpenTok.ConnectionStateCallback =
                OpenTok.ConnectionStateCallback.Builder().setState(OpenTok.ConnectionState.loggedIn)
                    .build()
            Handler(Looper.getMainLooper()).post {
                openTokPlatform.onStateUpdate(connectionStateCallback) {}
            }

            session.publish(publisher)
        }

        override fun onDisconnected(session: Session) {
            val connectionStateCallback: OpenTok.ConnectionStateCallback =
                OpenTok.ConnectionStateCallback.Builder()
                    .setState(OpenTok.ConnectionState.loggedOut)
                    .build()
            Handler(Looper.getMainLooper()).post {
                openTokPlatform.onStateUpdate(connectionStateCallback) {}
            }
        }

        override fun onStreamReceived(session: Session, stream: Stream) {
            Log.d(
                "OpenTok Flutter",
                "onStreamReceived: New Stream Received " + stream.streamId + " in session: " + session.sessionId
            )
            if (subscriber == null) {
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
        }

        override fun onStreamDropped(session: Session, stream: Stream) {
            Log.d(
                "OpenTok Flutter",
                "onStreamDropped: Stream Dropped: " + stream.streamId + " in session: " + session.sessionId
            )

            if (subscriber != null) {
                subscriber = null
                opentokVideoPlatformView.subscriberContainer.removeAllViews()
            }
        }

        override fun onError(session: Session, opentokError: OpentokError) {
            Log.d("OpenTok Flutter", "Session error: " + opentokError.message)
            val connectionStateCallback: OpenTok.ConnectionStateCallback =
                OpenTok.ConnectionStateCallback.Builder()
                    .setState(OpenTok.ConnectionState.error)
                    .build()
            Handler(Looper.getMainLooper()).post {
                openTokPlatform.onStateUpdate(connectionStateCallback) { }
            }
        }
    }

    private val publisherListener: PublisherKit.PublisherListener =
        object : PublisherKit.PublisherListener {
            override fun onStreamCreated(publisherKit: PublisherKit, stream: Stream) {
                Log.d(
                    "OpenTok Flutter",
                    "onStreamCreated: Publisher Stream Created. Own stream " + stream.streamId
                )
            }

            override fun onStreamDestroyed(publisherKit: PublisherKit, stream: Stream) {
                Log.d(
                    "OpenTok Flutter",
                    "onStreamDestroyed: Publisher Stream Destroyed. Own stream " + stream.streamId
                )
            }

            override fun onError(publisherKit: PublisherKit, opentokError: OpentokError) {
                Log.d("OpenTok Flutter", "PublisherKit onError: " + opentokError.message)
                val connectionStateCallback: OpenTok.ConnectionStateCallback =
                    OpenTok.ConnectionStateCallback.Builder()
                        .setState(OpenTok.ConnectionState.error)
                        .build()
                Handler(Looper.getMainLooper()).post {
                    openTokPlatform.onStateUpdate(connectionStateCallback) {}
                }
            }
        }

    private val subscriberListener: SubscriberKit.SubscriberListener =
        object : SubscriberKit.SubscriberListener {
            override fun onConnected(subscriberKit: SubscriberKit) {
                Log.d(
                    "OpenTok Flutter",
                    "onConnected: Subscriber connected. Stream: " + subscriberKit.stream.streamId
                )
            }

            override fun onDisconnected(subscriberKit: SubscriberKit) {
                Log.d(
                    "OpenTok Flutter",
                    "onDisconnected: Subscriber disconnected. Stream: " + subscriberKit.stream.streamId
                )
                val connectionStateCallback: OpenTok.ConnectionStateCallback =
                    OpenTok.ConnectionStateCallback.Builder()
                        .setState(OpenTok.ConnectionState.loggedOut)
                        .build()
                Handler(Looper.getMainLooper()).post {
                    openTokPlatform.onStateUpdate(connectionStateCallback) {}
                }
            }

            override fun onError(subscriberKit: SubscriberKit, opentokError: OpentokError) {
                Log.d("OpenTok Flutter", "SubscriberKit onError: " + opentokError.message)
                val connectionStateCallback: OpenTok.ConnectionStateCallback =
                    OpenTok.ConnectionStateCallback.Builder()
                        .setState(OpenTok.ConnectionState.error)
                        .build()
                Handler(Looper.getMainLooper()).post {
                    openTokPlatform.onStateUpdate(connectionStateCallback) {}
                }
            }
        }
}

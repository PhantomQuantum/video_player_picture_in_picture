package com.video_player_picture_in_picture.video_player_picture_in_picture

import android.app.Activity
import android.app.PictureInPictureParams
import android.content.Context
import android.content.res.Configuration
import android.graphics.Rect
import android.os.Build
import android.util.Log
import android.util.Rational
import android.view.View
import android.view.ViewGroup
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class VideoPlayerPictureInPicturePlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private val TAG = "VideoPlayerPictureInPicturePlugin"

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var isInPipMode = false
    private var componentCallback: android.content.ComponentCallbacks? = null

    // 默认宽高比
    private var defaultAspectRatio = Rational(16, 9)
    private var customWidth: Double? = null
    private var customHeight: Double? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "video_player_picture_in_picture")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        Log.d(TAG, "Plugin attached to engine")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isPipSupported" -> result.success(isPipSupported())

            "enterPipMode" -> {
                // Flutter 可以传入自定义宽高
                customWidth = call.argument<Double>("width")
                customHeight = call.argument<Double>("height")
                val success = enterPipMode()
                result.success(success)
            }

            "exitPipMode" -> result.success(exitPipMode())

            "isInPipMode" -> result.success(isInPipMode)

            "setAspectRatio" -> {
                val width = (call.argument<Double>("width") ?: 16.0).toInt()
                val height = (call.argument<Double>("height") ?: 9.0).toInt()
                defaultAspectRatio = Rational(width, height)
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    private fun isPipSupported(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O

    private fun enterPipMode(): Boolean {
        if (!isPipSupported() || activity == null) {
            Log.w(TAG, "PiP not supported or activity is null")
            return false
        }

        try {
            val paramsBuilder = PictureInPictureParams.Builder()

            // 使用 Flutter 层传入的宽高，如果没有则使用默认 16:9
            val aspectRatio = if (customWidth != null && customHeight != null) {
                val ratio = customWidth!!.toFloat() / customHeight!!.toFloat()
                val minAllowed = 0.418f
                val maxAllowed = 2.39f
                if (ratio in minAllowed..maxAllowed) {
                    Rational(customWidth!!, customHeight!!)
                } else {
                    Log.w(TAG, "Custom width/height ratio out of bounds, defaulting to 16:9")
                    defaultAspectRatio
                }
            } else {
                defaultAspectRatio
            }

            paramsBuilder.setAspectRatio(aspectRatio)

            // Android 12+ 支持 seamless resize
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                paramsBuilder.setSeamlessResizeEnabled(true)
                // 尝试使用 Activity 根视图作为 source rect
                val rootView = activity?.findViewById<ViewGroup>(android.R.id.content)?.getChildAt(0)
                rootView?.let {
                    val loc = IntArray(2)
                    it.getLocationInWindow(loc)
                    val rect = Rect(loc[0], loc[1], loc[0] + it.width, loc[1] + it.height)
                    paramsBuilder.setSourceRectHint(rect)
                    Log.d(TAG, "Set sourceRectHint: $rect")
                }
            }

            val params = paramsBuilder.build()
            val success = activity?.enterPictureInPictureMode(params) ?: false
            isInPipMode = success
            return success
        } catch (e: Exception) {
            Log.e(TAG, "Error entering PiP mode", e)
            return false
        }
    }

    private fun exitPipMode(): Boolean {
        if (!isPipSupported() || activity == null) return false
        if (!isInPipMode) return false
        isInPipMode = false
        notifyFlutterPipChanged()
        return true
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        setupPipModeListener()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        cleanupPipModeListener()
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        setupPipModeListener()
    }

    override fun onDetachedFromActivity() {
        cleanupPipModeListener()
        activity = null
    }

    private fun setupPipModeListener() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && activity != null) {
            componentCallback = object : android.content.ComponentCallbacks {
                override fun onConfigurationChanged(newConfig: Configuration) {
                    val inPip = activity?.isInPictureInPictureMode ?: false
                    if (inPip != isInPipMode) {
                        isInPipMode = inPip
                        notifyFlutterPipChanged()
                    }
                }

                override fun onLowMemory() {}
            }
            activity?.registerComponentCallbacks(componentCallback)
        }
    }

    private fun cleanupPipModeListener() {
        componentCallback?.let { activity?.unregisterComponentCallbacks(it) }
        componentCallback = null
    }

    private fun notifyFlutterPipChanged() {
        try {
            channel.invokeMethod("pipModeChanged", mapOf("isInPipMode" to isInPipMode))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to notify Flutter PiP state", e)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

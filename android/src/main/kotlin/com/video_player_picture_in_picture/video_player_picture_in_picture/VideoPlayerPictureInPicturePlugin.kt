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
import androidx.lifecycle.Lifecycle

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
        val activity = activity ?: run {
            Log.w(TAG, "PiP not supported or activity is null")
            return false
        }

        if (!isPipSupported()) {
            Log.w(TAG, "PiP not supported on this device")
            return false
        }

        if (activity.lifecycle.currentState != Lifecycle.State.RESUMED) {
            Log.w(TAG, "Activity is not resumed — skip PiP")
            return false
        }

        return try {
            val paramsBuilder = PictureInPictureParams.Builder()

            // ---- 设置宽高比例 ----
            val aspectRatio = when {
                customWidth != null && customHeight != null -> {
                    val ratio = customWidth!!.toFloat() / customHeight!!.toFloat()
                    val minAllowed = 0.418f
                    val maxAllowed = 2.39f

                    if (ratio in minAllowed..maxAllowed) {
                        Rational(
                            customWidth!!.toInt(),
                            customHeight!!.toInt()
                        )
                    } else {
                        Log.w(TAG, "Custom ratio out of bounds, using default 16:9")
                        defaultAspectRatio
                    }
                }

                else -> defaultAspectRatio
            }

            paramsBuilder.setAspectRatio(aspectRatio)

            // ---- Android 12+ seamless resize + sourceRectHint ----
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                paramsBuilder.setSeamlessResizeEnabled(true)

                val rootView =
                    activity.findViewById<ViewGroup>(android.R.id.content)?.getChildAt(0)
                rootView?.let {
                    val loc = IntArray(2)
                    it.getLocationInWindow(loc)
                    val rect = Rect(
                        loc[0],
                        loc[1],
                        loc[0] + it.width,
                        loc[1] + it.height
                    )
                    paramsBuilder.setSourceRectHint(rect)
                    Log.d(TAG, "Set sourceRectHint: $rect")
                }
            }

            val success = activity.enterPictureInPictureMode(paramsBuilder.build())
            isInPipMode = success
            success

        } catch (e: Exception) {
            Log.e(TAG, "Error entering PiP mode", e)
            false
        }
    }

    private fun exitPipMode(): Boolean {
        val activity = activity ?: return false
        if (!isPipSupported()) return false

        // 只有真的在 PiP 时才执行
        if (!activity.isInPictureInPictureMode) {
            isInPipMode = false
            return false
        }

        try {
            // 标记退出
            isInPipMode = false

            // 通知 Flutter
            notifyFlutterPipChanged()

            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error in exitPipMode()", e)
            return false
        }
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

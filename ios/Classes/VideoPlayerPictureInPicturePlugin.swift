import Flutter
import UIKit
import AVFoundation
import AVKit

public class VideoPlayerPipPlugin: NSObject, FlutterPlugin, AVPictureInPictureControllerDelegate {
    private var channel: FlutterMethodChannel?
    private var pipController: AVPictureInPictureController?
    private var isInPipMode = false
    private var observationToken: NSKeyValueObservation?

    // 可选自定义宽高
    private var customWidth: CGFloat?
    private var customHeight: CGFloat?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "video_player_picture_in_picture", binaryMessenger: registrar.messenger())
        let instance = VideoPlayerPipPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        NSLog("VideoPlayerPip: Plugin registered")
    }

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        NSLog("VideoPlayerPip: Plugin initialized")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isPipSupported":
            result(isPipSupported())
        case "enterPipMode":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
                return
            }
            if let width = args["width"] as? Double { customWidth = CGFloat(width) }
            if let height = args["height"] as? Double { customHeight = CGFloat(height) }
            enterPipMode(completion: result)
        case "exitPipMode":
            exitPipMode(completion: result)
        case "isInPipMode":
            result(isInPipMode)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func isPipSupported() -> Bool {
        if #available(iOS 14.0, *) {
            return AVPictureInPictureController.isPictureInPictureSupported()
        }
        return false
    }

    private func enterPipMode(completion: @escaping FlutterResult) {
        guard isPipSupported() else { completion(false); return }
        guard let keyWindow = getKeyWindow(), let rootView = keyWindow.rootViewController?.view else {
            completion(false)
            return
        }

        // 确保主线程调用
        DispatchQueue.main.async {
            // 查找 AVPlayerLayer
            guard let playerLayer = self.findAVPlayerLayerInView(rootView) else {
                completion(false)
                return
            }

            // 检查播放器是否存在
            guard let player = playerLayer.player else {
                completion(false)
                return
            }

            // 自动播放，确保 PiP 可以开始
            if player.timeControlStatus != .playing {
                player.play()
            }

            // 延迟启动 PiP 保证 AVPlayerLayer 准备好
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.startPip(playerLayer: playerLayer, completion: completion)
            }
        }
    }

    private func startPip(playerLayer: AVPlayerLayer, completion: @escaping FlutterResult) {
        if #available(iOS 14.0, *) {
            self.cleanupPipController()

            self.pipController = AVPictureInPictureController(playerLayer: playerLayer)
            self.pipController?.delegate = self

            if #available(iOS 14.2, *) {
                self.pipController?.canStartPictureInPictureAutomaticallyFromInline = true
            }

            if #available(iOS 15.0, *) {
                self.pipController?.requiresLinearPlayback = false
            }

            // 观察 PiP 状态
            if #available(iOS 14.0, *) {
                self.observationToken = self.pipController?.observe(\.isPictureInPictureActive, options: [.new]) { [weak self] (controller, change) in
                    guard let self = self, let newValue = change.newValue else { return }
                    self.isInPipMode = newValue
                    self.channel?.invokeMethod("pipModeChanged", arguments: ["isInPipMode": newValue])
                }
            }

            // 安全启动 PiP
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.pipController?.startPictureInPicture()
            }

            completion(true)
        } else {
            completion(false)
        }
    }

    private func exitPipMode(completion: @escaping FlutterResult) {
        if isInPipMode, let controller = pipController {
            controller.stopPictureInPicture()
            completion(true)
        } else {
            completion(false)
        }
    }

    private func cleanupPipController() {
        observationToken?.invalidate()
        observationToken = nil
        if let controller = pipController, isInPipMode {
            controller.stopPictureInPicture()
        }
        pipController = nil
        isInPipMode = false
    }

    private func getKeyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    private func findAVPlayerLayerInView(_ view: UIView) -> AVPlayerLayer? {
        if let layer = view.layer as? AVPlayerLayer, layer.player != nil {
            return layer
        }
        for subview in view.subviews {
            if let layer = findAVPlayerLayerInView(subview) {
                return layer
            }
        }
        return nil
    }

    // MARK: - AVPictureInPictureControllerDelegate

    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isInPipMode = true
        channel?.invokeMethod("pipModeChanged", arguments: ["isInPipMode": true])
    }

    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isInPipMode = false
        channel?.invokeMethod("pipModeChanged", arguments: ["isInPipMode": false])
        cleanupPipController()
    }

    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        channel?.invokeMethod("pipError", arguments: ["error": error.localizedDescription])
    }
}

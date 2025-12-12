import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_picture_in_picture/video_player_picture_in_picture_method_channel.dart';

abstract class VideoPlayerPictureInPicturePlatformInterface extends PlatformInterface {
  /// Constructs a VideoPlayerPipPlatform.
  VideoPlayerPictureInPicturePlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static VideoPlayerPictureInPicturePlatformInterface _instance = VideoPlayerPictureInPictureMethodChannel();

  /// The default instance of [VideoPlayerPipPlatform] to use.
  ///
  /// Defaults to [MethodChannelVideoPlayerPip].
  static VideoPlayerPictureInPicturePlatformInterface get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoPlayerPictureInPicturePlatformInterface] when
  /// they register themselves.
  static set instance(VideoPlayerPictureInPicturePlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Checks if the device supports PiP mode.
  Future<bool> isPipSupported() {
    throw UnimplementedError('isPipSupported() has not been implemented.');
  }

  /// Enters PiP mode for the specified player ID.
  Future<bool> enterPipMode(int playerId, {int? width, int? height}) {
    throw UnimplementedError('enterPipMode() has not been implemented.');
  }

  /// Exits PiP mode.
  Future<bool> exitPipMode() {
    throw UnimplementedError('exitPipMode() has not been implemented.');
  }

  /// Checks if the app is currently in PiP mode.
  Future<bool> isInPipMode() {
    throw UnimplementedError('isInPipMode() has not been implemented.');
  }
}

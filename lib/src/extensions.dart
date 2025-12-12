import 'package:video_player_picture_in_picture/video_player_picture_in_picture.dart';

extension VideoPlayerControllerExtension on VideoPlayerController {
  /// Checks if the device supports PiP mode.
  Future<bool> isPipSupported() {
    return VideoPlayerPictureInPicture.isPipSupported();
  }

  /// Enters PiP mode for the specified player ID.
  Future<bool> enterPipMode({required double width, required double height}) {
    return VideoPlayerPictureInPicture.enterPipMode(this, width, height);
  }

  /// Exits PiP mode.
  Future<bool> exitPipMode() {
    return VideoPlayerPictureInPicture.exitPipMode();
  }

  /// Checks if the app is currently in PiP mode.
  Future<bool> isInPipMode() {
    return VideoPlayerPictureInPicture.isInPipMode();
  }

  /// Stream of PiP mode state changes.
  Stream<bool> get onPipModeChanged {
    return VideoPlayerPictureInPicture.instance.onPipModeChanged;
  }
}

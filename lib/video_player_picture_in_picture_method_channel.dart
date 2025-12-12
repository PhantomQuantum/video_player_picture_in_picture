import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player_picture_in_picture/video_player_picture_in_picture_platform_interface.dart';

/// An implementation of [VideoPlayerPictureInPicturePlatformInterface] that uses method channels.
class VideoPlayerPictureInPictureMethodChannel extends VideoPlayerPictureInPicturePlatformInterface {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('video_player_picture_in_picture');

  @override
  Future<bool> isPipSupported() async {
    try {
      final isSupported = await methodChannel.invokeMethod<bool>('isPipSupported');
      return isSupported ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking PiP support: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> enterPipMode(double width, double height) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('enterPipMode', {'width': width, 'height': height});
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error entering PiP mode: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> exitPipMode() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('exitPipMode');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error exiting PiP mode: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> isInPipMode() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('isInPipMode');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking PiP mode: ${e.message}');
      return false;
    }
  }

  Future<dynamic> getPlatformVersion() async {}
}

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_picture_in_picture/video_player_picture_in_picture.dart';
import 'package:video_player_picture_in_picture/video_player_picture_in_picture_method_channel.dart';
import 'package:video_player_picture_in_picture/video_player_picture_in_picture_platform_interface.dart';

class MockVideoPlayerPictureInPicturePlatform
    with MockPlatformInterfaceMixin
    implements VideoPlayerPictureInPicturePlatformInterface {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> enterPipMode(int playerId, {int? width, int? height}) {
    // TODO: implement enterPipMode
    throw UnimplementedError();
  }

  @override
  Future<bool> exitPipMode() {
    // TODO: implement exitPipMode
    throw UnimplementedError();
  }

  @override
  Future<bool> isInPipMode() {
    // TODO: implement isInPipMode
    throw UnimplementedError();
  }

  @override
  Future<bool> isPipSupported() {
    // TODO: implement isPipSupported
    throw UnimplementedError();
  }
}

void main() {
  final VideoPlayerPictureInPicturePlatformInterface initialPlatform =
      VideoPlayerPictureInPicturePlatformInterface.instance;

  test('$VideoPlayerPictureInPictureMethodChannel is the default instance', () {
    expect(initialPlatform, isInstanceOf<VideoPlayerPictureInPictureMethodChannel>());
  });

  test('getPlatformVersion', () async {
    VideoPlayerPictureInPicture videoPlayerPictureInPicturePlugin = VideoPlayerPictureInPicture.instance;
    MockVideoPlayerPictureInPicturePlatform fakePlatform = MockVideoPlayerPictureInPicturePlatform();
    VideoPlayerPictureInPicturePlatformInterface.instance = fakePlatform;

    expect(await videoPlayerPictureInPicturePlugin.getPlatformVersion(), '42');
  });
}

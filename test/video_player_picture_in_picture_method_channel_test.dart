import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_picture_in_picture/video_player_picture_in_picture_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  VideoPlayerPictureInPictureMethodChannel platform = VideoPlayerPictureInPictureMethodChannel();
  const MethodChannel channel = MethodChannel('video_player_picture_in_picture');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      MethodCall methodCall,
    ) async {
      return '42';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}

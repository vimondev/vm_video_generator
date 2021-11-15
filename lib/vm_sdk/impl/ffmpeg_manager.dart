import 'dart:async';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/statistics.dart' show Statistics;

class FFMpegManager {
  FlutterFFmpeg ffmpegIns = FlutterFFmpeg();
  FlutterFFmpegConfig ffmpegConfig = FlutterFFmpegConfig();

  Future<bool> execute(
      List<String> args, Function(Statistics)? callback) async {
    if (callback != null) {
      ffmpegConfig.enableStatisticsCallback(callback);
    }
    return (await ffmpegIns.executeWithArguments(args)) == 0;
  }

  Future<void> cancel() async {
    await ffmpegIns.cancel();
  }
}

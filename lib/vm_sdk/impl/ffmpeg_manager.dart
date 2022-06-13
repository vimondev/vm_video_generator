import 'dart:async';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/statistics.dart';

class FFMpegManager {
  FFmpegKit ffmpegIns = FFmpegKit();
  FFmpegKitConfig ffmpegConfig = FFmpegKitConfig();

  Future<bool> execute(
      List<String> args, Function(Statistics)? callback) async {
    if (callback != null) {
      FFmpegKitConfig.enableStatisticsCallback(callback);
    } //
    else {
      FFmpegKitConfig.disableStatistics();
    }

    final FFmpegSession session = await FFmpegKit.executeWithArguments(args);
    final ReturnCode? returnCode = await session.getReturnCode();
    
    if (returnCode != null) {
      return returnCode.isValueSuccess();
    }

    return false;
  }

  Future<void> cancel() async {
    await FFmpegKit.cancel();
  }
}

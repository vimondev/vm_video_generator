import 'dart:async';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/statistics.dart';

class FFMpegManager {
  FFmpegKit ffmpegIns = FFmpegKit();
  FFmpegKitConfig ffmpegConfig = FFmpegKitConfig();

  Future<FFmpegSession> execute(
      List<String> args, Function(Statistics)? callback) async {
    
    if (callback != null) {
      FFmpegKitConfig.enableStatisticsCallback((statistics) => callback(statistics));
    }

    FFmpegKitConfig.enableLogCallback((log) {
      print(log.getMessage());
    });

    final FFmpegSession session = await FFmpegKit.executeWithArguments(args);
    final ReturnCode? returnCode = await session.getReturnCode();

    final log = await session.getAllLogsAsString();
    if (returnCode == null || !returnCode.isValueSuccess()) {
      throw Exception("FFMPEG EXECUTE FAILED!\nLOG : $log");
    }

    return session;
  }

  Future<void> cancel() async {
    await FFmpegKit.cancel();
  }
}

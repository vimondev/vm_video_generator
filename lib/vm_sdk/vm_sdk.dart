import 'dart:math';
import 'types/types.dart';
import 'impl/template_helper.dart';
import 'impl/ffmpeg_manager.dart';
import 'impl/ffmpeg_argument_generator.dart';

class VideoGenerator {
  FFMpegManager ffmpegManager = FFMpegManager();

  void initialize() {}

  Future<String?> autoGenerateVideo(List<MediaData> allList,
      Function(EGenerateStatus, double)? progressCallback) async {
    List<MediaData> filteredList = allList;

    return generateVideo(filteredList, EMusicStyle.styleA, progressCallback);
  }

  Future<String?> generateVideo(List<MediaData> pickedList, EMusicStyle? style,
      Function(EGenerateStatus, double)? progressCallback) async {
    EMusicStyle selectedStyle = style ?? EMusicStyle.styleA;

    final TemplateData? templateData = await loadTemplate(selectedStyle);
    if (templateData == null) return null;
    expandTemplate(templateData, pickedList.length);

    final GenerateArgumentResponse videoArgResponse =
        await generateVideoRenderArgument(templateData, pickedList);

    DateTime now = DateTime.now();

    bool isSuccess = await ffmpegManager.execute(
        videoArgResponse.arguments,
        (statistics) => {
              if (progressCallback != null)
                {
                  progressCallback(
                      EGenerateStatus.encoding,
                      min(
                          1.0,
                          (statistics.time / 1000.0) /
                              videoArgResponse.totalDuration!))
                }
              // print(statistics.bitrate),
              // print(statistics.executionId),
              // print(statistics.size),
              // print(statistics.speed),
              // print(statistics.time),
              // print(statistics.videoFps),
              // print(statistics.videoFrameNumber),
              // print(statistics.videoQuality)
            });
    if (!isSuccess) return null;

    final GenerateArgumentResponse audioArgResponse =
        await generateAudioRenderArgument(templateData, pickedList);

    isSuccess = await ffmpegManager.execute(
        audioArgResponse.arguments,
        (statistics) => {
              if (progressCallback != null)
                {progressCallback(EGenerateStatus.merge, 1.0)}
            });
    if (!isSuccess) return null;

    final GenerateArgumentResponse mergeArgResponse =
        await generateMergeArgument(
            videoArgResponse.outputPath, audioArgResponse.outputPath);

    isSuccess = await ffmpegManager.execute(
        mergeArgResponse.arguments,
        (statistics) => {
              if (progressCallback != null)
                {progressCallback(EGenerateStatus.merge, 1.0)}
            });
    print(isSuccess);
    print(DateTime.now().difference(now).inSeconds);
    if (!isSuccess) return null;

    String outputPath = mergeArgResponse.outputPath;
    return outputPath;
  }

  void cancelGenerate() async {
    try {
      await ffmpegManager.cancel();
    } catch (e) {}
  }

  void release() {}
}

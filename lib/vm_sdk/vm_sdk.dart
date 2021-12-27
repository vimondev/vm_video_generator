import 'dart:math';
import 'types/types.dart';
import 'impl/template_helper.dart';
import 'impl/ffmpeg_manager.dart';
import 'impl/ffmpeg_argument_generator.dart';
import 'impl/resource_manager.dart';
import 'impl/auto_select_helper.dart';

class VideoGenerator {
  bool isInitialized = false;
  FFMpegManager ffmpegManager = FFMpegManager();
  ResourceManager resourceManager = ResourceManager();

  // Intializing before video generate
  Future<void> initialize() async {
    await resourceManager.loadResourceMap();
    isInitialized = true;
  }

  List<MediaData> autoSelectMedia(List<MediaData> allList) {
    return selectMedia(allList);
  }

  EMusicStyle autoSelectMusic(List<MediaData> list) {
    return selectMusic(list);
  }

  // Generate the video by entering the user-specified photo/video list and music style.
  // You can check the progress via progress callback.
  // In the current version, only styleA works.
  Future<String?> generateVideo(
      List<MediaData> pickedList,
      EMusicStyle? style,
      Function(EGenerateStatus status, double progress, double estimatedTime)?
          progressCallback) async {
    EMusicStyle selectedStyle = style ?? EMusicStyle.styleA;

    final TemplateData? templateData = await loadTemplateData(selectedStyle);
    if (templateData == null) return null;

    await resourceManager.loadTemplateAssets(templateData);
    expandTemplate(templateData, pickedList.length);

    final GenerateArgumentResponse videoArgResponse =
        await generateVideoRenderArgument(templateData, pickedList);

    DateTime now = DateTime.now();

    double progress = 0, estimatedTime = 0;

    bool isSuccess = await ffmpegManager.execute(
        videoArgResponse.arguments,
        (statistics) => {
              if (progressCallback != null)
                {
                  progress = min(
                      1.0,
                      statistics.videoFrameNumber /
                          videoArgResponse.totalFrame!),
                  estimatedTime = (videoArgResponse.totalFrame! -
                          statistics.videoFrameNumber) /
                      statistics.videoFps,
                  progressCallback(
                      EGenerateStatus.encoding, progress, estimatedTime)
                }
            });
    if (!isSuccess) return null;

    final GenerateArgumentResponse audioArgResponse =
        await generateAudioRenderArgument(templateData, pickedList);

    isSuccess = await ffmpegManager.execute(
        audioArgResponse.arguments,
        (statistics) => {
              if (progressCallback != null)
                {progressCallback(EGenerateStatus.merge, 1.0, 0)}
            });
    if (!isSuccess) return null;

    final GenerateArgumentResponse mergeArgResponse =
        await generateMergeArgument(
            videoArgResponse.outputPath, audioArgResponse.outputPath);

    isSuccess = await ffmpegManager.execute(
        mergeArgResponse.arguments,
        (statistics) => {
              if (progressCallback != null)
                {progressCallback(EGenerateStatus.merge, 1.0, 0)}
            });
    print(isSuccess);
    print(DateTime.now().difference(now).inSeconds);
    if (!isSuccess) return null;

    String outputPath = mergeArgResponse.outputPath;
    return outputPath;
  }

  // cancel generate
  void cancelGenerate() async {
    try {
      await ffmpegManager.cancel();
    } catch (e) {}
  }

  // release
  void release() {}
}

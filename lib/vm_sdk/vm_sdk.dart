import 'dart:math';
import 'types/types.dart';
import 'impl/template_helper.dart';
import 'impl/ffmpeg_manager.dart';
import 'impl/ffmpeg_argument_generator.dart';
import 'impl/resource_manager.dart';

class VideoGenerator {
  bool isInitialized = false;
  FFMpegManager ffmpegManager = FFMpegManager();
  ResourceManager resourceManager = ResourceManager();

  // Intializing before video generate
  Future<void> initialize() async {
    await resourceManager.loadResourceMap();
    isInitialized = true;
  }

  // Automatically generate video.
  // (Currently, the operation is the same as generate video.)
  Future<String?> autoGenerateVideo(List<MediaData> allList,
      Function(EGenerateStatus, double)? progressCallback) async {
    List<MediaData> filteredList = allList;

    return generateVideo(filteredList, EMusicStyle.styleA, progressCallback);
  }

  // Generate the video by entering the user-specified photo/video list and music style.
  // You can check the progress via progress callback.
  // In the current version, only styleA works.
  Future<String?> generateVideo(List<MediaData> pickedList, EMusicStyle? style,
      Function(EGenerateStatus, double)? progressCallback) async {
    EMusicStyle selectedStyle = style ?? EMusicStyle.styleA;

    final TemplateData? templateData = await loadTemplateData(selectedStyle);
    if (templateData == null) return null;

    await resourceManager.loadTemplateAssets(templateData);
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

  // cancel generate
  void cancelGenerate() async {
    try {
      await ffmpegManager.cancel();
    } catch (e) {}
  }

  // release
  void release() {}
}

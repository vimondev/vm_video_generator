import 'dart:math';
import 'package:flutter/material.dart';

import 'types/types.dart';
import 'impl/title_helper.dart';
import 'impl/ffmpeg_manager.dart';
import 'impl/ffmpeg_argument_generator.dart';
import 'impl/resource_manager.dart';
import 'impl/auto_edit_helper.dart';
import 'impl/ml_kit_helper.dart';
import 'impl/lottie_widget.dart';

class VMSDKWidget extends StatelessWidget {
  VMSDKWidget({Key? key}) : super(key: key);

  final LottieWidget _lottieWidget = LottieWidget();

  bool _isInitialized = false;
  final FFMpegManager _ffmpegManager = FFMpegManager();
  final ResourceManager _resourceManager = ResourceManager();

  bool get isInitialized {
    return _isInitialized;
  }

  // Intializing before video generate
  Future<void> initialize() async {
    await _resourceManager.loadResourceMap();
    await loadLabelMap();
    _isInitialized = true;
  }

  Future<String?> extractMLKitDetectData(MediaData data) async {
    try {
      return await extractData(data);
    } catch (e) {}
    return null;
  }

  // Generate the video by entering the user-specified photo/video list and music style.
  // You can check the progress via progress callback.
  // In the current version, only styleA works.
  Future<String?> generateVideo(
      List<MediaData> mediaList,
      EMusicStyle? style,
      bool isAutoEdit,
      List<String> titles,
      Function(EGenerateStatus status, double progress, double estimatedTime)?
          progressCallback) async {
    EMusicStyle selectedStyle = style ?? EMusicStyle.styleA;

    final AutoEditedData autoEditedData =
        await generateAutoEditData(mediaList, selectedStyle, isAutoEdit);

    await _resourceManager.loadAutoEditAssets(autoEditedData);

    final TitleData title = (await loadTitleData(ETitleType.title04))!;
    title.texts.addAll(titles);

    ExportedTitlePNGSequenceData exportedTitleData =
        await _lottieWidget.exportTitlePNGSequence(title);

    final GenerateArgumentResponse videoArgResponse =
        await generateVideoRenderArgument(autoEditedData, exportedTitleData);

    final GenerateArgumentResponse audioArgResponse =
        await generateAudioRenderArgument(autoEditedData);

    DateTime now = DateTime.now();
    double progress = 0, estimatedTime = 0;

    bool isSuccess =
        await _ffmpegManager.execute(audioArgResponse.arguments, (statistics) {
      if (progressCallback != null) {
        progressCallback(EGenerateStatus.encoding, 0, 0);
      }
    });
    if (!isSuccess) return null;

    isSuccess =
        await _ffmpegManager.execute(videoArgResponse.arguments, (statistics) {
      if (progressCallback != null) {
        progress = min(
            1.0, statistics.videoFrameNumber / videoArgResponse.totalFrame!);
        estimatedTime =
            (videoArgResponse.totalFrame! - statistics.videoFrameNumber) /
                statistics.videoFps;
        progressCallback(EGenerateStatus.encoding, progress, estimatedTime);
      }
    });
    if (!isSuccess) return null;

    final GenerateArgumentResponse mergeArgResponse =
        await generateMergeArgument(
            videoArgResponse.outputPath, audioArgResponse.outputPath);

    isSuccess =
        await _ffmpegManager.execute(mergeArgResponse.arguments, (statistics) {
      if (progressCallback != null) {
        progressCallback(EGenerateStatus.merge, 1.0, 0);
      }
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
      await _ffmpegManager.cancel();
    } catch (e) {}
  }

  // release
  void release() {}

  @override
  Widget build(BuildContext context) {
    return _lottieWidget;
  }
}

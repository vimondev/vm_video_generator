import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:myapp/vm_sdk/text_box/text/config.dart';
import 'package:myapp/vm_sdk/text_box/text_box_config_controller.dart';
import 'package:tuple/tuple.dart';

import 'impl/convert_helper.dart';
import 'types/types.dart';
import 'impl/ffmpeg_manager.dart';
import 'impl/resource_manager.dart';
import 'impl/auto_edit_helper.dart';
import 'impl/ml_kit_helper.dart';
import 'impl/vm_text_widget.dart';
import 'impl/ffmpeg_helper.dart';

import 'text_box/text_box_builder.dart';

import 'extensions/extensions.dart';

const double _titleExportPercentage = 1 / 3.0;

class VMSDKWidget extends StatelessWidget {
  VMSDKWidget({Key? key}) : super(key: key);

  final VMTextWidget _textWidget = VMTextWidget();

  final TextBoxConfigController _textBoxConfigController = TextBoxConfigController(
    "label",
    padding: const EdgeInsets.all(10)
  );
  CanvasTextConfig _textConfig = CanvasTextConfig(text: "");

  bool _isInitialized = false;
  final FFMpegManager _ffmpegManager = FFMpegManager();

  Timer? _currentTimer;
  EGenerateStatus _currentStatus = EGenerateStatus.encoding;
  int _currentRenderedFrame = 0;
  int _maxRenderedFrame = 0;
  int _currentRenderedFrameInCallback = 0;
  int _allFrame = 0;

  bool get isInitialized {
    return _isInitialized;
  }

  // Intializing before video generate
  Future<void> initialize() async {
    await ResourceManager.getInstance().loadResourceMap();
    await loadLabelMap();
    _isInitialized = true;
  }

  Future<String?> extractMLKitDetectData(MediaData data) async {
    try {
      return await extractData(data);
    } //
    catch (e) {
      return null;
    }
  }

  // Generate the video by entering the user-specified photo/video list and music style.
  // You can check the progress via progress callback.
  // In the current version, only styleA works.
  Future<VideoGeneratedResult> generateVideo(
      List<MediaData> mediaList,
      EMusicSpeed? speed,
      bool isAutoEdit,
      List<String> texts,
      String language,
      Function(EGenerateStatus status, double progress)?
          progressCallback, { isExportTitle = true, isRunFFmpeg = true }) async {
    DateTime now = DateTime.now();
    _currentStatus = EGenerateStatus.titleExport;

    List<TemplateData> templateList = [];
    templateList.addAll(ResourceManager.getInstance().getRandomTemplateData());

    List<TemplateData> randomSortedTemplateList = [];
    while (templateList.isNotEmpty) {
      int randIdx =
          (Random()).nextInt(templateList.length) % templateList.length;
      randomSortedTemplateList.add(templateList[randIdx]);
      templateList.removeAt(randIdx);
    }

    mediaList = await _filterNotExistsMedia(mediaList);

    final AllEditedData allEditedData = await generateAllEditedData(
        mediaList, speed, randomSortedTemplateList, isAutoEdit, isRunFFmpeg: isRunFFmpeg);

    Resolution resolution = allEditedData.resolution;
    final int maxTextWidth = (resolution.width * 0.9).floor();
    final int maxTextHeight = resolution.height;

    bool isUseCanvasText = false;
    if (texts.length >= 3) {
      isUseCanvasText = true;
    }
    else {
      for (final text in texts) {
        if (text.hasEmoji() || text.hasSpecialCharacter()) {
          isUseCanvasText = true;
          break;
        }
      }
    }

    String pickedTextId = "";
    if (isUseCanvasText) {
      pickedTextId = "CanvasText";

      const List<Tuple3<Color, Color, Color>> colors = [
        Tuple3(Color(0xfffefefe), Colors.transparent, Colors.black),
        Tuple3(Colors.black, Colors.transparent, Color(0xffffcb1e)),
        Tuple3(Colors.white, Colors.transparent, Color(0xff8380d7)),
        Tuple3(Color(0xffffbe00), Colors.black, Colors.transparent),
        Tuple3(Color(0xffff4e91), Colors.white, Colors.transparent),
        Tuple3(Color(0xff9ee8f6), Color(0xff000001), Colors.transparent),
      ];

      final Tuple3<Color, Color, Color> pickedColor = colors[(Random()).nextInt(colors.length) % colors.length];
      int tryCount = 0;
      String pngPath = "";

      _textBoxConfigController.updateConfig(CanvasTextConfig(
        text: texts.join("\n"),
        fontSize: 51,
        borderRadius: 9,
        contentPadding: 48,
        textHeight: 1.3,
        outlineWidth: 12,
        textColor: pickedColor.item1,
        outlineColor: pickedColor.item2,
        fillColor: pickedColor.item3,
      ));

      try {
        pngPath = await _textBoxConfigController.renderImageAndSave().timeout(const Duration(seconds: 5));
      }
      catch (e) {
        print(e);
        if (++tryCount >= 6) rethrow;
      }
      print(pngPath);

      if (isExportTitle) {
        // wait 3~4 seconds
        await Future.delayed(Duration(seconds: 3 + Random().nextInt(2)));

        // wait 3~5 + 0~1 seconbd
        double totalFakeDelayTimeMs = (3.0 + Random().nextInt(3) + Random().nextDouble()) * 1000;
        final Duration fakeDelayDuration = Duration(milliseconds: (totalFakeDelayTimeMs / 250).floor());
        for (int i=0; i<250; i++) {
          double fakeProgress = i / 250.0;
          if (progressCallback != null) {
            progressCallback(_currentStatus, fakeProgress * _titleExportPercentage);
          }
          await Future.delayed(fakeDelayDuration);
          print("fakeProgress : $fakeProgress");
        }

        if (progressCallback != null) {
          progressCallback(_currentStatus, _titleExportPercentage);
        }

        // wait 0.5 seconds
        await Future.delayed(const Duration(milliseconds: 500));
      }

      Size size = _textBoxConfigController.size;

      double scale = 1.0;
      if (size.width > maxTextWidth) {
        scale = maxTextWidth / size.width;
      }
      if (size.height > maxTextHeight) {
        scale = min(maxTextHeight / size.height, scale);
      }

      final CanvasTextData canvasTextData = CanvasTextData();
      canvasTextData.imagePath = pngPath;
      canvasTextData.width = (size.width * scale).floor();
      canvasTextData.height = (size.height * scale).floor();
      canvasTextData.x = (resolution.width / 2) - (canvasTextData.width / 2);
      canvasTextData.y = (resolution.height / 2) - (canvasTextData.height / 2);
      if (allEditedData.ratio == ERatio.ratio916) {
        canvasTextData.y *= 0.6;
      }

      allEditedData.editedMediaList[0].canvasTexts.add(canvasTextData);
    }
    else {
      List<TextData> textDatas = ResourceManager.getInstance().getTextDataList(lineCount: texts.length);
      if (textDatas.isEmpty) {
        textDatas = ResourceManager.getInstance().getTextDataList(lineCount: texts.length);
      }
      final TextData pickedText = textDatas[(Random()).nextInt(textDatas.length) % textDatas.length];
      pickedTextId = pickedText.key;

      if (isExportTitle) {
        await _textWidget.loadText(pickedTextId, initTexts: texts, language: language);

        await _textWidget.extractAllSequence((progress) {
          if (progressCallback != null) {
            progressCallback(_currentStatus, progress * _titleExportPercentage);
          }
        });

        if (progressCallback != null) {
          progressCallback(_currentStatus, _titleExportPercentage);
        }
      }

      TextExportData exportedText = TextExportData(
          pickedTextId,
          _textWidget.width,
          _textWidget.height,
          _textWidget.frameRate,
          _textWidget.totalFrameCount,
          _textWidget.previewImagePath ?? "",
          _textWidget.allSequencesPath ?? "");

      EditedTextData editedTextData = EditedTextData(
        exportedText.id,
        0,
        0,
        _textWidget.width * 1.2,
        _textWidget.height * 1.2,
      );
      editedTextData.textExportData = exportedText;

      for (int i = 0; i < texts.length; i++) {
        final String key = "#TEXT${(i + 1)}";
        editedTextData.texts[key] = texts[i];
      }

      double scale = 1.0;
      if (editedTextData.width > maxTextWidth) {
        scale = maxTextWidth / editedTextData.width;
      }
      if (editedTextData.height > maxTextHeight) {
        scale = min(maxTextHeight / exportedText.height, scale);
      }
      editedTextData.width *= scale;
      editedTextData.height *= scale;

      editedTextData.x = (resolution.width / 2) - (editedTextData.width / 2);
      editedTextData.y = (resolution.height / 2) - (editedTextData.height / 2);

      if (allEditedData.ratio == ERatio.ratio916) {
        editedTextData.y *= 0.6;
      }

      allEditedData.editedMediaList[0].editedTexts.add(editedTextData);
    }

    final VideoGeneratedResult result = await _runFFmpeg(
        allEditedData.editedMediaList,
        allEditedData.musicList,
        allEditedData.ratio,
        progressCallback, isAutoEdit: true, isRunFFmpeg: isRunFFmpeg);

    result.speed = allEditedData.speed;
    result.editedMediaList.addAll(allEditedData.editedMediaList);
    result.musicList.addAll(allEditedData.musicList);

    result.renderTimeSec = DateTime.now().difference(now).inMilliseconds / 1000;
    result.titleKey = pickedTextId;
    result.json = parseAllEditedDataToJSON(allEditedData);

    return result;
  }

  Future<VideoGeneratedResult> generateVideoFromJSON(
      String encodedJSON,
      String language,
      Function(EGenerateStatus status, double progress)?
          progressCallback) async {
    AllEditedData allEditedData = parseJSONToAllEditedData(encodedJSON);

    List<EditedTextData> texts = [];
    for (final EditedMedia editedMedia in allEditedData.editedMediaList) {
      if (editedMedia.editedTexts.isNotEmpty) {
        texts.addAll(editedMedia.editedTexts);
      }
    }
    double totalProgress = 0;
    for (final EditedTextData editedText in texts) {
      await _textWidget.loadText(editedText.id,
          initTexts: editedText.texts.values.toList(), language: language);
      await _textWidget.extractAllSequence((progress) {
        if (progressCallback != null) {
          progressCallback(_currentStatus, (totalProgress + (progress / texts.length)) * _titleExportPercentage);
        }
      });
      totalProgress = min(totalProgress + (1.0 / texts.length), 1.0);

      editedText.textExportData = TextExportData(
          editedText.id,
          _textWidget.width,
          _textWidget.height,
          _textWidget.frameRate,
          _textWidget.totalFrameCount,
          _textWidget.previewImagePath!,
          _textWidget.allSequencesPath!);
    }

    final VideoGeneratedResult result = await _runFFmpeg(
        allEditedData.editedMediaList,
        allEditedData.musicList,
        allEditedData.ratio,
        progressCallback);

    return result;
  }

  Future<List<MediaData>> _filterNotExistsMedia(List<MediaData> mediaList) async {
    List<MediaData> result = [];

    for (final media in mediaList) {
      final File file = File(media.absolutePath);
      final bool isExists = await file.exists();

      if (isExists) {
        result.add(media);
      }
    }

    return result;
  }

  int _currentThumbnailExtractCount = 0;
  Future<void> _extractAndMapThumbnail(EditedMedia editedMedia) async {
    while (_currentThumbnailExtractCount >= 5) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _currentThumbnailExtractCount++;
    try {
      editedMedia.thumbnailPath = await extractThumbnail(editedMedia) ?? "";
    }
    catch (e) {
      print(e);
    }
    _currentThumbnailExtractCount--;
  }

  Future<VideoGeneratedResult> _runFFmpeg(
      List<EditedMedia> editedMediaList,
      List<MusicData> musicList,
      ERatio ratio,
      Function(EGenerateStatus status, double progress)?
          progressCallback, { isAutoEdit = false, isRunFFmpeg = true }) async {
    try {
      final List<SpotInfo> spotInfoList = [];
      final List<String> thumbnailList = [];

      setRatio(ratio);

      double currentDuration = 0;
      for (int i = 0; i < editedMediaList.length; i++) {
        spotInfoList.add(
            SpotInfo(currentDuration, editedMediaList[i].mediaData.gpsString));
        currentDuration += editedMediaList[i].duration;
      }

      if (!isRunFFmpeg) {
        // List<Future> extractThumbnailFutures = [];
        // for (int i = 0; i < editedMediaList.length; i++) {
        //   extractThumbnailFutures.add(_extractAndMapThumbnail(editedMediaList[i]));
        // }
        // await Future.wait(extractThumbnailFutures);

        // for (int i = 0; i < editedMediaList.length; i++) {
        //   thumbnailList.add(editedMediaList[i].thumbnailPath!);
        // }

        final VideoGeneratedResult result = VideoGeneratedResult(
          "", spotInfoList, thumbnailList);

        result.editedMediaList.addAll(editedMediaList);
        result.musicList.addAll(musicList);

        return result;
      }

      await ResourceManager.getInstance()
          .loadResourceFromAssets(editedMediaList, ratio);

      _currentStatus = EGenerateStatus.encoding;
      _currentRenderedFrame = 0;
      _maxRenderedFrame = 0;
      _currentRenderedFrameInCallback = 0;
      _allFrame = 0;

      int videoFramerate = getFramerate();
      for (int i = 0; i < editedMediaList.length; i++) {
        final EditedMedia editedMedia = editedMediaList[i];
        double duration =
            normalizeTime(editedMedia.duration + editedMedia.xfadeDuration);
        _allFrame += (duration * videoFramerate).floor();

        if (i < editedMediaList.length - 1) {
          TransitionData? transition = editedMedia.transition;
          if (transition != null && transition.type == ETransitionType.xfade) {
            final EditedMedia nextMedia = editedMediaList[i + 1];
            double duration = normalizeTime(editedMedia.duration +
                nextMedia.duration -
                editedMedia.xfadeDuration -
                0.01);
            _allFrame += (duration * videoFramerate).floor();
          }
        }
      }

      if (_currentTimer != null) {
        _currentTimer!.cancel();
      }

      _currentTimer =
          Timer.periodic(const Duration(milliseconds: 250), (timer) {
        _currentTimer = timer;
        if (progressCallback != null) {
          if (_currentRenderedFrame + _currentRenderedFrameInCallback >
              _maxRenderedFrame) {
            _maxRenderedFrame =
                _currentRenderedFrame + _currentRenderedFrameInCallback;
          }

          progressCallback(
              _currentStatus,
              min(
                  1.0,
                  _titleExportPercentage +
                      (_maxRenderedFrame / _allFrame) *
                          (1 - _titleExportPercentage)));
        }
      });

      DateTime now = DateTime.now();

      final List<RenderedData> clipDataList = [];
      double totalDuration = 0;

      for (int i = 0; i < editedMediaList.length; i++) {
        final EditedMedia editedMedia = editedMediaList[i];

        TransitionData? prevTransition, nextTransition;
        if (i > 0) {
          prevTransition = editedMediaList[i - 1].transition;
        }
        if (i < editedMediaList.length - 1) {
          nextTransition = editedMediaList[i].transition;
        }

        final RenderedData clipData = await clipRender(
            editedMedia,
            i,
            prevTransition,
            nextTransition,
            (statistics) => _currentRenderedFrameInCallback =
                statistics.getVideoFrameNumber(), isOnlyOneClip: editedMediaList.length == 1);

        _currentRenderedFrameInCallback = 0;

        double duration =
            normalizeTime(editedMedia.duration + editedMedia.xfadeDuration);
        _currentRenderedFrame += (duration * videoFramerate).floor();

        clipDataList.add(clipData);

        String thumbnailPath = await extractThumbnail(editedMediaList[i]) ?? "";
        editedMedia.thumbnailPath = thumbnailPath;
        thumbnailList.add(thumbnailPath);

        totalDuration += editedMedia.duration;
      }

      final List<RenderedData> xfadeAppliedList = [];
      for (int i = 0; i < clipDataList.length; i++) {
        final RenderedData curRendered = clipDataList[i];
        final EditedMedia editedMedia = editedMediaList[i];
        TransitionData? xfadeTransition = editedMediaList[i].transition;

        if (i < editedMediaList.length - 1 &&
            editedMedia.xfadeDuration > 0 &&
            xfadeTransition != null &&
            xfadeTransition.type == ETransitionType.xfade) {
          //
          final RenderedData nextRendered = clipDataList[i + 1];

          final RenderedData xfadeApplied = await applyXFadeTransitions(
              curRendered,
              nextRendered,
              i,
              (xfadeTransition as XFadeTransitionData).filterName,
              editedMedia.xfadeDuration,
              (statistics) => _currentRenderedFrameInCallback =
                  statistics.getVideoFrameNumber());

          _currentRenderedFrameInCallback = 0;
          double duration = normalizeTime(curRendered.duration +
              nextRendered.duration -
              editedMedia.xfadeDuration -
              0.01);
          _currentRenderedFrame += (duration * videoFramerate).floor();

          xfadeAppliedList.add(xfadeApplied);
          i++;
        } //
        else {
          xfadeAppliedList.add(curRendered);
        }
      }

      // if (isAutoEdit && editedMediaList.length > 1 && totalDuration >= 10) {
      //   double curDuration = 0;
      //   List<RenderedData> fadeOutClips = [];
      //   for (int i = xfadeAppliedList.length - 1; i >= 0; i--) {
      //     RenderedData lastClip = xfadeAppliedList.removeLast();
      //     fadeOutClips.add(lastClip);
          
      //     curDuration += lastClip.duration;
      //     if (curDuration >= 2) {
      //       final RenderedData fadeOutApplied =
      //           await applyFadeOut(fadeOutClips.reversed.toList());

      //       xfadeAppliedList.add(fadeOutApplied);
      //       break;
      //     }
      //   }
      // }

      _currentStatus = EGenerateStatus.finishing;
      _currentRenderedFrame = _allFrame;

      List<MusicData> regeneratedMusicList = [];
      if (musicList.isNotEmpty) {
        int currentMusicIndex = 0;
        double remainTotalDuration = totalDuration;

        while (remainTotalDuration > 0) {
          MusicData musicData = musicList[currentMusicIndex % musicList.length];
          regeneratedMusicList.add(musicData);

          remainTotalDuration -= musicData.duration;
          currentMusicIndex++;
        }
      }

      final RenderedData mergedClip = await mergeAllClips(xfadeAppliedList);
      final RenderedData resultClip = await applyMusics(mergedClip, regeneratedMusicList);

      print("elapsed time for rendering : ${DateTime.now().difference(now).inMilliseconds / 1000}s");
      
      File resultFile = File(resultClip.absolutePath);
      if (await resultFile.exists()) {
        double fileSizeInMegaBytes = ((await resultFile.length()) * 1.0) / 1024 / 1024;
        print("resultFile : ${(fileSizeInMegaBytes * 100).floor() / 100}MB");
      }

      if (_currentTimer != null) {
        _currentTimer!.cancel();
      }
      _currentTimer = null;

      if (progressCallback != null) {
        progressCallback(_currentStatus, 1);
      }

      final VideoGeneratedResult result = VideoGeneratedResult(
          resultClip.absolutePath, spotInfoList, thumbnailList);

      result.editedMediaList.addAll(editedMediaList);
      result.musicList.addAll(musicList);

      return result;
    } //
    catch (e) {
      if (_currentTimer != null) {
        _currentTimer!.cancel();
      }
      _currentTimer = null;

      rethrow;
    }
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
    return Transform.translate(
        offset: const Offset(-9999999, -99999),
        child: Stack(children: [
          _textWidget,
          TextBoxBuilder(controller: _textBoxConfigController, config: _textConfig)
        ]));
  }
}

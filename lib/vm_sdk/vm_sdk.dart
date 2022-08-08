import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:myapp/vm_sdk/impl/text_helper.dart';

import 'impl/convert_helper.dart';
import 'types/types.dart';
import 'impl/ffmpeg_manager.dart';
import 'impl/resource_manager.dart';
import 'impl/auto_edit_helper.dart';
import 'impl/ml_kit_helper.dart';
import 'impl/vm_text_widget.dart';

import 'impl/ffmpeg_helper.dart';

const double _titleExportPercentage = 1 / 3.0;

class VMSDKWidget extends StatelessWidget {
  VMSDKWidget({Key? key}) : super(key: key);

  final VMTextWidget _textWidget = VMTextWidget();

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
      EMusicStyle? style,
      bool isAutoEdit,
      List<String> texts,
      String language,
      Function(EGenerateStatus status, double progress)?
          progressCallback) async {
    DateTime now = DateTime.now();
    _currentStatus = EGenerateStatus.titleExport;

    EMusicStyle selectedStyle;
    if (style != null) {
      selectedStyle = style;
    } //
    else {
      const List<EMusicStyle> randomStyleList = [
        EMusicStyle.beautiful,
        EMusicStyle.upbeat,
        EMusicStyle.hopeful,
        EMusicStyle.inspiring,
        EMusicStyle.fun,
        EMusicStyle.joyful,
        EMusicStyle.happy,
        EMusicStyle.cheerful,
        EMusicStyle.energetic
      ];

      selectedStyle = randomStyleList[
          Random().nextInt(randomStyleList.length) % randomStyleList.length];
    }

    List<TemplateData> templateList = [];
    templateList.addAll(
        (ResourceManager.getInstance().getTemplateData(selectedStyle) ??
            ResourceManager.getInstance().getTemplateData(EMusicStyle.fun)!));

    List<TemplateData> randomSortedTemplateList = [];
    while (templateList.isNotEmpty) {
      int randIdx =
          (Random()).nextInt(templateList.length) % templateList.length;
      randomSortedTemplateList.add(templateList[randIdx]);
      templateList.removeAt(randIdx);
    }

    final AllEditedData allEditedData = await generateAllEditedData(
        mediaList, selectedStyle, randomSortedTemplateList, isAutoEdit);

    List<String> textIds;
    if (texts.length >= 2) {
      textIds = ResourceManager.getInstance().getTwoLineTextList();
    }
    //
    else {
      textIds = ResourceManager.getInstance().getOneLineTextList();
    }
    final String pickedTextId =
        textIds[(Random()).nextInt(textIds.length) % textIds.length];
    await _textWidget.loadText(pickedTextId);

    for (int i = 0; i < texts.length; i++) {
      final String key = "#TEXT${(i + 1)}";
      await _textWidget.setTextValue(key, texts[i],
          isExtractPreviewImmediate: false);
    }
    await _textWidget.extractAllSequence((progress) {
      if (progressCallback != null) {
        progressCallback(_currentStatus, progress * _titleExportPercentage);
      }
    });

    if (progressCallback != null) {
      progressCallback(_currentStatus, _titleExportPercentage);
    }

    TextExportData exportedText = TextExportData(
        pickedTextId,
        _textWidget.width * 1.3,
        _textWidget.height * 1.3,
        _textWidget.frameRate,
        _textWidget.previewImagePath!,
        _textWidget.allSequencesPath!);

    for (int i = 0; i < texts.length; i++) {
      final String key = "#TEXT${(i + 1)}";
      exportedText.texts[key] = texts[i];
    }

    Resolution resolution = allEditedData.resolution;
    final int maxTextWidth = (resolution.width * 0.9).floor();
    final int maxTextHeight = (resolution.height * 0.9).floor();
    
    exportedText.scale = 1;
    if (exportedText.width > maxTextWidth) {
      exportedText.scale = maxTextWidth / exportedText.width;
    }
    if (exportedText.height > maxTextHeight) {
      exportedText.scale = min(maxTextHeight / exportedText.height, exportedText.scale);
    }

    exportedText.x =
        (resolution.width / 2) - (exportedText.width * exportedText.scale / 2);
    exportedText.y = (resolution.height / 2) -
        (exportedText.height * exportedText.scale / 2);

    allEditedData.editedMediaList[0].exportedText = exportedText;

    final VideoGeneratedResult result = await _runFFmpeg(
        allEditedData.editedMediaList,
        allEditedData.musicList,
        allEditedData.ratio,
        progressCallback);

    result.musicStyle = selectedStyle;
    result.editedMediaList.addAll(allEditedData.editedMediaList);
    result.musicList.addAll(allEditedData.musicList);

    result.renderTimeSec = DateTime.now().difference(now).inMilliseconds / 1000;
    result.titleKey = pickedTextId;
    result.json = parseAllEditedDataToJSON(allEditedData);

    return result;
  }

  Future<VideoGeneratedResult> generateVideoFromJSON(
      String encodedJSON,
      Function(EGenerateStatus status, double progress)?
          progressCallback) async {
    AllEditedData allEditedData = parseJSONToAllEditedData(encodedJSON);

    final VideoGeneratedResult result = await _runFFmpeg(
        allEditedData.editedMediaList,
        allEditedData.musicList,
        allEditedData.ratio,
        progressCallback);

    return result;
  }

  Future<VideoGeneratedResult> _runFFmpeg(
      List<EditedMedia> editedMediaList,
      List<MusicData> musicList,
      ERatio ratio,
      Function(EGenerateStatus status, double progress)?
          progressCallback) async {
    try {
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

      setRatio(ratio);
      DateTime now = DateTime.now();

      final List<RenderedData> clipDataList = [];
      final List<String> thumbnailList = [];
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

        final RenderedData? clipData = await clipRender(
            editedMedia,
            i,
            prevTransition,
            nextTransition,
            (statistics) => _currentRenderedFrameInCallback =
                statistics.getVideoFrameNumber());

        _currentRenderedFrameInCallback = 0;

        double duration =
            normalizeTime(editedMedia.duration + editedMedia.xfadeDuration);
        _currentRenderedFrame += (duration * videoFramerate).floor();

        if (clipData == null) throw Exception("ERR_CLIP_RENDER_FAILED");
        clipDataList.add(clipData);

        thumbnailList.add(await extractThumbnail(editedMediaList[i], i) ?? "");
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

          final RenderedData? xfadeApplied = await applyXFadeTransitions(
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

          if (xfadeApplied == null) {
            throw Exception("ERR_TRANSITION_RENDER_FAILED");
          }
          xfadeAppliedList.add(xfadeApplied);
          i++;
        } //
        else {
          xfadeAppliedList.add(curRendered);
        }
      }

      if (totalDuration >= 10) {
        double curDuration = 0;
        List<RenderedData> fadeOutClips = [];
        for (int i = xfadeAppliedList.length - 1; i >= 0; i--) {
          RenderedData lastClip = xfadeAppliedList.removeLast();
          fadeOutClips.add(lastClip);
          
          curDuration += lastClip.duration;
          if (curDuration >= 3) break;
        }

        final RenderedData? fadeOutApplied =
            await applyFadeOut(fadeOutClips.reversed.toList());
        
        if (fadeOutApplied == null) {
          throw Exception("ERR_FADE_OUT_RENDER_FAILED");
        }

        xfadeAppliedList.add(fadeOutApplied);
      }

      _currentStatus = EGenerateStatus.finishing;
      _currentRenderedFrame = _allFrame;

      final RenderedData? mergedClip = await mergeVideoClip(xfadeAppliedList);
      if (mergedClip == null) throw Exception("ERR_MERGE_FAILED");

      final RenderedData? resultClip = await applyMusics(mergedClip, musicList);
      if (resultClip == null) throw Exception("ERR_APPLY_MUSIC_FAILED");

      print(DateTime.now().difference(now).inSeconds);

      if (_currentTimer != null) {
        _currentTimer!.cancel();
      }
      _currentTimer = null;

      final List<SpotInfo> spotInfoList = [];
      double currentDuration = 0;
      for (int i = 0; i < editedMediaList.length; i++) {
        spotInfoList.add(
            SpotInfo(currentDuration, editedMediaList[i].mediaData.gpsString));
        currentDuration += editedMediaList[i].duration;
      }

      if (progressCallback != null) {
        progressCallback(_currentStatus, 1);
      }

      final VideoGeneratedResult result =  VideoGeneratedResult(
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
    return _textWidget;
  }
}

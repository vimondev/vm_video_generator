import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:myapp/vm_sdk/impl/text_helper.dart';

import 'types/types.dart';
import 'impl/template_helper.dart';
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
  final ResourceManager _resourceManager = ResourceManager();

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
  Future<VideoGeneratedResult?> generateVideo(
      List<MediaData> mediaList,
      EMusicStyle? style,
      bool isAutoEdit,
      List<String> texts,
      Function(EGenerateStatus status, double progress)?
          progressCallback) async {
    try {
      _currentStatus = EGenerateStatus.titleExport;

      EMusicStyle selectedStyle = style ?? EMusicStyle.styleA;
      final List<TemplateData>? templateList =
          await loadTemplateData(selectedStyle);
      if (templateList == null) return null;

      final AutoEditedData autoEditedData = await generateAutoEditData(
          mediaList, selectedStyle, templateList, isAutoEdit);

      await _resourceManager.loadAutoEditAssets(autoEditedData);

      List<ETextID> textIds;
      if (texts.length >= 2) {
        textIds = twoLineTitles;
      }
      //
      else {
        textIds = oneLineTitles;
      }
      final ETextID pickedTextId = textIds[(Random()).nextInt(textIds.length) % textIds.length];
      await _textWidget.loadText(pickedTextId);

      for (int i=0; i<texts.length; i++) {
        final String key = "#TEXT${(i + 1)}";
        await _textWidget.setTextValue(key, texts[i], isExtractPreviewImmediate: false);
      }
      await _textWidget.extractAllSequence((progress) {
        if (progressCallback != null) {
          progressCallback(_currentStatus, progress * _titleExportPercentage);
        }
      });

      if (progressCallback != null) {
        progressCallback(_currentStatus, _titleExportPercentage);
      }

      ExportedTextPNGSequenceData exportedTextData =
          ExportedTextPNGSequenceData(
              _textWidget.allSequencesPath!,
              _textWidget.width.floor(),
              _textWidget.height.floor(),
              _textWidget.frameRate);

      final List<AutoEditMedia> autoEditMediaList =
          autoEditedData.autoEditMediaList;
      final Map<String, TransitionData> transitionMap =
          autoEditedData.transitionMap;
      final Map<String, FrameData> frameMap = autoEditedData.frameMap;
      final Map<String, StickerData> stickerMap = autoEditedData.stickerMap;

      _currentStatus = EGenerateStatus.encoding;
      _currentRenderedFrame = 0;
      _maxRenderedFrame = 0;
      _currentRenderedFrameInCallback = 0;
      _allFrame = 0;

      int videoFramerate = getFramerate();
      for (int i = 0; i < autoEditMediaList.length; i++) {
        final AutoEditMedia autoEditMedia = autoEditMediaList[i];
        double duration =
            normalizeTime(autoEditMedia.duration + autoEditMedia.xfadeDuration);
        _allFrame += (duration * videoFramerate).floor();

        if (i < autoEditMediaList.length - 1) {
          TransitionData? transition =
              transitionMap[autoEditMedia.transitionKey];
          if (transition != null && transition.type == ETransitionType.xfade) {
            final AutoEditMedia nextMedia = autoEditMediaList[i + 1];
            double duration = normalizeTime(autoEditMedia.duration +
                nextMedia.duration -
                autoEditMedia.xfadeDuration -
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
              _currentStatus, min(1.0, _titleExportPercentage + (_maxRenderedFrame / _allFrame) * (1 - _titleExportPercentage)));
        }
      });

      setRatio(autoEditedData.ratio);
      DateTime now = DateTime.now();

      final List<RenderedData> clipDataList = [];
      for (int i = 0; i < autoEditMediaList.length; i++) {
        final AutoEditMedia autoEditMedia = autoEditMediaList[i];
        final FrameData? frameData = frameMap[autoEditMedia.frameKey];
        final StickerData? stickerData = stickerMap[autoEditMedia.stickerKey];

        TransitionData? prevTransition, nextTransition;
        if (i > 0) {
          prevTransition =
              transitionMap[autoEditMediaList[i - 1].transitionKey];
        }
        if (i < autoEditMediaList.length - 1) {
          nextTransition = transitionMap[autoEditMediaList[i].transitionKey];
        }

        final RenderedData? clipData = await clipRender(
            autoEditMedia,
            i,
            frameData,
            stickerData,
            prevTransition,
            nextTransition,
            i == 0 ? exportedTextData : null,
            (statistics) =>
                _currentRenderedFrameInCallback = statistics.videoFrameNumber);

        _currentRenderedFrameInCallback = 0;

        double duration =
            normalizeTime(autoEditMedia.duration + autoEditMedia.xfadeDuration);
        _currentRenderedFrame += (duration * videoFramerate).floor();

        if (clipData == null) return null;
        clipDataList.add(clipData);
      }

      final List<RenderedData> xfadeAppliedList = [];
      for (int i = 0; i < clipDataList.length; i++) {
        final RenderedData curRendered = clipDataList[i];
        final AutoEditMedia autoEditMedia = autoEditMediaList[i];
        TransitionData? xfadeTransition =
            transitionMap[autoEditMediaList[i].transitionKey];

        if (i < autoEditMediaList.length - 1 &&
            autoEditMedia.xfadeDuration > 0 &&
            xfadeTransition != null &&
            xfadeTransition.type == ETransitionType.xfade) {
          //
          final RenderedData nextRendered = clipDataList[i + 1];

          final RenderedData? xfadeApplied = await applyXFadeTransitions(
              curRendered,
              nextRendered,
              i,
              (xfadeTransition as XFadeTransitionData).filterName,
              autoEditMedia.xfadeDuration,
              (statistics) => _currentRenderedFrameInCallback =
                  statistics.videoFrameNumber);

          _currentRenderedFrameInCallback = 0;
          double duration = normalizeTime(curRendered.duration +
              nextRendered.duration -
              autoEditMedia.xfadeDuration -
              0.01);
          _currentRenderedFrame += (duration * videoFramerate).floor();

          if (xfadeApplied == null) return null;
          xfadeAppliedList.add(xfadeApplied);
          i++;
        } //
        else {
          xfadeAppliedList.add(curRendered);
        }
      }

      _currentStatus = EGenerateStatus.finishing;
      _currentRenderedFrame = _allFrame;

      final RenderedData? mergedClip = await mergeVideoClip(xfadeAppliedList);
      if (mergedClip == null) return null;

      final RenderedData? resultClip =
          await applyMusics(mergedClip, autoEditedData.musicList);
      if (resultClip == null) return null;

      print(DateTime.now().difference(now).inSeconds);

      if (_currentTimer != null) {
        _currentTimer!.cancel();
      }
      _currentTimer = null;

      final List<SpotInfo> spotInfoList = [];
      double currentDuration = 0;
      for (int i=0; i<autoEditMediaList.length; i++) {
        spotInfoList.add(SpotInfo(currentDuration, autoEditMediaList[i].mediaData.gpsString));
        currentDuration += autoEditMediaList[i].duration;
      }

      if (progressCallback != null) {
        progressCallback(_currentStatus, 1);
      }

      return VideoGeneratedResult(resultClip.absolutePath, autoEditedData, spotInfoList);
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

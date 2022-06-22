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

      await ResourceManager.getInstance().loadAutoEditAssets(autoEditedData);

      List<ETextID> textIds;
      if (texts.length >= 2) {
        textIds = twoLineTitles;
      }
      //
      else {
        textIds = oneLineTitles;
      }
      final ETextID pickedTextId =
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
          _textWidget.width,
          _textWidget.height,
          _textWidget.frameRate,
          _textWidget.previewImagePath!,
          _textWidget.allSequencesPath!);

      for (int i = 0; i < texts.length; i++) {
        final String key = "#TEXT${(i + 1)}";
        exportedText.texts[key] = texts[i];
      }

      Resolution resolution = autoEditedData.resolution;
      final int maxTextWidth = (resolution.width * 0.9).floor();
      if (exportedText.width > maxTextWidth) {
        exportedText.scale = maxTextWidth / exportedText.width;
      }
      else {
        exportedText.scale = 1;
      }

      exportedText.x = (resolution.width / 2) - (exportedText.width * exportedText.scale / 2);
      exportedText.y = (resolution.height / 2) - (exportedText.height * exportedText.scale / 2);

      final List<EditedMedia> editedMediaList = autoEditedData.editedMediaList;

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

      setRatio(autoEditedData.ratio);
      DateTime now = DateTime.now();

      final List<RenderedData> clipDataList = [];
      final List<String> thumbnailList = [];

      for (int i = 0; i < editedMediaList.length; i++) {
        final EditedMedia editedMedia = editedMediaList[i];
        final FrameData? frameData = editedMedia.frame;
        final StickerData? stickerData = editedMedia.sticker;

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
            frameData,
            stickerData,
            prevTransition,
            nextTransition,
            i == 0 ? exportedText : null,
            (statistics) => _currentRenderedFrameInCallback =
                statistics.getVideoFrameNumber());

        _currentRenderedFrameInCallback = 0;

        double duration =
            normalizeTime(editedMedia.duration + editedMedia.xfadeDuration);
        _currentRenderedFrame += (duration * videoFramerate).floor();

        if (clipData == null) return null;
        clipDataList.add(clipData);

        thumbnailList.add(await extractThumbnail(editedMediaList[i], i) ?? "");
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
      for (int i = 0; i < editedMediaList.length; i++) {
        spotInfoList.add(
            SpotInfo(currentDuration, editedMediaList[i].mediaData.gpsString));
        currentDuration += editedMediaList[i].duration;
      }

      if (progressCallback != null) {
        progressCallback(_currentStatus, 1);
      }

      return VideoGeneratedResult(
          resultClip.absolutePath, autoEditedData, spotInfoList, thumbnailList);
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

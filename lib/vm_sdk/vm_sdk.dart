import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

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
    mediaList = await _scaleImageMedia(mediaList);

    final AllEditedData allEditedData = await generateAllEditedData(
        mediaList, style, randomSortedTemplateList, isAutoEdit);

    List<TextData> textDatas = ResourceManager.getInstance().getTextDataList(lineCount: texts.length, speed: allEditedData.speed);
    if (textDatas.isEmpty) {
      textDatas = ResourceManager.getInstance().getTextDataList(lineCount: texts.length);
    }
    final TextData pickedText = textDatas[(Random()).nextInt(textDatas.length) % textDatas.length];
    final String pickedTextId = pickedText.key;

    await _textWidget.loadText(pickedTextId, initTexts: texts);

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
        _textWidget.totalFrameCount,
        _textWidget.previewImagePath!,
        _textWidget.allSequencesPath!,
        _textWidget.textDataMap);

    EditedTextData editedTextData = EditedTextData(
      exportedText.id,
      0,
      0,
      _textWidget.width * 1.3,
      _textWidget.height * 1.3,
    );
    editedTextData.textExportData = exportedText;

    for (int i = 0; i < texts.length; i++) {
      final String key = "#TEXT${(i + 1)}";
      editedTextData.texts[key] = texts[i];
    }

    Resolution resolution = allEditedData.resolution;
    final int maxTextWidth = resolution.width;
    final int maxTextHeight = resolution.height;

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

    final VideoGeneratedResult result = await _runFFmpeg(
        allEditedData.editedMediaList,
        allEditedData.musicList,
        allEditedData.ratio,
        progressCallback);

    result.musicStyle = allEditedData.style;
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

    List<EditedTextData> texts = [];
    for (final EditedMedia editedMedia in allEditedData.editedMediaList) {
      if (editedMedia.editedTexts.isNotEmpty) {
        texts.addAll(editedMedia.editedTexts);
      }
    }
    double totalProgress = 0;
    for (final EditedTextData editedText in texts) {
      await _textWidget.loadText(editedText.id,
          initTexts: editedText.texts.values.toList());
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
          _textWidget.allSequencesPath!,
          _textWidget.textDataMap);
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

  Future<List<MediaData>> _scaleImageMedia(List<MediaData> mediaList) async {
    List<MediaData> result = [];

    for (int i=0; i<mediaList.length; i++) {
      final media = mediaList[i];
      MediaData newMedia = await scaleImageMedia(media);

      result.add(newMedia);
    }

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

        final RenderedData clipData = await clipRender(
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

      if (totalDuration >= 10) {
        double curDuration = 0;
        List<RenderedData> fadeOutClips = [];
        for (int i = xfadeAppliedList.length - 1; i >= 0; i--) {
          RenderedData lastClip = xfadeAppliedList.removeLast();
          fadeOutClips.add(lastClip);
          
          curDuration += lastClip.duration;
          if (curDuration >= 2) {
            final RenderedData fadeOutApplied =
                await applyFadeOut(fadeOutClips.reversed.toList());

            xfadeAppliedList.add(fadeOutApplied);
            break;
          }
        }
      }

      _currentStatus = EGenerateStatus.finishing;
      _currentRenderedFrame = _allFrame;

      final RenderedData mergedClip = await mergeAllClips(xfadeAppliedList);
      final RenderedData resultClip = await applyMusics(mergedClip, musicList);

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

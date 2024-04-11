import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:path/path.dart';

import 'resource_manager.dart';

import '../types/types.dart';
import 'global_helper.dart';
import 'type_helper.dart';
import 'resource_fetch_helper.dart';

class _GetMusicResponse {
  EMusicSpeed musicSpeed;
  List<MusicData> musicList;

  _GetMusicResponse(this.musicSpeed, this.musicList);
}

Map<int, EMediaLabel> _classifiedLabelMap = {};
Map<int, bool> _definitiveLabelMap = {};

Future<void> loadLabelMap() async {
  List classifiedList =
      jsonDecode(await loadResourceString("data/mlkit-label-classified.json"));
  List definitiveList =
      jsonDecode(await loadResourceString("data/mlkit-label-definitive.json"));

  for (final Map map in classifiedList) {
    int id = map["id"];
    String type = map["type"];
    EMediaLabel mediaLabel = getMediaLabel(type);

    _classifiedLabelMap[id] = mediaLabel;
  }

  for (final int id in definitiveList) {
    _definitiveLabelMap[id] = true;
  }
}

Future<EMediaLabel> _detectMediaLabel(
    EditedMedia media, MLKitDetected detected) async {
  EMediaLabel mediaLabel = EMediaLabel.none;
  final Map<EMediaLabel, double> labelConfidenceMap = {
    EMediaLabel.background: 0,
    EMediaLabel.person: 0,
    EMediaLabel.action: 0,
    EMediaLabel.object: 0,
    EMediaLabel.food: 0,
    EMediaLabel.animal: 0,
    EMediaLabel.others: 0
  };

  List<DetectedFrameData> detectedList = [];
  if (media.mediaData.type == EMediaType.image) {
    detectedList.addAll(detected.list);
  } //
  else if (media.mediaData.type == EMediaType.video) {
    final int startIndex = (media.startTime / (1.0 / detected.fps)).floor();
    final int endIndex =
        ((media.startTime + media.duration) / (1.0 / detected.fps)).floor();

    for (int i = startIndex; i <= endIndex && i < detected.list.length; i++) {
      detectedList.add(detected.list[i]);
    }
  }

  for (final DetectedFrameData frameData in detectedList) {
    for (final ImageLabel imageLabel in frameData.labelList) {
      EMediaLabel mediaLabel = _classifiedLabelMap[imageLabel.index]!;
      double threshold = 1.0;

      if (mediaLabel == EMediaLabel.person) {
        threshold *= 4.0;
      } //
      else if (mediaLabel == EMediaLabel.background ||
          mediaLabel == EMediaLabel.animal ||
          mediaLabel == EMediaLabel.food) {
        threshold *= 2.0;
      }

      labelConfidenceMap[mediaLabel] =
          labelConfidenceMap[mediaLabel]! + imageLabel.confidence * threshold;
    }
  }

  double maxValue = -1;
  for (final entry in labelConfidenceMap.entries) {
    if (entry.value > maxValue) {
      maxValue = entry.value;
      mediaLabel = entry.key;
    }
  }

  return mediaLabel;
}

ERatio detectRatio(List<EditedMedia> list) {
  Map<ERatio, int> ratioCountMap = {
    ERatio.ratio11: 0,
    ERatio.ratio169: 0,
    ERatio.ratio916: 0
  };

  const aspectRatio169 = 16.0 / 9.0;
  const aspectRatio11 = 1;
  const aspectRatio916 = 9.0 / 16.0;

  for (int i = 0; i < list.length; i++) {
    final int width = list[i].mediaData.width;
    final int height = list[i].mediaData.height;
    final double aspectRatio = (width * 1.0) / height;

    // 1:1 ~ 16:9의 중간값 이상
    if (aspectRatio >= (aspectRatio11 + aspectRatio169) / 2.0) {
      ratioCountMap[ERatio.ratio169] = ratioCountMap[ERatio.ratio169]! + 1;
    }
    // 1:1 ~ 9:16의 중간값 이하
    else if (aspectRatio <= (aspectRatio11 + aspectRatio916) / 2.0) {
      ratioCountMap[ERatio.ratio916] = ratioCountMap[ERatio.ratio916]! + 1;
    } else {
      ratioCountMap[ERatio.ratio11] = ratioCountMap[ERatio.ratio11]! + 1;
    }
  }

  // 60% 이상이면 해당 해상도 적용
  if (ratioCountMap[ERatio.ratio169]! / list.length >= 0.6) {
    return ERatio.ratio169;
  }
  //
  else if (ratioCountMap[ERatio.ratio916]! / list.length >= 0.6) {
    return ERatio.ratio916;
  }

  // 나머지는 1:1 적용
  return ERatio.ratio11;
}

Future<AllEditedData> generateAllEditedData(
    List<MediaData> list,
    EMusicSpeed? musicSpeed,
    List<TemplateData> templateList,
    bool isAutoSelect,
    { isRunFFmpeg = true }) async {
  final AllEditedData allEditedData = AllEditedData();

  list.sort((a, b) => a.createDate.compareTo(b.createDate));

  final musicsData = await _getMusics(musicSpeed);

  final List<MusicData> musicList = musicsData.musicList;
  allEditedData.speed = musicsData.musicSpeed;

  print("curSpeed : ${allEditedData.speed}");

  bool isUseTemplateDuration = false;

  if (list.length >= 10) {
    switch (allEditedData.speed) {
      case EMusicSpeed.mm:
      case EMusicSpeed.f:
      case EMusicSpeed.ff:
        isUseTemplateDuration = true;
        break;

      default:
        break;
    }
  }

  ////////////////////////////////////
  // GENERATE MLKIT DETECTED OBJECT //
  ////////////////////////////////////

  final Map<MediaData, MLKitDetected> mlkitMap = {};
  final Map<MediaData, Map<int, double>> mediaAllLabelConfidenceMap = {};
  for (int i = 0; i < list.length; i++) {
    final MediaData media = list[i];
    final Map<int, double> allLabelConfidence = {};

    MLKitDetected detected = MLKitDetected.fromJson(media.mlkitDetected!);

    for (int j = 0; j < detected.list.length; j++) {
      final DetectedFrameData frameData = detected.list[j];

      for (int k = 0; k < frameData.labelList.length; k++) {
        final ImageLabel label = frameData.labelList[k];

        if (!allLabelConfidence.containsKey(label.index)) {
          allLabelConfidence[label.index] = 0;
        }
        allLabelConfidence[label.index] =
            allLabelConfidence[label.index]! + label.confidence;
      }
    }

    for (final key in allLabelConfidence.keys) {
      allLabelConfidence[key] = allLabelConfidence[key]! / detected.list.length;
    }

    mediaAllLabelConfidenceMap[media] = allLabelConfidence;
    mlkitMap[media] = detected;
  }

  /////////////////////
  // SET MEDIA GROUP //
  /////////////////////

  final Map<int, List<MediaData>> groupMap = <int, List<MediaData>>{};
  int curGroupIndex = 0;

  if (list.length > 1) {
    for (int i = 0; i < list.length - 1; i++) {
      final MediaData curData = list[i], nextData = list[i + 1];
      bool isGrouped = false;

      final int totalSecondsDiff =
          (curData.createDate.difference(nextData.createDate).inSeconds).abs();
      final int minutesDiff = ((totalSecondsDiff / 60) % 60).floor();
      final int hoursDiff = ((totalSecondsDiff / 3600) % 60).floor();

      if (minutesDiff >= 30 || hoursDiff >= 1) {
        isGrouped = true;
      } //
      else if (curData.gpsData.latitude.length >= 3 &&
          curData.gpsData.longitude.length >= 3 &&
          nextData.gpsData.latitude.length >= 3 &&
          nextData.gpsData.longitude.length >= 3) {
        for (int j = 0; j < 3; j++) {
          final diffThreshold = j <= 1 ? 0 : 15;
          final double latitudeDiff =
              (curData.gpsData.latitude[j] - nextData.gpsData.latitude[j])
                  .abs();
          final double longitudeDiff =
              (curData.gpsData.longitude[j] - nextData.gpsData.longitude[j])
                  .abs();

          if (latitudeDiff > diffThreshold || longitudeDiff > diffThreshold) {
            isGrouped = true;
            break;
          }
        }
      }

      if (!groupMap.containsKey(curGroupIndex)) {
        groupMap[curGroupIndex] = <MediaData>[];
      }
      groupMap[curGroupIndex]!.add(curData);

      if (isGrouped) {
        curGroupIndex++;
      }

      // last Element
      if (i + 1 == list.length - 1) {
        if (!groupMap.containsKey(curGroupIndex)) {
          groupMap[curGroupIndex] = <MediaData>[];
        }
        groupMap[curGroupIndex]!.add(nextData);
      }
    }
  }
  //
  else {
    groupMap[curGroupIndex] = <MediaData>[];
    groupMap[curGroupIndex]!.add(list[0]);
  }

  ////////////////////////////////////////////
  // MEDIA FILTERING, REMOVE DUPLICATE CLIP //
  ////////////////////////////////////////////

  int totalMediaCount = list.length;
  if (isAutoSelect) {
    // MEDIA FILTERING
    for (final entry in groupMap.entries) {
      if (totalMediaCount < 20) break;

      final int key = entry.key;
      final List<MediaData> curList = entry.value;

      for (int i = 0; i < curList.length; i++) {
        final MediaData data = curList[i];
        bool isShortVideo = false, isFewObject = false;
        bool isContainDefinitiveLabel = false;
        bool isRemove = false;

        // less than 3 seconds (video)
        if (data.type == EMediaType.video &&
            data.duration != null &&
            data.duration! < 3) {
          isShortVideo = true;
        }

        // Detected ImageLabels <= 4
        Map<int, double> labelMap = mediaAllLabelConfidenceMap[data]!;
        if (labelMap.length <= 4) {
          isFewObject = true;
        }

        // If contain definitve label, pass
        for (final label in labelMap.entries) {
          if (_definitiveLabelMap.containsKey(label.key)) {
            isContainDefinitiveLabel = true;
            break;
          }
        }

        if (isShortVideo) {
          isRemove = true;
        } //
        else if (!isContainDefinitiveLabel) {
          if (isFewObject) isRemove = true;
        }

        if (isRemove) {
          curList.removeAt(i);
          i--;
          totalMediaCount--;
        }
        if (totalMediaCount < 20) break;
      }
    }

    // REMOVE DUPLICATE CLIP
    for (final entry in groupMap.entries) {
      if (totalMediaCount < 20) break;

      final List<MediaData> curList = entry.value;
      int startSimilarIndex = -1, endSimilarIndex = -1;

      for (int i = 0; i < curList.length - 1; i++) {
        final MediaData cur = curList[i], next = curList[i + 1];

        final Map<int, double> curLabelMap = mediaAllLabelConfidenceMap[cur]!,
            nextLabelMap = mediaAllLabelConfidenceMap[next]!;
        final Map<int, bool> allLabelMap = {};

        for (final label in curLabelMap.entries) {
          if (label.value >= 0.1) {
            allLabelMap[label.key] = true;
          }
        }
        for (final label in nextLabelMap.entries) {
          if (label.value >= 0.1) {
            allLabelMap[label.key] = true;
          }
        }

        double similarity = 0;
        for (final labelKey in allLabelMap.keys) {
          double curConfidence =
              curLabelMap.containsKey(labelKey) ? curLabelMap[labelKey]! : 0;
          double nextConfidence =
              nextLabelMap.containsKey(labelKey) ? nextLabelMap[labelKey]! : 0;

          similarity += min(curConfidence, nextConfidence) /
              max(curConfidence, nextConfidence);
        }
        similarity /= allLabelMap.length;

        if (similarity >= 0.4) {
          if (startSimilarIndex == -1) {
            startSimilarIndex = i;
          }
          endSimilarIndex = i + 1;
        } //
        else {
          if (startSimilarIndex != -1 && endSimilarIndex != -1) {
            int duplicatedCount = endSimilarIndex - startSimilarIndex + 1;
            int picked =
                startSimilarIndex + (Random()).nextInt(duplicatedCount);

            final List<MediaData> removeTargets = [];
            for (int j = startSimilarIndex;
                j <= endSimilarIndex && j < curList.length;
                j++) {
              if (picked != j) removeTargets.add(curList[j]);
            }

            for (final MediaData deleteTarget in removeTargets) {
              curList.remove(deleteTarget);
              totalMediaCount--;
              if (totalMediaCount < 20) break;
            }

            i = startSimilarIndex;
            startSimilarIndex = endSimilarIndex = -1;

            if (totalMediaCount < 20) break;
          }
        }
      }
    }
  }

  ////////////////////////////////////////
  // SET CLIP DURATION, SET MEDIA LABEL //
  ////////////////////////////////////////

  final List<double> durationList = [];
  for (int i = 0; i < templateList.length; i++) {
    final List<SceneData> scenes = templateList[i].scenes;

    for (int j = 0; j < scenes.length; j++) {
      durationList.add(scenes[j].duration);
    }
  }
  int currentMediaIndex = 0;
  double totalRemainDuration = 0;
  double totalDuration = 0;

  for (final entry in groupMap.entries) {
    final List<MediaData> curList = entry.value;
    if (curList.isEmpty) continue;

    for (int i = 0; i < curList.length; i++) {
      final MediaData mediaData = curList[i];
      final EditedMedia editedMedia = EditedMedia(mediaData);
      if (i == curList.length - 1) editedMedia.isBoundary = true;

      if (isUseTemplateDuration) {
        final double currentDuration =
            durationList[currentMediaIndex % durationList.length];
        if (mediaData.type == EMediaType.image) {
          editedMedia.duration = currentDuration;
        } //
        else if (mediaData.type == EMediaType.video) {
          if (mediaData.duration! < currentDuration) {
            editedMedia.duration = mediaData.duration!;
            totalRemainDuration += currentDuration - mediaData.duration!;
          } //
          else {
            editedMedia.startTime =
                min(3, (mediaData.duration! - currentDuration) / 2.0);
            editedMedia.duration = currentDuration;

            if (totalRemainDuration > 0) {
              final double mediaRemainDuration = max(
                  0,
                  (mediaData.duration! -
                      currentDuration -
                      editedMedia.startTime));

              if (mediaRemainDuration >= totalRemainDuration) {
                editedMedia.duration += totalRemainDuration;
                totalRemainDuration = 0;
              } //
              else {
                editedMedia.duration += mediaRemainDuration;
                totalRemainDuration -= mediaRemainDuration;

                if (editedMedia.startTime >= totalRemainDuration) {
                  editedMedia.startTime -= totalRemainDuration;
                  editedMedia.duration += totalRemainDuration;
                  totalRemainDuration = 0;
                } //
                else {
                  totalRemainDuration -= editedMedia.startTime;
                  editedMedia.duration += editedMedia.startTime;
                  editedMedia.startTime = 0;
                }
              }
            }
          }
        }
      }
      else {
        if (mediaData.type == EMediaType.image) {
          if (totalMediaCount > 1) {
            editedMedia.duration = 3 + Random().nextDouble();
          }
          else {
            editedMedia.duration = 5 + Random().nextDouble();
          }
        } //
        else if (mediaData.type == EMediaType.video) {
          if (totalMediaCount > 1) {
            // ~5s
            if (mediaData.duration! < 5) {
              editedMedia.duration = mediaData.duration!;
            }
            // 5~10s
            else if (mediaData.duration! < 10) {
              double gap = (mediaData.duration! - 5) * 0.2; // 0 ~ 1
              editedMedia.startTime = gap;
              editedMedia.duration = mediaData.duration! - (gap * 2); // 5 ~ 8
            }
            // 10s~
            else {
              editedMedia.startTime = 1 + (Random().nextDouble() * 0.3);
              editedMedia.duration = 8 + (Random().nextDouble() * 0.3);
            }
          }
          else {
            // ~5s
            if (mediaData.duration! < 5) {
              editedMedia.duration = mediaData.duration!;
            }
            // 5~20s
            else if (mediaData.duration! < 22) {
              double gap = min(1, (mediaData.duration! - 5) * 0.2); // 0 ~ 1
              editedMedia.startTime = gap;
              editedMedia.duration = mediaData.duration! - (gap * 2); // 5 ~ 8
            }
            // 20s~
            else {
              editedMedia.startTime = 1 + (Random().nextDouble() * 0.3);
              editedMedia.duration = 20 + (Random().nextDouble() * 0.3);
            }
          }
        }
      }

      editedMedia.mediaLabel = EMediaLabel.background;
          // await _detectMediaLabel(editedMedia, mlkitMap[mediaData]!);

      allEditedData.editedMediaList.add(editedMedia);
      currentMediaIndex++;

      totalDuration += editedMedia.duration;
    }
  }

  final lastEditedMedia = allEditedData.editedMediaList[allEditedData.editedMediaList.length - 1];
  if (lastEditedMedia.mediaData.type == EMediaType.image) {
    lastEditedMedia.duration = 5;
  }
  else {
    if (lastEditedMedia.duration < 5 && lastEditedMedia.mediaData.duration! >= 5) {
      lastEditedMedia.startTime = 0;
      lastEditedMedia.duration = 5;
    }
  }

  //////////////////
  // DETECT RATIO //
  //////////////////

  final ERatio ratio = detectRatio(allEditedData.editedMediaList);
  final Resolution resolution = Resolution.fromRatio(ratio);

  allEditedData.ratio = ratio;
  allEditedData.resolution = resolution;

  ///////////////////
  // SET CROP DATA //
  ///////////////////

  for (int i = 0; i < allEditedData.editedMediaList.length; i++) {
    EditedMedia editedMedia = allEditedData.editedMediaList[i];

    // int mediaWidth = max(1, editedMedia.mediaData.width);
    // int mediaHeight = max(1, editedMedia.mediaData.height);
    //
    // double aspectRatio = (resolution.width * 1.0) / resolution.height;
    // double baseCropWidth = aspectRatio;
    // double baseCropHeight = 1;
    //
    // double scaleFactor =
    //     min(mediaWidth / baseCropWidth, mediaHeight / baseCropHeight);
    // int cropWidth = (baseCropWidth * scaleFactor).floor();
    // int cropHeight = (baseCropHeight * scaleFactor).floor();
    //
    // double cropLeft = (mediaWidth - cropWidth) / 2;
    // double cropRight = cropLeft + cropWidth;
    // double cropTop = (mediaHeight - cropHeight) / 2;
    // double cropBottom = cropTop + cropHeight;
    // editedMedia.cropLeft = cropLeft / mediaWidth;
    // editedMedia.cropRight = cropRight / mediaWidth;
    // editedMedia.cropTop = cropTop / mediaHeight;
    // editedMedia.cropBottom = cropBottom / mediaHeight;

    double mediaScaleFactor = max(resolution.width / editedMedia.mediaData.width, resolution.height / editedMedia.mediaData.height);
    Rect centerRect = generateRect(Size(editedMedia.mediaData.width.toDouble(), editedMedia.mediaData.height.toDouble()), Size(resolution.width.toDouble(), resolution.height.toDouble()));

    editedMedia.scale = mediaScaleFactor;
    editedMedia.cropLeft = centerRect.left;
    editedMedia.cropRight = centerRect.right;
    editedMedia.cropTop = centerRect.top;
    editedMedia.cropBottom = centerRect.bottom;
  }

  ///////////////////////
  // INSERT TRANSITION //
  ///////////////////////

  // TO DO : Load from Template Data
  final List<XFadeTransitionData> originXfadeTransitionList =
          ResourceManager.getInstance().getAllXFadeTransitions();
  // final List<OverlayTransitionData>
  //     originOverlayTransitionList = ResourceManager.getInstance().getAllOverlayTransitions(speed: speed);

  final List<XFadeTransitionData> curXfadeTransitionList = [];
  // final List<OverlayTransitionData> curRecommendedOverlayTransitionList = [], curOtherOverlayTransitionList = [];
  curXfadeTransitionList.addAll(originXfadeTransitionList);
  // curRecommendedOverlayTransitionList.addAll(originOverlayTransitionList.where((element) => element.isRecommend).toList());
  // curOtherOverlayTransitionList.addAll(originOverlayTransitionList.where((element) => !element.isRecommend).toList());

  int lastTransitionInsertedIndex = 0;
  int clipCount = 3 + (Random()).nextInt(2);

  bool isPassedBoundary = false;

  for (int i = 0; i < allEditedData.editedMediaList.length - 1; i++) {
    final EditedMedia editedMedia = allEditedData.editedMediaList[i];
    if (editedMedia.isBoundary) {
      isPassedBoundary = true;
    }

    final int diff = i - lastTransitionInsertedIndex;
    if (diff >= clipCount) {
      ETransitionType currentTransitionType = ETransitionType.xfade;

      double xfadeDuration = 0.8;

      if (editedMedia.duration < 2) {
        continue;
      }
      if (allEditedData.editedMediaList[i + 1].duration < (xfadeDuration + 0.1)) {
        continue;
      }

      if (isPassedBoundary) {
        // currentTransitionType = (Random()).nextDouble() >= 0.3
        //     ? ETransitionType.xfade
        //     : ETransitionType.overlay;
        currentTransitionType = ETransitionType.xfade;
      } //
      else {
        continue;
      }

      if (currentTransitionType == ETransitionType.xfade) {
        if (editedMedia.mediaData.type == EMediaType.video) {
          final double mediaRemainDuration = max(
              0,
              (editedMedia.mediaData.duration! -
                  editedMedia.duration -
                  editedMedia.startTime));

          if (mediaRemainDuration < xfadeDuration) {
            continue;
          }
        }
        editedMedia.xfadeDuration = xfadeDuration;
      }

      if (currentTransitionType == ETransitionType.xfade) {
        int randIdx = (Random()).nextInt(curXfadeTransitionList.length) %
            curXfadeTransitionList.length;
        editedMedia.transition = curXfadeTransitionList[randIdx];
        curXfadeTransitionList.removeAt(randIdx);
        if (curXfadeTransitionList.isEmpty) {
          curXfadeTransitionList.addAll(originXfadeTransitionList);
        }
      } //
      // else if (currentTransitionType == ETransitionType.overlay) {
      //   List<OverlayTransitionData> curOverlayTransitionList;
      //   if (Random().nextDouble() >= 0.4 && curRecommendedOverlayTransitionList.isNotEmpty) {
      //     curOverlayTransitionList = curRecommendedOverlayTransitionList;
      //   }
      //   else {
      //     if (curRecommendedOverlayTransitionList.isEmpty && curOtherOverlayTransitionList.isEmpty) {
      //       curRecommendedOverlayTransitionList.addAll(originOverlayTransitionList.where((element) => element.isRecommend).toList());
      //       curOtherOverlayTransitionList.addAll(originOverlayTransitionList.where((element) => !element.isRecommend).toList());
      //     }
      //     curOverlayTransitionList = curOtherOverlayTransitionList;
      //   }

      //   int randIdx = (Random()).nextInt(curOverlayTransitionList.length) %
      //       curOverlayTransitionList.length;
      //   editedMedia.transition = curOverlayTransitionList[randIdx];

      //   if (editedMedia.transition != null) {
      //     final OverlayTransitionData overlayTransitionData =
      //         editedMedia.transition as OverlayTransitionData;
      //     if (overlayTransitionData.fileMap[ratio]!.duration >=
      //         editedMedia.duration) {
      //       editedMedia.transition = null;
      //       continue;
      //     }
      //   }

      //   curOverlayTransitionList.removeAt(randIdx);
      // }

      lastTransitionInsertedIndex = i;
      clipCount = 3 + (Random()).nextInt(2);
      isPassedBoundary = false;
    }
  }

  ////////////////////////////
  // INSERT FRAME & STICKER //
  ////////////////////////////

  // TO DO : Load from Template Data

  // final Map<EMediaLabel, List<FrameData>> originFrameMap = ResourceManager.getInstance().getFrameDataMap(speed: speed),
  //     curRecommendedFrameMap = {}, curOtherFrameMap = {};
  // final Map<EMediaLabel, List<StickerData>> originStickerMap = ResourceManager.getInstance().getStickerDataMap(speed: speed),
  //     curStickerMap = {};

  // for (final key in originFrameMap.keys) {
  //   curRecommendedFrameMap[key] = [];
  //   curOtherFrameMap[key] = [];
    
  //   curRecommendedFrameMap[key]!.addAll(originFrameMap[key]!.where((frame) => frame.isRecommend).toList());
  //   curOtherFrameMap[key]!.addAll(originFrameMap[key]!.where((frame) => !frame.isRecommend).toList());
  // }

  // for (final key in originStickerMap.keys) {
  //   curStickerMap[key] = [];
  //   curStickerMap[key]!.addAll(originStickerMap[key]!);
  // }

  // int lastFrameInsertedIndex = 0;
  // clipCount = 2 + (Random()).nextInt(1);

  // // EXCEPT FIRST MEDIA
  // for (int i = 1; i < allEditedData.editedMediaList.length; i++) {
  //   final EditedMedia editedMedia = allEditedData.editedMediaList[i];

  //   if (editedMedia.duration < 2.5) {
  //     continue;
  //   }

  //   final int diff = i - lastFrameInsertedIndex;

  //   EMediaLabel mediaLabel = editedMedia.mediaLabel;
  //   switch (mediaLabel) {
  //     case EMediaLabel.background:
  //     case EMediaLabel.action:
  //       {
  //         if (diff >= clipCount) {
  //           mediaLabel = EMediaLabel.background;
  //           if (!originFrameMap.containsKey(mediaLabel)) continue;

  //           List<FrameData> curFrameList;
  //           if (Random().nextDouble() >= 0.4 && curRecommendedFrameMap[mediaLabel]!.isNotEmpty) {
  //             curFrameList = curRecommendedFrameMap[mediaLabel]!;
  //           }
  //           else {
  //             if (curRecommendedFrameMap[mediaLabel]!.isEmpty && curOtherFrameMap[mediaLabel]!.isEmpty) {
  //               curRecommendedFrameMap[mediaLabel]!.addAll(originFrameMap[mediaLabel]!.where((frame) => frame.isRecommend).toList());
  //               curOtherFrameMap[mediaLabel]!.addAll(originFrameMap[mediaLabel]!.where((frame) => !frame.isRecommend).toList());
  //             }
  //             curFrameList = curOtherFrameMap[mediaLabel]!;
  //           }

  //           int randIdx =
  //               (Random()).nextInt(curFrameList.length) % curFrameList.length;
  //           editedMedia.frame = curFrameList[randIdx];
  //           curFrameList.removeAt(randIdx);

  //           lastFrameInsertedIndex = i;
  //           clipCount = 4 + (Random()).nextInt(1);
  //         }
  //       }
  //       break;

  //     case EMediaLabel.person:
  //     case EMediaLabel.food:
  //     case EMediaLabel.animal:
  //     //   {
  //     //     // 80% 확률로 스티커 삽입
  //     //     if ((Random()).nextDouble() >= 0.8) continue;
  //     //     if (!curStickerMap.containsKey(mediaLabel)) continue;

  //     //     List<StickerData> curStickerList = curStickerMap[mediaLabel]!;
  //     //     int randIdx =
  //     //         (Random()).nextInt(curStickerList.length) % curStickerList.length;

  //     //     final StickerData? stickerData = curStickerList[randIdx];

  //     //     if (stickerData != null) {
  //     //       final EditedStickerData editedStickerData =
  //     //           EditedStickerData(stickerData);

  //     //       final double stickerWidth =
  //     //           editedStickerData.fileinfo!.width * editedStickerData.scale;
  //     //       final double stickerHeight =
  //     //           editedStickerData.fileinfo!.height * editedStickerData.scale;

  //     //       final double radian = Random().nextDouble() * pi * 2;
  //     //       final double distance =
  //     //           (videoWidth > videoHeight ? videoHeight / 4 : videoWidth / 4);

  //     //       editedStickerData.x = (videoWidth / 2) +
  //     //           (cos(radian) * distance) -
  //     //           (stickerWidth / 2);
  //     //       editedStickerData.y = (videoHeight / 2) +
  //     //           (sin(radian) * distance) -
  //     //           (stickerHeight / 2);

  //     //       editedMedia.stickers.add(editedStickerData);

  //     //       curStickerList.removeAt(randIdx);
  //     //       if (curStickerList.isEmpty) {
  //     //         curStickerList.addAll(originStickerMap[mediaLabel]!);
  //     //       }
  //     //     }
  //     //   }
  //       break;

  //     case EMediaLabel.object:
  //     default:
  //       mediaLabel = EMediaLabel.none;
  //       continue;
  //   }
  // }

  print("--------------------------------------");
  print("--------------------------------------");
  for (int i = 0; i < allEditedData.editedMediaList.length; i++) {
    final editedMedia = allEditedData.editedMediaList[i];
    print(
        "${basename(editedMedia.mediaData.absolutePath)} / totalDuration:${editedMedia.mediaData.duration} / start:${editedMedia.startTime} / duration:${editedMedia.duration} / remain:${editedMedia.mediaData.duration != null ? (editedMedia.mediaData.duration! - editedMedia.startTime - editedMedia.duration) : 0} / ${editedMedia.mediaLabel}");
    print(
        "frame:${editedMedia.frame?.key} / resolution:(${editedMedia.mediaData.width},${editedMedia.mediaData.height}) / rect: (left:${editedMedia.cropLeft}, right: ${editedMedia.cropRight}, top: ${editedMedia.cropTop}, bottom: ${editedMedia.cropBottom})");
    if (editedMedia.transition != null) {
      print("index : $i");
      print(editedMedia.transition?.key);
      print("");
      print("");
    }
    print("");
  }

  totalRemainDuration = totalDuration;
  int musicIndex = 0;

  Map<String, MusicData> musicDataMap = {};
  while (musicList.isNotEmpty && totalRemainDuration > 0) {
    MusicData musicData = musicList[musicIndex % musicList.length];
    allEditedData.musicList.add(musicData);

    if (!musicDataMap.containsKey(musicData.filename)) {
      musicDataMap[musicData.filename] = musicData;
    }

    print(musicData.filename);
    print("speed: ${musicData.speed}");
    print("");

    totalRemainDuration -= musicData.duration;
    musicIndex++;
  }

  if (isRunFFmpeg) {
    List<Future> downloadMusicFutures = [];
    for (final musicData in musicDataMap.values) {
      downloadMusicFutures.add(_downloadAndMapMusic(musicData));
    }
    await Future.wait(downloadMusicFutures);
  }

  return allEditedData;
}

Future<void> _downloadAndMapMusic(MusicData musicData) async {
  final File file = (await downloadResource(musicData.filename, musicData.url)).file;
  musicData.absolutePath = file.path;
}

Future<_GetMusicResponse> _getMusics(EMusicSpeed? musicSpeed) async {
  final List<MusicData> randomSortMusicList = [];

  final Map<EMusicSpeed, List<SongFetchModel>> songMapBySpeed = {
    EMusicSpeed.ss: [],
    EMusicSpeed.s: [],
    EMusicSpeed.m: [],
    EMusicSpeed.mm: [],
    EMusicSpeed.f: [],
    EMusicSpeed.ff: [],
  };

  List<SongFetchModel> songs = [];
  songs.addAll(ResourceManager.getInstance().getAllSongFetchModels()); // copy elements

  while (songs.isNotEmpty) {
    // RANDOM PICK & ADD (SIMILAR RANDOM SORT)
    int randIdx = (Random()).nextInt(songs.length) % songs.length;
    SongFetchModel song = songs[randIdx];
    songs.removeAt(randIdx);

    songMapBySpeed[song.speed]!.add(song);
  }

  if (musicSpeed == null || musicSpeed == EMusicSpeed.none) {
    Map<double, EMusicSpeed> speedProbabilityMap = {
      0.3: EMusicSpeed.s,
      0.6: EMusicSpeed.m,
      0.8: EMusicSpeed.mm,
      1.0: EMusicSpeed.f
    };
    double randValue = Random().nextDouble();
    EMusicSpeed randSpeed = songMapBySpeed.keys.first;
    
    for (final elem in speedProbabilityMap.entries) {
      if (randValue < elem.key) {
        randSpeed = elem.value;
        break;
      }
    }
    musicSpeed = randSpeed;
  }

  List<SongFetchModel> allSongList = [];
  allSongList.addAll(songMapBySpeed[musicSpeed]!);

  print("style : $musicSpeed");
  print("allSongList : ${allSongList.length}");

  while (allSongList.isNotEmpty) {
    int randIdx = (Random()).nextInt(allSongList.length) % allSongList.length;
    SongFetchModel song = allSongList[randIdx];
    allSongList.removeAt(randIdx);

    double duration = song.duration;
    SourceModel? source = song.source;

    if (source != null) {
      String name = source.name;
      String url = source.url;

      MusicData musicData = MusicData();
      musicData.title = song.title;
      musicData.duration = duration;
      musicData.filename = name;
      musicData.speed = song.speed;
      musicData.url = url;
      musicData.volume = 0.5;

      randomSortMusicList.add(musicData);
    }
  }

  return _GetMusicResponse(musicSpeed, randomSortMusicList);
}

Rect generateRect(Size mediaSize, Size resolutionSize) {
  ///e.g calculate the scale to scale the media to fit to video. E.g 3440:1440 need to be scaled down ↓ by 0.75 to fit to 1920:1080
  ///In which case, the scaleFactor would be 0.75
  double mediaScaleFactor = max(resolutionSize.width / mediaSize.width, resolutionSize.height / mediaSize.height);

  Size scaledToFitMediaSize = Size(mediaScaleFactor * mediaSize.width, mediaScaleFactor * mediaSize.height);
  ///e.g scale 3440:1440 video to 2580:1080 to fit in a video ratio of 1920:1080

  ///e.g basic crop left, right
  double cropLeft = (scaledToFitMediaSize.width - resolutionSize.width) / 2;
  double cropTop = (scaledToFitMediaSize.height - resolutionSize.height) / 2;
  Rect finalRect = Rect.fromLTWH(cropLeft / resolutionSize.width, cropTop / resolutionSize.height, 1, 1);
  /// Make percent-based rect. e.g: Rect.fromLTWH(0.1, 0.1, 1.1, 1.1);
  /// This rect is based on resolution dimension, so width, height always equals to 1

  return finalRect;
}


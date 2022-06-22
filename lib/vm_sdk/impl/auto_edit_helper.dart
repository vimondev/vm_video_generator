import 'dart:convert';
import 'dart:math';

import 'resource_manager.dart';
import 'package:path/path.dart';

import '../types/types.dart';
import 'global_helper.dart';

Map<int, EMediaLabel> classifiedLabelMap = {};
Map<int, bool> definitiveLabelMap = {};

Map<ETransitionType, List<String>> tempTransitionMap = {
  ETransitionType.xfade: [
    "xfade_fade",
    "xfade_wiperight",
    "xfade_slideright",
    "xfade_rectcrop",
    "xfade_circlecrop",
    "xfade_radial"
  ],
  ETransitionType.overlay: [
    "TRANSITION_DA001",
    "TRANSITION_DA002",
    "TRANSITION_DA003",
    "TRANSITION_HJ001",
    "TRANSITION_HJ002",
    "TRANSITION_HJ003",
    "TRANSITION_ON001",
    "TRANSITION_ON002",
    "TRANSITION_ON003",
    "TRANSITION_SW001",
    "TRANSITION_SW002",
    "TRANSITION_SW003",
    "TRANSITION_SW004",
    "TRANSITION_SW005",
    "TRANSITION_SW006",
    "TRANSITION_YJ001",
    "TRANSITION_YJ002",
    "TRANSITION_YJ003",
    "TRANSITION_YJ004",
    "TRANSITION_YJ005",
    "TRANSITION_YJ006",
    "TRANSITION_YJ007",
    "TRANSITION_YJ008",
    "TRANSITION_YJ009",
    "TRANSITION_YJ010",
    "TRANSITION_YJ011",
    "TRANSITION_YJ012",
    "TRANSITION_YJ013",
    "TRANSITION_YJ014",
  ],
};

Map<EMediaLabel, List<String>> tempFrameMap = {
  EMediaLabel.background: [
    "FRAME_HJ008",
    "FRAME_HJ009",
    "FRAME_HJ014",
    "FRAME_ON016",
    "FRAME_ON019",
    "FRAME_SW011",
    "FRAME_SW012",
    "FRAME_SW014",
    "FRAME_SW015",
    "FRAME_SW017",
    "FRAME_SW022",
    "FRAME_SW023",
    "FRAME_SW024",
    "FRAME_YJ004",
    "FRAME_YJ008",
    "FRAME_YJ010",
    "FRAME_YJ019",
    "FRAME_YJ020",
    "FRAME_YJ025",
    "FRAME_YJ027",
    "FRAME_YJ031",
    "FRAME_YJ032"
  ]
};

Map<EMediaLabel, List<String>> tempStickerMap = {
  EMediaLabel.person: [
    "STICKER_YJ005",
    "STICKER_YJ018",
    "STICKER_YJ028",
  ],
  EMediaLabel.food: [
    "STICKER_YJ005",
    "STICKER_YJ006",
    "STICKER_YJ023",
    "STICKER_YJ024",
    "STICKER_YJ029",
    "STICKER_YJ030",
    "STICKER_DA024",
    "STICKER_DA025",
    "STICKER_HJ015",
    "STICKER_HJ018",
  ],
  EMediaLabel.animal: [
    "STICKER_DA005",
    "STICKER_HJ017"
  ],
};

Future<void> loadLabelMap() async {
  List classifiedList =
      jsonDecode(await loadResourceString("data/mlkit-label-classified.json"));
  List definitiveList =
      jsonDecode(await loadResourceString("data/mlkit-label-definitive.json"));

  for (final Map map in classifiedList) {
    int id = map["id"];
    String type = map["type"];
    EMediaLabel mediaLabel = EMediaLabel.none;

    switch (type) {
      case "background":
        mediaLabel = EMediaLabel.background;
        break;

      case "person":
        mediaLabel = EMediaLabel.person;
        break;

      case "action":
        mediaLabel = EMediaLabel.action;
        break;

      case "object":
        mediaLabel = EMediaLabel.object;
        break;

      case "food":
        mediaLabel = EMediaLabel.food;
        break;

      case "animal":
        mediaLabel = EMediaLabel.animal;
        break;

      case "others":
        mediaLabel = EMediaLabel.others;
        break;

      default:
        break;
    }

    classifiedLabelMap[id] = mediaLabel;
  }

  for (final int id in definitiveList) {
    definitiveLabelMap[id] = true;
  }
}

Future<EMediaLabel> detectMediaLabel(
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
      EMediaLabel mediaLabel = classifiedLabelMap[imageLabel.index]!;
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

  for (int i=0; i<list.length; i++) {
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
    }
    else {
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

Future<AutoEditedData> generateAutoEditData(
    List<MediaData> list,
    EMusicStyle musicStyle,
    List<TemplateData> templateList,
    bool isAutoSelect) async {
  final AutoEditedData autoEditedData = AutoEditedData();

  list.sort((a, b) => a.createDate.compareTo(b.createDate));

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

      if (minutesDiff >= 10 || hoursDiff >= 1) {
        isGrouped = true;
      } //
      else {
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

  if (isAutoSelect) {
    int totalMediaCount = list.length;

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
          if (definitiveLabelMap.containsKey(label.key)) {
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

  for (final entry in groupMap.entries) {
    final List<MediaData> curList = entry.value;
    if (curList.isEmpty) continue;

    for (int i = 0; i < curList.length; i++) {
      final MediaData mediaData = curList[i];
      final EditedMedia editedMedia = EditedMedia(mediaData);
      if (i == curList.length - 1) editedMedia.isBoundary = true;

      final double currentDuration =
          durationList[currentMediaIndex % durationList.length];
      if (mediaData.type == EMediaType.image) {
        editedMedia.duration = currentDuration;
      } //
      else if (mediaData.type == EMediaType.video) {
        if (mediaData.duration! < currentDuration) {
          editedMedia.duration = mediaData.duration!;
          totalRemainDuration += currentDuration - mediaData.duration!;
          // print(mediaData.absolutePath);
          // print("index : $currentMediaIndex");
          // print("defined : $currentDuration");
          // print("duration : ${editedMedia.duration}");
          // print("remain : ${currentDuration - mediaData.duration!}");
          // print("totalRemain : $totalRemainDuration");
          // print("");
          // print("");
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

            // print(mediaData.absolutePath);
            // print("index : $currentMediaIndex");
            // print("defined : $currentDuration");
            // print("start/b : ${editedMedia.startTime}");
            // print("duration/b : ${editedMedia.duration}");
            // print("mediaRemain/b : $mediaRemainDuration");
            // print("totalRemain/b : $totalRemainDuration");
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
            // print("");
            // print("start/a : ${editedMedia.startTime}");
            // print("duration/a : ${editedMedia.duration}");
            // print("mediaRemain/a : $mediaRemainDuration");
            // print("totalRemain/a : $totalRemainDuration");
            // print("");
            // print("");
          }
        }
      }

      editedMedia.mediaLabel =
          await detectMediaLabel(editedMedia, mlkitMap[mediaData]!);

      autoEditedData.editedMediaList.add(editedMedia);
      currentMediaIndex++;
    }
  }

  //////////////////
  // DETECT RATIO //
  //////////////////

  final ERatio ratio = detectRatio(autoEditedData.editedMediaList);
  autoEditedData.ratio = ratio;
  autoEditedData.resolution = Resolution.fromRatio(ratio);

  int videoWidth = autoEditedData.resolution.width;
  int videoHeight = autoEditedData.resolution.height;

  ///////////////////
  // SET CROP DATA //
  ///////////////////
  
  for (int i=0; i<autoEditedData.editedMediaList.length; i++) {
    EditedMedia editedMedia = autoEditedData.editedMediaList[i];

    int mediaWidth = editedMedia.mediaData.width;
    int mediaHeight = editedMedia.mediaData.height;

    double scaleFactor = max(videoWidth / mediaWidth, videoHeight / mediaHeight);
    editedMedia.zoomX = scaleFactor;
    editedMedia.zoomY = scaleFactor;

    int scaledWidth = (mediaWidth * scaleFactor).floor();
    int scaledHeight = (mediaHeight * scaleFactor).floor();

    editedMedia.translateX = ((scaledWidth - videoWidth) / 2).floor();
    editedMedia.translateY = ((scaledHeight - videoHeight) / 2).floor();
  }

  ///////////////////////
  // INSERT TRANSITION //
  ///////////////////////

  // TO DO : Load from Template Data
  final Map<ETransitionType, List<String>> transitionMap = tempTransitionMap;
  final List<String> originXfadeTransitionList =
          transitionMap[ETransitionType.xfade]!,
      originOverlayTransitionList = transitionMap[ETransitionType.overlay]!;

  final List<String> curXfadeTransitionList = [], curOverlayTransitionList = [];
  curXfadeTransitionList.addAll(originXfadeTransitionList);
  curOverlayTransitionList.addAll(originOverlayTransitionList);

  int lastTransitionInsertedIndex = 0;
  int clipCount = 4 + (Random()).nextInt(3);

  bool isPassedBoundary = false;

  for (int i = 0; i < autoEditedData.editedMediaList.length - 1; i++) {
    final EditedMedia editedMedia = autoEditedData.editedMediaList[i];
    if (editedMedia.isBoundary) {
      isPassedBoundary = true;
    }

    final int diff = i - lastTransitionInsertedIndex;
    if (diff >= clipCount) {
      ETransitionType currentTransitionType = ETransitionType.xfade;

      double xfadeDuration = 1;
      if (musicStyle == EMusicStyle.styleB) {
        xfadeDuration = 0.8;
      } //
      else if (musicStyle == EMusicStyle.styleC) {
        xfadeDuration = 0.5;
      }

      if (editedMedia.duration < 2) continue;
      if (autoEditedData.editedMediaList[i + 1].duration <
          (xfadeDuration + 0.1)) continue;

      if (isPassedBoundary) {
        currentTransitionType = (Random()).nextDouble() >= 0.4
            ? ETransitionType.xfade
            : ETransitionType.overlay;
      } //
      else {
        currentTransitionType = ETransitionType.xfade;
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
        editedMedia.transition = ResourceManager.getInstance().getTransitionData(curXfadeTransitionList[randIdx]);
        curXfadeTransitionList.removeAt(randIdx);
        if (curXfadeTransitionList.isEmpty) {
          curXfadeTransitionList.addAll(originXfadeTransitionList);
        }
      } //
      else if (currentTransitionType == ETransitionType.overlay) {
        int randIdx = (Random()).nextInt(curOverlayTransitionList.length) %
            curOverlayTransitionList.length;
        editedMedia.transition = ResourceManager.getInstance().getTransitionData(curOverlayTransitionList[randIdx]);
        curOverlayTransitionList.removeAt(randIdx);
        if (curOverlayTransitionList.isEmpty) {
          curOverlayTransitionList.addAll(originOverlayTransitionList);
        }
      }

      lastTransitionInsertedIndex = i;
      clipCount = 4 + (Random()).nextInt(3);
      isPassedBoundary = false;
    }
  }

  ////////////////////////////
  // INSERT FRAME & STICKER //
  ////////////////////////////

  // TO DO : Load from Template Data

  final Map<EMediaLabel, List<String>> originFrameMap = tempFrameMap,
      curFrameMap = {};
  final Map<EMediaLabel, List<String>> originStickerMap = tempStickerMap,
      curStickerMap = {};

  for (final key in originFrameMap.keys) {
    curFrameMap[key] = [];
    curFrameMap[key]!.addAll(originFrameMap[key]!);
  }

  for (final key in originStickerMap.keys) {
    curStickerMap[key] = [];
    curStickerMap[key]!.addAll(originStickerMap[key]!);
  }

  int lastStickerInsertedIndex = 0;
  clipCount = 4 + (Random()).nextInt(2);

  for (int i = 0; i < autoEditedData.editedMediaList.length; i++) {
    final EditedMedia editedMedia = autoEditedData.editedMediaList[i];

    final int diff = i - lastStickerInsertedIndex;
    if (diff >= clipCount) {
      if (editedMedia.duration < 2) continue;

      EMediaLabel mediaLabel = editedMedia.mediaLabel;

      switch (mediaLabel) {
        case EMediaLabel.background:
        case EMediaLabel.action:
          {
            mediaLabel = EMediaLabel.background;
            if (!curFrameMap.containsKey(mediaLabel)) continue;

            List<String> curFrameList = curFrameMap[mediaLabel]!;
            int randIdx =
                (Random()).nextInt(curFrameList.length) % curFrameList.length;
            editedMedia.frame = ResourceManager.getInstance().getFrameData(curFrameList[randIdx]);

            curFrameList.removeAt(randIdx);
            if (curFrameList.isEmpty) {
              curFrameList.addAll(originFrameMap[mediaLabel]!);
            }
          }
          break;

        case EMediaLabel.person:
        case EMediaLabel.food:
        case EMediaLabel.animal:
          {
            if (!curStickerMap.containsKey(mediaLabel)) continue;

            List<String> curStickerList = curStickerMap[mediaLabel]!;
            int randIdx = (Random()).nextInt(curStickerList.length) %
                curStickerList.length;
            editedMedia.sticker = ResourceManager.getInstance().getStickerData(curStickerList[randIdx]);

            final double stickerWidth = editedMedia.sticker!.fileinfo!.width * 1;
            final double stickerHeight = editedMedia.sticker!.fileinfo!.height * 1;

            final double minX = stickerWidth / 2;
            final double minY = stickerHeight / 2;
            final double maxX = videoWidth - stickerWidth - minX;
            final double maxY = videoHeight - stickerHeight - minY;

            final List<List<double>> posList = [
              [minX, minY],
              [minX, maxY],
              [maxX, minY],
              [maxX, maxY]
            ];

            final List<double> pickedPos = posList[(Random()).nextInt(posList.length) % posList.length];

            editedMedia.sticker!.x = pickedPos[0];
            editedMedia.sticker!.y = pickedPos[1];

            curStickerList.removeAt(randIdx);
            if (curStickerList.isEmpty) {
              curStickerList.addAll(originStickerMap[mediaLabel]!);
            }
          }
          break;

        case EMediaLabel.object:
        default:
          mediaLabel = EMediaLabel.none;
          continue;
      }

      lastStickerInsertedIndex = i;
      clipCount = 4 + (Random()).nextInt(2);
    }
  }

  print("--------------------------------------");
  print("--------------------------------------");
  for (int i = 0; i < autoEditedData.editedMediaList.length; i++) {
    final editedMedia = autoEditedData.editedMediaList[i];
    print(
        "${basename(editedMedia.mediaData.absolutePath)} / totalDuration:${editedMedia.mediaData.duration} / start:${editedMedia.startTime} / duration:${editedMedia.duration} / remain:${editedMedia.mediaData.duration != null ? (editedMedia.mediaData.duration! - editedMedia.startTime - editedMedia.duration) : 0} / ${editedMedia.mediaLabel}");
    print("frame:${editedMedia.frame?.key} / sticker:${editedMedia.sticker?.key} / stickerPos:(${editedMedia.sticker?.x},${editedMedia.sticker?.y}), / resolution:(${editedMedia.mediaData.width},${editedMedia.mediaData.height}) / zoom:(${editedMedia.zoomX},${editedMedia.zoomY}) / translate:(${editedMedia.translateX},${editedMedia.translateY})");
    if (editedMedia.transition != null) {
      print("index : $i");
      print(editedMedia.transition?.key);
      print("");
      print("");
    }
    print("");
  }

  for (int i = 0; i < templateList.length; i++) {
    autoEditedData.musicList.add(templateList[i].music);
  }

  return autoEditedData;
}

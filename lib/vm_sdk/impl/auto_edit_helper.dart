import 'dart:convert';
import 'dart:math';

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
    // "TRANSITION_SW002",
    "TRANSITION_SW003",
    "TRANSITION_YJ001",
    "TRANSITION_YJ002",
    "TRANSITION_YJ003",
    "TRANSITION_YJ004",
    "TRANSITION_YJ005",
    // "TRANSITION_SW001"
  ],
};

Map<EMediaLabel, List<String>> tempStickerMap = {
  EMediaLabel.background: [
    "STICKER_DA007",
    "STICKER_HJ009",
    "STICKER_HJ014",
    "STICKER_HJ016",
    "STICKER_ON014",
    "STICKER_ON016",
    "STICKER_ON019",
    "STICKER_ON020",
    "STICKER_SW009",
    "STICKER_SW011",
    "STICKER_SW012",
    "STICKER_SW014",
    "STICKER_SW015",
    "STICKER_SW017",
    "STICKER_YJ008",
    "STICKER_YJ014",
    "STICKER_YJ015",
    "STICKER_YJ017",
    "STICKER_YJ019",
    "STICKER_YJ020",
    "STICKER_YJ021",
    "STICKER_YJ026",
    "STICKER_YJ027",
  ],
  EMediaLabel.object: [
    "STICKER_DA003",
    "STICKER_DA009",
    "STICKER_DA018",
    "STICKER_DA019",
    "STICKER_DA020",
    "STICKER_DA021",
    "STICKER_HJ001",
    "STICKER_HJ005",
    "STICKER_HJ010",
    "STICKER_HJ011",
    "STICKER_HJ015",
    "STICKER_ON009",
    "STICKER_ON013",
    "STICKER_ON015",
    "STICKER_SW001",
    "STICKER_SW010",
    "STICKER_SW018",
    "STICKER_SW020",
    "STICKER_YJ001",
    "STICKER_YJ002",
    "STICKER_YJ003",
    "STICKER_YJ005",
    "STICKER_YJ006",
    "STICKER_YJ007",
    // "STICKER_YJ011",
    // "STICKER_YJ012",
    "STICKER_YJ018",
    "STICKER_YJ022",
    "STIKER_ON004",
    "STIKER_ON005",
    "STIKER_ON008",

// "STICKER_DA002",
// "STICKER_DA004",
// "STICKER_DA005",
// "STICKER_DA006",
// "STICKER_DA008",
// "STICKER_DA011",
// "STICKER_DA012",
// "STICKER_DA013",
// "STICKER_DA014",
// "STICKER_DA015",
// "STICKER_DA016",
// "STICKER_DA017",
// "STICKER_HJ002",
// "STICKER_HJ003",
// "STICKER_HJ004",
// "STICKER_HJ006",
// "STICKER_HJ007",
// "STICKER_HJ012",
// "STICKER_HJ013",
// "STICKER_ON010",
// "STICKER_ON011",
// "STICKER_ON012",
// "STICKER_ON017",
// "STICKER_ON018",
// "STICKER_SW002",
// "STICKER_SW003",
// "STICKER_SW004",
// "STICKER_SW005",
// "STICKER_SW006",
// "STICKER_SW007",
// "STICKER_SW008",
// "STICKER_SW013",
// "STICKER_SW016",
// "STICKER_SW019",
// "STICKER_YJ004",
// "STICKER_YJ009",
// "STICKER_YJ010",
// "STICKER_YJ013",
// "STICKER_YJ016",
// "STICKER_YJ023",
// "STICKER_YJ024",
// "STICKER_YJ025",
// "STIKER_ON001",
// "STIKER_ON002",
// "STIKER_ON003",
// "STIKER_ON006",
// "STIKER_ON007",

// "STICKER_DA010",
// "STICKER_HJ008",
  ]
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
    AutoEditMedia media, MLKitDetected detected) async {
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
            (curData.gpsData.latitude[j] - nextData.gpsData.latitude[j]).abs();
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
      final AutoEditMedia autoEditMedia = AutoEditMedia(mediaData);
      if (i == curList.length - 1) autoEditMedia.isBoundary = true;

      final double currentDuration =
          durationList[currentMediaIndex % durationList.length];
      if (mediaData.type == EMediaType.image) {
        autoEditMedia.duration = currentDuration;
      } //
      else if (mediaData.type == EMediaType.video) {
        if (mediaData.duration! < currentDuration) {
          autoEditMedia.duration = mediaData.duration!;
          totalRemainDuration += currentDuration - mediaData.duration!;
          // print(mediaData.absolutePath);
          // print("index : $currentMediaIndex");
          // print("defined : $currentDuration");
          // print("duration : ${autoEditMedia.duration}");
          // print("remain : ${currentDuration - mediaData.duration!}");
          // print("totalRemain : $totalRemainDuration");
          // print("");
          // print("");
        } //
        else {
          autoEditMedia.startTime =
              min(3, (mediaData.duration! - currentDuration) / 2.0);
          autoEditMedia.duration = currentDuration;

          if (totalRemainDuration > 0) {
            final double mediaRemainDuration = max(
                0,
                (mediaData.duration! -
                    currentDuration -
                    autoEditMedia.startTime));

            // print(mediaData.absolutePath);
            // print("index : $currentMediaIndex");
            // print("defined : $currentDuration");
            // print("start/b : ${autoEditMedia.startTime}");
            // print("duration/b : ${autoEditMedia.duration}");
            // print("mediaRemain/b : $mediaRemainDuration");
            // print("totalRemain/b : $totalRemainDuration");
            if (mediaRemainDuration >= totalRemainDuration) {
              autoEditMedia.duration += totalRemainDuration;
              totalRemainDuration = 0;
            } //
            else {
              autoEditMedia.duration += mediaRemainDuration;
              totalRemainDuration -= mediaRemainDuration;

              if (autoEditMedia.startTime >= totalRemainDuration) {
                autoEditMedia.startTime -= totalRemainDuration;
                autoEditMedia.duration += totalRemainDuration;
                totalRemainDuration = 0;
              } //
              else {
                totalRemainDuration -= autoEditMedia.startTime;
                autoEditMedia.duration += autoEditMedia.startTime;
                autoEditMedia.startTime = 0;
              }
            }
            // print("");
            // print("start/a : ${autoEditMedia.startTime}");
            // print("duration/a : ${autoEditMedia.duration}");
            // print("mediaRemain/a : $mediaRemainDuration");
            // print("totalRemain/a : $totalRemainDuration");
            // print("");
            // print("");
          }
        }
      }

      autoEditMedia.mediaLabel =
          await detectMediaLabel(autoEditMedia, mlkitMap[mediaData]!);

      autoEditedData.autoEditMediaList.add(autoEditMedia);
      currentMediaIndex++;
    }
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
  int clipCount = 5 + (Random()).nextInt(3);

  bool isPassedBoundary = false;

  for (int i = 0; i < autoEditedData.autoEditMediaList.length - 1; i++) {
    final AutoEditMedia autoEditMedia = autoEditedData.autoEditMediaList[i];
    if (autoEditMedia.isBoundary) {
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

      if (autoEditMedia.duration < 2) continue;
      if (autoEditedData.autoEditMediaList[i + 1].duration <
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
        final double mediaRemainDuration = max(
            0,
            (autoEditMedia.mediaData.duration! -
                autoEditMedia.duration -
                autoEditMedia.startTime));

        if (mediaRemainDuration < xfadeDuration) {
          continue;
        } //
        else {
          autoEditMedia.xfadeDuration = xfadeDuration;
        }
      }

      if (currentTransitionType == ETransitionType.xfade) {
        int randIdx = (Random()).nextInt(curXfadeTransitionList.length) %
            curXfadeTransitionList.length;
        autoEditMedia.transitionKey = curXfadeTransitionList[randIdx];
        curXfadeTransitionList.removeAt(randIdx);
        if (curXfadeTransitionList.isEmpty) {
          curXfadeTransitionList.addAll(originXfadeTransitionList);
        }
      } //
      else if (currentTransitionType == ETransitionType.overlay) {
        int randIdx = (Random()).nextInt(curOverlayTransitionList.length) %
            curOverlayTransitionList.length;
        autoEditMedia.transitionKey = curOverlayTransitionList[randIdx];
        curOverlayTransitionList.removeAt(randIdx);
        if (curOverlayTransitionList.isEmpty) {
          curOverlayTransitionList.addAll(originXfadeTransitionList);
        }
      }

      lastTransitionInsertedIndex = i;
      clipCount = 5 + (Random()).nextInt(3);
      isPassedBoundary = false;
    }
  }

  ////////////////////
  // INSERT STICKER //
  ////////////////////

  // TO DO : Load from Template Data
  final Map<EMediaLabel, List<String>> originStickerMap = tempStickerMap,
      curStickerMap = {};

  for (final key in originStickerMap.keys) {
    curStickerMap[key] = [];
    curStickerMap[key]!.addAll(originStickerMap[key]!);
  }

  int lastStickerInsertedIndex = 0;
  clipCount = 4 + (Random()).nextInt(3);

  for (int i = 0; i < autoEditedData.autoEditMediaList.length; i++) {
    final AutoEditMedia autoEditMedia = autoEditedData.autoEditMediaList[i];

    final int diff = i - lastStickerInsertedIndex;
    if (diff >= clipCount) {
      if (autoEditMedia.duration < 2) continue;

      EMediaLabel mediaLabel = autoEditMedia.mediaLabel;

      switch (mediaLabel) {
        case EMediaLabel.background:
        case EMediaLabel.action:
          mediaLabel = EMediaLabel.background;
          break;

        case EMediaLabel.person:
        case EMediaLabel.object:
        case EMediaLabel.food:
        case EMediaLabel.animal:
          mediaLabel = EMediaLabel.object;
          break;

        default:
          mediaLabel = EMediaLabel.none;
          break;
      }

      if (!curStickerMap.containsKey(mediaLabel)) continue;

      List<String> curStickerList = curStickerMap[mediaLabel]!;
      int randIdx =
          (Random()).nextInt(curStickerList.length) % curStickerList.length;
      autoEditMedia.stickerKey = curStickerList[randIdx];

      curStickerList.removeAt(randIdx);
      if (curStickerList.isEmpty) {
        curStickerList.addAll(originStickerMap[mediaLabel]!);
      }

      lastStickerInsertedIndex = i;
      clipCount = 4 + (Random()).nextInt(3);
    }
  }

  print("--------------------------------------");
  print("--------------------------------------");
  for (int i = 0; i < autoEditedData.autoEditMediaList.length; i++) {
    final autoEditMedia = autoEditedData.autoEditMediaList[i];
    print(
        "${basename(autoEditMedia.mediaData.absolutePath)} / totalDuration:${autoEditMedia.mediaData.duration} / start:${autoEditMedia.startTime} / duration:${autoEditMedia.duration} / remain:${autoEditMedia.mediaData.duration != null ? (autoEditMedia.mediaData.duration! - autoEditMedia.startTime - autoEditMedia.duration) : 0} / ${autoEditMedia.mediaLabel} / sticker:${autoEditMedia.stickerKey}");
    if (autoEditMedia.transitionKey != null) {
      print("index : $i");
      print(autoEditMedia.transitionKey);
      print("");
    }
  }

  for (int i = 0; i < templateList.length; i++) {
    autoEditedData.musicList.add(templateList[i].music);
  }

  return autoEditedData;
}

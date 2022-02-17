import 'dart:convert';
import 'dart:math';

import 'package:path/path.dart';

import '../types/types.dart';
import 'global_helper.dart';

Map<int, EMediaLabel> classifiedLabelMap = {};
Map<int, bool> definitiveLabelMap = {};

Map<EMusicStyle, List<double>> tempDurationMap = {
  EMusicStyle.styleA: [5, 3.5, 4, 3, 3.5, 4, 3, 3.5, 4, 3, 3.5, 4, 3],
  EMusicStyle.styleB: [5, 4.5, 4, 5, 4.5, 4, 5, 4.5, 4, 5, 4.5, 4, 5],
  EMusicStyle.styleC: [5, 3.5, 3, 2.5, 3.5, 3, 2.5, 3.5, 3, 2.5, 3.5, 3, 2.5]
};

Map<EMusicStyle, Map<ETransitionType, List<String>>> tempTransitionMap = {
  EMusicStyle.styleA: {
    ETransitionType.xfade: [
      "xfade_fade",
      "xfade_wiperight",
      "xfade_slideright",
      "xfade_rectcrop",
      "xfade_circlecrop",
      "xfade_radial"
    ],
    ETransitionType.overlay: [
      "Transition_SW001",
      "Transition_DA001",
      "Transition_DA002",
      "Transition_HJ001",
      "Transition_HJ002",
      "Transition_ON001",
      "Transition_ON002",
      // "Transition_SW002",
      "Transition_YJ001",
      "Transition_YJ002",
      // "Transition_YJ003",
    ],
  },
  EMusicStyle.styleB: {
    ETransitionType.xfade: [
      "xfade_wiperight",
      "xfade_rectcrop",
      "xfade_radial",
      "xfade_slideright",
      "xfade_fade",
      "xfade_circlecrop"
    ],
    ETransitionType.overlay: [
      "Transition_SW001",
      "Transition_DA001",
      "Transition_DA002",
      "Transition_HJ001",
      "Transition_HJ002",
      "Transition_ON001",
      "Transition_ON002",
      // "Transition_SW002",
      "Transition_YJ001",
      "Transition_YJ002",
      // "Transition_YJ003",
    ],
  },
  EMusicStyle.styleC: {
    ETransitionType.xfade: [
      "xfade_circlecrop",
      "xfade_fade",
      "xfade_radial",
      "xfade_wiperight",
      "xfade_rectcrop",
      "xfade_slideright"
    ],
    ETransitionType.overlay: [
      "Transition_SW001",
      "Transition_DA001",
      "Transition_DA002",
      "Transition_HJ001",
      "Transition_HJ002",
      "Transition_ON001",
      "Transition_ON002",
      // "Transition_SW002",
      "Transition_YJ001",
      "Transition_YJ002",
      // "Transition_YJ003",
    ],
  }
};

Map<EMusicStyle, Map<EMediaLabel, List<String>>> tempStickerMap = {
  EMusicStyle.styleA: {
    EMediaLabel.background: [
      "Sticker_DA007",
      "Sticker_SW002",
      "Sticker_SW004",
      "Sticker_YJ004",
      "Sticker_YJ008",
      "Sticker_YJ009",
      "Sticker_YJ010",
    ],
    EMediaLabel.object: [
      "Sticker_DA001",
      "Sticker_DA002",
      "Sticker_DA003",
      "Sticker_DA004",
      "Sticker_DA005",
      "Sticker_DA007",
      "Sticker_HJ001",
      "Sticker_HJ002",
      "Sticker_HJ003",
      "Sticker_HJ005",
      "Sticker_SW003",
      "Sticker_SW004",
      "Sticker_SW005",
      "Sticker_YJ001",
      "Sticker_YJ002",
      "Sticker_YJ003",
      "Sticker_YJ004",
      "Sticker_YJ005",
      "Sticker_YJ006",
      "Sticker_YJ007",
      "Sticker_YJ008",
      "Sticker_YJ009",
      "Sticker_YJ010",
      "Stiker_ON005",
      "Stiker_ON006",
      "Stiker_ON007",
      "Stiker_ON008",
      // "Sticker_HJ006",
      // "Sticker_DA006",
      // "Sticker_DA008",
      // "Sticker_HJ004",
      // "Sticker_SW001",
      // "Sticker_SW002",
      // "Sticker_SW006",
      // "Sticker_SW007",
      // "Sticker_SW008",
      // "Stiker_ON001",
      // "Stiker_ON002",
      // "Stiker_ON003",
      // "Stiker_ON004",
    ]
  },
  EMusicStyle.styleB: {
    EMediaLabel.background: [
      "Sticker_DA007",
      "Sticker_SW002",
      "Sticker_SW004",
      "Sticker_YJ004",
      "Sticker_YJ008",
      "Sticker_YJ009",
      "Sticker_YJ010",
    ],
    EMediaLabel.object: [
      "Sticker_DA001",
      "Sticker_DA002",
      "Sticker_DA003",
      "Sticker_DA004",
      "Sticker_DA005",
      "Sticker_DA007",
      "Sticker_HJ001",
      "Sticker_HJ002",
      "Sticker_HJ003",
      "Sticker_HJ005",
      "Sticker_SW003",
      "Sticker_SW004",
      "Sticker_SW005",
      "Sticker_YJ001",
      "Sticker_YJ002",
      "Sticker_YJ003",
      "Sticker_YJ004",
      "Sticker_YJ005",
      "Sticker_YJ006",
      "Sticker_YJ007",
      "Sticker_YJ008",
      "Sticker_YJ009",
      "Sticker_YJ010",
      "Stiker_ON005",
      "Stiker_ON006",
      "Stiker_ON007",
      "Stiker_ON008",
      // "Sticker_HJ006",
      // "Sticker_DA006",
      // "Sticker_DA008",
      // "Sticker_HJ004",
      // "Sticker_SW001",
      // "Sticker_SW002",
      // "Sticker_SW006",
      // "Sticker_SW007",
      // "Sticker_SW008",
      // "Stiker_ON001",
      // "Stiker_ON002",
      // "Stiker_ON003",
      // "Stiker_ON004",
    ]
  },
  EMusicStyle.styleC: {
    EMediaLabel.background: [
      "Sticker_DA007",
      "Sticker_SW002",
      "Sticker_SW004",
      "Sticker_YJ004",
      "Sticker_YJ008",
      "Sticker_YJ009",
      "Sticker_YJ010",
    ],
    EMediaLabel.object: [
      "Sticker_DA001",
      "Sticker_DA002",
      "Sticker_DA003",
      "Sticker_DA004",
      "Sticker_DA005",
      "Sticker_DA007",
      "Sticker_HJ001",
      "Sticker_HJ002",
      "Sticker_HJ003",
      "Sticker_HJ005",
      "Sticker_SW003",
      "Sticker_SW004",
      "Sticker_SW005",
      "Sticker_YJ001",
      "Sticker_YJ002",
      "Sticker_YJ003",
      "Sticker_YJ004",
      "Sticker_YJ005",
      "Sticker_YJ006",
      "Sticker_YJ007",
      "Sticker_YJ008",
      "Sticker_YJ009",
      "Sticker_YJ010",
      "Stiker_ON005",
      "Stiker_ON006",
      "Stiker_ON007",
      "Stiker_ON008",
      // "Sticker_HJ006",
      // "Sticker_DA006",
      // "Sticker_DA008",
      // "Sticker_HJ004",
      // "Sticker_SW001",
      // "Sticker_SW002",
      // "Sticker_SW006",
      // "Sticker_SW007",
      // "Sticker_SW008",
      // "Stiker_ON001",
      // "Stiker_ON002",
      // "Stiker_ON003",
      // "Stiker_ON004",
    ]
  }
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
    List<MediaData> list, EMusicStyle musicStyle, bool isAutoSelect) async {
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

  final List<double> durationList = tempDurationMap[musicStyle]!;
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

  final Map<ETransitionType, List<String>> transitionMap =
      tempTransitionMap[musicStyle]!;

  int lastTransitionInsertedIndex = 0;
  int xfadeTransitionIndex =
      (Random()).nextInt(transitionMap[ETransitionType.xfade]!.length);
  int overlayTransitionIndex =
      (Random()).nextInt(transitionMap[ETransitionType.overlay]!.length);

  int clipCount = 3 + (Random()).nextInt(3);
  bool isPassedBoundary = false;

  for (int i = 0; i < autoEditedData.autoEditMediaList.length - 1; i++) {
    final AutoEditMedia autoEditMedia = autoEditedData.autoEditMediaList[i];
    if (autoEditMedia.isBoundary) {
      isPassedBoundary = true;
    }

    final int diff = i - lastTransitionInsertedIndex;
    if (diff >= clipCount) {
      ETransitionType currentTransitionType = ETransitionType.xfade;

      if (isPassedBoundary) {
        currentTransitionType = false && (Random()).nextDouble() >= 0.35
            ? ETransitionType.xfade
            : ETransitionType.overlay;
      } //
      else {
        currentTransitionType = false && (Random()).nextDouble() >= 0.2
            ? ETransitionType.xfade
            : ETransitionType.overlay;
      }

      if (currentTransitionType == ETransitionType.xfade) {
        final double mediaRemainDuration = max(
            0,
            (autoEditMedia.mediaData.duration! -
                autoEditMedia.duration -
                autoEditMedia.startTime));

        if (mediaRemainDuration < 1) {
          currentTransitionType = ETransitionType.overlay;
          // OR
          // continue;
        }
      }

      int index = 0;
      if (currentTransitionType == ETransitionType.xfade) {
        index = xfadeTransitionIndex++;
      } //
      else if (currentTransitionType == ETransitionType.overlay) {
        index = overlayTransitionIndex++;
      }

      List<String> currentTransitionList =
          transitionMap[currentTransitionType]!;

      autoEditMedia.transitionKey =
          currentTransitionList[index % currentTransitionList.length];

      lastTransitionInsertedIndex = i;
      clipCount = 2 + (Random()).nextInt(3);
      isPassedBoundary = false;
    }
  }

  ////////////////////
  // INSERT STICKER //
  ////////////////////

  final Map<EMediaLabel, List<String>> stickerMap = tempStickerMap[musicStyle]!;
  final Map<EMediaLabel, int> stickerIndexMap = {};
  for (final entry in stickerMap.entries) {
    stickerIndexMap[entry.key] = (Random()).nextInt(entry.value.length);
  }

  int lastStickerInsertedIndex = 0;
  clipCount = 0; //2 + (Random()).nextInt(3);

  for (int i = 0; i < autoEditedData.autoEditMediaList.length; i++) {
    final AutoEditMedia autoEditMedia = autoEditedData.autoEditMediaList[i];

    final int diff = i - lastStickerInsertedIndex;
    if (diff >= clipCount) {
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

      if (!stickerMap.containsKey(mediaLabel)) continue;

      int index = stickerIndexMap[mediaLabel]!;
      stickerIndexMap[mediaLabel] = stickerIndexMap[mediaLabel]! + 1;

      List<String> currentStickerList = stickerMap[mediaLabel]!;
      autoEditMedia.stickerKey =
          currentStickerList[index % currentStickerList.length];

      lastStickerInsertedIndex = i;
      // clipCount = 2 + (Random()).nextInt(3);
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

  autoEditedData.musicList.addAll([
    MusicData("bgm03.m4a", 90),
    MusicData("bgm04.m4a", 90),
    MusicData("bgm05.m4a", 90)
  ]);

  return autoEditedData;
}

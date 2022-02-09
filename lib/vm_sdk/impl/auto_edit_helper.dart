import 'dart:math';

import '../types/types.dart';

Map<int, bool> definitiveLabelMap = {439: true};

Map<EMusicStyle, List<double>> tempDurationMap = {
  EMusicStyle.styleA: [4, 5, 6, 4, 5, 6, 4, 5, 6, 4, 5, 6, 4, 5, 6],
  EMusicStyle.styleB: [6, 7, 8, 6, 7, 8, 6, 7, 8, 6, 7, 8, 6, 7, 8],
  EMusicStyle.styleC: [3, 4, 5, 3, 4, 5, 3, 4, 5, 3, 4, 5, 3, 4, 5]
};

void generateAutoEditData(
    List<MediaData> list, EMusicStyle musicStyle, bool isAutoSelect) {
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
  int currentGroupIndex = 0;

  for (int i = 0; i < list.length - 1; i++) {
    final MediaData currentData = list[i], nextData = list[i + 1];
    bool isGrouped = false;

    final int totalSecondsDiff =
        (currentData.createDate.difference(nextData.createDate).inSeconds)
            .abs();
    final int minutesDiff = ((totalSecondsDiff / 60) % 60).floor();
    final int hoursDiff = ((totalSecondsDiff / 3600) % 60).floor();

    if (minutesDiff >= 10 || hoursDiff >= 1) {
      isGrouped = true;
    } else {
      for (int j = 0; j < 3; j++) {
        final diffThreshold = j <= 1 ? 0 : 15;
        final double latitudeDiff =
            (currentData.gpsData.latitude[j] - nextData.gpsData.latitude[j])
                .abs();
        final double longitudeDiff =
            (currentData.gpsData.longitude[j] - nextData.gpsData.longitude[j])
                .abs();

        if (latitudeDiff > diffThreshold || longitudeDiff > diffThreshold) {
          isGrouped = true;
          break;
        }
      }
    }

    if (!groupMap.containsKey(currentGroupIndex)) {
      groupMap[currentGroupIndex] = <MediaData>[];
    }
    groupMap[currentGroupIndex]!.add(currentData);

    if (isGrouped) {
      currentGroupIndex++;
    }

    // last Element
    if (i + 1 == list.length - 1) {
      if (!groupMap.containsKey(currentGroupIndex)) {
        groupMap[currentGroupIndex] = <MediaData>[];
      }
      groupMap[currentGroupIndex]!.add(nextData);
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
      final List<MediaData> currentList = entry.value;

      for (int i = 0; i < currentList.length; i++) {
        final MediaData data = currentList[i];
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
        } else if (!isContainDefinitiveLabel) {
          if (isFewObject) isRemove = true;
        }

        if (isRemove) {
          currentList.removeAt(i);
          i--;
          totalMediaCount--;
        }
        if (totalMediaCount < 20) break;
      }

      // if (currentList.isEmpty) {
      //   groupMap.remove(key);
      // }
    }

    // REMOVE DUPLICATE CLIP
    for (final entry in groupMap.entries) {
      if (totalMediaCount < 20) break;

      final int key = entry.key;
      final List<MediaData> currentList = entry.value;

      for (int i = 0; i < currentList.length - 1; i++) {
        final MediaData current = currentList[i], next = currentList[i + 1];

        final Map<int, double> currentLabelMap =
                mediaAllLabelConfidenceMap[current]!,
            nextLabelMap = mediaAllLabelConfidenceMap[next]!;
        final Map<int, bool> allLabelMap = {};

        for (final label in currentLabelMap.entries) {
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
          double currentConfidence = currentLabelMap.containsKey(labelKey)
              ? currentLabelMap[labelKey]!
              : 0;
          double nextConfidence =
              nextLabelMap.containsKey(labelKey) ? nextLabelMap[labelKey]! : 0;

          similarity += min(currentConfidence, nextConfidence) /
              max(currentConfidence, nextConfidence);
        }
        similarity /= allLabelMap.length;

        print(current.absolutePath);
        print(next.absolutePath);
        print(similarity);
        print("");

        // 0.45
      }
    }
    print("");
  }

  print("");
}

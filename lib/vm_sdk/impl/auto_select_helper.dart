import '../types/types.dart';

List<MediaData> selectMedia(List<MediaData> list) {
  final List<MediaData> selectedList = <MediaData>[];
  final Map<int, List<MediaData>> groupMap = <int, List<MediaData>>{};
  int currentGroupIndex = 0;

  list.sort((a, b) => a.createDate.compareTo(b.createDate));

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

  for (final entry in groupMap.entries) {
    final List<MediaData> list = entry.value;

    // TO DO : Add Some Random Logic
    if (list.isNotEmpty) {
      selectedList.add(list[0]);
    }
  }

  return selectedList;
}

EMusicStyle selectMusic(List<MediaData> list) {
  return EMusicStyle.styleB;
}

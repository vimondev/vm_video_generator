import 'global.dart';
import 'fetch.dart';

enum ETransitionType { xfade, overlay }
enum EStickerType { object }

class MusicData {
  String filename = "";
  String? absolutePath;
  double duration = 0;
  double startTime = 0;
}

class ResourceData {
  String key;
  ResourceData(this.key);
}

class TransitionData extends ResourceData {
  ETransitionType type;

  TransitionData(String key, this.type) : super(key);
}

class XFadeTransitionData extends TransitionData {
  String filterName = "";
  XFadeTransitionData(String key, this.filterName)
      : super(key, ETransitionType.xfade);
  XFadeTransitionData.fromJson(String key, Map map)
      : super(key, ETransitionType.xfade) {
    filterName = map["filterName"];
  }
}

class ResourceFileInfo {
  int width;
  int height;
  double duration;
  SourceModel source;
  ResourceFileInfo(this.width, this.height, this.duration, this.source);
}

class TransitionFileInfo extends ResourceFileInfo {
  double transitionPoint;
  TransitionFileInfo(int width, int height, double duration,
      this.transitionPoint, SourceModel source)
      : super(width, height, duration, source);
}

class OverlayTransitionData extends TransitionData {
  Map<ERatio, TransitionFileInfo> fileMap = {};

  OverlayTransitionData(String key) : super(key, ETransitionType.overlay);
  OverlayTransitionData.fromFetchModel(
      String key, TransitionFetchModel fetchModel)
      : super(key, ETransitionType.overlay) {
    for (final ratio in fetchModel.sourceMap.keys) {
      Resolution resolution = Resolution.fromRatio(ratio);
      fileMap[ratio] = TransitionFileInfo(
          resolution.width,
          resolution.height,
          fetchModel.duration,
          fetchModel.transitionPoint,
          fetchModel.sourceMap[ratio]!);
    }
  }
  // OverlayTransitionData.fromJson(String key, Map map)
  //     : super(key, ETransitionType.overlay) {
  //   if (map.containsKey("ratios")) {
  //     for (final key in map["ratios"].keys) {
  //       ERatio? ratio;

  //       switch (key) {
  //         case "11":
  //           ratio = ERatio.ratio11;
  //           break;

  //         case "916":
  //           ratio = ERatio.ratio916;
  //           break;

  //         case "169":
  //           ratio = ERatio.ratio169;
  //           break;

  //         default:
  //           break;
  //       }

  //       if (ratio != null) {
  //         final Map dataMap = map["ratios"][key];
  //         final int width = dataMap["width"];
  //         final int height = dataMap["height"];
  //         final double duration = dataMap["duration"] * 1.0;
  //         final double transitionPoint = dataMap["transitionPoint"] * 1.0;
  //         final String filename = dataMap["filename"];

  //         fileMap[ratio] = TransitionFileInfo(
  //             width, height, duration, transitionPoint, filename);
  //       }
  //     }
  //   }
  // }
}

class FrameData extends ResourceData {
  Map<ERatio, ResourceFileInfo> fileMap = {};
  EMediaLabel type = EMediaLabel.none;

  FrameData(String key) : super(key);
  FrameData.fromFetchModel(String key, FrameFetchModel fetchModel)
      : super(key) {
    for (final ratio in fetchModel.sourceMap.keys) {
      Resolution resolution = Resolution.fromRatio(ratio);
      fileMap[ratio] = ResourceFileInfo(resolution.width, resolution.height,
          fetchModel.duration, fetchModel.sourceMap[ratio]!);
      type = fetchModel.type;
    }
  }
  // FrameData.fromJson(String key, Map map) : super(key) {
  //   if (map.containsKey("ratios")) {
  //     for (final key in map["ratios"].keys) {
  //       ERatio? ratio;

  //       switch (key) {
  //         case "11":
  //           ratio = ERatio.ratio11;
  //           break;

  //         case "916":
  //           ratio = ERatio.ratio916;
  //           break;

  //         case "169":
  //           ratio = ERatio.ratio169;
  //           break;

  //         default:
  //           break;
  //       }

  //       if (ratio != null) {
  //         final Map dataMap = map["ratios"][key];
  //         final int width = dataMap["width"];
  //         final int height = dataMap["height"];
  //         final double duration = dataMap["duration"] * 1.0;
  //         final String filename = dataMap["filename"];

  //         fileMap[ratio] = ResourceFileInfo(width, height, duration, filename);
  //       }
  //     }
  //   }
  // }
}

class StickerData extends ResourceData {
  ResourceFileInfo? fileinfo;
  EMediaLabel type = EMediaLabel.none;

  StickerData(String key) : super(key);
  StickerData.fromFetchModel(String key, StickerFetchModel fetchModel)
      : super(key) {
    fileinfo = ResourceFileInfo(fetchModel.width, fetchModel.height,
        fetchModel.duration, fetchModel.source!);
    type = fetchModel.type;
  }
  // StickerData.fromJson(String key, Map map) : super(key) {
  //   switch (map["type"]) {
  //     case "object":
  //       type = EStickerType.object;
  //       break;

  //     default:
  //       break;
  //   }

  //   final int width = map["width"];
  //   final int height = map["height"];
  //   final double duration = map["duration"] * 1.0;
  //   final String filename = map["filename"];

  //   fileinfo = ResourceFileInfo(width, height, duration, filename);
  // }
}

class EditedStickerData extends StickerData {
  double x = 0;
  double y = 0;
  double rotate = 0;
  double scale = 1;

  EditedStickerData(StickerData stickerData) : super(stickerData.key) {
    fileinfo = stickerData.fileinfo;
    type = stickerData.type;
  }
}

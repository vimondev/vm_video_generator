import 'global.dart';

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
  String filename;
  ResourceFileInfo(this.width, this.height, this.duration, this.filename);
}

class TransitionFileInfo extends ResourceFileInfo {
  double transitionPoint;
  TransitionFileInfo(int width, int height, double duration,
      this.transitionPoint, String filename)
      : super(width, height, duration, filename);
}

class OverlayTransitionData extends TransitionData {
  Map<ERatio, TransitionFileInfo> fileMap = {};

  OverlayTransitionData(String key) : super(key, ETransitionType.overlay);
  OverlayTransitionData.fromJson(String key, Map map)
      : super(key, ETransitionType.overlay) {
    if (map.containsKey("ratios")) {
      for (final key in map["ratios"].keys) {
        ERatio? ratio;

        switch (key) {
          case "11":
            ratio = ERatio.ratio11;
            break;

          case "916":
            ratio = ERatio.ratio916;
            break;

          case "169":
            ratio = ERatio.ratio169;
            break;

          default:
            break;
        }

        if (ratio != null) {
          final Map dataMap = map["ratios"][key];
          final int width = dataMap["width"];
          final int height = dataMap["height"];
          final double duration = dataMap["duration"] * 1.0;
          final double transitionPoint = dataMap["transitionPoint"] * 1.0;
          final String filename = dataMap["filename"];

          fileMap[ratio] = TransitionFileInfo(
              width, height, duration, transitionPoint, filename);
        }
      }
    }
  }
}

class FrameData extends ResourceData {
  Map<ERatio, ResourceFileInfo> fileMap = {};
  FrameData(String key) : super(key);
  FrameData.fromJson(String key, Map map) : super(key) {
    if (map.containsKey("ratios")) {
      for (final key in map["ratios"].keys) {
        ERatio? ratio;

        switch (key) {
          case "11":
            ratio = ERatio.ratio11;
            break;

          case "916":
            ratio = ERatio.ratio916;
            break;

          case "169":
            ratio = ERatio.ratio169;
            break;

          default:
            break;
        }

        if (ratio != null) {
          final Map dataMap = map["ratios"][key];
          final int width = dataMap["width"];
          final int height = dataMap["height"];
          final double duration = dataMap["duration"] * 1.0;
          final String filename = dataMap["filename"];

          fileMap[ratio] = ResourceFileInfo(width, height, duration, filename);
        }
      }
    }
  }
}

class StickerData extends ResourceData {
  ResourceFileInfo? fileinfo;
  EStickerType type = EStickerType.object;

  StickerData(String key) : super(key);
  StickerData.fromJson(String key, Map map) : super(key) {
    switch (map["type"]) {
      case "object":
        type = EStickerType.object;
        break;

      default:
        break;
    }

    final int width = map["width"];
    final int height = map["height"];
    final double duration = map["duration"] * 1.0;
    final String filename = map["filename"];

    fileinfo = ResourceFileInfo(width, height, duration, filename);
  }
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
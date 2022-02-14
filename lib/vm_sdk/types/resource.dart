enum ETransitionType { xfade, overlay }
enum EStickerType { object, background }

class MusicData {
  String filename;
  double duration;

  MusicData(this.filename, this.duration);
}

class TransitionData {
  ETransitionType type = ETransitionType.xfade;
  int? width;
  int? height;
  double? duration;
  double? transitionPoint;
  String? filename;
  String? filterName;

  TransitionData(this.type, this.width, this.height, this.duration,
      this.transitionPoint, this.filename, this.filterName);

  TransitionData.fromJson(Map map) {
    switch (map["type"]) {
      case "overlay":
        {
          width = map["width"];
          height = map["height"];
          duration = map["duration"] * 1.0;
          transitionPoint = map["transitionPoint"] * 1.0;
          filename = map["filename"];
          type = ETransitionType.overlay;
        }
        break;

      case "xfade":
      default:
        {
          filterName = map["filterName"];
          type = ETransitionType.xfade;
        }
        break;
    }
  }
}

class StickerData {
  EStickerType type = EStickerType.object;
  String filename = "";
  int width = 0;
  int height = 0;
  double duration = 0.0;

  StickerData(this.type, this.filename, this.width, this.height, this.duration);

  StickerData.fromJson(Map map) {
    switch (map["type"]) {
      case "background":
        type = EStickerType.background;
        break;

      case "object":
        type = EStickerType.object;
        break;

      default:
        break;
    }
    filename = map["filename"];
    width = map["width"];
    height = map["height"];
    duration = map["duration"] * 1.0;

    StickerData(type, filename, width, height, duration);
  }
}

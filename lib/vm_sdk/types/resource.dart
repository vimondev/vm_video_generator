enum ETransitionType { xfade, overlay }
enum EFilterType { overlay }

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
          duration = map["duration"];
          transitionPoint = map["transitionPoint"];
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

class FilterData {
  EFilterType type = EFilterType.overlay;
  String filename = "";
  int width = 0;
  int height = 0;
  double duration = 0.0;

  FilterData(this.type, this.filename, this.width, this.height, this.duration);

  FilterData.fromJson(Map map) {
    switch (map["type"]) {
      case "xfade":
      default:
        type = EFilterType.overlay;
        break;
    }
    filename = map["filename"];
    width = map["width"];
    height = map["height"];
    duration = map["duration"];

    FilterData(type, filename, width, height, duration);
  }
}

enum ETransitionType { xfade, overlay }
enum EFilterType { overlay }

class TransitionData {
  ETransitionType type = ETransitionType.xfade;
  int width = 0;
  int height = 0;
  double duration = 0;
  double transitionPoint = 0;
  String? filename;

  TransitionData(this.type, this.width, this.height, this.duration,
      this.transitionPoint, this.filename);

  TransitionData.fromJson(Map map) {
    switch (map["type"]) {
      case "overlay":
        type = ETransitionType.overlay;
        break;

      case "xfade":
      default:
        type = ETransitionType.xfade;
        break;
    }
    width = map["width"];
    height = map["height"];
    duration = map["duration"];
    transitionPoint = map["transitionPoint"];

    if (map.containsKey("filename")) filename = map["filename"];

    TransitionData(type, width, height, duration, transitionPoint, filename);
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

enum ETransitionType { xfade, overlay }
enum EFilterType { overlay }

class TransitionData {
  ETransitionType type = ETransitionType.xfade;
  double duration = 0;
  double transitionPoint = 0;
  String? filename;

  TransitionData(this.type, this.duration, this.transitionPoint, this.filename);

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
    duration = map["duration"];
    transitionPoint = map["transitionPoint"];

    if (map.containsKey("filename")) filename = map["filename"];

    TransitionData(type, duration, transitionPoint, filename);
  }
}

class FilterData {
  EFilterType type = EFilterType.overlay;
  String filename = "";
  double duration = 0.0;

  FilterData(this.type, this.filename, this.duration);

  FilterData.fromJson(Map map) {
    switch (map["type"]) {
      case "xfade":
      default:
        type = EFilterType.overlay;
        break;
    }
    filename = map["filename"];
    duration = map["duration"];

    FilterData(type, filename, duration);
  }
}

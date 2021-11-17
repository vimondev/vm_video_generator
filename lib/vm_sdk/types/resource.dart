enum ETransitionType { xfade, overlay }
enum EFilterType { overlay }

class TransitionData {
  ETransitionType type = ETransitionType.xfade;
  double duration = 0;
  double transitionPoint = 0;
  String? filename;
  String? blendFunc;
  Map? args;

  TransitionData(this.type, this.duration, this.transitionPoint, this.filename,
      this.blendFunc, this.args);

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
    if (map.containsKey("blendFunc")) blendFunc = map["blendFunc"];
    if (map.containsKey("args")) args = map["args"];

    TransitionData(type, duration, transitionPoint, filename, blendFunc, args);
  }
}

class FilterData {
  EFilterType type = EFilterType.overlay;
  String filename = "";
  String blendFunc = "";
  double duration = 0.0;
  Map args = {};

  FilterData(
      this.type, this.filename, this.blendFunc, this.duration, this.args);

  FilterData.fromJson(Map map) {
    switch (map["type"]) {
      case "xfade":
      default:
        type = EFilterType.overlay;
        break;
    }
    filename = map["filename"];
    blendFunc = map["blendFunc"];
    duration = map["duration"];
    args = map["args"];

    FilterData(type, filename, blendFunc, duration, args);
  }
}

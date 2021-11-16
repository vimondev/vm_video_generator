enum ETransitionType { xfade, overlay }

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
    type = map["type"] == "xfade"
        ? ETransitionType.xfade
        : ETransitionType.overlay;
    duration = map["duration"];
    transitionPoint = map["transitionPoint"];

    String? filename, blendFunc;
    Map<String, dynamic>? args;

    if (map.containsKey("filename")) filename = map["filename"];
    if (map.containsKey("blendFunc")) blendFunc = map["blendFunc"];
    if (map.containsKey("args")) args = map["args"];

    TransitionData(type, duration, transitionPoint, filename, blendFunc, args);
  }
}

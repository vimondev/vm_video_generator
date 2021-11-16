class SceneData {
  double duration;
  SceneData(this.duration);
}

class TemplateData {
  String name = "";
  double version = 0;
  String music = "";
  List<SceneData> scenes = <SceneData>[];
  List<String> transitionKeys = <String>[];
  List<String> filterKeys = <String>[];

  TemplateData(this.name, this.version, this.music, this.scenes);

  TemplateData.fromJson(Map map) {
    name = map["name"];
    version = map["version"];
    music = map["music"];

    final List<Map> sceneMaps = map["scenes"].cast<Map>();
    for (final Map map in sceneMaps) {
      scenes.add(SceneData(map["duration"]));
    }

    transitionKeys = map["transitions"].cast<String>();
    filterKeys = map["filters"].cast<String>();

    TemplateData(name, version, music, scenes);
  }
}

class SceneData {
  double duration;
  // String? filterKey;
  // String? transitionKey;

  SceneData(this.duration); //, this.filterKey, this.transitionKey);
}

class TemplateData {
  String name = "";
  double version = 0;
  String music = "";
  List<SceneData> scenes = <SceneData>[];

  TemplateData(this.name, this.version, this.music, this.scenes);

  TemplateData.fromJson(Map map) {
    name = map["name"];
    version = map["version"];
    music = map["music"];

    final List<dynamic> sceneMaps = map["scenes"];

    for (final Map map in sceneMaps) {
      final double duration = map["duration"];
      // String? filterKey;
      // String? transitionKey;

      // if (map.containsKey("filterKey")) filterKey = map["filterKey"];
      // if (map.containsKey("transitionKey")) filterKey = map["transitionKey"];

      scenes.add(SceneData(duration));
    }

    TemplateData(name, version, music, scenes);
  }
}

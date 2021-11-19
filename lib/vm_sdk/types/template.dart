import 'resource.dart';

class SceneData {
  double duration;
  SceneData(this.duration);
}

class TemplateData {
  String name = "";
  double version = 0;
  String music = "";
  List<SceneData> scenes = <SceneData>[];
  Map<String, TransitionData?> transitionDatas = {};
  Map<String, FilterData?> filterDatas = {};

  TemplateData(this.name, this.version, this.music, this.scenes);

  TemplateData.fromJson(Map map) {
    name = map["name"];
    version = map["version"];
    music = map["music"];

    final List<Map> sceneMaps = map["scenes"].cast<Map>();
    for (final Map map in sceneMaps) {
      scenes.add(SceneData(map["duration"]));
    }

    final List<String> transitionKeys = map["transitions"].cast<String>();
    final List<String> filterKeys = map["filters"].cast<String>();

    for (final String transitionKey in transitionKeys) {
      transitionDatas[transitionKey] = null;
    }
    for (final String filterKey in filterKeys) {
      filterDatas[filterKey] = null;
    }

    TemplateData(name, version, music, scenes);
  }
}

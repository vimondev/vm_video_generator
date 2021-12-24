import 'resource.dart';

class SceneData {
  String name;
  double duration;
  String? filterKey;
  String? transitionKey;

  SceneData(this.name, this.duration, this.filterKey, this.transitionKey);
}

class TemplateData {
  String name = "";
  double version = 0;
  MusicData music = MusicData("", 0);
  List<SceneData> scenes = <SceneData>[];
  Map<String, TransitionData?> transitionDatas = {};
  Map<String, FilterData?> filterDatas = {};

  TemplateData(this.name, this.version, this.music, this.scenes);

  TemplateData.fromJson(Map map) {
    name = map["name"];
    version = map["version"];
    final musicMap = map["music"];

    music = MusicData(musicMap["filename"], musicMap["duration"] * 1.0);

    final List<Map> sceneMaps = map["scenes"].cast<Map>();
    for (final Map map in sceneMaps) {
      scenes.add(SceneData(map["name"], map["duration"] * 1.0, map["filter"],
          map["transition"]));
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

import 'types.dart';

class SceneData {
  String name;
  double duration;

  SceneData(this.name, this.duration);
}

class TemplateData {
  String name = "";
  double version = 0;
  List<SceneData> scenes = <SceneData>[];
  List<EMusicStyle> styles = [];

  TemplateData(this.name, this.version, this.scenes);

  TemplateData.fromJson(Map map) {
    name = map["name"];
    version = map["version"] * 1.0;

    final List<Map> sceneMaps = map["scenes"].cast<Map>();
    for (final Map map in sceneMaps) {
      scenes.add(SceneData(map["name"], map["duration"] * 1.0));
    }

    final List<String> tags = map["tags"].cast<String>();
    for (final String tag in tags) {
      final EMusicStyle? style = musicStyleMap[tag];
      if (style != null) {
        styles.add(style);
      }
    }

    TemplateData(name, version, scenes);
  }
}

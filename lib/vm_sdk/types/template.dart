import 'resource.dart';

class SceneData {
  String name;
  double duration;
  String? stickerKey;
  String? transitionKey;

  SceneData(this.name, this.duration, this.stickerKey, this.transitionKey);
}

class TemplateData {
  String name = "";
  double version = 0;
  MusicData music = MusicData();
  List<SceneData> scenes = <SceneData>[];
  Map<String, TransitionData?> transitionDatas = {};
  Map<String, StickerData?> stickerDatas = {};

  TemplateData(this.name, this.version, this.music, this.scenes);

  TemplateData.fromJson(Map map) {
    name = map["name"];
    version = map["version"];
    final musicMap = map["music"];

    music = MusicData();
    music.filename = musicMap["filename"];
    music.duration = musicMap["duration"] * 1.0;

    final List<Map> sceneMaps = map["scenes"].cast<Map>();
    for (final Map map in sceneMaps) {
      scenes.add(SceneData(map["name"], map["duration"] * 1.0, map["sticker"],
          map["transition"]));
    }

    final List<String> transitionKeys = map["transitions"].cast<String>();
    final List<String> stickerKeys = map["stickers"].cast<String>();

    for (final String transitionKey in transitionKeys) {
      transitionDatas[transitionKey] = null;
    }
    for (final String stickerKey in stickerKeys) {
      stickerDatas[stickerKey] = null;
    }

    TemplateData(name, version, music, scenes);
  }
}

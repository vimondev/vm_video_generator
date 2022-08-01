import 'global.dart';
import '../impl/type_helper.dart';

class SourceModel {
  String name = "";
  String url = "";

  SourceModel.fromJson(Map map) {
    name = map["name"];
    url = map["url"];
  }
}

class SongFetchModel {
  String title = "";
  String artist = "";
  double duration = 0;
  SourceModel? source;

  SongFetchModel.fromJson(Map map) {
    title = map["title"];
    artist = map["artist"];
    duration = map["duration"] * 1.0;

    Map? sourceMap = map["source"];
    if (sourceMap != null) {
      source = SourceModel.fromJson(sourceMap);
    }
  }
}

class FrameFetchModel {
  String name = "";
  double duration = 0;
  EMediaLabel type = EMediaLabel.none;
  EMusicSpeed speed = EMusicSpeed.medium;
  Map<ERatio, SourceModel> sourceMap = {};

  FrameFetchModel.fromJson(Map map) {
    name = map["name"];
    duration = map["duration"] * 1.0;
    type = getMediaLabel(map["type"]);
    speed = getMusicSpeed(map["speed"]);

    sourceMap[ERatio.ratio11] = SourceModel.fromJson(map["source_11"]);
    sourceMap[ERatio.ratio169] = SourceModel.fromJson(map["source_169"]);
    sourceMap[ERatio.ratio916] = SourceModel.fromJson(map["source_916"]);
  }
}

class StickerFetchModel {
  String name = "";
  double duration = 0;
  int width = 0;
  int height = 0;
  EMediaLabel type = EMediaLabel.none;
  EMusicSpeed speed = EMusicSpeed.medium;
  SourceModel? source;

  StickerFetchModel.fromJson(Map map) {
    name = map["name"];
    duration = map["duration"] * 1.0;
    width = map["width"];
    height = map["height"];
    type = getMediaLabel(map["type"]);
    speed = getMusicSpeed(map["speed"]);

    Map? sourceMap = map["source"];
    if (sourceMap != null) {
      source = SourceModel.fromJson(sourceMap);
    }
  }
}

class TransitionFetchModel {
  String name = "";
  double duration = 0;
  double transitionPoint = 0;
  Map<ERatio, SourceModel> sourceMap = {};

  TransitionFetchModel.fromJson(Map map) {
    name = map["name"];
    duration = map["duration"] * 1.0;
    transitionPoint = map["transitionPoint"] * 1.0;

    sourceMap[ERatio.ratio11] = SourceModel.fromJson(map["source_11"]);
    sourceMap[ERatio.ratio169] = SourceModel.fromJson(map["source_169"]);
    sourceMap[ERatio.ratio916] = SourceModel.fromJson(map["source_916"]);
  }
}

class FontFetchModel {
  String fontFamily = "";
  SourceModel? source;

  FontFetchModel.fromJson(Map map) {
    fontFamily = map["fontFamily"];

    Map? sourceMap = map["file"];
    if (sourceMap != null) {
      source = SourceModel.fromJson(sourceMap);
    }
  }
}

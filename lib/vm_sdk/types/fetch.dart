import 'dart:io';

import 'global.dart';
import '../impl/type_helper.dart';

class SourceModel {
  String name = "";
  String url = "";

  SourceModel.fromJson(Map map) {
    name = map["name"] ?? "";
    url = map["url"] ?? "";
  }
}

class HashTagModel {
  int id = 0;
  String name = "";
  HashTagModel.fromJson(Map map) {
    id = map["id"] ?? 0;
    name = map["name"] ?? "";
  }
}

class SongFetchModel {
  String title = "";
  double duration = 0;
  bool isRecommended = false;
  EMusicSpeed speed = EMusicSpeed.none;
  List<HashTagModel> hashtags = [];
  SourceModel? source;

  SongFetchModel.fromJson(Map map) {
    title = map["title"] ?? "";
    duration = map["duration"] != null ? map["duration"] * 1.0 : 0;
    isRecommended = map["isRecommended"] ?? false;
    speed = musicSpeedMap[map["speed"]?.toString()] ?? EMusicSpeed.none;

    Map? sourceMap = map["source"];
    if (sourceMap != null) {
      source = SourceModel.fromJson(sourceMap);
    }
    List? hashtagsList = map["hashtags"];
    if (hashtagsList != null && hashtagsList.isNotEmpty) {
      for (final hashtag in hashtagsList) {
        hashtags.add(HashTagModel.fromJson(hashtag));
      }
    }
  }
}

class FrameFetchModel {
  String name = "";
  double duration = 0;
  EMediaLabel type = EMediaLabel.none;
  Map<ERatio, SourceModel> sourceMap = {};

  FrameFetchModel.fromJson(Map map) {
    name = map["name"] ?? "";
    duration = map["duration"] != null ? map["duration"] * 1.0 : 0;
    type = getMediaLabel(map["type"]);

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
  SourceModel? source;

  StickerFetchModel.fromJson(Map map) {
    name = map["name"] ?? "";
    duration = map["duration"] != null ? map["duration"] * 1.0 : 0;
    width = map["width"] ?? 0;
    height = map["height"] ?? 0;
    type = getMediaLabel(map["type"]);

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
    name = map["name"] ?? "";
    duration = map["duration"] != null ? map["duration"] * 1.0 : 0;
    transitionPoint = map["transitionPoint"] != null ? map["transitionPoint"] * 1.0 : 0;

    sourceMap[ERatio.ratio11] = SourceModel.fromJson(map["source_11"]);
    sourceMap[ERatio.ratio169] = SourceModel.fromJson(map["source_169"]);
    sourceMap[ERatio.ratio916] = SourceModel.fromJson(map["source_916"]);
  }
}

class FontFetchModel {
  String fontFamily = "";
  SourceModel? source;

  FontFetchModel.fromJson(Map map) {
    fontFamily = map["fontFamily"] ?? "";

    Map? sourceMap = map["file"];
    if (sourceMap != null) {
      source = SourceModel.fromJson(sourceMap);
    }
  }
}

class DownloadResourceResponse {
  String filename;
  File file;
  
  DownloadResourceResponse(this.filename, this.file);
}

class DownloadFontResponse extends DownloadResourceResponse {
  String base64;
  DownloadFontResponse(String filename, File file, this.base64) : super(filename, file);
}
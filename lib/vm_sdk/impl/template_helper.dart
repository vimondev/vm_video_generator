import '../types/types.dart';
import 'global_helper.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

const Map<EMusicStyle, String> templateMap = {
  EMusicStyle.styleA: "styleA_01.json"
};

Future<TemplateData?> loadTemplate(EMusicStyle musicStyle) async {
  if (!templateMap.containsKey(musicStyle)) return null;

  final String jsonString =
      await rootBundle.loadString("assets/template/${"styleA_01.json"}");
  final TemplateData templateData =
      TemplateData.fromJson(jsonDecode(jsonString));

  final bgmfile = templateData.music;

  await copyAssetToLocalDirectory("raw/audio/$bgmfile", bgmfile);
  return templateData;
}

void expandTemplate(TemplateData templateData, int inputFileCount) {
  int sceneCount = templateData.scenes.length;
  if (inputFileCount > sceneCount) {
    final List<SceneData> newSceneList = <SceneData>[];

    for (int i = 0; i < inputFileCount / (sceneCount * 1.0); i++) {
      newSceneList.addAll(templateData.scenes);
    }

    templateData.scenes = newSceneList;
  }
}

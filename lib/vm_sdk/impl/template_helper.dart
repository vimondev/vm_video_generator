import '../types/types.dart';
import 'global_helper.dart';
import 'dart:convert';

const Map<EMusicStyle, String> templateMap = {
  EMusicStyle.styleA: "styleA_01.json",
  EMusicStyle.styleB: "styleB_04.json"
};

Future<TemplateData?> loadTemplateData(EMusicStyle musicStyle) async {
  if (!templateMap.containsKey(musicStyle)) return null;

  final TemplateData templateData = TemplateData.fromJson(jsonDecode(
      await loadResourceString("template/${templateMap[musicStyle]}")));

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

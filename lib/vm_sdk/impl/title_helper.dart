import '../types/types.dart';
import 'global_helper.dart';
import 'dart:convert';

const Map<ETitleType, String> titleMap = {
  ETitleType.title01: "title01.json",
  ETitleType.title02: "title02.json",
  ETitleType.title03: "title03.json",
  ETitleType.title04: "title04.json",
  ETitleType.title05: "title05.json",
  ETitleType.title06: "title06.json",
  ETitleType.title07: "title07.json",
  ETitleType.title08: "title08.json",
  ETitleType.title09: "title09.json",
  ETitleType.title10: "title10.json",
  ETitleType.title11: "title11.json",
  ETitleType.title12: "title12.json",
  ETitleType.title13: "title13.json",
  ETitleType.title14: "title14.json",
  ETitleType.title15: "title15.json",
  ETitleType.title16: "title16.json",
  ETitleType.title17: "title17.json",
  ETitleType.title18: "title18.json",
  ETitleType.title19: "title19.json",
  ETitleType.title20: "title20.json",
  ETitleType.title21: "title21.json",
  ETitleType.title22: "title22.json",
  ETitleType.title23: "title23.json",
  ETitleType.title24: "title24.json",
  ETitleType.title25: "title25.json",
  ETitleType.title26: "title26.json",
  ETitleType.title27: "title27.json",
  ETitleType.title28: "title28.json",
  ETitleType.title29: "title29.json",
  ETitleType.title30: "title30.json",
  ETitleType.title31: "title31.json",
  ETitleType.title32: "title32.json",
  ETitleType.title33: "title33.json",
};

Future<TitleData?> loadTitleData(ETitleType titleType) async {
  if (!titleMap.containsKey(titleType)) return null;

  final Map<String, dynamic> loadedMap =
      jsonDecode(await loadResourceString("title/${titleMap[titleType]}"));

  final String filename = loadedMap["filename"];
  final List<String> fontFamily = List<String>.from(loadedMap["fontFamily"]);
  final List<String> fontFileName = List<String>.from(loadedMap["fontFileName"]);

  final String json = await loadResourceString("raw/lottie-jsons/$filename");

  List<String> fontBase64 = [];
  for (int i = 0; i < fontFileName.length; i++) {
    fontBase64.add(await loadResourceBase64("raw/fonts/${fontFileName[i]}"));
  }

  return TitleData(json, fontFamily, fontBase64);
}

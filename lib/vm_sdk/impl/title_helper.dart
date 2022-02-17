import '../types/types.dart';
import 'global_helper.dart';
import 'dart:convert';

const Map<ETitleType, String> titleMap = {
  ETitleType.title01: "title01.json",
  ETitleType.title02: "title02.json",
  ETitleType.title03: "title03.json",
  ETitleType.title04: "title04.json",
  ETitleType.title05: "title05.json",
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

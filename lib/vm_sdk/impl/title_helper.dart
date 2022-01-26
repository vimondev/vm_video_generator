import '../types/types.dart';
import 'global_helper.dart';
import 'dart:convert';

const Map<ETitleType, String> titleMap = {ETitleType.title01: "title01.json"};

Future<TitleData?> loadTitleData(ETitleType titleType) async {
  if (!titleMap.containsKey(titleType)) return null;

  final Map loadedMap =
      jsonDecode(await loadResourceString("title/${titleMap[titleType]}"));

  final String filename = loadedMap["filename"];
  final String fontFamily = loadedMap["fontFamily"];
  final String fontFileName = loadedMap["fontFileName"];

  final String json = await loadResourceString("raw/lottie-jsons/$filename");
  final String fontBase64 = await loadResourceBase64("raw/fonts/$fontFileName");

  return TitleData(json, fontFamily, fontBase64);
}

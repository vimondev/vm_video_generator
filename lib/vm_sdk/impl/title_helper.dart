import '../types/types.dart';
import 'global_helper.dart';
import 'dart:convert';

const Map<ETitleType, String> titleMap = {
  ETitleType.title01: "title01.json",
  ETitleType.title02: "title02.json",
  ETitleType.title03: "title03.json"
};

Future<List<TitleData>?> loadTitleData(ETitleType titleType) async {
  if (!titleMap.containsKey(titleType)) return null;
  final List<TitleData> results = [];

  final Map loadedMap =
      jsonDecode(await loadResourceString("title/${titleMap[titleType]}"));

  if (loadedMap.containsKey("childs")) {
    final List childs = loadedMap["childs"];
    for (int i = 0; i < childs.length; i++) {
      final Map item = childs[i];
      final String filename = item["filename"];
      final String fontFamily = item["fontFamily"];
      final String fontFileName = item["fontFileName"];

      final String json =
          await loadResourceString("raw/lottie-jsons/$filename");
      final String fontBase64 =
          await loadResourceBase64("raw/fonts/$fontFileName");

      results.add(TitleData(json, fontFamily, fontBase64));
    }
  }

  return results;
}

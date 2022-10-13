import 'dart:io';

import '../types/types.dart';
import 'resource_manager.dart';
import 'resource_fetch_helper.dart';
import 'global_helper.dart';
import 'dart:convert';

Future<DownloadFontResponse> _downloadFont(String fontFamily, String fontFileName) async {
  return DownloadFontResponse(fontFileName, File(""), await loadResourceBase64('raw/font/$fontFileName'));
  // return downloadFont(fontFamily);
}

Future<TextWidgetData?> loadTextWidgetData(String id, int lineCount) async {
  if (ResourceManager.getInstance().getTextData(id) == null) return null;

  final Map<String, dynamic> loadedMap =
      jsonDecode(await loadResourceString("text/$id ${lineCount >= 2 ? "TWO" : "ONE"}.json"));

  final ETextType type =
      id.toString().startsWith("Caption") ? ETextType.Caption : ETextType.Title;
  final String filename = loadedMap["filename"];
  final List<String> fontFamily = List<String>.from(loadedMap["fontFamily"]);
  final List<String> fontFileName = List<String>.from(loadedMap["fontFileName"]);

  String json = await loadResourceString("raw/lottie-jsons/$filename");

  String locale = Platform.localeName;
  if (locale.contains("_")) {
    locale = locale.split("_")[0];
  }
  
  print(locale);

  switch (locale) {
    case "vi":
    case "es":
      locale = "th";
      break;

    default: break;
  }

  for (int i=0; i<fontFamily.length; i++) {
    String replaceFontfamily = ResourceManager.getInstance().getReplaceFont(fontFamily[i], locale);
    if (replaceFontfamily.compareTo(fontFamily[i]) != 0) {
      print(replaceFontfamily);
      json = json.replaceAll("\"${fontFamily[i]}\"", "\"$replaceFontfamily\"");
      fontFamily[i] = replaceFontfamily;
    }
  }

  List<Future<DownloadFontResponse>> loadFontBase64Futures = [];
  for (int i = 0; i < fontFamily.length; i++) {
    loadFontBase64Futures.add(_downloadFont(fontFamily[i], fontFileName[i]));
  }
  List<String> fontBase64 = (await Future.wait(loadFontBase64Futures)).map<String>((item) => item.base64).toList();

  return TextWidgetData(type, json, fontFamily, fontBase64);
}

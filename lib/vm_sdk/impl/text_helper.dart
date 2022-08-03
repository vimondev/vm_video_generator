import 'dart:io';

import '../types/types.dart';
import 'resource_manager.dart';
import 'resource_fetch_helper.dart';
import 'global_helper.dart';
import 'dart:convert';

Future<String> _loadFontBase64(String fontFamily, String fontFileName) async {
  File file = await downloadFont(fontFamily, fontFileName);
  return base64.encode(await file.readAsBytes());
}

Future<TextWidgetData?> loadTextWidgetData(String id) async {
  if (ResourceManager.getInstance().getTextData(id) == null) return null;

  final Map<String, dynamic> loadedMap =
      jsonDecode(await loadResourceString("text/$id.json"));

  final ETextType type =
      id.toString().startsWith("Caption") ? ETextType.Caption : ETextType.Title;
  final String filename = loadedMap["filename"];
  final List<String> fontFamily = List<String>.from(loadedMap["fontFamily"]);
  final List<String> fontFileName =
      List<String>.from(loadedMap["fontFileName"]);

  final String json = await loadResourceString("raw/lottie-jsons/$filename");

  List<Future<String>> loadFontBase64Futures = [];
  for (int i = 0; i < fontFamily.length; i++) {
    loadFontBase64Futures.add(_loadFontBase64(fontFamily[i], fontFileName[i]));
  }

  List<String> fontBase64 = await Future.wait(loadFontBase64Futures);

  return TextWidgetData(type, json, fontFamily, fontBase64);
}

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
  ETitleType.title34: "title34.json",
  ETitleType.title35: "title35.json",
  ETitleType.title36: "title36.json",
  ETitleType.title37: "title37.json",
  ETitleType.title38: "title38.json",
  ETitleType.title39: "title39.json",
  ETitleType.title40: "title40.json",
  ETitleType.title41: "title41.json",
  ETitleType.title42: "title42.json",
  ETitleType.title43: "title43.json",
  ETitleType.title44: "title44.json",
  ETitleType.title45: "title45.json",
  ETitleType.title46: "title46.json",
  ETitleType.title47: "title47.json",
  ETitleType.title48: "title48.json",
  ETitleType.title49: "title49.json",
  ETitleType.title50: "title50.json",
  ETitleType.title51: "title51.json",
  ETitleType.title52: "title52.json",
  ETitleType.title53: "title53.json",
  ETitleType.title54: "title54.json",
  ETitleType.title55: "title55.json",
  ETitleType.title56: "title56.json",
  ETitleType.title57: "title57.json",
  ETitleType.title58: "title58.json",
  ETitleType.title59: "title59.json",
  ETitleType.title60: "title60.json",
  ETitleType.title61: "title61.json",
  ETitleType.title62: "title62.json",
  ETitleType.title63: "title63.json",
  ETitleType.title64: "title64.json",
  ETitleType.title65: "title65.json",
  ETitleType.title66: "title66.json",
  ETitleType.title67: "title67.json",
  ETitleType.title68: "title68.json",
  ETitleType.title69: "title69.json",
  ETitleType.title70: "title70.json",
  ETitleType.title71: "title71.json",
  ETitleType.title72: "title72.json",
  ETitleType.title73: "title73.json",
  ETitleType.title74: "title74.json",
  ETitleType.title75: "title75.json",
  ETitleType.title76: "title76.json",
  ETitleType.title77: "title77.json",
  ETitleType.title78: "title78.json",
  ETitleType.title79: "title79.json",
  ETitleType.title80: "title80.json",
  ETitleType.title81: "title81.json",
  ETitleType.title82: "title82.json",
  ETitleType.title83: "title83.json",
  ETitleType.title84: "title84.json",
  ETitleType.title85: "title85.json",
  ETitleType.title86: "title86.json",
  ETitleType.title87: "title87.json",
  ETitleType.title88: "title88.json",
  ETitleType.title89: "title89.json",
  ETitleType.title90: "title90.json",
  ETitleType.title91: "title91.json",
  ETitleType.title92: "title92.json",
  ETitleType.title93: "title93.json",
  ETitleType.title94: "title94.json",
  ETitleType.title95: "title95.json",
  ETitleType.title96: "title96.json",
  ETitleType.title97: "title97.json",
  ETitleType.title98: "title98.json",
  ETitleType.title99: "title99.json",
  ETitleType.title100: "title100.json"
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

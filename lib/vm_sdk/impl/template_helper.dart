import '../types/types.dart';
import 'global_helper.dart';
import 'dart:convert';
import 'dart:math';

const Map<EMusicStyle, List<String>> templateMap = {
  EMusicStyle.styleA: ["01", "05"], // SLOW
  EMusicStyle.styleB: ["03", "06"], // MEDIUM
  EMusicStyle.styleC: ["02", "04"] // FAST
};

// const Map<EMusicStyle, List<String>> templateMap = {
//   EMusicStyle.styleA: ["05", "01"], // SLOW
//   EMusicStyle.styleB: ["06", "03"], // MEDIUM
//   EMusicStyle.styleC: ["04", "02"] // FAST
// };

Future<List<TemplateData>?> loadTemplateData(EMusicStyle musicStyle) async {
  if (!templateMap.containsKey(musicStyle)) return null;
  List<TemplateData> templateList = [];

  List<String> templateJsonList = templateMap[musicStyle]!;

  bool flag = (Random()).nextDouble() >= 0.5;
  if (flag) {
    for (int i = 0; i < templateJsonList.length; i++) {
      String jsonFilename = "${templateJsonList[i]}.json";
      templateList.add(TemplateData.fromJson(
          jsonDecode(await loadResourceString("template/$jsonFilename"))));
    }
  } //
  else {
    for (int i = templateJsonList.length - 1; i >= 0; i--) {
      String jsonFilename = "${templateJsonList[i]}.json";
      templateList.add(TemplateData.fromJson(
          jsonDecode(await loadResourceString("template/$jsonFilename"))));
    }
  }

  return templateList;
}

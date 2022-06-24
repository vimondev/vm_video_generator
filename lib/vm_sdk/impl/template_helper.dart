import '../types/types.dart';
import 'global_helper.dart';
import 'dart:convert';
import 'dart:math';

const Map<EMusicStyle, List<String>> templateMap = {
  EMusicStyle.calm: ["01", "05"],
  EMusicStyle.dreamy: ["01", "05"],
  EMusicStyle.ambient: ["01", "05"],
  EMusicStyle.beautiful: ["03", "06"],
  EMusicStyle.upbeat: ["03", "06"],
  EMusicStyle.hopeful: ["03", "06"],
  EMusicStyle.inspiring: ["03", "06"],
  EMusicStyle.fun: ["03", "06"],
  EMusicStyle.joyful: ["03", "06"],
  EMusicStyle.happy: ["03", "06"],
  EMusicStyle.cheerful: ["02", "04"],
  EMusicStyle.energetic: ["02", "04"],
};

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

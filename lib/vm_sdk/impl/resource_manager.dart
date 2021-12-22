import '../types/types.dart';
import 'global_helper.dart';
import 'dart:convert';

class ResourceManager {
  static const rawAssetPath = "raw";
  static const audioAssetPath = "$rawAssetPath/audio";
  static const transitionAssetPath = "$rawAssetPath/transition";
  static const stickerAssetPath = "$rawAssetPath/sticker";
  static const filterAssetPath = "$rawAssetPath/filter";

  Map<String, TransitionData> transitionMap = <String, TransitionData>{};
  Map<String, FilterData> filterMap = <String, FilterData>{};

  Future<void> loadResourceMap() async {
    final transitionJsonMap =
        jsonDecode(await loadResourceString("data/transition.json"));

    for (final String transitionKey in transitionJsonMap.keys) {
      transitionMap[transitionKey] =
          TransitionData.fromJson(transitionJsonMap[transitionKey]!);
    }

    final filterJsonMap =
        jsonDecode(await loadResourceString("data/filter.json"));

    for (final String filterKey in filterJsonMap.keys) {
      filterMap[filterKey] = FilterData.fromJson(filterJsonMap[filterKey]!);
    }
  }

  Future<void> loadTemplateAssets(TemplateData templateData) async {
    await loadAudioFile(templateData.music.filename);

    for (final String transitionKey in templateData.transitionDatas.keys) {
      if (transitionMap.containsKey(transitionKey)) {
        final TransitionData transitionData = transitionMap[transitionKey]!;
        templateData.transitionDatas[transitionKey] = transitionData;
        if (transitionData.filename != null) {
          await loadTransitionFile(transitionData.filename!);
        }
      }
    }

    for (final String filterKey in templateData.filterDatas.keys) {
      if (filterMap.containsKey(filterKey)) {
        final FilterData filterData = filterMap[filterKey]!;
        templateData.filterDatas[filterKey] = filterData;
        await loadFilterFile(filterData.filename);
      }
    }
  }

  Future<void> loadAudioFile(String filename) async {
    await copyAssetToLocalDirectory("$audioAssetPath/$filename");
  }

  Future<void> loadTransitionFile(String filename) async {
    await copyAssetToLocalDirectory("$transitionAssetPath/$filename");
  }

  Future<void> loadStickerFile(String filename) async {
    await copyAssetToLocalDirectory("$stickerAssetPath/$filename");
  }

  Future<void> loadFilterFile(String filename) async {
    await copyAssetToLocalDirectory("$filterAssetPath/$filename");
  }
}

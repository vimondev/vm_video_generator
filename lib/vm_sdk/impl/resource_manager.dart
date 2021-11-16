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

  Future<void> loadResourceMap() async {
    final transitionJsonMap =
        jsonDecode(await loadResourceString("data/transition.json"));

    for (final String transitionKey in transitionJsonMap.keys) {
      transitionMap[transitionKey] =
          TransitionData.fromJson(transitionJsonMap[transitionKey]!);
    }
  }

  Future<void> loadTemplateAssets(TemplateData templateData) async {
    await loadAudioFile(templateData.music);

    for (final String transitionKey in templateData.transitionKeys) {
      if (transitionMap.containsKey(transitionKey)) {
        final TransitionData transitionData = transitionMap[transitionKey]!;
        if (transitionData.filename != null) {
          await loadTransitionFile(transitionData.filename!);
        }
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

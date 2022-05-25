import '../types/types.dart';
import 'global_helper.dart';
import 'dart:convert';

class ResourceManager {
  static const rawAssetPath = "raw";
  static const audioAssetPath = "$rawAssetPath/audio";
  static const transitionAssetPath = "$rawAssetPath/transition";
  static const frameAssetPath = "$rawAssetPath/frame";
  static const stickerAssetPath = "$rawAssetPath/sticker";

  Map<String, TransitionData> transitionMap = <String, TransitionData>{};
  Map<String, FrameData> frameMap = <String, FrameData>{};
  Map<String, StickerData> stickerMap = <String, StickerData>{};

  Future<void> loadResourceMap() async {
    final transitionJsonMap =
        jsonDecode(await loadResourceString("data/transition.json"));

    for (final String key in transitionJsonMap.keys) {
      if (transitionJsonMap[key]["type"] == "overlay") {
        transitionMap[key] = OverlayTransitionData.fromJson(key, transitionJsonMap[key]);
      }
      else {
        transitionMap[key] = XFadeTransitionData.fromJson(key, transitionJsonMap[key]);
      }
    }

    final frameJsonMap =
        jsonDecode(await loadResourceString("data/frame.json"));

    for (final String key in frameJsonMap.keys) {
      frameMap[key] =
          FrameData.fromJson(key, frameJsonMap[key]);
    }

    final stickerJsonMap =
        jsonDecode(await loadResourceString("data/sticker.json"));

    for (final String key in stickerJsonMap.keys) {
      stickerMap[key] =
          StickerData.fromJson(key, stickerJsonMap[key]);
    }
  }

  Future<void> loadAutoEditAssets(AutoEditedData autoEditedData) async {
    for (int i = 0; i < autoEditedData.musicList.length; i++) {
      await loadAudioFile(autoEditedData.musicList[i].filename);
    }
    ERatio ratio = autoEditedData.ratio;

    for (int i = 0; i < autoEditedData.autoEditMediaList.length; i++) {
      final AutoEditMedia autoEditMedia = autoEditedData.autoEditMediaList[i];
      String? transitionKey = autoEditMedia.transitionKey;
      String? frameKey = autoEditMedia.frameKey;
      String? stickerKey = autoEditMedia.stickerKey;

      final TransitionData? transitionData = transitionMap[transitionKey];
      final FrameData? frameData = frameMap[frameKey];
      final StickerData? stickerData = stickerMap[stickerKey];

      if (transitionData != null) {
        autoEditedData.transitionMap[transitionKey!] = transitionData;
        if (transitionData.type == ETransitionType.overlay) {
          TransitionFileInfo? fileInfo = (transitionData as OverlayTransitionData).fileMap[ratio];
          if (fileInfo != null) {
            await loadTransitionFile(fileInfo.filename);
          }
        }
      }
      if (frameData != null) {
        autoEditedData.frameMap[frameKey!] = frameData;
        ResourceFileInfo? fileInfo = frameData.fileMap[ratio];
        if (fileInfo != null) {
          await loadFrameFile(fileInfo.filename);
        }
      }
      if (stickerData != null) {
        autoEditedData.stickerMap[stickerKey!] = stickerData;
        ResourceFileInfo? fileInfo = stickerData.fileinfo;
        if (fileInfo != null) {
          await loadStickerFile(fileInfo.filename);
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

  Future<void> loadFrameFile(String filename) async {
    await copyAssetToLocalDirectory("$frameAssetPath/$filename");
  }

  Future<void> loadStickerFile(String filename) async {
    await copyAssetToLocalDirectory("$stickerAssetPath/$filename");
  }
}

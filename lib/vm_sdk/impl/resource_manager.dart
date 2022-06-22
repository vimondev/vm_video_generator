import '../types/types.dart';
import 'global_helper.dart';
import 'dart:convert';

class ResourceManager {
  static ResourceManager? _instance;

  static const _rawAssetPath = "raw";
  static const _audioAssetPath = "$_rawAssetPath/audio";
  static const _transitionAssetPath = "$_rawAssetPath/transition";
  static const _frameAssetPath = "$_rawAssetPath/frame";
  static const _stickerAssetPath = "$_rawAssetPath/sticker";

  final Map<String, TransitionData> _transitionMap = <String, TransitionData>{};
  final Map<String, FrameData> _frameMap = <String, FrameData>{};
  final Map<String, StickerData> _stickerMap = <String, StickerData>{};

  static ResourceManager getInstance() {
    _instance ??= ResourceManager();
    return _instance!;
  }

  Future<void> loadResourceMap() async {
    final transitionJsonMap =
        jsonDecode(await loadResourceString("data/transition.json"));

    for (final String key in transitionJsonMap.keys) {
      if (transitionJsonMap[key]["type"] == "overlay") {
        _transitionMap[key] = OverlayTransitionData.fromJson(key, transitionJsonMap[key]);
      }
      else {
        _transitionMap[key] = XFadeTransitionData.fromJson(key, transitionJsonMap[key]);
      }
    }

    final frameJsonMap =
        jsonDecode(await loadResourceString("data/frame.json"));

    for (final String key in frameJsonMap.keys) {
      _frameMap[key] =
          FrameData.fromJson(key, frameJsonMap[key]);
    }

    final stickerJsonMap =
        jsonDecode(await loadResourceString("data/sticker.json"));

    for (final String key in stickerJsonMap.keys) {
      _stickerMap[key] =
          StickerData.fromJson(key, stickerJsonMap[key]);
    }
  }

  TransitionData? getTransitionData(String key) {
    return _transitionMap[key];
  }

  FrameData? getFrameData(String key) {
    return _frameMap[key];
  }

  StickerData? getStickerData(String key) {
    return _stickerMap[key];
  }

  Future<void> loadAutoEditAssets(AutoEditedData autoEditedData) async {
    for (int i = 0; i < autoEditedData.musicList.length; i++) {
      await _loadAudioFile(autoEditedData.musicList[i].filename);
    }
    ERatio ratio = autoEditedData.ratio;

    for (int i = 0; i < autoEditedData.editedMediaList.length; i++) {
      final EditedMedia editedMedia = autoEditedData.editedMediaList[i];

      final TransitionData? transitionData = editedMedia.transition;
      final FrameData? frameData = editedMedia.frame;
      final StickerData? stickerData = editedMedia.sticker;

      if (transitionData != null) {
        if (transitionData.type == ETransitionType.overlay) {
          TransitionFileInfo? fileInfo = (transitionData as OverlayTransitionData).fileMap[ratio];
          if (fileInfo != null) {
            await _loadTransitionFile(fileInfo.filename);
          }
        }
      }
      if (frameData != null) {
        ResourceFileInfo? fileInfo = frameData.fileMap[ratio];
        if (fileInfo != null) {
          await _loadFrameFile(fileInfo.filename);
        }
      }
      if (stickerData != null) {
        ResourceFileInfo? fileInfo = stickerData.fileinfo;
        if (fileInfo != null) {
          await _loadStickerFile(fileInfo.filename);
        }
      }
    }
  }

  Future<void> _loadAudioFile(String filename) async {
    await copyAssetToLocalDirectory("$_audioAssetPath/$filename");
  }

  Future<void> _loadTransitionFile(String filename) async {
    await copyAssetToLocalDirectory("$_transitionAssetPath/$filename");
  }

  Future<void> _loadFrameFile(String filename) async {
    await copyAssetToLocalDirectory("$_frameAssetPath/$filename");
  }

  Future<void> _loadStickerFile(String filename) async {
    await copyAssetToLocalDirectory("$_stickerAssetPath/$filename");
  }
}

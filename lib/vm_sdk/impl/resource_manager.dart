import 'dart:io';

import '../types/types.dart';
import 'global_helper.dart';
import 'dart:convert';

class ResourceManager {
  static ResourceManager? _instance;

  static const _rawAssetPath = "raw";
  static const _transitionAssetPath = "$_rawAssetPath/transition";
  static const _frameAssetPath = "$_rawAssetPath/frame";
  static const _stickerAssetPath = "$_rawAssetPath/sticker";

  final Map<String, TransitionData> _transitionMap = <String, TransitionData>{};
  final Map<String, FrameData> _frameMap = <String, FrameData>{};
  final Map<String, StickerData> _stickerMap = <String, StickerData>{};
  final Map<EMusicStyle, List<TemplateData>> _templateMap = {};

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

    final List templateJsonList =
        jsonDecode(await loadResourceString("data/template.json"));

    for (int i=0; i<templateJsonList.length; i++) {
      final filename = templateJsonList[i];
      final templateJson = jsonDecode(await loadResourceString("template/$filename"));

      final TemplateData templateData = TemplateData.fromJson(templateJson);
      for (int j=0; j<templateData.styles.length; j++) {
        EMusicStyle style = templateData.styles[j];
        if (_templateMap[style] == null) _templateMap[style] = [];

        _templateMap[style]!.add(templateData);
      }
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

  List<TemplateData>? getTemplateData(EMusicStyle style) {
    return _templateMap[style];
  }

  Future<void> loadResourceFromAssets(List<EditedMedia> editedMediaList,ERatio ratio) async {
    for (int i = 0; i < editedMediaList.length; i++) {
      final EditedMedia editedMedia = editedMediaList[i];

      final TransitionData? transitionData = editedMedia.transition;
      final FrameData? frameData = editedMedia.frame;
      final List<StickerData> stickerDataList = editedMedia.stickers;

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
      for (int j = 0; j < stickerDataList.length; j++) {
        final StickerData stickerData = stickerDataList[j];
        ResourceFileInfo? fileInfo = stickerData.fileinfo;
        if (fileInfo != null) {
          await _loadStickerFile(fileInfo.filename);
        }
      }
    }
  }

  Future<File> _loadTransitionFile(String filename) async {
    return await copyAssetToLocalDirectory("$_transitionAssetPath/$filename");
  }

  Future<File> _loadFrameFile(String filename) async {
    return await copyAssetToLocalDirectory("$_frameAssetPath/$filename");
  }

  Future<File> _loadStickerFile(String filename) async {
    return await copyAssetToLocalDirectory("$_stickerAssetPath/$filename");
  }
}

import 'dart:io';

import '../types/types.dart';
import 'global_helper.dart';
import 'resource_fetch_helper.dart';
import 'dart:convert';

class ResourceManager {
  static ResourceManager? _instance;

  // static const _rawAssetPath = "raw";
  // static const _transitionAssetPath = "$_rawAssetPath/transition";
  // static const _frameAssetPath = "$_rawAssetPath/frame";
  // static const _stickerAssetPath = "$_rawAssetPath/sticker";

  final Map<String, TransitionData> _transitionMap = <String, TransitionData>{};
  final Map<String, FrameData> _frameMap = <String, FrameData>{};
  final Map<String, StickerData> _stickerMap = <String, StickerData>{};
  final Map<EMusicStyle, List<TemplateData>> _templateMap = {};

  static ResourceManager getInstance() {
    _instance ??= ResourceManager();
    return _instance!;
  }

  Future<void> _loadTransitionMap() async {
    List<TransitionFetchModel> fetchedList = await fetchTransitions();
    Map<String, TransitionFetchModel> map = {};

    for (int i = 0; i < fetchedList.length; i++) {
      final fetchedModel = fetchedList[i];
      map[fetchedModel.name] = fetchedModel;
    }

    final transitionJsonMap =
        jsonDecode(await loadResourceString("data/transition.json"));

    for (final String key in transitionJsonMap.keys) {
      if (transitionJsonMap[key]["enable"] == false) continue;

      if (transitionJsonMap[key]["type"] == "overlay") {
        TransitionFetchModel? fetchModel = map[key];
        if (fetchModel != null) {
          _transitionMap[key] =
              OverlayTransitionData.fromFetchModel(key, fetchModel);
        }
        // _transitionMap[key] =
        // OverlayTransitionData.fromJson(key, transitionJsonMap[key]);
      } else {
        _transitionMap[key] =
            XFadeTransitionData.fromJson(key, transitionJsonMap[key]);
      }
    }
  }

  Future<void> _loadFrameMap() async {
    List<FrameFetchModel> fetchedList = await fetchFrames();
    Map<String, FrameFetchModel> map = {};

    for (int i = 0; i < fetchedList.length; i++) {
      final fetchedModel = fetchedList[i];
      map[fetchedModel.name] = fetchedModel;
    }

    final frameJsonMap =
        jsonDecode(await loadResourceString("data/frame.json"));

    for (final String key in frameJsonMap.keys) {
      if (frameJsonMap[key]["enable"] == false) continue;

      FrameFetchModel? fetchModel = map[key];
      if (fetchModel != null) {
        _frameMap[key] = FrameData.fromFetchModel(key, fetchModel);
      }
      // _frameMap[key] =
      // FrameData.fromJson(key, frameJsonMap[key]);
    }
  }

  Future<void> _loadStickerMap() async {
    List<StickerFetchModel> fetchedList = await fetchStickers();
    Map<String, StickerFetchModel> map = {};

    for (int i = 0; i < fetchedList.length; i++) {
      final fetchedModel = fetchedList[i];
      map[fetchedModel.name] = fetchedModel;
    }

    final stickerJsonMap =
        jsonDecode(await loadResourceString("data/sticker.json"));

    for (final String key in stickerJsonMap.keys) {
      if (stickerJsonMap[key]["enable"] == false) continue;

      StickerFetchModel? fetchModel = map[key];
      if (fetchModel != null) {
        _stickerMap[key] = StickerData.fromFetchModel(key, fetchModel);
      }
      // _stickerMap[key] =
      // StickerData.fromJson(key, stickerJsonMap[key]);
    }
  }

  Future<void> _loadTemplateMap() async {
    final List templateJsonList =
        jsonDecode(await loadResourceString("data/template.json"));

    for (int i = 0; i < templateJsonList.length; i++) {
      final filename = templateJsonList[i];
      final templateJson =
          jsonDecode(await loadResourceString("template/$filename"));

      final TemplateData templateData = TemplateData.fromJson(templateJson);
      for (int j = 0; j < templateData.styles.length; j++) {
        EMusicStyle style = templateData.styles[j];
        if (_templateMap[style] == null) _templateMap[style] = [];

        _templateMap[style]!.add(templateData);
      }
    }
  }

  Future<void> loadResourceMap() async {
    await Future.wait([
      _loadTransitionMap(),
      _loadFrameMap(),
      _loadStickerMap(),
      _loadTemplateMap()
    ]);
  }

  List<OverlayTransitionData> getAllOverlayTransitions() {
    return _transitionMap.keys
        .where((key) => _transitionMap[key]!.type == ETransitionType.overlay)
        .map<OverlayTransitionData>(
            (key) => _transitionMap[key] as OverlayTransitionData)
        .toList();
  }

  List<XFadeTransitionData> getAllXFadeTransitions() {
    return _transitionMap.keys
        .where((key) => _transitionMap[key]!.type == ETransitionType.xfade)
        .map<XFadeTransitionData>(
            (key) => _transitionMap[key] as XFadeTransitionData)
        .toList();
  }

  Map<EMediaLabel, List<FrameData>> getFrameDataMap() {
    Map<EMediaLabel, List<FrameData>> map = {EMediaLabel.background: []};

    for (final key in _frameMap.keys) {
      final FrameData frame = _frameMap[key]!;
      map[EMediaLabel.background]!.add(frame);
    }

    return map;
  }

  Map<EMediaLabel, List<StickerData>> getStickerDataMap() {
    Map<EMediaLabel, List<StickerData>> map = {};

    for (final key in _stickerMap.keys) {
      final StickerData sticker = _stickerMap[key]!;
      if (!map.containsKey(sticker.type)) map[sticker.type] = [];

      map[sticker.type]!.add(sticker);
    }

    return map;
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

  Future<void> loadResourceFromAssets(
      List<EditedMedia> editedMediaList, ERatio ratio) async {
    final List<Future> futures = [];
    final Map<String, bool> existsMap = {};

    for (int i = 0; i < editedMediaList.length; i++) {
      final EditedMedia editedMedia = editedMediaList[i];

      final TransitionData? transitionData = editedMedia.transition;
      final FrameData? frameData = editedMedia.frame;
      final List<StickerData> stickerDataList = editedMedia.stickers;

      if (transitionData != null) {
        if (transitionData.type == ETransitionType.overlay) {
          TransitionFileInfo? fileInfo =
              (transitionData as OverlayTransitionData).fileMap[ratio];
          if (fileInfo != null) {
            if (existsMap[fileInfo.source.name] == true) continue;

            existsMap[fileInfo.source.name] = true;
            futures.add(_loadResourceFile(fileInfo));
          }
        }
      }
      if (frameData != null) {
        ResourceFileInfo? fileInfo = frameData.fileMap[ratio];
        if (fileInfo != null) {
          if (existsMap[fileInfo.source.name] == true) continue;

          existsMap[fileInfo.source.name] = true;
          futures.add(_loadResourceFile(fileInfo));
        }
      }
      for (int j = 0; j < stickerDataList.length; j++) {
        final StickerData stickerData = stickerDataList[j];
        ResourceFileInfo? fileInfo = stickerData.fileinfo;
        if (fileInfo != null) {
          if (existsMap[fileInfo.source.name] == true) continue;

          existsMap[fileInfo.source.name] = true;
          futures.add(_loadResourceFile(fileInfo));
        }
      }
    }
    await Future.wait(futures);
  }

  Future<void> _loadResourceFile(ResourceFileInfo resource) async {
    await downloadResource(resource.source.name, resource.source.url);
  }

  // Future<File> _loadTransitionFile(String filename) async {
  //   return await copyAssetToLocalDirectory("$_transitionAssetPath/$filename");
  // }

  // Future<File> _loadFrameFile(String filename) async {
  //   return await copyAssetToLocalDirectory("$_frameAssetPath/$filename");
  // }

  // Future<File> _loadStickerFile(String filename) async {
  //   return await copyAssetToLocalDirectory("$_stickerAssetPath/$filename");
  // }
}

import '../types/types.dart';
import 'global_helper.dart';
import 'resource_fetch_helper.dart';
import 'dart:convert';

class ResourceManager {
  static ResourceManager? _instance;

  final Map<String, TransitionData> _transitionMap = <String, TransitionData>{};
  final Map<String, FrameData> _frameMap = <String, FrameData>{};
  final Map<String, StickerData> _stickerMap = <String, StickerData>{};
  final Map<String, TextData> _textMap = <String, TextData>{};
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
      if (transitionJsonMap[key]["type"] == "overlay") {
        TransitionFetchModel? fetchModel = map[key];
        if (fetchModel != null) {
          _transitionMap[key] =
              OverlayTransitionData.fromFetchModel(key, fetchModel);
          _transitionMap[key]!.isEnableAutoEdit =
              transitionJsonMap[key]["enable"];
        }
      } else {
        _transitionMap[key] =
            XFadeTransitionData.fromJson(key, transitionJsonMap[key]);
        _transitionMap[key]!.isEnableAutoEdit =
            transitionJsonMap[key]["enable"];
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
      FrameFetchModel? fetchModel = map[key];
      if (fetchModel != null) {
        _frameMap[key] = FrameData.fromFetchModel(key, fetchModel);
        _frameMap[key]!.isEnableAutoEdit = frameJsonMap[key]["enable"];
      }
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
      StickerFetchModel? fetchModel = map[key];
      if (fetchModel != null) {
        _stickerMap[key] = StickerData.fromFetchModel(key, fetchModel);
        _stickerMap[key]!.isEnableAutoEdit = stickerJsonMap[key]["enable"];
      }
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

  Future<void> _loadTextMap() async {
    final textJsonMap = jsonDecode(await loadResourceString("data/text.json"));

    for (final String key in textJsonMap.keys) {
      final Map map = textJsonMap[key];
      _textMap[key] = TextData.fromJson(key, map);
      _textMap[key]!.isEnableAutoEdit = textJsonMap[key]["enable"];
    }
  }

  Future<void> loadResourceMap() async {
    await Future.wait([
      _loadTransitionMap(),
      _loadFrameMap(),
      _loadStickerMap(),
      _loadTemplateMap(),
      _loadTextMap()
    ]);
  }

  List<OverlayTransitionData> getAllOverlayTransitions(
      {bool isAutoEdit = true}) {
    return _transitionMap.keys
        .where((key) =>
            _transitionMap[key]!.type == ETransitionType.overlay &&
            (!isAutoEdit || _transitionMap[key]!.isEnableAutoEdit))
        .map<OverlayTransitionData>(
            (key) => _transitionMap[key] as OverlayTransitionData)
        .toList();
  }

  List<XFadeTransitionData> getAllXFadeTransitions({bool isAutoEdit = true}) {
    return _transitionMap.keys
        .where((key) =>
            _transitionMap[key]!.type == ETransitionType.xfade &&
            (!isAutoEdit || _transitionMap[key]!.isEnableAutoEdit))
        .map<XFadeTransitionData>(
            (key) => _transitionMap[key] as XFadeTransitionData)
        .toList();
  }

  Map<EMediaLabel, List<FrameData>> getFrameDataMap({bool isAutoEdit = true}) {
    Map<EMediaLabel, List<FrameData>> map = {EMediaLabel.background: []};

    for (final key in _frameMap.keys) {
      final FrameData frame = _frameMap[key]!;

      if (!isAutoEdit || frame.isEnableAutoEdit) {
        map[EMediaLabel.background]!.add(frame);
      }
    }

    return map;
  }

  Map<EMediaLabel, List<StickerData>> getStickerDataMap(
      {bool isAutoEdit = true}) {
    Map<EMediaLabel, List<StickerData>> map = {};

    for (final key in _stickerMap.keys) {
      final StickerData sticker = _stickerMap[key]!;

      if (!isAutoEdit || sticker.isEnableAutoEdit) {
        if (!map.containsKey(sticker.type)) map[sticker.type] = [];
        map[sticker.type]!.add(sticker);
      }
    }

    return map;
  }

  List<String> getOneLineTextList({bool isAutoEdit = true}) {
    return _textMap.keys
        .where((key) =>
            _textMap[key]!.lineCount == 1 &&
            (!isAutoEdit || _textMap[key]!.isEnableAutoEdit))
        .map<String>((key) => key)
        .toList();
  }

  List<String> getTwoLineTextList({bool isAutoEdit = true}) {
    return _textMap.keys
        .where((key) =>
            _textMap[key]!.lineCount == 2 &&
            (!isAutoEdit || _textMap[key]!.isEnableAutoEdit))
        .map<String>((key) => key)
        .toList();
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

  TextData? getTextData(String key) {
    return _textMap[key];
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
}

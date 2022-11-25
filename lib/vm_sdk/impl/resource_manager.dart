import 'dart:io';
import 'dart:math';

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
  
  final Map<String, Map<String, String>> _replaceFontMap = {};

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
          _transitionMap[key] = OverlayTransitionData.fromFetchModel(key, fetchModel);
        }
      }
      else {
        _transitionMap[key] = XFadeTransitionData.fromJson(key, transitionJsonMap[key]);
      }

      if (_transitionMap.containsKey(key)) {
        _transitionMap[key]!.isEnableAutoEdit = transitionJsonMap[key]["enable"];
        _transitionMap[key]!.isRecommend = transitionJsonMap[key]["isRecommend"];
        _transitionMap[key]!.exceptSpeed = transitionJsonMap[key]["exceptSpeed"];
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
        _frameMap[key]!.isRecommend = frameJsonMap[key]["isRecommend"];
        _frameMap[key]!.exceptSpeed = frameJsonMap[key]["exceptSpeed"];
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
      _textMap[key]!.unsupportLang = textJsonMap[key]["unsupportLang"];
      _textMap[key]!.isRecommend = textJsonMap[key]["isRecommend"];
      _textMap[key]!.exceptSpeed = textJsonMap[key]["exceptSpeed"];
      _textMap[key]!.lineCount = textJsonMap[key]["lineCount"];
    }

    final replaceFontJsonMap = jsonDecode(await loadResourceString("data/replace-font.json"));

    for (final String fontFamily in replaceFontJsonMap.keys) {
      final Map map = replaceFontJsonMap[fontFamily];
      
      _replaceFontMap[fontFamily] = {};
      for (final lang in map.keys) {
        _replaceFontMap[fontFamily]![lang] = map[lang];
      }
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
      {bool autoEditOnly = true, String? speed}) {
    return _transitionMap.keys
        .where((key) =>
            _transitionMap[key]!.type == ETransitionType.overlay &&
            (!autoEditOnly || (_transitionMap[key]!.isEnableAutoEdit && !_transitionMap[key]!.exceptSpeed.containsKey(speed))))
        .map<OverlayTransitionData>(
            (key) => _transitionMap[key] as OverlayTransitionData)
        .toList();
  }

  List<XFadeTransitionData> getAllXFadeTransitions({bool autoEditOnly = true, String? speed}) {
    return _transitionMap.keys
        .where((key) =>
            _transitionMap[key]!.type == ETransitionType.xfade &&
            (!autoEditOnly || (_transitionMap[key]!.isEnableAutoEdit && !_transitionMap[key]!.exceptSpeed.containsKey(speed))))
        .map<XFadeTransitionData>(
            (key) => _transitionMap[key] as XFadeTransitionData)
        .toList();
  }

  Map<EMediaLabel, List<FrameData>> getFrameDataMap({bool autoEditOnly = true, String? speed}) {
    Map<EMediaLabel, List<FrameData>> map = {EMediaLabel.background: []};

    for (final key in _frameMap.keys) {
      final FrameData frame = _frameMap[key]!;

      if (!autoEditOnly || (frame.isEnableAutoEdit && !frame.exceptSpeed.containsKey(speed))) {
        map[EMediaLabel.background]!.add(frame);
      }
    }

    return map;
  }

  Map<EMediaLabel, List<StickerData>> getStickerDataMap(
      {bool autoEditOnly = true, String? speed}) {
    Map<EMediaLabel, List<StickerData>> map = {};

    for (final key in _stickerMap.keys) {
      final StickerData sticker = _stickerMap[key]!;

      if (!autoEditOnly || (sticker.isEnableAutoEdit && !sticker.exceptSpeed.containsKey(speed))) {
        if (!map.containsKey(sticker.type)) map[sticker.type] = [];
        map[sticker.type]!.add(sticker);
      }
    }

    return map;
  }

  List<String> getTextList({bool autoEditOnly = true, String? speed, int lineCount = 2}) {
    String locale = Platform.localeName;
    if (locale.contains("_")) {
      locale = locale.split("_")[0].toLowerCase();
    }

    return _textMap.keys
        .where((key) =>
            ((!autoEditOnly) || (_textMap[key]!.isRecommend && !_textMap[key]!.unsupportLang.containsKey(locale) && !_textMap[key]!.exceptSpeed.containsKey(speed) && _textMap[key]!.lineCount >= lineCount)))
        .map<String>((key) => key)
        .toList();
  }

  List<TextData> getTextDataList({bool autoEditOnly = true, String? speed, int lineCount = 2}) {
    String locale = Platform.localeName;
    if (locale.contains("_")) {
      locale = locale.split("_")[0].toLowerCase();
    }

    return _textMap.keys
        .where((key) =>
            ((!autoEditOnly) || (_textMap[key]!.isRecommend && !_textMap[key]!.unsupportLang.containsKey(locale) && !_textMap[key]!.exceptSpeed.containsKey(speed) && _textMap[key]!.lineCount >= lineCount)))
        .map<TextData>((key) => _textMap[key]!)
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

  List<TemplateData> getRandomTemplateData() {
    List<EMusicStyle> keys = _templateMap.keys.toList();

    int pickedIndex = Random().nextInt(keys.length) % keys.length;
    EMusicStyle picked = keys[pickedIndex];

    return _templateMap[picked]!;
  }

  String getReplaceFont(String fontFamily, String language) {
    if (_replaceFontMap.containsKey(fontFamily) && _replaceFontMap[fontFamily]!.containsKey(language)) {
      return _replaceFontMap[fontFamily]![language]!;
    }

    return fontFamily;
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

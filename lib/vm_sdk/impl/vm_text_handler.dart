import 'dart:async';
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:myapp/vm_sdk/impl/text_helper.dart';
import 'package:myapp/vm_sdk/impl/vm_text_widget.dart';
import 'package:rxdart/rxdart.dart';

import '../types/text.dart';
import 'global_helper.dart';

class VMTextHandler {
  late final InAppWebViewController _webViewController;
  String? _currentDirPath;
  String? _currentPreviewPath;
  String? _currentSequencePath;

  double _elapsedTime = 0;

  String? _previewImagePath;
  String? _allSequencesPath;
  Map<int, String> _allSequencePathMap = {};
  List<String> _allSequencePaths = [];
  final Map<String, TextWidgetData?> _dataMapOneLine = {};
  final Map<String, TextWidgetData?> _dataMapTwoLine = {};

  List<String> _texts = [];

  Completer<void>? _reloadCompleter;
  Completer<void>? _currentPreviewCompleter;
  Completer<void>? _currentSequencesCompleter;

  final BehaviorSubject<String> _bhPreview = BehaviorSubject();
  final BehaviorSubject<String> _bhSequences = BehaviorSubject();
  final BehaviorSubject<TextExportData> _bhTextData =
      BehaviorSubject.seeded(TextExportData(id: '', width: 0, height: 0, totalFrameCount: 0, frameRate: 0));

  bool _isInitialized = false;

  TextExportData get currentExportData => _bhTextData.value;

  String get _id => _bhTextData.value.id;

  void setWebViewController(InAppWebViewController controller) {
    _isInitialized = true;
    _webViewController = controller;
    handleCallBack(controller);
  }

  ValueStream<String> get previewStream => _bhPreview.stream;

  ValueStream<String> get sequencesStream => _bhSequences.stream;

  Function(double progress)? _currentProgressCallback;

  double get elapsedTime => _elapsedTime;

  String? get previewImagePath => _previewImagePath;

  String? get allSequencesPath => _allSequencesPath;

  List<String> get allSequencePaths => _allSequencePaths;

  Future<void> loadText(String id, {List<String>? initTexts}) async {
    _export(currentExportData.copyWith(id: id));
    if (!_dataMapOneLine.containsKey(id)) {
      _dataMapOneLine[id] = await loadTextWidgetData(id, 1);
    }
    if (!_dataMapTwoLine.containsKey(id)) {
      _dataMapTwoLine[id] = await loadTextWidgetData(id, 2);
    }

    await setTextValue(initTexts ?? ["THIS IS TITLE!"]);
  }

  Future<void> setTextValue(List<String> values, {bool isExtractPreviewImmediate = true}) async {
    _texts = [];
    _texts.addAll(values);

    if (isExtractPreviewImmediate) {
      await extractPreview();
    }
  }

  void _printAllData() {
    print(currentExportData.toString());
  }

  Future<void> _removeAll() async {
    // if (_currentPreviewPath != null) {
    //   Directory previewDir = Directory(_currentPreviewPath!);
    //   if (await previewDir.exists()) {
    //     await previewDir.delete(recursive: true);
    //   }
    // }
    // if (_currentSequencePath != null) {
    //   Directory sequenceDir = Directory(_currentSequencePath!);
    //   if (await sequenceDir.exists()) {
    //     await sequenceDir.delete(recursive: true);
    //   }
    // }
    // if (_currentDirPath != null) {
    //   Directory currentDir = Directory(_currentDirPath!);
    //   if (await currentDir.exists()) {
    //     await currentDir.delete(recursive: true);
    //   }
    // }
    _export(currentExportData.copyWith(width: 0, height: 0, textDataMap: {}, totalFrameCount: 0, frameRate: 0));
    _allSequencePaths = [];
  }

  void _export(TextExportData data) => _bhTextData.add(data);

  Future<void> _createDirectory(String path) async {
    Directory dir = Directory(path);
    // if (await dir.exists()) {
    //   await dir.delete(recursive: true);
    // }
    await dir.create(recursive: true);
  }

  TextWidgetData? _getTextWidgetData() {
    if (_texts.length >= 2 && _dataMapTwoLine.containsKey(_id)) {
      return _dataMapTwoLine[_id];
    }
    return _dataMapOneLine.containsKey(_id) ? _dataMapOneLine[_id] : null;
  }

  Future<void> extractPreview() async {
    nullCheck();
    TextWidgetData? _data = _getTextWidgetData();
    if (_data == null) return;

    _data.texts = [];
    _data.texts.addAll(_texts);

    // await _reload();
    await _removeAll();
    _currentDirPath = "${await getAppDirectoryPath()}/${_id}_${DateTime.now().millisecondsSinceEpoch}";
    _currentPreviewPath = "$_currentDirPath/preview";
    _currentSequencePath = "$_currentDirPath/sequences";
    await _createDirectory(_currentDirPath!);
    await _createDirectory(_currentPreviewPath!);
    await _createDirectory(_currentSequencePath!);

    _currentPreviewCompleter = Completer();

    String fontFamilyArr = "[";
    for (int i = 0; i < _data.fontFamily.length; i++) {
      fontFamilyArr += "'${_data.fontFamily[i]}',";
    }
    fontFamilyArr += "]";

    String fontBase64Arr = "[";
    for (int i = 0; i < _data.fontBase64.length; i++) {
      fontBase64Arr += "'${_data.fontBase64[i]}',";
    }
    fontBase64Arr += "]";

    String textArr = "[";
    for (int i = 0; i < _data.texts.length; i++) {
      textArr += "'${_data.texts[i]}',";
    }
    textArr += "]";

    await _webViewController.evaluateJavascript(
        source:
            "ExtractPreview({ id: '$_id ${_data.texts.length >= 2 ? "TWO" : "ONE"} LINE', jobId: '', fontFamliyArr: $fontFamilyArr, fontBase64: $fontBase64Arr, json: ${_data.json}, texts: $textArr, letterSpacing: ${_data.letterSpacing} })");

    return _currentPreviewCompleter!.future;
  }

  Future<void> extractAllSequence(Function(double progress)? progressCallback) async {
    nullCheck();
    TextWidgetData? _data = _getTextWidgetData();
    if (_data == null) return;

    _data.texts = [];
    _data.texts.addAll(_texts);

    await _reload();
    await _removeAll();

    _currentDirPath = "${await getAppDirectoryPath()}/${_id}_${DateTime.now().millisecondsSinceEpoch}";
    _currentPreviewPath = "$_currentDirPath/preview";
    _currentSequencePath = "$_currentDirPath/sequences";
    await _createDirectory(_currentDirPath!);
    await _createDirectory(_currentPreviewPath!);
    await _createDirectory(_currentSequencePath!);

    _currentProgressCallback = progressCallback;
    _currentSequencesCompleter = Completer();

    String fontFamilyArr = "[";
    for (int i = 0; i < _data.fontFamily.length; i++) {
      fontFamilyArr += "'${_data.fontFamily[i]}',";
    }
    fontFamilyArr += "]";

    String fontBase64Arr = "[";
    for (int i = 0; i < _data.fontBase64.length; i++) {
      fontBase64Arr += "'${_data.fontBase64[i]}',";
    }
    fontBase64Arr += "]";

    String textArr = "[";
    for (int i = 0; i < _data.texts.length; i++) {
      textArr += "'${_data.texts[i]}',";
    }
    textArr += "]";

    await _webViewController.evaluateJavascript(
        source:
            "ExtractAllSequence({ id: '$_id ${_data.texts.length >= 2 ? "TWO" : "ONE"} LINE', jobId: '', fontFamliyArr: $fontFamilyArr, fontBase64: $fontBase64Arr, json: ${_data.json}, texts: $textArr, letterSpacing: ${_data.letterSpacing} })");

    return _currentSequencesCompleter!.future;
  }

  Future<void> _reload() async {
    nullCheck();
    await _webViewController.reload();

    _reloadCompleter = Completer();
    return _reloadCompleter!.future;
  }

  void _handleTransferInit(args) async {
    if (_reloadCompleter != null) {
      _reloadCompleter!.complete();
    }
  }

  void _handleTransferPreviewPNGData(args) async {
    try {
      List textData = args[0]["textData"];
      _elapsedTime = args[0]["elapsedTime"].toDouble();
      _allSequencePaths.clear();

      final preview = args[0]["preview"];
      String previewUrl = "$_currentPreviewPath/preview.png";
      writeFileFromBase64(previewUrl, preview.toString().replaceAll("data:image/png;base64,", ""));
      _export(currentExportData.copyWith(
          width: args[0]["width"].toDouble(),
          height: args[0]["height"].toDouble(),
          frameRate: args[0]["frameRate"].toDouble(),
          textDataMap: {}));
      final Map<String, VMText> textDataMap = {};
      for (int i = 0; i < textData.length; i++) {
        print('key is ${textData[i]['key']}');
        print('value is ${textData[i]['value']}');

        textDataMap[i.toString()] = VMText(
            textData[i]['key'],
            textData[i]['value'],
            Rectangle(textData[i]['x'].toDouble(), textData[i]['y'].toDouble(), textData[i]['width'].toDouble(),
                textData[i]['height'].toDouble()));
      }

      _export(currentExportData.copyWith(textDataMap: textDataMap));

      _previewImagePath = previewUrl;
      _printAllData();

      if (_currentPreviewCompleter != null) {
        _currentPreviewCompleter!.complete();
        _bhPreview.add(_previewImagePath!);
      }
    } catch (e) {
      if (_currentPreviewCompleter != null) {
        _currentPreviewCompleter!.completeError(e);
      }
    }
  }

  void _handleTransferAllSequenceStart(args) async {
    try {
      _allSequencePaths = [];
      _allSequencePathMap = {};

      _export(currentExportData.copyWith(
          width: args[0]["width"].toDouble(),
          height: args[0]["height"].toDouble(),
          frameRate: args[0]["frameRate"].toDouble(),
          totalFrameCount: args[0]["totalFrameCount"].toInt()));
      if (_currentProgressCallback != null) {
        _currentProgressCallback!(0);
      }
    } catch (e) {
      if (_currentSequencesCompleter != null) {
        _currentSequencesCompleter!.completeError(e);
      }
    }
  }

  void _handleTransferAllSequencePNGData(args) async {
    try {
      int frameNumber = int.parse(args[0]["frameNumber"].toString());
      String data = args[0]["data"].toString().replaceAll("data:image/png;base64,", "");

      final String sequenceFilePath = "$_currentSequencePath/$frameNumber.png";
      _allSequencePathMap[frameNumber] = sequenceFilePath;
      writeFileFromBase64(sequenceFilePath, data);

      if (_currentProgressCallback != null) {
        _currentProgressCallback!(_allSequencePathMap.length / (currentExportData.totalFrameCount * 1.0));
      }
    } catch (e) {
      if (_currentSequencesCompleter != null) {
        _currentSequencesCompleter!.completeError(e);
      }
    }
  }

  void _handleTransferAllSequenceComplete(args) async {
    try {
      List<int> frameNumbers = _allSequencePathMap.keys.toList();
      frameNumbers.sort();

      for (final int frameNumber in frameNumbers) {
        _allSequencePaths.add(_allSequencePathMap[frameNumber]!);
      }

      _allSequencesPath = _currentSequencePath;
      _printAllData();

      if (_currentProgressCallback != null) {
        _currentProgressCallback!(1);
      }

      if (_currentSequencesCompleter != null) {
        _currentSequencesCompleter!.complete();
        _bhSequences.add(_allSequencesPath!);
      }
    } catch (e) {
      if (_currentSequencesCompleter != null) {
        _currentSequencesCompleter!.completeError(e);
      }
    }
  }

  void _handleTransferPreviewFailed(args) {
    if (_currentPreviewCompleter != null) {
      _currentPreviewCompleter!.completeError(Object());
    }
  }

  void _handleTransferAllSequenceFailed(args) {
    if (_currentSequencesCompleter != null) {
      _currentSequencesCompleter!.completeError(Object());
    }
  }

  void handleTerminated() {
    _webViewController.reload();
  }

  void handleCallBack(InAppWebViewController controller) {
    controller.addJavaScriptHandler(handlerName: "TransferInit", callback: _handleTransferInit);
    controller.addJavaScriptHandler(handlerName: "TransferPreviewPNGData", callback: _handleTransferPreviewPNGData);
    controller.addJavaScriptHandler(handlerName: "TransferAllSequenceStart", callback: _handleTransferAllSequenceStart);
    controller.addJavaScriptHandler(
        handlerName: "TransferAllSequencePNGData", callback: _handleTransferAllSequencePNGData);
    controller.addJavaScriptHandler(
        handlerName: "TransferAllSequenceComplete", callback: _handleTransferAllSequenceComplete);
    controller.addJavaScriptHandler(handlerName: "TransferPreviewFailed", callback: _handleTransferPreviewFailed);
    controller.addJavaScriptHandler(
        handlerName: "TransferAllSequenceFailed", callback: _handleTransferAllSequenceFailed);
  }
  
  void nullCheck(){
    if(!_isInitialized) {
      throw 'WebView is not initialized';
    }
  }
}

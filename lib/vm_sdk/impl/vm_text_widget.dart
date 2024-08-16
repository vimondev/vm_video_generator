import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:myapp/vm_sdk/impl/text_helper.dart';
import 'package:myapp/vm_sdk/types/types.dart';
import 'package:myapp/vm_sdk/impl/global_helper.dart';
import 'package:rxdart/rxdart.dart';
class VMTextWidget extends StatelessWidget {
  InAppWebViewController? _controller;
  String? _currentDirPath;
  String? _currentPreviewPath;
  String? _currentSequencePath;

  String _id = "";
  double _width = 0;
  double _height = 0;
  double _frameRate = 0;
  int _totalFrameCount = 0;
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

  ValueStream<String> get previewStream => _bhPreview.stream;

  ValueStream<String> get sequencesStream => _bhSequences.stream;

  Function(double progress)? _currentProgressCallback;

  double get width => _width;

  double get height => _height;

  double get frameRate => _frameRate;

  int get totalFrameCount => _totalFrameCount;

  double get elapsedTime => _elapsedTime;

  String? get previewImagePath => _previewImagePath;

  String? get allSequencesPath => _allSequencesPath;

  List<String> get allSequencePaths => _allSequencePaths;

  Future<void> loadText(String id, { List<String>? initTexts, required language }) async {
    _id = id;

    if (!_dataMapOneLine.containsKey(id)) {
      _dataMapOneLine[id] = await loadTextWidgetData(id, 1, language);
    }
    if (!_dataMapTwoLine.containsKey(id)) {
      _dataMapTwoLine[id] = await loadTextWidgetData(id, 2, language);
    }

    await setTextValue(initTexts ?? ["THIS IS TITLE!"]);
  }

  Future<void> setTextValue(List<String> values, {bool isExtractPreviewImmediate = true}) async {
    _texts = [];
    _texts.addAll(values);

    // TEMP CODE : WILL BE REMOVED : START
    final tempMap = {
      "Title_SW054": true,
      "Title_SW055": true,
      "Title_SW056": true,
      "Title_SW057": true,
      "Title_SW058": true,
      "Title_SW059": true,
      "Title_SW060": true,
      "Title_SW061": true,
      "Title_SW062": true,
      "Title_SW063": true,
      "Title_SW064": true,
      "Title_SW065": true,
      "Title_SW066": true,
    };

    if (tempMap[_id] == true && _texts.length < 2) {
      _texts.add(" ");
    }
    // TEMP CODE : WILL BE REMOVED : END


    if (isExtractPreviewImmediate) {
      await extractPreview();
    }
  }

  void _printAllData() {
    print("printAllData !!");
    print("_previewImage : $_previewImagePath");
    print("_width : $_width ");
    print("_height : $_height ");
    print("_frameRate : $_frameRate ");
    print("_totalFrameCount : $_totalFrameCount ");
    print("_allSequences : $_allSequencePaths");
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
    _width = 0;
    _height = 0;
    _frameRate = 0;
    _totalFrameCount = 0;
    _allSequencePaths = [];
  }

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

    await _controller!.evaluateJavascript(
        source:
        "ExtractPreview({ id: '$_id ${_data.texts.length >= 2 ? "TWO" : "ONE"} LINE', jobId: '', fontFamliyArr: $fontFamilyArr, fontBase64: $fontBase64Arr, json: ${_data.json}, texts: $textArr, letterSpacing: ${_data.letterSpacing} })");

    return _currentPreviewCompleter!.future;
  }

  Future<void> extractAllSequence(Function(double progress)? progressCallback) async {
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

    await _controller!.evaluateJavascript(
        source:
        "ExtractAllSequence({ id: '$_id ${_data.texts.length >= 2 ? "TWO" : "ONE"} LINE', jobId: '', fontFamliyArr: $fontFamilyArr, fontBase64: $fontBase64Arr, json: ${_data.json}, texts: $textArr, letterSpacing: ${_data.letterSpacing} })");

    return _currentSequencesCompleter!.future;
  }

  Future<void> _reload() async {
    if (_controller != null) {
      await _controller!.reload();
    }
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
      _width = args[0]["width"].toDouble();
      _height = args[0]["height"].toDouble();
      _frameRate = args[0]["frameRate"].toDouble();
      _elapsedTime = args[0]["elapsedTime"].toDouble();
      _allSequencePaths.clear();

      final preview = args[0]["preview"];
      String previewUrl = "$_currentPreviewPath/preview.png";
      writeFileFromBase64(previewUrl, preview.toString().replaceAll("data:image/png;base64,", ""));

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
      _width = args[0]["width"].toDouble();
      _height = args[0]["height"].toDouble();
      _frameRate = args[0]["frameRate"].toDouble();
      _totalFrameCount = args[0]["totalFrameCount"].toInt();
      _allSequencePaths = [];
      _allSequencePathMap = {};

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
        _currentProgressCallback!(_allSequencePathMap.length / (_totalFrameCount * 1.0));
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

  void _handleTerminated(InAppWebViewController controller) {
    print("terminated. reload!");
    controller.reload();
  }

  void _setController(InAppWebViewController controller) {
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
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    InAppWebViewGroupOptions option = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: true,
        useShouldOverrideUrlLoading: true,
        useShouldInterceptFetchRequest: true,
      ),
      android: AndroidInAppWebViewOptions(
          useHybridComposition: true,
          mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
          supportMultipleWindows: true,
          useShouldInterceptRequest: true),
    );
    return SizedBox(
      height: 100,
      child: Transform.translate(
          offset: const Offset(-9999999, -99999),
          // offset: const Offset(0, 0),
          child: InAppWebView(
          initialOptions: option,
          initialFile: "packages/myapp/assets/html/index5.html",
          onWebViewCreated: (controller) {
            _setController(controller);
          },
          iosOnWebContentProcessDidTerminate: (controller) {
            _handleTerminated(controller);
          },
          onConsoleMessage: (controller, consoleMessage) {
            print('VMTextWebView - [$consoleMessage]');
          }),
    ));
  }

  void release() {
    _bhPreview.drain().then((value) => _bhPreview.close());
    _bhSequences.drain().then((value) => _bhSequences.close());
  }
}

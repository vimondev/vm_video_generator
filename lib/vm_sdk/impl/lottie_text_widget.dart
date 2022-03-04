import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:myapp/vm_sdk/impl/ml_kit_helper.dart';
import 'package:myapp/vm_sdk/types/types.dart';
import 'package:myapp/vm_sdk/impl/global_helper.dart';

import 'ffmpeg_manager.dart';

class Rectangle {
  double _x, _y, _width, _height;

  Rectangle(this._x, this._y, this._width, this._height);

  double get x => _x;
  double get y => _y;
  double get width => _width;
  double get height => _height;
}

class LottieText {
  String _key;
  String _value;
  Rectangle _boundingBox;

  LottieText(this._key, this._value, this._boundingBox);

  String get key {
    return _key;
  }
  String get value => _value;
  Rectangle get boundingBox => _boundingBox;
}

class LottieTextWidget extends StatelessWidget {

  InAppWebViewController? _controller;
  String? _currentDirPath;
  String? _currentPreviewPath;
  String? _currentSequencePath;
  String? _previewImage;
  double _width = 0;
  double _height = 0;
  double _frameRate = 0;
  int _totalFrames = 0;
  Map<String, LottieText> _textDataMap = {};
  List<String> _allSequences = [];

  late TitleData _data;
  late Completer<String> _currentPreviewCompleter;
  late Completer<List<String>> _currentSequencesCompleter;
  // late Completer<ExportedTitlePNGSequenceData> _currentTitleCompleter;

  String? get currentDirPath => _currentDirPath;
  String? get currentPreviewPath => _currentPreviewPath;
  String? get currentSequencePath => _currentSequencePath;
  String? get previewImage => _previewImage;
  double get width => _width;
  double get height => _height;
  double get frameRate => _frameRate;
  int get totalFrames => _totalFrames;
  Map<String, LottieText> get textDataMap => _textDataMap;
  List<String> get allSequences => _allSequences;

  void printAllData () {
    print("printAllData !!");
    print("_previewImage : $_previewImage ");
    print("_width : $_width ");
    print("_height : $_height ");
    print("_frameRate : $_frameRate ");
    print("_totalFrames : $_totalFrames ");
    print("_textDataMap : $_textDataMap");
    print("_allSequences : $_allSequences");
  }

  void removeAll () async {
    if (_currentPreviewPath != null) {
      Directory previewDir = Directory(_currentPreviewPath!);
      if (await previewDir.exists()) {
        previewDir.deleteSync(recursive: true);
      }
    }
    if (_currentSequencePath != null) {
      Directory sequenceDir = Directory(_currentSequencePath!);
      if (await sequenceDir.exists()) {
        sequenceDir.deleteSync(recursive: true);
      }
    }
    if (_currentDirPath != null) {
      Directory currentDir = Directory(_currentDirPath!);
      if (await currentDir.exists()) {
        currentDir.deleteSync(recursive: true);
      }
    }
    _width = 0;
    _height = 0;
    _frameRate = 0;
    _totalFrames = 0;
    _textDataMap = {};
    _allSequences = [];
  }

  void setData (TitleData data) {
    _data = data;
  }

  Future<String?> setTextValue (String key, String value) async {
    int length = _textDataMap.length;
    for (int i = 0; i < length; i++) {
      if (_textDataMap[i.toString()] != null) {
        LottieText? lottieText = _textDataMap[i.toString()];
        if (lottieText != null && lottieText.key == key) {
          _data.texts[i] = value;
          break;
        }
      }
    }

    return await extractPreview();
  }

  Future<void> _createDirectory(String path) async {
    Directory dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  }

  Future<String?> extractPreview() async {
    if (_currentDirPath != null || _currentPreviewPath != null || _currentSequencePath != null) {
      removeAll();
    }
    _currentDirPath = "${await getAppDirectoryPath()}/${DateTime.now().millisecondsSinceEpoch}";
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

    print('extractPreview - 11111');
    _controller!.evaluateJavascript(
        source:
        "setData({ fontFamily: $fontFamilyArr, base64: $fontBase64Arr, json: ${_data.json}, texts: $textArr });");
    _controller!.evaluateJavascript(source: "extractPreview();");
    print('extractPreview - 22222');

    return _currentPreviewCompleter.future;
  }

  Future<List<String>?> extractAllSequence() async {
    if (_currentDirPath != null || _currentPreviewPath != null || _currentSequencePath != null) {
      removeAll();
    }
    _currentDirPath = "${await getAppDirectoryPath()}/${DateTime.now().millisecondsSinceEpoch}";
    _currentPreviewPath = "$_currentDirPath/preview";
    _currentSequencePath = "$_currentDirPath/sequences";
    await _createDirectory(_currentDirPath!);
    await _createDirectory(_currentPreviewPath!);
    await _createDirectory(_currentSequencePath!);

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

    _controller!.evaluateJavascript(
        source:
        "setData({ fontFamily: $fontFamilyArr, base64: $fontBase64Arr, json: ${_data.json}, texts: $textArr });");
    _controller!.evaluateJavascript(source: "extractAllSequence();");

    return _currentSequencesCompleter.future;
  }



  // Future<ExportedTitlePNGSequenceData> exportTitlePNGSequence(
  //     TitleData data) async {
  //   _currentDirPath =
  //   "${await getAppDirectoryPath()}/${DateTime.now().millisecondsSinceEpoch}";
  //   _currentSequencePath = "$_currentDirPath/sequences";
  //
  //   await _createDirectory(_currentDirPath);
  //   await _createDirectory(_currentSequencePath);
  //
  //   _currentTitleCompleter = Completer();
  //
  //   String textArr = "[";
  //   for (int i = 0; i < data.texts.length; i++) {
  //     textArr += "'${data.texts[i]}',";
  //   }
  //   textArr += "]";
  //
  //   print("============= !!! ===========");
  //   print("fontFamily : ${data.fontFamily}");
  //   print("fontBase64 : ${data.fontBase64}");
  //   print("json: ${data.json}");
  //   print("texts : $textArr");
  //
  //   _controller!.evaluateJavascript(
  //       source:
  //       "setData({ fontFamily: `${data.fontFamily}`, base64: `${data.fontBase64}`, json: ${data.json}, texts: $textArr });");
  //   _controller!.evaluateJavascript(source: "run();");
  //
  //   return _currentTitleCompleter.future;
  // }

  void _handleTransferPreviewPNGData(args) async {
    _width = args[0]["width"].toDouble();
    _height = args[0]["height"].toDouble();
    List textData = args[0]["textData"];
    _frameRate = args[0]["frameRate"].toDouble();
    _textDataMap.clear();
    _allSequences.clear();

    final preview = args[0]["preview"];
    String previewUrl = "$_currentPreviewPath/preview.png";
    writeFileFromBase64(
        previewUrl,
        preview
            .toString()
            .replaceAll("data:image/png;base64,", ""));

    for (int i = 0; i < textData.length; i++) {
      _textDataMap[i.toString()] = LottieText(
          textData[i]['key'],
          textData[i]['value'],
          Rectangle(textData[i]['x'].toDouble(), textData[i]['y'].toDouble(), textData[i]['width'].toDouble(), textData[i]['height'].toDouble())
      );
    }

    // setState(() {
    //   _previewImage = previewUrl;
    // });

    _previewImage = previewUrl;

    printAllData();

    _currentPreviewCompleter.complete(previewUrl);
  }

  void _handleTransferAllSequencePNGData(args) async {
    _width = args[0]["width"].toDouble();
    _height = args[0]["height"].toDouble();
    _frameRate = args[0]["frameRate"].toDouble();
    List frames = args[0]["frames"];
    _totalFrames = frames.length;
    _allSequences.clear();

    for (int i = 0; i < frames.length; i++) {
      final String sequenceFilePath = "$_currentSequencePath/$i.png";
      _allSequences.add(sequenceFilePath);
      writeFileFromBase64(
          sequenceFilePath,
          frames[i]
              .toString()
              .replaceAll("data:image/png;base64,", ""));
    }

    printAllData();

    _currentSequencesCompleter.complete(_allSequences);
  }

  void _handleTransferPreviewFailed(args) {
    _currentPreviewCompleter.completeError(Object());
  }

  void _handleTransferAllSequenceFailed(args) {
    _currentSequencesCompleter.completeError(Object());
  }

  // void _handleTransferFailed(args) {
  //   _currentTitleCompleter.completeError(Object());
  // }

  void _setController(InAppWebViewController controller) {
    controller.addJavaScriptHandler(handlerName: "TransferPreviewPNGData", callback: _handleTransferPreviewPNGData);
    controller.addJavaScriptHandler(handlerName: "TransferAllSequencePNGData", callback: _handleTransferAllSequencePNGData);
    controller.addJavaScriptHandler(handlerName: "TransferPreviewFailed", callback: _handleTransferPreviewFailed);
    controller.addJavaScriptHandler(handlerName: "TransferAllSequenceFailed", callback: _handleTransferAllSequenceFailed);
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: Transform.translate(
        offset: const Offset(-99999, -99999),
        // offset: const Offset(0, 0),
        child: InAppWebView(
            initialFile: "assets/html/index4.html",
            onWebViewCreated: (controller) {
              _setController(controller);
            },
            onConsoleMessage: (controller, consoleMessage) {
              print(consoleMessage);
            }),
      ),
    );
  }
}

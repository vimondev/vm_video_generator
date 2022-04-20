import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:myapp/vm_sdk/impl/title_helper.dart';
import 'package:myapp/vm_sdk/types/types.dart';
import 'package:myapp/vm_sdk/impl/global_helper.dart';
import 'package:myapp/vm_sdk/widgets/customwebview.dart';

class Rectangle {
  double _x, _y, _width, _height;

  Rectangle(this._x, this._y, this._width, this._height);

  double get x => _x;
  double get y => _y;
  double get width => _width;
  double get height => _height;
}

class VMText {
  String _key;
  String _value;
  Rectangle _boundingBox;

  VMText(this._key, this._value, this._boundingBox);

  String get key => _key;
  String get value => _value;
  Rectangle get boundingBox => _boundingBox;
}

class VMTextWidget extends StatelessWidget {
  InAppWebViewController? _controller;
  String? _currentDirPath;
  String? _currentPreviewPath;
  String? _currentSequencePath;

  double _width = 0;
  double _height = 0;
  double _frameRate = 0;
  int _totalFrameCount = 0;
  Map<String, VMText> _textDataMap = {};

  String? _previewImagePath;
  List<String> _allSequencePaths = [];

  late TextData _data;
  late Completer<void> _currentPreviewCompleter;
  late Completer<void> _currentSequencesCompleter;

  double get width => _width;
  double get height => _height;
  double get frameRate => _frameRate;
  int get totalFrameCount => _totalFrameCount;
  Map<String, VMText> get textDataMap => _textDataMap;

  String? get previewImagePath => _previewImagePath;
  List<String> get allSequencePaths => _allSequencePaths;

  Future<void> loadText(ETextID id) async {
    _data = (await loadTextData(id))!;

    _data.texts.add("TITLE");
    _data.texts.add("SUBTITLE");

    await _extractPreview();
  }

  Future<void> setTextValue(String key, String value) async {
    final List<VMText> texts = _textDataMap.values.toList();
    for (int i = 0; i < texts.length; i++) {
      VMText text = texts[i];
      if (text.key == key) {
        _data.texts[i] = value;
        break;
      }
    }

    await _extractPreview();
  }

  void _printAllData() {
    print("printAllData !!");
    print("_previewImage : $_previewImagePath");
    print("_width : $_width ");
    print("_height : $_height ");
    print("_frameRate : $_frameRate ");
    print("_totalFrameCount : $_totalFrameCount ");
    print("_textDataMap : $_textDataMap");
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
    _textDataMap = {};
    _allSequencePaths = [];
  }

  Future<void> _createDirectory(String path) async {
    Directory dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  }

  Future<void> _extractPreview() async {
    await _reload();
    await _removeAll();
    _currentDirPath =
        "${await getAppDirectoryPath()}/${DateTime.now().millisecondsSinceEpoch}";
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
            "(async function () { await setData({ fontFamily: $fontFamilyArr, base64: $fontBase64Arr, json: ${_data.json}, texts: $textArr }); extractPreview(); })()");

    return _currentPreviewCompleter.future;
  }

  Future<void> _extractAllSequence() async {
    await _reload();
    await _removeAll();

    _currentDirPath =
        "${await getAppDirectoryPath()}/${DateTime.now().millisecondsSinceEpoch}";
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
            "(async function () { await setData({ fontFamily: $fontFamilyArr, base64: $fontBase64Arr, json: ${_data.json}, texts: $textArr }); extractAllSequence(); })()");

    return _currentSequencesCompleter.future;
  }

  Future<void> _reload() async {
    if (_controller != null) {
      await _controller!.reload();
    }
  }

  void _handleTransferPreviewPNGData(args) async {
    try {
      _width = args[0]["width"].toDouble();
      _height = args[0]["height"].toDouble();
      List textData = args[0]["textData"];
      _frameRate = args[0]["frameRate"].toDouble();
      _textDataMap.clear();
      _allSequencePaths.clear();

      final preview = args[0]["preview"];
      String previewUrl = "$_currentPreviewPath/preview.png";
      writeFileFromBase64(previewUrl,
          preview.toString().replaceAll("data:image/png;base64,", ""));

      for (int i = 0; i < textData.length; i++) {
        print('key is ${textData[i]['key']}');
        print('value is ${textData[i]['value']}');

        _textDataMap[i.toString()] = VMText(
            textData[i]['key'],
            textData[i]['value'],
            Rectangle(
                textData[i]['x'].toDouble(),
                textData[i]['y'].toDouble(),
                textData[i]['width'].toDouble(),
                textData[i]['height'].toDouble()));
      }

      _previewImagePath = previewUrl;
      _printAllData();

      _currentPreviewCompleter.complete();
    } catch (e) {
      _currentPreviewCompleter.completeError(e);
    }
  }

  void _handleTransferAllSequencePNGData(args) async {
    try {
      _width = args[0]["width"].toDouble();
      _height = args[0]["height"].toDouble();
      _frameRate = args[0]["frameRate"].toDouble();
      List frames = args[0]["frames"];
      _totalFrameCount = frames.length;
      _allSequencePaths.clear();

      for (int i = 0; i < frames.length; i++) {
        final String sequenceFilePath = "$_currentSequencePath/$i.png";
        _allSequencePaths.add(sequenceFilePath);
        writeFileFromBase64(sequenceFilePath,
            frames[i].toString().replaceAll("data:image/png;base64,", ""));
      }

      _printAllData();
      _currentSequencesCompleter.complete();
    } catch (e) {
      _currentPreviewCompleter.completeError(e);
    }
  }

  void _handleTransferPreviewFailed(args) {
    _currentPreviewCompleter.completeError(Object());
  }

  void _handleTransferAllSequenceFailed(args) {
    _currentSequencesCompleter.completeError(Object());
  }

  void _setController(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
        handlerName: "TransferPreviewPNGData",
        callback: _handleTransferPreviewPNGData);
    controller.addJavaScriptHandler(
        handlerName: "TransferAllSequencePNGData",
        callback: _handleTransferAllSequencePNGData);
    controller.addJavaScriptHandler(
        handlerName: "TransferPreviewFailed",
        callback: _handleTransferPreviewFailed);
    controller.addJavaScriptHandler(
        handlerName: "TransferAllSequenceFailed",
        callback: _handleTransferAllSequenceFailed);
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: Transform.translate(
        offset: const Offset(-9999999, -99999),
        // offset: const Offset(0, 0),
        child: CustomWebView(
          callback: _setController,
          initialFile: "assets/html/index4.html",
        ),
      ),
    );
  }
}

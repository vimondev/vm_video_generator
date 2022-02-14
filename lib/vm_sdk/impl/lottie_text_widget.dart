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

class LottieTextWidget extends StatefulWidget {
  LottieTextWidget({Key? key}) : super(key: key);

  _LottieTextWidgetState _lottieTextWidgetState = _LottieTextWidgetState();

  @override
  _LottieTextWidgetState createState() {
    return _lottieTextWidgetState;
  }

  Future<ExportedTitlePNGSequenceData> exportTitlePNGSequence(
      TitleData data) async {
    ExportedTitlePNGSequenceData exportedTitleData =
    await _lottieTextWidgetState.exportTitlePNGSequence(data);
    return exportedTitleData;
  }
}

class _LottieTextWidgetState extends State<LottieTextWidget> {
  InAppWebViewController? _controller;
  late String _currentDirPath;
  late String _currentSequencePath;
  String? _previewImage;
  double _width = 0;
  double _height = 0;
  double _frameRate = 0;
  int _totalFrames = 0;
  Map<String, LottieText> _textDataMap = {};
  List<String> _allSequences = [];

  late Completer<ExportedTitlePNGSequenceData> _currentTitleCompleter;

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

  Future<void> _createDirectory(String path) async {
    Directory dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  }

  Future<ExportedTitlePNGSequenceData> exportTitlePNGSequence(
      TitleData data) async {
    _currentDirPath =
    "${await getAppDirectoryPath()}/${DateTime.now().millisecondsSinceEpoch}";
    _currentSequencePath = "$_currentDirPath/sequences";

    await _createDirectory(_currentDirPath);
    await _createDirectory(_currentSequencePath);

    _currentTitleCompleter = Completer();

    String textArr = "[";
    for (int i = 0; i < data.texts.length; i++) {
      textArr += "'${data.texts[i]}',";
    }
    textArr += "]";

    print("============= !!! ===========");
    print("fontFamily : ${data.fontFamily}");
    print("fontBase64 : ${data.fontBase64}");
    print("json: ${data.json}");
    print("texts : $textArr");

    String temp =
        "setData({ fontFamily: `${data.fontFamily}`, base64: `${data.fontBase64}`, json: ${data.json}, texts: $textArr });";
    _controller!.evaluateJavascript(
        source:
        "setData({ fontFamily: `${data.fontFamily}`, base64: `${data.fontBase64}`, json: ${data.json}, texts: $textArr });");
    _controller!.evaluateJavascript(source: "run();");

    return _currentTitleCompleter.future;
  }

  void _handleTransferPNGData(args) async {
    _width = args[0]["width"];
    _height = args[0]["height"];
    List textData = args[0]["textData"];
    _frameRate = args[0]["frameRate"];
    List frames = args[0]["frames"];
    _totalFrames = frames.length;
    _textDataMap.clear();
    _textDataMap = {};
    _allSequences.clear();

    final preview = args[0]["preview"];
    String previewUrl = "$_currentDirPath/preview.png";
    writeFileFromBase64(
        previewUrl,
        preview["base64"]
            .toString()
            .replaceAll("data:image/png;base64,", ""));

    for (int i = 0; i < textData.length; i++) {
      _textDataMap.addAll({
        '${i.toString()}' : LottieText(
            textData[i]['key'],
            textData[i]['value'],
            Rectangle(textData[i]['x'].toDouble(), textData[i]['y'].toDouble(), textData[i]['width'].toDouble(), textData[i]['height'].toDouble())
        )
      });
    }

    for (int i = 0; i < frames.length; i++) {
      final String sequenceFilePath = "$_currentDirPath/$i.png";
      _allSequences.add(sequenceFilePath);
      writeFileFromBase64(
          sequenceFilePath,
          frames[i]["base64"]
              .toString()
              .replaceAll("data:image/png;base64,", ""));
    }
    setState(() {
      _previewImage = previewUrl;
    });

    printAllData();

    _currentTitleCompleter.complete(ExportedTitlePNGSequenceData(
        _currentDirPath, _width, _height, _frameRate));
  }

  void _handleTransferFailed(args) {
    _currentTitleCompleter.completeError(Object());
  }

  void _setController(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
        handlerName: "TransferPNGData", callback: _handleTransferPNGData);

    controller.addJavaScriptHandler(
        handlerName: "TransferFailed", callback: _handleTransferFailed);
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            child: _previewImage != null ? Image.file(
              File(_previewImage!),
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ) : null,
          ),
          Container(
            height: 100,
            child: Transform.translate(
              offset: const Offset(-99999, -99999),
              // offset: const Offset(0, 0),
              child: InAppWebView(
                  initialFile: "assets/html/index3.html",
                  onWebViewCreated: (controller) {
                    _setController(controller);
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    print(consoleMessage);
                  }),
            ),
          ),
        ],
      ),
    );
  }
}

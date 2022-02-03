import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:myapp/vm_sdk/impl/ml_kit_helper.dart';
import 'package:myapp/vm_sdk/types/types.dart';
import 'package:myapp/vm_sdk/impl/global_helper.dart';

import 'ffmpeg_manager.dart';

class LottieWidget extends StatelessWidget {
  LottieWidget({Key? key}) : super(key: key);

  final FFMpegManager _ffmpegManager = FFMpegManager();
  InAppWebViewController? _controller;
  late String _currentDirPath;
  late String _currentSequencePath;
  late Completer<ExportedTitlePNGSequenceData> _currentTitleCompleter;

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

    String temp =
        "setData({ fontFamily: `${data.fontFamily}`, base64: `${data.fontBase64}`, json: ${data.json}, texts: $textArr });";
    _controller!.evaluateJavascript(
        source:
            "setData({ fontFamily: `${data.fontFamily}`, base64: `${data.fontBase64}`, json: ${data.json}, texts: $textArr });");
    _controller!.evaluateJavascript(source: "run();");

    return _currentTitleCompleter.future;
  }

  void _handleTransferPNGFile(args) {
    String frameNumber = args[0].toString();
    String base64Str =
        args[1].toString().replaceAll("data:image/png;base64,", "");

    print("$frameNumber.png");

    writeFileFromBase64("$_currentDirPath/$frameNumber.png", base64Str);
  }

  void _handleTransferPNGData(args) async {
    int width = args[0]["width"];
    int height = args[0]["height"];
    double frameRate = args[0]["frameRate"];

    List frames = args[0]["frames"];
    List<String> inputArguments = [];
    List<String> filterStrings = [];
    List<String> outputArguments = [];

    int currentCount = 0;
    for (int i = 0; i < frames.length; i++) {
      int startFrame = frames[i]["startFrame"];
      int endFrame = frames[i]["endFrame"];
      final String sequenceFilePath = "$_currentSequencePath/sequence$i.png";
      writeFileFromBase64(
          sequenceFilePath,
          frames[i]["base64"]
              .toString()
              .replaceAll("data:image/png;base64,", ""));

      inputArguments.addAll(["-i", sequenceFilePath]);

      int currentY = 0;
      for (int j = startFrame; j <= endFrame; j++) {
        filterStrings.add(
            "[$i:v]crop=$width:$height:0:${(height + currentY)},setdar=dar=${(width / height)},scale=$width:$height[out$currentCount];");
        outputArguments.addAll([
          "-map",
          "[out$currentCount]",
          "$_currentDirPath/$currentCount.png"
        ]);

        currentY += height;
        currentCount++;

        // if (currentCount >= 101) break;
      }
      // if (currentCount >= 101) break;
    }

    List<String> arguments = [];

    // generate -filter_complex
    String filterComplexStr = "";
    for (final String filterStr in filterStrings) {
      filterComplexStr += filterStr;
    }

    if (filterComplexStr.endsWith(";")) {
      filterComplexStr =
          filterComplexStr.substring(0, filterComplexStr.length - 1);
    }

    arguments.addAll(inputArguments);
    arguments.addAll(["-filter_complex", filterComplexStr]);
    arguments.addAll(outputArguments);

    bool isSuccess = await _ffmpegManager.execute(arguments, (p0) => null);
    print(isSuccess);
  }

  void _handleTransferComplete(args) {
    String width = args[0].toString();
    String height = args[1].toString();
    String frameRate = args[2].toString();

    _currentTitleCompleter.complete(ExportedTitlePNGSequenceData(
        _currentDirPath,
        int.parse(width),
        int.parse(height),
        double.parse(frameRate)));
  }

  void _handleTransferFailed(args) {
    _currentTitleCompleter.completeError(Object());
  }

  void _setController(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
        handlerName: "TransferPNGBase64", callback: _handleTransferPNGFile);

    controller.addJavaScriptHandler(
        handlerName: "TransferPNGData", callback: _handleTransferPNGData);

    controller.addJavaScriptHandler(
        handlerName: "TransferComplete", callback: _handleTransferComplete);

    controller.addJavaScriptHandler(
        handlerName: "TransferFailed", callback: _handleTransferFailed);

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
        // offset: const Offset(-99999, -99999),
        offset: const Offset(0, 0),
        child: InAppWebView(
            initialFile: "assets/html/index.html",
            onWebViewCreated: (controller) {
              _setController(controller);
            },
            onConsoleMessage: (controller, consoleMessage) {
              print(consoleMessage);
            }));
  }
}

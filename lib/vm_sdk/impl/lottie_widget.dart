import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:myapp/vm_sdk/types/types.dart';
import 'package:myapp/vm_sdk/impl/global_helper.dart';

class LottieWidget extends StatelessWidget {
  LottieWidget({Key? key}) : super(key: key);

  late InAppWebViewController _controller;
  late String _currentDirPath;
  late Completer<ExportedTitlePNGSequenceData> _currentTitleCompleter;

  Future<ExportedTitlePNGSequenceData> exportTitlePNGSequence(
      TitleData data) async {
    _currentDirPath =
        "${await getAppDirectoryPath()}/${DateTime.now().millisecondsSinceEpoch}";

    Directory dir = Directory(_currentDirPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    _currentTitleCompleter = Completer();

    _controller.evaluateJavascript(
        source:
            "setData({ fontFamily: `${data.fontFamily}`, base64: `${data.fontBase64}`, json: ${data.json}, text: `${data.text}` });");
    _controller.evaluateJavascript(source: "run();");

    return _currentTitleCompleter.future;
  }

  void _handleTransferPNGFile(args) {
    String frameNumber = args[0].toString();
    String base64Str =
        args[1].toString().replaceAll("data:image/png;base64,", "");

    print("$frameNumber.png");

    writeFileFromBase64("$_currentDirPath/$frameNumber.png", base64Str);
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
        handlerName: "TransferComplete", callback: _handleTransferComplete);

    controller.addJavaScriptHandler(
        handlerName: "TransferFailed", callback: _handleTransferFailed);

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(
          url: Uri.parse("http://172.16.6.189:8080/index.html?date=1")),
      // URLRequest(url: Uri.parse("https://videomonster.com")),
      onWebViewCreated: (controller) {
        _setController(controller);
      },
      onConsoleMessage: (controller, consoleMessage) {
        print(consoleMessage);
      },
    );
  }
}

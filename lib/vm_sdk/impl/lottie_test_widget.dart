import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:myapp/vm_sdk/types/types.dart';

class LottieTestWidget extends StatelessWidget {
  InAppWebViewController? _controller;
  late TitleData _data;

  void setData (TitleData data) {
    _data = data;
  }

  void run() {
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

    print('fontFamily: ' + fontFamilyArr);
    _controller!.evaluateJavascript(
        source:
        "setData({ fontFamily: $fontFamilyArr, base64: $fontBase64Arr, json: ${_data.json}, texts: $textArr });");
    _controller!.evaluateJavascript(source: "run();");
  }

  void _setController(InAppWebViewController controller) {
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 700,
      child: Transform.translate(
        // offset: const Offset(-99999, -99999),
        offset: const Offset(0, 0),
        child: InAppWebView(
            initialFile: "assets/html/index_test.html",
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

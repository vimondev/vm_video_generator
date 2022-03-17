import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Webview extends StatelessWidget {
  static final Webview _instance = Webview._internal();
  static var _callback;
  static String? _initialFile;


  factory Webview({callback, initialFile}) {
    _callback = callback;
    _initialFile = initialFile;
    return _instance;
  }

  Webview._internal() {

  }

  // const Webview({Key? key, this.callback, this.initialFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
          initialFile: _initialFile,
          onWebViewCreated: (controller) {
            _callback(controller);
          },
          onConsoleMessage: (controller, consoleMessage) {
            print(consoleMessage);
          });
  }
}

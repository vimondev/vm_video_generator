import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CustomWebView extends StatelessWidget {
  static final CustomWebView _instance = CustomWebView._internal();
  static var _callback;
  static var _handleTerminated;
  static String? _initialFile;
  InAppWebViewController? _controller;

  InAppWebViewController? get controller => _controller;

  factory CustomWebView({callback, handleTerminated, initialFile}) {
    _callback = callback;
    _handleTerminated = handleTerminated;
    _initialFile = initialFile;
    return _instance;
  }

  CustomWebView._internal() {}

  // const Webview({Key? key, this.callback, this.initialFile}) : super(key: key);

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

    return InAppWebView(
        initialOptions: option,
        initialFile: _initialFile,
        onWebViewCreated: (controller) {
          _controller = controller;
          _callback(controller);
        },
        iosOnWebContentProcessDidTerminate: (controller) {
          _handleTerminated(controller);
        },
        onConsoleMessage: (controller, consoleMessage) {
          print(consoleMessage);
        });
  }
}

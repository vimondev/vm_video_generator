import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';

String? dirpath;

Future<void> createFileFromString(String frame, String encoded) async {
  Uint8List bytes = base64.decode(encoded);

  File file = File("${dirpath!}/$frame.png");
  await file.writeAsBytes(bytes);
}

class CustomWebView extends StatefulWidget {
  CustomWebView({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  late InAppWebViewController controller;

  void run() async {
    // String curFilename = "title1_text2";
    // final String fontFamily = 'Jalnan';
    // final String fontFilename = 'Jalnan.ttf';

    // String curFilename = "title2_text2";
    // final String fontFamily = 'SCoreDream8Heavy';
    // final String fontFilename = 'SCDream8.otf';

    String curFilename = "title3_text2";
    final String fontFamily = 'VITROCORE';
    final String fontFilename = 'VITROCORE.ttf';

    final String text = 'THIS IS FANCY TITLE!!';

    final String json =
        (await rootBundle.loadString("assets/lottie/$curFilename.json"));
    dirpath = "${(await getApplicationDocumentsDirectory()).path}/$curFilename";
    Directory dir = Directory(dirpath!);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    final ByteData byteData =
        await rootBundle.load("assets/lottie/$fontFilename");
    final String fontBase64 = base64.encode(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    controller.evaluateJavascript(
        source:
            "setData({ fontFamily: `$fontFamily`, base64: `$fontBase64`, json: $json, text: `$text` });");
    controller.evaluateJavascript(source: "run();");
  }

  void setController(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
        handlerName: "TransferPNGBase64",
        callback: (args) {
          print(args[0]);
          createFileFromString(args[0].toString(),
              args[1].toString().replaceAll("data:image/png;base64,", ""));
        });

    controller.addJavaScriptHandler(
        handlerName: "TransferComplete",
        callback: (args) => {
              print(args[0]) // frameRate
            });

    controller.addJavaScriptHandler(
        handlerName: "TransferFailed", callback: (args) => {});

    this.controller = controller;
  }

  @override
  State<CustomWebView> createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView> {
  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(
          url: Uri.parse("http://172.16.6.189:8080/index.html?date=20")),
      onWebViewCreated: (controller) => {
        widget.setController(controller)
        /////
      },
      onConsoleMessage: (controller, consoleMessage) {
        print(consoleMessage);
        // it will print: {message: {"bar":"bar_value","baz":"baz_value"}, messageLevel: 1}
      },
    );
  }
}

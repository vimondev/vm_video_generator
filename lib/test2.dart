import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:myapp/vm_sdk/impl/lottie_text_widget.dart';
import 'package:myapp/vm_sdk/impl/title_helper.dart';
import 'vm_sdk/impl/lottie_test_widget.dart';
import 'vm_sdk/vm_sdk.dart';
import 'vm_sdk/types/types.dart';
import 'vm_sdk/impl/global_helper.dart';
import 'dart:convert';
import 'vm_sdk/impl/lottie_widget.dart';
import 'package:flutter/services.dart' show rootBundle;

class TestWidget2 extends StatefulWidget {
  TestWidget2({Key? key}) : super(key: key);

  @override
  State<TestWidget2> createState() => _TestWidget2State();
}

class _TestWidget2State extends State<TestWidget2> {
  // final VMSDKWidget _vmsdkWidget = VMSDKWidget();
  late LottieTestWidget _lottieTestWidget = LottieTestWidget();
  ETitleType? _title;

  void _run() async {
    if (_title == null) {
      _title = ETitleType.title01;
    } else {
      bool isNext = false;
      for (var value in ETitleType.values) {
        if (isNext == true) {
          _title = value;
          break;
        }
        if (_title == value) {
          isNext = true;
        }
      }
      if (isNext == true && _title == ETitleType.title33) {
        _title = ETitleType.title01;
      }
    }

    final TitleData title = (await loadTitleData(_title!))!;
    print('title is ');

    print(title.json);
    print(title.fontFamily);
    print(title.fontBase64);
    print(title.texts);

    title.texts.addAll(["THIS IS VIMON V-LOG", "This is subtitle"]);

    _lottieTestWidget.setData(title);
    _lottieTestWidget.run();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("VM SDK TEST"),
      ),
      resizeToAvoidBottomInset: false,
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _lottieTestWidget,
            ],
          ),
        ),
      ),
      backgroundColor: Colors.grey,
      floatingActionButton: FloatingActionButton(
          onPressed: _run, tooltip: 'Run', child: const Icon(Icons.play_arrow)),
    );
  }
}
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/vm_sdk/impl/vm_text_widget.dart';
import 'vm_sdk/impl/global_helper.dart';
import 'vm_sdk/impl/resource_manager.dart';
import 'vm_sdk/impl/ffmpeg_manager.dart';
import 'vm_sdk/types/types.dart';

class TestWidget extends StatefulWidget {
  const TestWidget({Key? key}) : super(key: key);

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  final VMTextWidget _vmTextWidget = VMTextWidget();

  List<String> imageList = [];
  String _currentText = "";

  bool _isInitialized = false;

  final FFMpegManager _ffmpegManager = FFMpegManager();

  void _run() async {
    try {
      if (!_isInitialized) {
        await ResourceManager.getInstance().loadResourceMap();
        _isInitialized = true;
      }

      setState(() {
        imageList = [];
      });

      final List<TextData> allTexts = ResourceManager.getInstance().getTextDataList(autoEditOnly: false, lineCount: 2);
      allTexts.sort((a, b) {
        final aValue = "${a.group}_${a.key}";
        final bValue = "${b.group}_${b.key}";

        return aValue.compareTo(bValue);
      });

      Map filteredText = {
        "Title_SW046": true,
        "Title_SW047": true,
        "Title_SW048": true,
        "Title_SW049": true,
        "Title_SW050": true,
        "Title_SW051": true,
        "Title_SW052": true,
        "Title_SW053": true,

        "Title_SW054": true,
        "Title_SW055": true,
        "Title_SW056": true,
        "Title_SW057": true,
        "Title_SW058": true,
        "Title_SW059": true,
        "Title_SW060": true,
        "Title_SW061": true,
        "Title_SW062": true,
        "Title_SW063": true,
        "Title_SW064": true,
        "Title_SW065": true,
        "Title_SW066": true,
      };

      for (int i = 0; i < allTexts.length; i++) {
        DateTime now = DateTime.now();

        final TextData currentTextData = allTexts[i];
        final String currentText = currentTextData.key;
        if (!filteredText.containsKey(currentText)) continue;

        print('text is $currentText');
        print('_currentIndex is $i / ${allTexts.length}');

        await _vmTextWidget.loadText(currentText, initTexts: ["THIS IS TITLE", "THIS IS SUBTITLE"], language: "ko");
        // await _vmTextWidget.loadText(currentText, initTexts: ["첫번째줄 테스트", "두번째줄 테스트"], language: "ko");
        // await _vmTextWidget.loadText(currentText, initTexts: ["パスワードを再確認してください。", "パスワードを再確認してください。"], language: "ja");
        
        await _vmTextWidget.extractAllSequence((progress) => {});

        final String appDirPath = await getAppDirectoryPath();
        final String webmPath = "$appDirPath/webm";
        Directory dir = Directory(webmPath);
        await dir.create(recursive: true);

        String? preview = _vmTextWidget.previewImagePath;

        int width = (_vmTextWidget.width / 2).floor();
        int height = (_vmTextWidget.height / 2).floor();

        width -= width % 2;
        height -= height % 2;

        await _ffmpegManager.execute([
          "-framerate",
          _vmTextWidget.frameRate.toString(),
          "-i",
          "${_vmTextWidget.allSequencesPath!}/%d.png",
          "-vf",
          "scale=$width:$height",

          "-c:v",
          "libvpx-vp9",
          "-pix_fmt",
          "yuva420p",
          "$webmPath/$currentText.webm",
          // "$webmPath/${currentTextData.group}_$currentText.webm",

          // "-c:v",
          // "libx264",
          // "-preset",
          // "ultrafast",
          // "-pix_fmt",
          // "yuv420p",
          // "$webmPath/$currentText.mp4",
          // // "$webmPath/${currentTextData.group}_$currentText.mp4",

          "-y"
        ], (p0) => null);

        File thumbnailFile = File(_vmTextWidget.previewImagePath!);
        await thumbnailFile.copy("$webmPath/$currentText.png");
        // await thumbnailFile.copy("$webmPath/${currentTextData.group}_$currentText.png");

        print(webmPath);
        print(currentText);

        await Future.delayed(const Duration(milliseconds: 1000));

        setState(() {
          _currentText = currentText;
          if (preview != null) imageList = [preview];
        });

        print("");
      }

      print("done!");
    } catch (e) {
      print(e);
    }
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
              Text(_currentText),
              ListView.builder(
                itemCount: imageList.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  return Image.file(
                    File(imageList[index]),
                    width: MediaQuery.of(this.context).size.width,
                    fit: BoxFit.fitWidth,
                  );
                },
              ),
              _vmTextWidget,
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

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
        // "Title_ES005": true,
        // "Title_ES006": true,
        // "Title_ES007": true,
        // "Title_JH014": true,
        // "Title_JH015": true,
        // "Title_JH016": true,
        // "Title_SW042": true,
        // "Title_SW043": true,
        // "Title_SW044": true,
        // "Title_SW045": true,
        // "Title_YE001": true,
        // "Title_YE002": true,
        // "Title_YE003": true,
      };

      for (int i = 0; i < allTexts.length; i++) {
        DateTime now = DateTime.now();

        final TextData currentTextData = allTexts[i];
        final String currentText = currentTextData.key;
        // if (!filteredText.containsKey(currentText)) continue;

        print('text is $currentText');
        print('_currentIndex is $i / ${allTexts.length}');

        // await _vmTextWidget.loadText(currentText, initTexts: ["첫번째줄 테스트", "두번째줄 테스트"]);
        // await _vmTextWidget.loadText(currentText, initTexts: ["THIS IS TITLE"], language: "en");
        // await _vmTextWidget.loadText(currentText, initTexts: ["パスワードを再確認してください。", "パスワードを再確認してください。"]);
        // await _vmTextWidget.loadText(currentText, initTexts: ["Sẵn sàng tiệc chưa?", "Sẵn sàng tiệc chưa?"]);
        // await _vmTextWidget.loadText(currentText, initTexts: ["วิดีโอที่คุณสร้างกำลังรอคุณอยู่", "วิดีโอที่คุณสร้างกำลังรอคุณอยู่"]);

        await _vmTextWidget.loadText(currentText, initTexts: ["THIS IS TITLE", "THIS IS SUBTITLE"], language: "ko");
        // await _vmTextWidget.loadText(currentText, initTexts: ["첫번째줄 테스트", "두번째줄 테스트"], language: "ko");
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
          "$webmPath/${currentTextData.group}_$currentText.webm",

          // "-c:v",
          // "libx264",
          // "-preset",
          // "ultrafast",
          // "-pix_fmt",
          // "yuv420p",
          // "$webmPath/${currentTextData.group}_$currentText.mp4",

          "-y"
        ], (p0) => null);

        File thumbnailFile = File(_vmTextWidget.previewImagePath!);
        await thumbnailFile.copy("$webmPath/${currentTextData.group}_$currentText.png");

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

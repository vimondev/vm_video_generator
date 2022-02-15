import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:myapp/vm_sdk/impl/lottie_text_widget.dart';
import 'package:myapp/vm_sdk/impl/title_helper.dart';
import 'vm_sdk/vm_sdk.dart';
import 'vm_sdk/types/types.dart';
import 'vm_sdk/impl/global_helper.dart';
import 'dart:convert';
import 'vm_sdk/impl/lottie_widget.dart';
import 'package:flutter/services.dart' show rootBundle;

class TestWidget extends StatefulWidget {
  TestWidget({Key? key}) : super(key: key);

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  // final VMSDKWidget _vmsdkWidget = VMSDKWidget();
  late LottieTextWidget _lottieTextWidget = LottieTextWidget();

  List<String> imageList = [];

  void _run() async {
    print('This is _run method of TestWidget');
    final TitleData title = (await loadTitleData(ETitleType.title04))!;
    print('title is ');

    print(title.json);
    print(title.fontFamily);
    print(title.fontBase64);
    print(title.texts);

    title.texts.addAll(["THIS IS VIMON V-LOG", "This is subtitle"]);

    _lottieTextWidget.setData(title);

    String? preview = await _lottieTextWidget.extractPreview();

    preview = await _lottieTextWidget.setTextValue("#TEXT1", "이 앱은 VIIV입니다.");

    preview = await _lottieTextWidget.setTextValue("#TEXT2", "가나다라마바사아자차카타파하0123456789");

    // setState(() {
    //   if (preview != null) imageList = [ preview ];
    // });
    // print('TestWidget result preview is : $preview');

    List<String>? sequences = await _lottieTextWidget.extractAllSequence();

    print("test.dart - sequences : ");
    if (sequences != null) {
      for (int i = 0; i < sequences.length; i++) {
        print(sequences[i]);
      }
    }

    setState(() {
      if (sequences != null) imageList = sequences;
    });




    // if (!_vmsdkWidget.isInitialized) {
    //   await _vmsdkWidget.initialize();
    // }
    //
    // final String assetPath = "_test/set01";
    // final filelist =
    //     json.decode(await loadResourceString("$assetPath/test.json"));
    //
    // final List<MediaData> mediaList = <MediaData>[];
    //
    // for (final Map file in filelist) {
    //   final String filename = file["filename"];
    //   final EMediaType type =
    //       file["type"] == "image" ? EMediaType.image : EMediaType.video;
    //   final int width = file["width"];
    //   final int height = file["height"];
    //   DateTime createDate = DateTime.parse(file["createDate"]);
    //   String gpsString = file["gpsString"];
    //
    //   double? duration;
    //   if (file.containsKey("duration")) duration = file["duration"];
    //
    //   final mediaFile = await copyAssetToLocalDirectory("$assetPath/$filename");
    //   mediaList.add(MediaData(mediaFile.path, type, width, height, duration,
    //       createDate, gpsString, null));
    // }
    //
    // final String? videoPath = await _vmsdkWidget.generateVideo(
    //     mediaList,
    //     EMusicStyle.styleB,
    //     // ["THIS IS", "VIMON V-LOG"],
    //     ["THIS IS VIMON V-LOG"],
    //     (status, progress, estimatedTime) {});
    //
    // if (videoPath != null) {
    //   await GallerySaver.saveVideo(videoPath);
    // }
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
              ListView.builder(
                itemCount: imageList.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    child: Image.file(
                      File(imageList[index]),
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                  );
                },
              ),
              _lottieTextWidget,
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

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

class TestWidget extends StatelessWidget {
  TestWidget({Key? key}) : super(key: key);


  // final VMSDKWidget _vmsdkWidget = VMSDKWidget();
  final LottieTextWidget _lottieTextWidget = LottieTextWidget();

  void _run() async {

    print('This is _run method of TestWidget');
    final TitleData title = (await loadTitleData(ETitleType.title04))!;
    print('title is ');

    print(title.json);
    print(title.fontFamily);
    print(title.fontBase64);
    print(title.texts);

    title.texts.addAll(["THIS IS VIMON V-LOG", "This is subtitle"]);
    ExportedTitlePNGSequenceData exportedTitleData = await _lottieTextWidget.exportTitlePNGSequence(title);

    print('TestWidget - ExportedTitlePNGSequenceData : ');
    print(exportedTitleData.folderPath);
    print(exportedTitleData.width);
    print(exportedTitleData.height);
    print(exportedTitleData.frameRate);

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
      body: _lottieTextWidget,
      backgroundColor: Colors.grey,
      floatingActionButton: FloatingActionButton(
          onPressed: _run, tooltip: 'Run', child: const Icon(Icons.play_arrow)),
    );
  }
}

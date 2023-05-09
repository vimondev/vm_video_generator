import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';

import 'vm_sdk/vm_sdk.dart';
import 'vm_sdk/types/types.dart';
import 'vm_sdk/impl/global_helper.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TestWidget extends StatelessWidget {
  TestWidget({Key? key}) : super(key: key);

  final VMSDKWidget _vmsdkWidget = VMSDKWidget();

  void _run() async {
    if (!_vmsdkWidget.isInitialized) {
      await _vmsdkWidget.initialize();
    }

    String testSetName = "oriented";

    final filelist = json.decode(await rootBundle.loadString("assets/_test/mediajson-joined/$testSetName.json"));

    List<MediaData> mediaList = [];

    for (final Map file in filelist) {
      String filename = file["filename"];
      final EMediaType type = file["type"] == "image" ? EMediaType.image : EMediaType.video;
      final int width = file["width"];
      final int height = file["height"];
      final int orientation = file["orientation"] ?? 0;

      // if (type != EMediaType.video) continue;

      double? duration;
      DateTime createDate = DateTime.parse(file["createDate"]);
      String gpsString = file["gpsString"];
      String mlkitDetected = file["mlkitDetected"];

      if (file.containsKey("duration")) duration = file["duration"] * 1.0;

      // if (filename == "20211113_195754.mp4") {
      //   filename = "20211113_195754_no_audio.mp4";
      // }

      final writedFile = await copyAssetToLocalDirectory("_test/$testSetName/$filename");
      mediaList.add(
          MediaData(writedFile.path, type, width, height, orientation, duration, createDate, gpsString, mlkitDetected));

      if (mediaList.length >= 30) break;
    }

    for (int i = 0; i < EMusicStyle.values.length; i++) {
      EMusicStyle style = EMusicStyle.energetic; //EMusicStyle.values[i % EMusicStyle.values.length];

      VideoGeneratedResult result = await _vmsdkWidget.generateVideo(
          mediaList,
          style,
          false,
          // ["THIS IS TITLE", "THIS IS SUBTITLE"], "ko", (status, progress) {
          // ["THIS IS TITLE 😀", "🕹 이모지 테스트 ✅"], "ko", (status, progress) {
          // ["THIS IS TITLE", "☻ ♥ ♦ ♣ ♠ 특수문자 테스트"], "ko", (status, progress) {
          ["THIS IS TITLE 😀", "🕹 ☻ ♥ ♦ ♣ ♠ 특수문자 테스트 ✅"],
          "ko", (status, progress) {
        //["THIS IS TITLE", "☻ ♥ ♦ ♣ ♠ 특수문자 테스트"
        print(status);
        print(progress);
      });

      await GallerySaver.saveVideo(result.generatedVideoPath);
      break;
    }

    // VideoGeneratedResult result = await _vmsdkWidget.generateVideo(
    //     mediaList,
    //     EMusicStyle.ambient,
    //     false,
    //     ["THIS IS TITLE 😀", "🕹 ☻ ♥ ♦ ♣ ♠ 특수문자 테스트 ✅"],
    //     "ko", (status, progress) {
    //   print(status);
    //   print(progress);
    // }, isExportTitle: false, isRunFFmpeg: false);
    // print("totalRenderTime : ${result.renderTimeSec}s");
    // print("");

    // result = await _vmsdkWidget.generateVideoFromJSON(result.json,
    //     (status, progress) {
    //   print(status);
    //   print(progress);
    // });

    // await GallerySaver.saveVideo(result.generatedVideoPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("VM SDK TEST"),
      ),
      body: _vmsdkWidget,
      floatingActionButton: FloatingActionButton(onPressed: _run, tooltip: 'Run', child: const Icon(Icons.play_arrow)),
    );
  }
}

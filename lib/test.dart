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

    final filelist = json.decode(
        await rootBundle.loadString("assets/_test/mediajson-joined/monaco2.json"));
        // await rootBundle.loadString("assets/_test/mediajson-joined/monaco2.json"));

    List<MediaData> mediaList = [];

    for (final Map file in filelist) {
      final String filename = file["filename"];
      final EMediaType type =
          file["type"] == "image" ? EMediaType.image : EMediaType.video;
      final int width = file["width"];
      final int height = file["height"];

      if (type != EMediaType.video) continue;

      double? duration;
      DateTime createDate = DateTime.parse(file["createDate"]);
      String gpsString = file["gpsString"];
      String mlkitDetected = file["mlkitDetected"];

      if (file.containsKey("duration")) duration = file["duration"] * 1.0;

      final writedFile =
          await copyAssetToLocalDirectory("_test/monaco2/$filename");
      mediaList.add(MediaData(writedFile.path, type, width, height, duration,
          createDate, gpsString, mlkitDetected));
    }

    for (int i=0; i<EMusicStyle.values.length; i++) {
      EMusicStyle style = EMusicStyle.values[i];

      VideoGeneratedResult result =
          await _vmsdkWidget.generateVideo(mediaList, style, false,
              // ["THIS IS", "VIMON V-LOG"],
              ["$style"], "ko", (status, progress) {
        print(status);
        print(progress);
      });

      await GallerySaver.saveVideo(result.generatedVideoPath);
    }

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
      floatingActionButton: FloatingActionButton(
          onPressed: _run, tooltip: 'Run', child: const Icon(Icons.play_arrow)),
    );
  }
}

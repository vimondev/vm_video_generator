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

    final String assetPath = "_test/set01";
    final filelist =
        json.decode(await loadResourceString("$assetPath/test.json"));

    final List<MediaData> mediaList = <MediaData>[];

    for (final Map file in filelist) {
      final String filename = file["filename"];
      final EMediaType type =
          file["type"] == "image" ? EMediaType.image : EMediaType.video;
      final int width = file["width"];
      final int height = file["height"];
      DateTime createDate = DateTime.parse(file["createDate"]);
      String gpsString = file["gpsString"];

      double? duration;
      if (file.containsKey("duration")) duration = file["duration"];

      final mediaFile = await copyAssetToLocalDirectory("$assetPath/$filename");
      mediaList.add(MediaData(mediaFile.path, type, width, height, duration,
          createDate, gpsString, null));
    }

    final String? videoPath = await _vmsdkWidget.generateVideo(
        mediaList,
        EMusicStyle.styleB,
        // ["THIS IS", "VIMON V-LOG"],
        ["THIS IS VIMON V-LOG"],
        (status, progress, estimatedTime) {});

    if (videoPath != null) {
      await GallerySaver.saveVideo(videoPath);
    }
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

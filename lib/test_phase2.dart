import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';

import 'package:path/path.dart';
import 'vm_sdk/types/global.dart';
import 'vm_sdk/vm_sdk.dart';
import 'vm_sdk/impl/global_helper.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TestWidget extends StatelessWidget {
  TestWidget({Key? key}) : super(key: key);

  late final VMSDKController _controller;

  void _run() async {
    if (!_controller.isInitialized) {
      await _controller.initialize();
    }

    final exportedJSON = json.decode(await rootBundle.loadString("assets/phase2-exported-set1.json"));

    List slides = exportedJSON["timeline"]["slides"];
    List bgm = exportedJSON["timeline"]["bgm"];

    for (int i = 0; i < slides.length; i++) {
      final String filename = basename(slides[i]["localPath"]);

      final writedFile = await copyAssetToLocalDirectory("_test/set1/$filename");
      slides[i]["localPath"] = writedFile.path;
    }

    for (int i = 0; i < bgm.length; i++) {
      final String filename = basename(bgm[i]["sourcePath"]);

      final writedFile = await copyAssetToLocalDirectory("raw/audio/$filename");
      bgm[i]["sourcePath"] = writedFile.path;
    }

    final String encodedJSON = json.encode(exportedJSON);
    final VideoGeneratedResult? result = await _controller.generateVideoFromJSON(encodedJSON, "en", (status, progress) {
      print(status);
      print(progress);
    });

    if (result != null) {
      await GallerySaver.saveVideo(result.generatedVideoPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("VM SDK TEST"),
      ),
      body: VMSDKWidget(
          onWebViewControllerCreated: (controller) {},
          onControllerCreated: (controller) {
            _controller = controller;
          }),
      floatingActionButton: FloatingActionButton(onPressed: _run, tooltip: 'Run', child: const Icon(Icons.play_arrow)),
    );
  }
}

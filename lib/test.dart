import 'vm_sdk/vm_sdk.dart';
import 'vm_sdk/types/types.dart';
import 'vm_sdk/impl/global_helper.dart';
import 'dart:convert';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:flutter/services.dart' show rootBundle;

VideoGenerator videoGenerator = VideoGenerator();
void testMethod() async {
  const String testAssetPath = "assets/_test";
  final filelist =
      json.decode(await rootBundle.loadString("$testAssetPath/test.json"));

  final List<MediaData> mediaList = <MediaData>[];

  for (final Map file in filelist) {
    final String filename = file["filename"];
    final EMediaType type =
        file["type"] == "image" ? EMediaType.image : EMediaType.video;
    final int width = file["width"];
    final int height = file["height"];

    // if (type == EMediaType.image) continue;

    double? duration;
    DateTime? createDate;
    String? gpsString;

    if (file.containsKey("duration")) duration = file["duration"];
    if (file.containsKey("createDate")) {
      createDate = DateTime.parse(file["createDate"]);
    }
    if (file.containsKey("gpsString")) gpsString = file["gpsString"];

    final writedFile =
        await copyAssetToLocalDirectory("_test/$filename", filename);
    mediaList.add(MediaData(
        writedFile.path, type, width, height, duration, createDate, gpsString));
  }

  final resultVideoPath = await videoGenerator.autoGenerateVideo(
      mediaList, (status, progress) => {print(status), print(progress)});

  if (resultVideoPath != null) {
    final isSuccess = await GallerySaver.saveVideo(resultVideoPath);
    print(isSuccess);
  }
}

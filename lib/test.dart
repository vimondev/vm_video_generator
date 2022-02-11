import 'vm_sdk/vm_sdk.dart';
import 'vm_sdk/types/types.dart';
import 'vm_sdk/impl/global_helper.dart';
import 'dart:convert';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:flutter/services.dart' show rootBundle;

VideoGenerator videoGenerator = VideoGenerator();

void testMethod() async {
  if (!videoGenerator.isInitialized) {
    await videoGenerator.initialize();
  }

  final filelist = json.decode(await rootBundle
      .loadString("assets/_test/mediajson-joined/monaco2.json"));

  final List<MediaData> mediaList = <MediaData>[];

  for (final Map file in filelist) {
    final String filename = file["filename"];
    final EMediaType type =
        file["type"] == "image" ? EMediaType.image : EMediaType.video;
    final int width = file["width"];
    final int height = file["height"];

    // if (type == EMediaType.video) continue;

    double? duration;
    DateTime createDate = DateTime.parse(file["createDate"]);
    String gpsString = file["gpsString"];
    String mlkitDetected = file["mlkitDetected"];

    if (file.containsKey("duration")) duration = file["duration"] * 1.0;

    mediaList.add(MediaData(filename, type, width, height, duration, createDate,
        gpsString, mlkitDetected));
    if (file.containsKey("duration")) duration = file["duration"];

    // final writedFile =
    //     await copyAssetToLocalDirectory("$testAssetPath/$filename");
    mediaList.add(MediaData(
        filename, type, width, height, duration, createDate, gpsString, null));
  }

  final autoSelected = videoGenerator.autoSelectMedia(mediaList);

  // final resultVideoPath = await videoGenerator.generateVideo(
  //     mediaList,
  //     EMusicStyle.styleB,
  //     (status, progress, estimatedTime) =>
  //         {print(status), print(progress), print(estimatedTime)});

  // if (resultVideoPath != null) {
  //   final isSuccess = await GallerySaver.saveVideo(resultVideoPath);
  //   print(isSuccess);
  // }

  print("");
}

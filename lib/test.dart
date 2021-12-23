import 'vm_sdk/vm_sdk.dart';
import 'vm_sdk/types/types.dart';
import 'vm_sdk/impl/global_helper.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

VideoGenerator videoGenerator = VideoGenerator();

void testMethod() async {
  if (!videoGenerator.isInitialized) {
    await videoGenerator.initialize();
  }

  final filelist =
      json.decode(await rootBundle.loadString("assets/_test/exiftestset.json"));

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
    // if (file.containsKey("duration")) duration = file["duration"];

    mediaList.add(MediaData(
        filename, type, width, height, duration, createDate, gpsString));
  }

  final autoSelected = videoGenerator.autoSelectMedia(mediaList);

  print("");
}

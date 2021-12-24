import 'package:path/path.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

import 'vm_sdk/types/types.dart';
import 'vm_sdk/impl/global_helper.dart';
import 'vm_sdk/impl/ml_kit_helper.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

FlutterFFprobe ffprobe = FlutterFFprobe();

void testMethod() async {
  const String testAssetPath = "_test/set02";
  final filelist = [];

  final manifestContent = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = json.decode(manifestContent);

  for (final key in manifestMap.keys.toList()) {
    if (key.contains(testAssetPath) && !key.contains(".DS_")) {
      filelist.add(basename(key));
    }
  }

  List<MediaData> testMediaList = [];
  for (final String filename in filelist) {
    final writedFile =
        await copyAssetToLocalDirectory("$testAssetPath/$filename");

    final mediaInfo = await ffprobe.getMediaInformation(writedFile.path);
    final streams = mediaInfo.getStreams()![0].getAllProperties();

    int width = streams["width"];
    int height = streams["height"];
    EMediaType type = EMediaType.image;

    final extname = extension(filename);

    switch (extname.toLowerCase()) {
      case ".mp4":
      case ".mov":
        type = EMediaType.video;
        break;

      case ".jpg":
      case ".jpeg":
      case ".png":
      default:
        break;
    }
    testMediaList
        .add(MediaData(writedFile.path, type, width, height, null, null, null));
  }

  List<double> durationList = [];
  List<double> lengthList = [];
  List<String?> results = [];
  for (final media in testMediaList) {
    DateTime now = DateTime.now();
    final result = await extractMLKitData(media);
    durationList.add(DateTime.now().difference(now).inMilliseconds / 1000);
    results.add(result);

    if (result != null) {
      lengthList.add(result.length / 1024);
    }
  }
  print("");
}

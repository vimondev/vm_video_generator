import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:path/path.dart';

import 'vm_sdk/types/types.dart';
import 'vm_sdk/impl/global_helper.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'vm_sdk/impl/ml_kit_helper.dart';

void testMethod() async {
  const String testAssetPath = "_test/set1";
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

    final mediaInfo = (await FFprobeKit.getMediaInformation(writedFile.path)).getMediaInformation();
    final streams = mediaInfo!.getStreams()[0].getAllProperties();

    int width = streams!["width"];
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
    testMediaList.add(MediaData(
        writedFile.path, type, width, height, 0, null, DateTime.now(), "", null));
  }

  List<double> durationList = [];
  List<double> lengthList = [];
  List<String?> results = [];
  for (final media in testMediaList) {
    DateTime now = DateTime.now();
    final result = await extractData(media);
    durationList.add(DateTime.now().difference(now).inMilliseconds / 1000);
    results.add(result);

    if (result != null) {
      lengthList.add(result.length / 1024);
    }
  }
  print("");
}

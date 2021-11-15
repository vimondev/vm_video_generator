import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<String> getAppDirectoryPath() async {
  final appDirectory = await getApplicationDocumentsDirectory();
  return appDirectory.path;
}

Future<File> copyAssetToLocalDirectory(
    String assetPath, String filename) async {
  final String appDirPath = await getAppDirectoryPath();

  final ByteData byteData = await rootBundle.load("assets/$assetPath");
  return await File("$appDirPath/$filename").writeAsBytes(byteData.buffer
      .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
}

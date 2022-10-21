import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<String> getAppDirectoryPath() async {
  final appDirectory = await getApplicationDocumentsDirectory();
  return appDirectory.path;
}

Future<String> loadResourceString(String assetPath) async {
  return await rootBundle.loadString("packages/myapp/$assetPath");
}

Future<ByteData> loadResourceByteData(String assetPath) async {
  return await rootBundle.load("packages/myapp/$assetPath");
}

Future<String> loadResourceBase64(String assetPath) async {
  final ByteData byteData = await rootBundle.load("packages/myapp/$assetPath");
  return base64.encode(byteData.buffer
      .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
}

Future<void> writeFileFromBase64(String path, String base64Str) async {
  Uint8List bytes = base64.decode(base64Str);

  File file = File(path);
  await file.writeAsBytes(bytes);
}

Future<File> copyAssetToLocalDirectory(String assetPath) async {
  final String filename = basename(assetPath);
  final String appDirPath = await getAppDirectoryPath();

  final ByteData byteData = await rootBundle.load("packages/myapp/$assetPath");
  return await File("$appDirPath/$filename").writeAsBytes(byteData.buffer
      .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
}

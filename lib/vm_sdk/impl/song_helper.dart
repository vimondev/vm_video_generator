import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'http_helper.dart';

import 'global_helper.dart';

Future<Map<String, int>> getHashtags() async {
  final Response response = await httpGet("/songs?type=all", null);
  final result = jsonDecode(response.body);

  final Map<String, int> resultMap = {};

  List tags = result["results"];
  for (int i=0; i<tags.length; i++) {
    final Map tag = tags[i];
    
    String name = tag["name"];
    int id = tag["id"];

    resultMap[name] = id;
  }

  return resultMap;
}

Future<List> getSongs(int id) async {
  final Response response = await httpGet("/songs?hashtags=$id", null);
  final result = jsonDecode(response.body);

  return result["results"];
}

Future<File> downloadSong(String filename, String url) async {
  final Response response = await httpGet(url, null);
  if (response.contentLength == 0) {
    throw Exception("ERR_MUSIC_DOWNLOAD_FAILED");
  }

  final appDir = await getAppDirectoryPath();
  File file = File("$appDir/$filename");
  await file.writeAsBytes(response.bodyBytes);

  return file;
}
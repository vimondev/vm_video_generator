import 'dart:convert';
import 'dart:io';

import '../types/types.dart';

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

Future<List<SongFetchModel>> fetchSongs(int hashtagId) async {
  final Response response = await httpGet("/songs?hashtags=$hashtagId&pageSize=99999", null);
  final result = jsonDecode(response.body);

  final List list = result["results"];
  return list.map<SongFetchModel>((map) => SongFetchModel.fromJson(map)).toList();
}

Future<List<SongFetchModel>> fetchAllSongs() async {
  final Response response = await httpGet("/songs?pageSize=99999&responseMode=light", null);
  final result = jsonDecode(response.body);

  final List list = result["results"];
  return list.map<SongFetchModel>((map) => SongFetchModel.fromJson(map)).toList();
}

Future<List<TransitionFetchModel>> fetchTransitions() async {
  final Response response = await httpGet("/transitions?pageSize=99999", null);
  final result = jsonDecode(response.body);

  final List list = result["results"];
  return list.map<TransitionFetchModel>((map) => TransitionFetchModel.fromJson(map)).toList();
}

Future<List<FrameFetchModel>> fetchFrames() async {
  final Response response = await httpGet("/frames?pageSize=99999", null);
  final result = jsonDecode(response.body);

  final List list = result["results"];
  return list.map<FrameFetchModel>((map) => FrameFetchModel.fromJson(map)).toList();
}

Future<List<StickerFetchModel>> fetchStickers() async {
  final Response response = await httpGet("/stickers?pageSize=99999", null);
  final result = jsonDecode(response.body);

  final List list = result["results"];
  return list.map<StickerFetchModel>((map) => StickerFetchModel.fromJson(map)).toList();
}

Future<DownloadResourceResponse> downloadResource(String filename, String url) async {
  final Response response = await httpGet(url, null);
  if (response.contentLength == 0) {
    throw Exception("ERR_RESOURCE_DOWNLOAD_FAILED");
  }

  final appDir = await getAppDirectoryPath();
  File file = File("$appDir/$filename");
  await file.writeAsBytes(response.bodyBytes);

  print(file.path);

  return DownloadResourceResponse(filename, file);
}

Future<DownloadFontResponse> downloadFont(String fontFamily) async {
  final Response response = await httpGet("/fonts?fontFamily=$fontFamily&pageSize=99999", null);
  final result = jsonDecode(response.body);

  final List list = result["results"];
  if (list.isEmpty) throw Exception("ERR_FONT_NOT_FOUND");

  for (int i=0; i<list.length; i++) {
    final font = FontFetchModel.fromJson(list[i]);
    if (font.fontFamily.compareTo(fontFamily) == 0) {
      DownloadResourceResponse res = await downloadResource(font.source!.name, font.source!.url);
      return DownloadFontResponse(res.filename, res.file, base64.encode(await res.file.readAsBytes()));
    }
  }

  final source = FontFetchModel.fromJson(list[0]).source!;
  DownloadResourceResponse res = await downloadResource(source.name, source.url);

  return DownloadFontResponse(res.filename, res.file, base64.encode(await res.file.readAsBytes()));
}
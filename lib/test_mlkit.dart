import 'package:file_saver/file_saver.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:myapp/vm_sdk/impl/ffmpeg_manager.dart';
import 'package:path/path.dart';

import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';

import 'vm_sdk/types/types.dart';
import 'vm_sdk/impl/global_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_ml_kit/google_ml_kit.dart';

final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();
final ImageLabeler imageLabeler = GoogleMlKit.vision.imageLabeler();
FFMpegManager ffMpegManager = FFMpegManager();
FlutterFFprobe ffprobe = FlutterFFprobe();

class TestMedia {
  String filename;
  EMediaType type;
  int width;
  int height;
  List<String> frames;

  TestMedia(this.filename, this.type, this.width, this.height, this.frames);
}

Map convertFaceToMap(Face face) {
  final Map map = {};

  map["boundingBox"] = <String, dynamic>{
    'top': face.boundingBox.top,
    'bottom': face.boundingBox.bottom,
    'left': face.boundingBox.left,
    'right': face.boundingBox.right
  };
  map["headEulerAngleY"] = face.headEulerAngleY;
  map["headEulerAngleZ"] = face.headEulerAngleZ;
  map["leftEyeOpenProbability"] = face.leftEyeOpenProbability;
  map["rightEyeOpenProbability"] = face.rightEyeOpenProbability;
  map["smilingProbability"] = face.smilingProbability;
  map["trackingId"] = face.trackingId;

  return map;
}

Map convertImageLabelToMap(ImageLabel label) {
  final Map map = {};

  map["confidence"] = label.confidence;
  map["index"] = label.index;
  map["label"] = label.label;

  return map;
}

Future<void> sleep() async {
  return Future.delayed(const Duration(milliseconds: 100));
}

int currentDetectCount = 0;
Future<Map> detectObjects(String path) async {
  while (currentDetectCount >= 100) {
    await sleep();
  }
  currentDetectCount++;

  List<Map> faceList = [];
  List<Map> labelList = [];
  try {
    final InputImage inputImage = InputImage.fromFilePath(path);

    final detectedFaceList = await faceDetector.processImage(inputImage);
    for (final face in detectedFaceList) {
      faceList.add(convertFaceToMap(face));
    }

    final detectedLabelList = await imageLabeler.processImage(inputImage);
    for (final label in detectedLabelList) {
      labelList.add(convertImageLabelToMap(label));
    }
  } catch (e) {}

  currentDetectCount--;
  return {'faceList': faceList, 'labelList': labelList};
}

Future<Map> runDetect(TestMedia media) async {
  final Map map = {
    'filename': basename(media.filename),
    'width': media.width,
    'height': media.height
  };

  List<Future<Map>> futures = [];
  for (final frame in media.frames) {
    futures.add(detectObjects(frame));
  }
  map["detected"] = await Future.wait(futures);

  return map;
}

void testMethod() async {
  const String testAssetPath = "_mlkittest/set01";
  final filelist = [];

  final manifestContent = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = json.decode(manifestContent);

  for (final key in manifestMap.keys.toList()) {
    if (key.contains(testAssetPath) && !key.contains(".DS_")) {
      filelist.add(basename(key));
    }
  }

  final String baseFolder = await getAppDirectoryPath();
  final String resultFolder = "$baseFolder/results";
  final dir = Directory(resultFolder);
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
  await dir.create(recursive: true);

  List<File> fileObjList = <File>[];

  List<TestMedia> testMediaList = [];
  for (final String filename in filelist) {
    final writedFile =
        await copyAssetToLocalDirectory("$testAssetPath/$filename");
    fileObjList.add(writedFile);

    final mediaInfo = await ffprobe.getMediaInformation(writedFile.path);
    final streams = mediaInfo.getStreams()![0].getAllProperties();

    int width = streams["width"];
    int height = streams["height"];
    EMediaType type = EMediaType.image;
    List<String> frames = [];

    int scaledWidth = -1;
    int scaledHeight = -1;

    if (width > height) {
      scaledWidth = 480;
      scaledHeight = (height * (scaledWidth / width)).floor();
      if (scaledHeight % 2 == 1) scaledHeight += 1;
    } else {
      scaledHeight = 480;
      scaledWidth = (width * (scaledHeight / height)).floor();
      if (scaledWidth % 2 == 1) scaledWidth += 1;
    }

    final extname = extension(filename);
    final index = filename.indexOf(extname);

    final folderName = "$resultFolder/${filename.substring(0, index)}";
    final dir = Directory(folderName);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    switch (extname.toLowerCase()) {
      case ".mp4":
      case ".mov":
        {
          if (await ffMpegManager.execute([
            "-i",
            writedFile.path,
            "-filter_complex",
            "fps=4,scale=$scaledWidth:$scaledHeight,setdar=dar=${scaledWidth / scaledHeight}",
            "$folderName/%d.jpg",
            "-y"
          ], (p0) => null)) {
            frames = [];
            await for (final entity in dir.list()) {
              frames.add(entity.path);
            }
          }
        }
        type = EMediaType.video;
        break;

      case ".jpg":
      case ".jpeg":
      case ".png":
      default:
        if (await ffMpegManager.execute([
          "-i",
          writedFile.path,
          "-filter_complex",
          "scale=$scaledWidth:$scaledHeight,setdar=dar=${scaledWidth / scaledHeight}",
          "$folderName/1.jpg",
          "-y"
        ], (p0) => null)) {
          frames = [];
          await for (final entity in dir.list()) {
            frames.add(entity.path);
          }
        }
        break;
    }
    testMediaList
        .add(TestMedia(filename, type, scaledWidth, scaledHeight, frames));
  }

  DateTime now = DateTime.now();
  List<Future<Map>> futures = <Future<Map>>[];

  for (final media in testMediaList) {
    futures.add(runDetect(media));
  }
  List<Map> results = await Future.wait(futures);
  await File("$resultFolder/result.json").writeAsString(json.encode(results));

  print(DateTime.now().difference(now).inMilliseconds);

  // final zipFile = File("$baseFolder/result.zip");
  // await ZipFile.createFromDirectory(
  //     sourceDir: dir, zipFile: zipFile, recurseSubDirs: true);

  // final fileSaveResult = await FileSaver.instance
  //     .saveFile("subin", await zipFile.readAsBytes(), "zip");

  // print(fileSaveResult);
}

import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:path/path.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../types/global.dart';
import 'ffmpeg_manager.dart';
import 'global_helper.dart';

final FaceDetector faceDetector = FaceDetector(options: FaceDetectorOptions());
final ImageLabeler imageLabeler = ImageLabeler(options: ImageLabelerOptions());
final FFMpegManager ffMpegManager = FFMpegManager();
const int convertFrame = 2;

Map convertFaceToMap(Face face) {
  final Map map = {};

  map["b"] = <String, dynamic>{
    "t": face.boundingBox.top.floor(),
    "b": face.boundingBox.bottom.floor(),
    "l": face.boundingBox.left.floor(),
    "r": face.boundingBox.right.floor()
  };
  if (face.headEulerAngleY != null) {
    map["ay"] = double.parse(face.headEulerAngleY!.toStringAsFixed(4));
  }
  if (face.headEulerAngleZ != null) {
    map["az"] = double.parse(face.headEulerAngleZ!.toStringAsFixed(4));
  }
  if (face.leftEyeOpenProbability != null) {
    map["lp"] = double.parse(face.leftEyeOpenProbability!.toStringAsFixed(4));
  }
  if (face.rightEyeOpenProbability != null) {
    map["rp"] = double.parse(face.rightEyeOpenProbability!.toStringAsFixed(4));
  }
  if (face.smilingProbability != null) {
    map["sp"] = double.parse(face.smilingProbability!.toStringAsFixed(4));
  }
  if (face.trackingId != null) {
    map["tid"] = int.parse(face.trackingId!.toString());
  }

  return map;
}

Map convertImageLabelToMap(ImageLabel label) {
  final Map map = {};

  map["c"] = double.parse(label.confidence.toStringAsFixed(4));
  map["id"] = label.index;

  return map;
}

Future<Map> detectObjects(String path) async {
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

  return {"f": faceList, "lb": labelList};
}

Future<List<Map>> runDetect(List<String> frames) async {
  List<Future<Map>> futures = [];
  for (final frame in frames) {
    futures.add(detectObjects(frame));
  }

  return await Future.wait(futures);
}

Future<String?> extractData(MediaData data) async {
  String? result;

  final String filename = basename(data.absolutePath);
  final String extname = extension(filename);
  final int index = filename.indexOf(extname);

  final String mlkitResultDir =
      "${await getAppDirectoryPath()}/mlkit/${filename.substring(0, index)}";
  final Directory dir = Directory(mlkitResultDir);

  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
  await dir.create(recursive: true);

  int scaledWidth = -1;
  int scaledHeight = -1;

  if (data.width > data.height) {
    scaledWidth = 480;
    scaledHeight = (data.height * (scaledWidth / data.width)).floor();
    if (scaledHeight % 2 == 1) scaledHeight += 1;
  } else {
    scaledHeight = 480;
    scaledWidth = (data.width * (scaledHeight / data.height)).floor();
    if (scaledWidth % 2 == 1) scaledWidth += 1;
  }

  double trimDuration = 10;
  if (data.type == EMediaType.video && data.duration != null) {
    trimDuration = min(data.duration!, 10);
  }

  await ffMpegManager.execute([
    "-i",
    data.absolutePath,
    "-filter_complex",
    "${data.type == EMediaType.video ? "trim=0:$trimDuration,setpts=PTS-STARTPTS,fps=$convertFrame," : ""}scale=$scaledWidth:$scaledHeight,setdar=dar=${scaledWidth / scaledHeight}",
    "$mlkitResultDir/${data.type == EMediaType.video ? "%d" : "1"}.jpg",
    "-y"
  ], (p0) => null);
  final List<String> frames = [];
  await for (final entity in dir.list()) {
    frames.add(entity.path);
  }

  result = json.encode({"fps": convertFrame, "r": await runDetect(frames)});
  await dir.delete(recursive: true);

  return result;
}

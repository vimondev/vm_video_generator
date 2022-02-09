import 'dart:convert';

class BoundingBox {
  int top;
  int bottom;
  int left;
  int right;

  BoundingBox(this.top, this.bottom, this.left, this.right);
}

class FaceDetected {
  BoundingBox boundingBox;
  double? headEulerAngleY;
  double? headEulerAngleZ;
  double? leftEyeOpenProbability;
  double? rightEyeOpenProbability;
  double? smilingProbability;
  int? trackingId;

  FaceDetected(this.boundingBox);
}

class ImageLabel {
  double confidence;
  int index;

  ImageLabel(this.confidence, this.index);
}

class DetectedFrameData {
  List<FaceDetected> faceList = [];
  List<ImageLabel> labelList = [];
}

class MLKitDetected {
  int fps = 0;
  List<DetectedFrameData> list = [];

  MLKitDetected.fromJson(String jsonString) {
    final Map map = json.decode(jsonString);
    fps = map["fps"];

    final List frameMapList = map["r"];
    for (int i = 0; i < frameMapList.length; i++) {
      final DetectedFrameData frameData = DetectedFrameData();
      final Map frameMap = frameMapList[i];

      final List faceMapList = frameMap["f"];
      final List labelMapList = frameMap["lb"];

      for (int j = 0; j < faceMapList.length; j++) {
        final Map faceMap = faceMapList[j];
        final Map boundingBoxMap = faceMap["b"];

        final FaceDetected faceDetected = FaceDetected(BoundingBox(
            boundingBoxMap["t"],
            boundingBoxMap["b"],
            boundingBoxMap["l"],
            boundingBoxMap["r"]));

        if (faceMap.containsKey("ay")) {
          faceDetected.headEulerAngleY = faceMap["ay"] * 1.0;
        }
        if (faceMap.containsKey("az")) {
          faceDetected.headEulerAngleZ = faceMap["az"] * 1.0;
        }
        if (faceMap.containsKey("lp")) {
          faceDetected.leftEyeOpenProbability = faceMap["lp"] * 1.0;
        }
        if (faceMap.containsKey("rp")) {
          faceDetected.rightEyeOpenProbability = faceMap["rp"] * 1.0;
        }
        if (faceMap.containsKey("sp")) {
          faceDetected.smilingProbability = faceMap["sp"] * 1.0;
        }
        if (faceMap.containsKey("tid")) {
          faceDetected.trackingId = faceMap["tid"];
        }

        frameData.faceList.add(faceDetected);
      }

      for (int j = 0; j < labelMapList.length; j++) {
        final Map labelMap = labelMapList[j];
        frameData.labelList
            .add(ImageLabel(labelMap["c"] * 1.0, labelMap["id"]));
      }

      list.add(frameData);
    }
  }
}

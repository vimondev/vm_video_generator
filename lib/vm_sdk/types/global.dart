import 'resource.dart';
import 'text.dart';
import 'dart:math';

enum ERatio { ratio916, ratio11, ratio169 }
enum EMediaType { image, video }
enum EMediaLabel {
  none,
  background,
  person,
  action,
  object,
  food,
  animal,
  others
}
enum EMusicSpeed {
  none,
  ss,
  s,
  m,
  mm,
  f,
  ff
}
enum EMusicStyle {
  none,
  calm,
  dreamy,
  ambient,
  beautiful,
  upbeat,
  hopeful,
  inspiring,
  fun,
  joyful,
  happy,
  cheerful,
  energetic
}

const Map<String, EMusicSpeed> musicSpeedMap = {
  "SS": EMusicSpeed.ss,
  "S": EMusicSpeed.s,
  "M": EMusicSpeed.m,
  "MM": EMusicSpeed.mm,
  "F": EMusicSpeed.f,
  "FF": EMusicSpeed.ff
};

const Map<String, EMusicStyle> musicStyleMap = {
  "Energetic": EMusicStyle.energetic,
  "Cheerful": EMusicStyle.cheerful,
  "Happy": EMusicStyle.happy,
  "Joyful": EMusicStyle.joyful,
  "Fun": EMusicStyle.fun,
  "Inspiring": EMusicStyle.inspiring,
  "Hopeful": EMusicStyle.hopeful,
  "Upbeat": EMusicStyle.upbeat,
  "Beautiful": EMusicStyle.beautiful,
  "Ambient": EMusicStyle.ambient,
  "Dreamy": EMusicStyle.dreamy,
  "Calm": EMusicStyle.calm,
};

enum EGenerateStatus { none, titleExport, encoding, finishing }

List<double> parseGPS(String gpsString) {
  final List<String> splitted1 = gpsString.split("\"")[0].split("' ");

  String temp = splitted1[0];
  double value1 = 0, value2 = 0, value3 = 0;

  final List<String> splitted2 = temp.split(" deg ");

  value1 = double.parse(splitted2[0]);
  value2 = double.parse(splitted2[1]);
  value3 = double.parse(splitted1[1]);

  return [value1, value2, value3];
}

class GPSData {
  List<double> latitude = <double>[];
  List<double> longitude = <double>[];

  GPSData();

  GPSData.fromString(String gpsString) {
    try {
      // gpsString ex) 33 deg 10' 28.70" N, 126 deg 16' 16.40" E
      List<String> splitted = gpsString.split(", ");

      latitude = parseGPS(splitted[0]);
      longitude = parseGPS(splitted[1]);
    } catch (e) {}
  }
}

class MediaData {
  String absolutePath; // File absolute path
  String? scaledPath;
  EMediaType type; // Media Tyle (image/video)
  int width; // Width
  int height; // Height
  int orientation;
  double? duration; // Duration (video only)
  DateTime createDate; // Exif Create Date
  String gpsString;
  GPSData gpsData = GPSData(); // Exif GPS Data (Parsed)
  String? mlkitDetected;

  MediaData(this.absolutePath, this.type, this.width, this.height, this.orientation,
      this.duration, this.createDate, this.gpsString, this.mlkitDetected) {
    gpsData = GPSData.fromString(gpsString);
  }
}

class EditedMedia {
  MediaData mediaData;
  String? thumbnailPath;
  EMediaLabel mediaLabel = EMediaLabel.none;
  bool isBoundary = false;

  double startTime = 0;
  double duration = 0;
  double xfadeDuration = 0;
  bool hFlip = false;
  bool vFlip = false;
  // int translateX = 0;
  // int translateY = 0;
  // double zoomX = 0;
  // double zoomY = 0;
  double scale = 1;
  double cropLeft = 0;
  double cropTop = 0;
  double cropRight = 1;
  double cropBottom = 1;
  double angle = 0;
  double volume = 1;
  double playbackSpeed = 1;
  Point<double>? rectBoundary;
  FrameData? frame;
  List<EditedStickerData> stickers = [];
  List<CanvasTextData> canvasTexts = [];
  TransitionData? transition;
  List<EditedTextData> editedTexts = [];
  double? rotate;

  EditedMedia(this.mediaData);
}

class Resolution {
  int width = 0;
  int height = 0;

  Resolution(this.width, this.height);
  Resolution.fromRatio(ERatio ratio) {
    switch (ratio) {
      case ERatio.ratio169:
        width = 1920;
        height = 1080;
        break;

      case ERatio.ratio916:
        width = 1080;
        height = 1920;
        break;

      case ERatio.ratio11:
      default:
        width = 1080;
        height = 1080;
        break;
    }
  }
}

class AllEditedData {
  List<EditedMedia> editedMediaList = [];
  List<MusicData> musicList = [];
  ERatio ratio = ERatio.ratio11;
  EMusicSpeed speed = EMusicSpeed.none;
  Resolution resolution = Resolution.fromRatio(ERatio.ratio11);
}

class SpotInfo {
  double startTime;
  String gpsString;

  SpotInfo(this.startTime, this.gpsString);
}


class VideoGeneratedResult {
  String generatedVideoPath;
  List<SpotInfo> spotInfoList;
  Map<int, String> thumbnailListMap;
  EMusicSpeed speed = EMusicSpeed.none;

  List<EditedMedia> editedMediaList = [];
  List<MusicData> musicList = [];

  String json = "";
  String titleKey = "";
  double renderTimeSec = 0;

  VideoGeneratedResult(this.generatedVideoPath, this.spotInfoList, this.thumbnailListMap);
}
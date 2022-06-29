import 'resource.dart';
import 'text.dart';

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
enum EMusicStyle {
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
  EMediaType type; // Media Tyle (image/video)
  int width; // Width
  int height; // Height
  double? duration; // Duration (video only)
  DateTime createDate; // Exif Create Date
  String gpsString;
  GPSData gpsData = GPSData(); // Exif GPS Data (Parsed)
  String? mlkitDetected;

  MediaData(this.absolutePath, this.type, this.width, this.height,
      this.duration, this.createDate, this.gpsString, this.mlkitDetected) {
    gpsData = GPSData.fromString(gpsString);
  }
}

class EditedMedia {
  MediaData mediaData;
  EMediaLabel mediaLabel = EMediaLabel.none;
  bool isBoundary = false;

  double startTime = 0;
  double duration = 0;
  double xfadeDuration = 0;

  int translateX = 0;
  int translateY = 0;
  double zoomX = 0;
  double zoomY = 0;

  FrameData? frame;
  StickerData? sticker;
  TransitionData? transition;
  TextExportData? exportedText;

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
  List<String> thumbnailList;
  String json = "";

  VideoGeneratedResult(this.generatedVideoPath, this.spotInfoList, this.thumbnailList);
}
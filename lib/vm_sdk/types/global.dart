import 'package:myapp/vm_sdk/types/resource.dart';

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
enum EMusicStyle { styleA, styleB, styleC }
enum EGenerateStatus { none, encoding, merge }

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
  GPSData gpsData = GPSData(); // Exif GPS Data (Parsed)
  String? mlkitDetected;

  MediaData(this.absolutePath, this.type, this.width, this.height,
      this.duration, this.createDate, String gpsString, this.mlkitDetected) {
    gpsData = GPSData.fromString(gpsString);
  }
}

class AutoEditMedia {
  MediaData mediaData;
  EMediaLabel mediaLabel = EMediaLabel.none;
  bool isBoundary = false;

  double startTime = 0;
  double duration = 0;

  String? stickerKey;
  String? transitionKey;

  AutoEditMedia(this.mediaData);
}

class AutoEditedData {
  List<AutoEditMedia> autoEditMediaList = [];
  List<MusicData> musicList = [];

  Map<String, TransitionData> transitionMap = <String, TransitionData>{};
  Map<String, StickerData> stickerMap = <String, StickerData>{};
}

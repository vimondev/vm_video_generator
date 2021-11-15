enum EMediaType { image, video }
enum EMusicStyle { styleA, styleB, styleC }
enum EGenerateStatus { none, encoding, merge }

class MediaData {
  String absolutePath; // File absolute path
  EMediaType type; // Media Tyle (image/video)
  int width; // Width
  int height; // Height
  double? duration; // Duration (video only)
  DateTime? createDate; // Exif Create Date
  String? gpsString; // Exif GPS String

  MediaData(this.absolutePath, this.type, this.width, this.height,
      this.duration, this.createDate, this.gpsString);
}

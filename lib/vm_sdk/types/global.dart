enum EMediaType { image, video }
enum EMusicStyle { styleA, styleB, styleC }
enum EGenerateStatus { none, encoding, merge }

class MediaData {
  String absolutePath;
  EMediaType type;
  int width;
  int height;
  double? duration;
  DateTime? createDate;
  String? gpsString;

  MediaData(this.absolutePath, this.type, this.width, this.height,
      this.duration, this.createDate, this.gpsString);
}

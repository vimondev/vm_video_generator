enum ETextType { Title, Caption }
class TextWidgetData {
  ETextType type;
  String json;

  List<String> fontFamily;
  List<String> fontBase64;
  List<String> texts = [];

  TextWidgetData(this.type, this.json, this.fontFamily, this.fontBase64);
}

class TextExportData {
  String id;

  double x = 0;
  double y = 0;
  double width;
  double height;
  double frameRate;
  double scale = 0;
  double rotate = 0;
  String previewImagePath;
  String allSequencesPath;

  Map<String, String> texts = {};

  TextExportData(this.id, this.width, this.height, this.frameRate,
      this.previewImagePath, this.allSequencesPath);
}

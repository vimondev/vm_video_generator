import '../impl/vm_text_widget.dart';

enum ETextType { Title, Caption }
class TextWidgetData {
  ETextType type;
  String json;
  double letterSpacing;

  List<String> fontFamily;
  List<String> fontBase64;
  List<String> texts = [];

  TextWidgetData(this.type, this.json, this.fontFamily, this.fontBase64, this.letterSpacing);
}
class TextExportData {
  String id;
  double width;
  double height;
  double frameRate;
  int totalFrameCount;
  String previewImagePath;
  String allSequencesPath;

  TextExportData(this.id, this.width, this.height, this.frameRate, this.totalFrameCount,
      this.previewImagePath, this.allSequencesPath);
}

class EditedTextData {
  String id;
  double x;
  double y;
  double width;
  double height;
  double rotate = 0;
  
  Map<String, String> texts = {};

  TextExportData? textExportData;
  EditedTextData(this.id, this.x, this.y, this.width, this.height);
}
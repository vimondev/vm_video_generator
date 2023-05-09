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
  final String id;
  final double width;
  final double height;
  final double frameRate;
  final int totalFrameCount;
  final String? previewImagePath;
  final String? allSequencesPath;
  final Map<String, VMText> textDataMap;

  TextExportData(
      {required this.id,
      required this.width,
      required this.height,
      required this.frameRate,
      required this.totalFrameCount,
      this.previewImagePath,
      this.allSequencesPath,
      this.textDataMap = const {}});

  TextExportData copyWith(
          {String? id,
          double? width,
          double? height,
          double? frameRate,
          int? totalFrameCount,
          String? previewImagePath,
          String? allSequencesPath,
          Map<String, VMText>? textDataMap}) =>
      TextExportData(
          id: id ?? this.id,
          width: width ?? this.width,
          height: height ?? this.height,
          frameRate: frameRate ?? this.frameRate,
          totalFrameCount: totalFrameCount ?? this.totalFrameCount);

  @override
  String toString() {
    return 'printAllData !!\npreviewImage : $previewImagePath\nwidth : $width\nheight : $height\nframeRate : $frameRate\ntotalFrameCount : $totalFrameCount\textDataMap : $textDataMap\nallSequencesPath : $allSequencesPath';
  }
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
